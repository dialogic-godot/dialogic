extends Control

func _ready() -> void:
	print("[Dialogic] Testing scene was started.")
	if !ProjectSettings.get_setting('internationalization/locale/test', "").is_empty():
		print("Testing locale is: ", ProjectSettings.get_setting('internationalization/locale/test'))
	$PauseIndictator.hide()
	
	var scene: Node = Dialogic.Styles.add_layout_style(DialogicUtil.get_editor_setting('current_test_style', ''))
	if not scene is CanvasLayer:
		if scene is Control:
			scene.position = get_viewport_rect().size/2.0
		if scene is Node2D:
			scene.position = get_viewport_rect().size/2.0

	randomize()
	var current_timeline: String = DialogicUtil.get_editor_setting('current_timeline_path')
	Dialogic.start(current_timeline)
	Dialogic.timeline_ended.connect(get_tree().quit)
	Dialogic.signal_event.connect(recieve_event_signal)
	Dialogic.text_signal.connect(recieve_text_signal)

func recieve_event_signal(argument:String) -> void:
	print("[Dialogic] Encountered a signal event: ", argument)

func recieve_text_signal(argument:String) -> void:
	print("[Dialogic] Encountered a signal in text: ", argument)

func _input(event:InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Dialogic.paused = !Dialogic.paused
		$PauseIndictator.visible = Dialogic.paused
