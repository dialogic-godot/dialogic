extends Control

func _ready() -> void:
	print("[Dialogic] Testing scene was started.")
	if not ProjectSettings.get_setting('internationalization/locale/test', "").is_empty():
		print("Testing locale is: ", ProjectSettings.get_setting('internationalization/locale/test'))
	$PauseIndictator.hide()

	var scene: Node = DialogicUtil.autoload().Styles.load_style(DialogicUtil.get_editor_setting('current_test_style', ''))
	if not scene is CanvasLayer:
		if scene is Control:
			scene.position = get_viewport_rect().size/2.0
		if scene is Node2D:
			scene.position = get_viewport_rect().size/2.0

	randomize()
	var current_timeline: String = DialogicUtil.get_editor_setting("current_timeline_path", "")
	var start_from_index: int = DialogicUtil.get_editor_setting("play_from_index", -1)
	if not current_timeline:
		get_tree().quit()
	DialogicUtil.autoload().start(current_timeline, start_from_index)
	DialogicUtil.autoload().timeline_ended.connect(get_tree().quit)
	DialogicUtil.autoload().signal_event.connect(receive_event_signal)
	DialogicUtil.autoload().text_signal.connect(receive_text_signal)

func receive_event_signal(argument:Variant) -> void:
	print("[Dialogic] Encountered a signal event: ", argument)

func receive_text_signal(argument:String) -> void:
	print("[Dialogic] Encountered a signal in text: ", argument)

func _input(event:InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		DialogicUtil.autoload().paused = !DialogicUtil.autoload().paused
		$PauseIndictator.visible = DialogicUtil.autoload().paused

	if (event is InputEventMouseButton
	and event.is_pressed()
	and event.button_index == MOUSE_BUTTON_MIDDLE):
		var auto_skip: DialogicAutoSkip = DialogicUtil.autoload().Inputs.auto_skip
		var is_auto_skip_enabled := auto_skip.enabled

		auto_skip.disable_on_unread_text = false
		auto_skip.enabled = not is_auto_skip_enabled
