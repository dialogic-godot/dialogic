extends Control


func _ready():
	var dialog_scene_path = DialogicUtil.get_project_setting(
		'dialogic/editor/test_dialog_scene', 'res://addons/dialogic/Other/DefaultDialogNode.tscn')
	var scene = load(dialog_scene_path).instantiate()
	add_child(scene)
	if !get_child(0) is CanvasLayer:
		if get_child(0) is Control:
			get_child(0).rect_position = get_viewport_rect().size/2.0
		if get_child(0) is Node2D:
			get_child(0).position = get_viewport_rect().size/2.0
	
	randomize()
	var current_timeline = ProjectSettings.get_setting('dialogic/editor/current_timeline_path')
	Dialogic.start_timeline(current_timeline)
	Dialogic.timeline_ended.connect(get_tree().quit)
	Dialogic.signal_event.connect(recieve_event_signal)
	Dialogic.text_signal.connect(recieve_text_signal)

func recieve_event_signal(argument):
	print("[Dialogic] Encountered a signal event: ", argument)

func recieve_text_signal(argument):
	print("[Dialogic] Encountered a signal in text: ", argument)
	