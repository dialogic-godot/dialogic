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
	for t in DialogicUtil.get_timeline_list():
		if t['name'] == timeline:
			d.timeline = t['file'].replace('.json', '')
			return d
	d.dialog_script = {
		"events":[{"character":"","portrait":"",
		"text":"[Dialogic Error] Loading dialog [color=red]" + timeline + "[/color]. It seems like the timeline doesn't exists. Maybe the name is wrong?"}]
	}
	return d


static func get_default_definitions_list() -> Array:
	return DialogicDefinitionsSingleton.get_default_definitions_list()


static func get_definitions_list() -> Array:
	return DialogicDefinitionsSingleton.get_definitions_list()


func save_definitions():
	return DialogicDefinitionsSingleton.save_definitions()


func reset_definitions():
	return DialogicDefinitionsSingleton.init(true)


static func get_variable(name: String) -> String:
	return DialogicDefinitionsSingleton.get_variable(name)


static func set_variable(name: String, value) -> void:
	DialogicDefinitionsSingleton.set_variable(name, value)


func get_glossary(name: String) -> Dictionary:
	return DialogicDefinitionsSingleton.get_glossary(name)


func set_glossary(name: String, title: String, text: String, extra: String) -> void:
	DialogicDefinitionsSingleton.set_glossary(name, title, text, extra)
