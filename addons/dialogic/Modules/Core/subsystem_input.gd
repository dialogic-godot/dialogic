extends DialogicSubsystem
## Subsystem that handles input, Auto-Advance, and skipping.
##
## This subsystem can be accessed via GDScript: `Dialogic.Inputs`.


signal dialogic_action_priority
signal dialogic_action

## Whenever the Auto-Skip timer finishes, this signal is emitted.
## Configure Auto-Skip settings via [member auto_skip].
signal autoskip_timer_finished


const _SETTING_INPUT_ACTION := "dialogic/text/input_action"
const _SETTING_INPUT_ACTION_DEFAULT := "dialogic_default_action"

var input_block_timer := Timer.new()
var _auto_skip_timer_left: float = 0.0
var action_was_consumed := false
var input_was_mouse_input := false

var auto_skip: DialogicAutoSkip = null
var auto_advance: DialogicAutoAdvance = null
var manual_advance: DialogicManualAdvance = null


#region SUBSYSTEM METHODS
################################################################################

func clear_game_state(_clear_flag := DialogicGameHandler.ClearFlags.FULL_CLEAR) -> void:
	if not is_node_ready():
		await ready

	manual_advance.disabled_until_next_event = false
	manual_advance.system_enabled = true


func pause() -> void:
	auto_advance.autoadvance_timer.paused = true
	input_block_timer.paused = true
	set_process(false)


func resume() -> void:
	auto_advance.autoadvance_timer.paused = false
	input_block_timer.paused = false
	var is_autoskip_timer_done := _auto_skip_timer_left > 0.0
	set_process(!is_autoskip_timer_done)


func post_install() -> void:
	dialogic.Settings.connect_to_change('autoadvance_delay_modifier', auto_advance._update_autoadvance_delay_modifier)
	auto_skip.toggled.connect(_on_autoskip_toggled)
	auto_skip._init()
	add_child(input_block_timer)
	input_block_timer.one_shot = true


#endregion


#region MAIN METHODS
################################################################################

func handle_input() -> void:
	if dialogic.paused or is_input_blocked():
		return

	if not action_was_consumed:
		# We want to stop auto-advancing that cancels on user inputs.
		if (auto_advance.is_enabled()
			and auto_advance.enabled_until_user_input):
			auto_advance.enabled_until_user_input = false
			action_was_consumed = true

		# We want to stop auto-skipping if it's enabled, we are listening
		# to user inputs, and it's not instant skipping.
		if (auto_skip.disable_on_user_input
		and auto_skip.enabled):
			auto_skip.enabled = false
			action_was_consumed = true


	dialogic_action_priority.emit()

	if action_was_consumed:
		action_was_consumed = false
		return

	dialogic_action.emit()
	input_was_mouse_input = false


## Unhandled Input is used for all NON-Mouse based inputs.
func _unhandled_input(event:InputEvent) -> void:
	if is_input_pressed(event, true):
		if event is InputEventMouse or event is InputEventScreenTouch:
			return
		input_was_mouse_input = false
		handle_input()


## Input is used for all mouse based inputs.
## If any DialogicInputNode is present this won't do anything (because that node handles MouseInput then).
func _input(event:InputEvent) -> void:
	if is_input_pressed(event):
		if not event is InputEventMouse:
			return
		if get_tree().get_nodes_in_group('dialogic_input').any(func(node):return node.is_visible_in_tree()):
			return
		input_was_mouse_input = true
		handle_input()


func is_input_pressed(event: InputEvent, exact := false) -> bool:
	var action: String = ProjectSettings.get_setting(_SETTING_INPUT_ACTION, _SETTING_INPUT_ACTION_DEFAULT)
	return (event is InputEventAction and event.action == action) or Input.is_action_just_pressed(action, exact)


## This is called from the gui_input of the InputCatcher and DialogText nodes
func handle_node_gui_input(event:InputEvent) -> void:
	if Input.is_action_just_pressed(ProjectSettings.get_setting(_SETTING_INPUT_ACTION, _SETTING_INPUT_ACTION_DEFAULT)):
		if event is InputEventMouseButton and event.pressed:
			input_was_mouse_input = true
			handle_input()


func is_input_blocked() -> bool:
	return input_block_timer.time_left > 0.0 and not auto_skip.enabled


func block_input(time:=0.1) -> void:
	if time > 0:
		input_block_timer.wait_time = max(time, input_block_timer.time_left)
		input_block_timer.start()


func _ready() -> void:
	auto_skip = DialogicAutoSkip.new()
	auto_advance = DialogicAutoAdvance.new()
	manual_advance = DialogicManualAdvance.new()

	# We use the process method to count down the auto-start_autoskip_timer timer.
	set_process(false)


func stop_timers() -> void:
	auto_advance.autoadvance_timer.stop()
	input_block_timer.stop()
	_auto_skip_timer_left = 0.0

#endregion


#region AUTO-SKIP
################################################################################

## This method will advance the timeline based on Auto-Skip settings.
## The state, whether Auto-Skip is enabled, is ignored.
func start_autoskip_timer() -> void:
	_auto_skip_timer_left = auto_skip.time_per_event
	set_process(true)
	await autoskip_timer_finished


## If Auto-Skip disables, we want to stop the timer.
func _on_autoskip_toggled(enabled: bool) -> void:
	if not enabled:
		_auto_skip_timer_left = 0.0


## Handles fine-grained Auto-Skip logic.
## The [method _process] method allows for a more precise timer than the
## [Timer] class.
func _process(delta: float) -> void:
	if _auto_skip_timer_left > 0:
		_auto_skip_timer_left -= delta

		if _auto_skip_timer_left <= 0:
			autoskip_timer_finished.emit()

	else:
		autoskip_timer_finished.emit()
		set_process(false)

#endregion

#region TEXT EFFECTS
################################################################################


func effect_input(_text_node:Control, skipped:bool, _argument:String) -> void:
	if skipped:
		return
	dialogic.Text.show_next_indicators()
	await dialogic.Inputs.dialogic_action_priority
	dialogic.Text.hide_next_indicators()
	dialogic.Inputs.action_was_consumed = true


func effect_noskip(text_node:Control, skipped:bool, argument:String) -> void:
	dialogic.Text.set_text_reveal_skippable(false, true)
	manual_advance.disabled_until_next_event = true
	effect_autoadvance(text_node, skipped, argument)


func effect_autoadvance(_text_node: Control, _skipped:bool, argument:String) -> void:
	if argument.ends_with('?'):
		argument = argument.trim_suffix('?')
	else:
		auto_advance.enabled_until_next_event = true

	if argument.is_valid_float():
		auto_advance.override_delay_for_current_event = float(argument)

#endregion
