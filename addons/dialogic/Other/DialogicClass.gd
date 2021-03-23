extends Node
class_name Dialogic

# TODO save definitions on timeline end

# Exposed and safe to use methods for Dialogic
# See documentation here:
# https://github.com/coppolaemilio/dialogic

# ### /!\ ###
# Do not use methods from other classes as it could break the plugin's integrity
# ### /!\ ###

static func start(timeline: String, reset_saves: bool=true, dialog_scene_path: String="res://addons/dialogic/Dialog.tscn", debug_mode: bool=false):
	var dialog:  = load(dialog_scene_path)
	var d = dialog.instance()
	d.reset_saves = reset_saves
	d.debug_mode = debug_mode
	if not timeline.empty():
		for t in DialogicUtil.get_timeline_list():
			if t['name'] == timeline or t['file'] == timeline:
				d.timeline = t['file']
				return d
		d.dialog_script = {
			"events":[{"character":"","portrait":"",
			"text":"[Dialogic Error] Loading dialog [color=red]" + timeline + "[/color]. It seems like the timeline doesn't exists. Maybe the name is wrong?"}]
		}
	return d


static func start_from_save(initial_timeline: String, dialog_scene_path: String="res://addons/dialogic/Dialog.tscn", debug_mode: bool=false):
	var current := get_current_timeline()
	if current.empty():
		current = initial_timeline
	return start(current, false, dialog_scene_path, debug_mode)


static func get_default_definitions() -> Dictionary:
	return DialogicSingleton.get_default_definitions()


static func get_definitions() -> Dictionary:
	return DialogicSingleton.get_default_definitions()


func save_definitions():
	return DialogicSingleton.save_definitions()


func reset_saves():
	return DialogicSingleton.init(true)


static func get_variable(name: String) -> String:
	return DialogicSingleton.get_variable(name)


static func set_variable(name: String, value) -> void:
	DialogicSingleton.set_variable(name, value)


static func get_glossary(name: String) -> Dictionary:
	return DialogicSingleton.get_glossary(name)


static func set_glossary(name: String, title: String, text: String, extra: String) -> void:
	DialogicSingleton.set_glossary(name, title, text, extra)


static func get_current_timeline() -> String:
	return DialogicSingleton.get_current_timeline()
