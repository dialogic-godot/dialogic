extends Node
class_name Dialogic


static func start(timeline: String, dialog_scene_path: String="res://addons/dialogic/Dialog.tscn", debug_mode:bool=false):
	var dialog = load(dialog_scene_path)
	var d = dialog.instance()
	d.debug_mode = debug_mode
	for t in DialogicUtil.get_timeline_list():
		if t['name'] == timeline:
			d.timeline = t['file'].replace('.json', '')
			return d
	d.dialog_script = {
		"events":[{"character":"","portrait":"",
		"text":"[Dialogic Error] Loading dialog [color=red]" + timeline + "[/color]. It seems like the timeline doesn't exists. Maybe the name is wrong?"}]
	}
	return d


static func get_var(variable: String):
	return DialogicUtil.get_var(variable)


static func set_var(variable: String, value):
	for d in DialogicUtil.get_definition_list():
		if d['name'] == variable:
			DialogicUtil.set_definition(d['section'], 'value', value)
	return value
