extends DialogicSubsystem

## Subsystem that handles input, autoadvance & skipping.


signal dialogic_action_priority
signal dialogic_action
signal autoskip_timer_finished

var input_block_timer := Timer.new()
var _auto_skip_timer_left: float = 0.0
var action_was_consumed := false

var auto_skip: DialogicAutoSkip = null
var auto_advance : DialogicAutoAdvance = null

####### SUBSYSTEM METHODS ######################################################
#region SUBSYSTEM METHODS
func clear_game_state(clear_flag:=Dialogic.ClearFlags.FULL_CLEAR) -> void:
	if not is_node_ready():
		await ready


	set_manualadvance(true)

func pause() -> void:
	auto_advance.autoadvance_timer.paused = true
	input_block_timer.paused = true
	set_process(false)


func resume() -> void:
	auto_advance.autoadvance_timer.paused = false
	input_block_timer.paused = false
	var is_autoskip_timer_done := _auto_skip_timer_left > 0.0
	set_process(!is_autoskip_timer_done)

#endregion

####### MAIN METHODS ###########################################################
#region MAIN METHODS

func handle_input():
	if Dialogic.paused or is_input_blocked():
		return

	if !action_was_consumed:
		# We want to stop auto-advancing that cancels on user inputs.
		if (auto_advance.is_enabled()
			and auto_advance.enabled_until_user_input):
			auto_advance.enabled_until_next_event = false
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


## Unhandled Input is used for all NON-Mouse based inputs.
func _unhandled_input(event:InputEvent) -> void:
	if Input.is_action_pressed(ProjectSettings.get_setting('dialogic/text/input_action', 'dialogic_default_action')):
		if event is InputEventMouse:
			return
		handle_input()


## Input is used for all mouse based inputs.
## If any DialogicInputNode is present this won't do anything (because that node handles MouseInput then).
func _input(event:InputEvent) -> void:
	if Input.is_action_pressed(ProjectSettings.get_setting('dialogic/text/input_action', 'dialogic_default_action')):
		if not event is InputEventMouse or get_tree().get_nodes_in_group('dialogic_input').any(func(node):return node.is_visible_in_tree()):
			return
		handle_input()


func is_input_blocked() -> bool:
	return input_block_timer.time_left > 0.0


func block_input(time:=0.1) -> void:
	if time > 0:
		input_block_timer.wait_time = time
		input_block_timer.start()


func _ready() -> void:
	auto_skip = DialogicAutoSkip.new()
	auto_advance = DialogicAutoAdvance.new()

	# We use the process method to count down the auto-start_autoskip_timer timer.
	set_process(false)

func post_install() -> void:
	Dialogic.Settings.connect_to_change('autoadvance_delay_modifier', auto_advance._update_autoadvance_delay_modifier)
	auto_skip.toggled.connect(_on_autoskip_toggled)
	add_child(input_block_timer)
	input_block_timer.one_shot = true


func stop() -> void:
	auto_advance.autoadvance_timer.stop()
	input_block_timer.stop()
	_auto_skip_timer_left = 0.0

#endregion

####### AUTO-SKIP ##############################################################
#region AUTO-SKIP
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
func _process(delta):
	if _auto_skip_timer_left > 0:
		_auto_skip_timer_left -= delta

		if _auto_skip_timer_left <= 0:
			autoskip_timer_finished.emit()

	else:
		autoskip_timer_finished.emit()
		set_process(false)
#endregion

####### MANUAL ADVANCE #########################################################
#region MANUAL ADVANCE

func set_manualadvance(enabled:=true, temp:= false) -> void:
	if !dialogic.current_state_info.has('manual_advance'):
		dialogic.current_state_info['manual_advance'] = {'enabled':false, 'temp_enabled':false}
	if temp:
		dialogic.current_state_info['manual_advance']['temp_enabled'] = enabled
	else:
		dialogic.current_state_info['manual_advance']['enabled'] = enabled


func is_manualadvance_enabled() -> bool:
	return dialogic.current_state_info['manual_advance']['enabled'] and dialogic.current_state_info['manual_advance'].get('temp_enabled', true)

#endregion

####### TEXT EFFECTS ###########################################################
#region TEXT EFFECTS

func effect_input(text_node:Control, skipped:bool, argument:String) -> void:
	if skipped:
		return
	Dialogic.Text.show_next_indicators()
	await Dialogic.Input.dialogic_action_priority
	Dialogic.Text.hide_next_indicators()
	Dialogic.Input.action_was_consumed = true


func effect_noskip(text_node:Control, skipped:bool, argument:String) -> void:
	Dialogic.Text.set_text_reveal_skippable(false, true)
	set_manualadvance(false, true)
	effect_autoadvance(text_node, skipped, argument)


func effect_autoadvance(text_node: Control, skipped:bool, argument:String) -> void:
	if argument.ends_with('?'):
		argument = argument.trim_suffix('?')
	else:
		auto_advance.enabled_until_next_event = true

	if argument.is_valid_float():
		auto_advance.override_delay_for_current_event = float(argument)
#endregion
