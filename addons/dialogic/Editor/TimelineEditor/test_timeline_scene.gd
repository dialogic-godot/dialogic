extends Control

func _ready() -> void:
	print("[Dialogic] Testing scene was started.")
	if !ProjectSettings.get_setting('internationalization/locale/test', "").is_empty():
		print("Testing locale is: ", ProjectSettings.get_setting('internationalization/locale/test'))
	$PauseIndictator.hide()
	var dialog_scene_path: String = ProjectSettings.get_setting(
		'dialogic/layout/layout_scene',
		DialogicUtil.get_default_layout()
	)
	var scene: Node = load(dialog_scene_path).instantiate()
	DialogicUtil.apply_scene_export_overrides(scene, ProjectSettings.get_setting('dialogic/layout/export_overrides', {}))
	add_child(scene)
	if not scene is CanvasLayer:
		if scene is Control:
			scene.position = get_viewport_rect().size/2.0
		if scene is Node2D:
			scene.position = get_viewport_rect().size/2.0

	randomize()
	var current_timeline: String = DialogicUtil.get_editor_setting('current_timeline_path')
	Dialogic.start_timeline(current_timeline)
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
