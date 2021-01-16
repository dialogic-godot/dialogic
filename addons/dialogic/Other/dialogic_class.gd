extends Node
class_name Dialogic


static func start(timeline: String):
	var dialog = load("res://addons/dialogic/Dialog.tscn")
	var d = dialog.instance()
	for t in DialogicUtil.get_timeline_list():
		if t['name'] == timeline:
			print(t)
			d.timeline = t['file'].replace('.json', '')
			print(d.timeline)
			return d
	d.dialog_script = {
		"events":[{"character":"","portrait":"",
		"text":"[Dialogic Error] Loading dialog [color=red]" + timeline + "[/color]. It seems like the timeline doesn't exists. Maybe the name is wrong?"}]
	}
	return d
