extends Node

## Exposed and safe to use methods for Dialogic
## See documentation here:
## https://github.com/coppolaemilio/dialogic

## ### /!\ ###
## Do not use methods from other classes as it could break the plugin's integrity
## ### /!\ ###
##
## Trying to follow this documentation convention: https://github.com/godotengine/godot/pull/41095
class_name Dialogic


## Refactor the start function for 2.0 there should be a cleaner way to do it :)

## Starts the dialog for the given timeline and returns a Dialog node.
## You must then add it manually to the scene to display the dialog.
##
## Example:
## var new_dialog = Dialogic.start('Your Timeline Name Here')
## add_child(new_dialog)
##
## This is exactly the same as using the editor:
## you can drag and drop the scene located at /addons/dialogic/Dialog.tscn 
## and set the current timeline via the inspector.
##
## @param timeline				The timeline to load. You can provide the timeline name or the filename.
## @param reset_saves			True to reset dialogic saved data such as definitions.
## @param dialog_scene_path		If you made a custom Dialog scene or moved it from its default path, you can specify its new path here.
## @param debug_mode			Debug is disabled by default but can be enabled if needed.
## @param use_canvas_instead	Create the Dialog inside a canvas layer to make it show up regardless of the camera 2D/3D situation.
## @returns						A Dialog node to be added into the scene tree.
static func start(timeline: String, reset_saves: bool=true, dialog_scene_path: String="res://addons/dialogic/Dialog.tscn", debug_mode: bool=false, use_canvas_instead=true):
	var dialog_scene = load(dialog_scene_path)
	var dialog_node = null
	var canvas_dialog_node = null
	var returned_dialog_node = null
	
	if use_canvas_instead:
		var canvas_dialog_script = load("res://addons/dialogic/Nodes/canvas_dialog_node.gd")
		canvas_dialog_node = canvas_dialog_script.new()
		canvas_dialog_node.set_dialog_node_scene(dialog_scene)
		dialog_node = canvas_dialog_node.dialog_node
	else:
		dialog_node = dialog_scene.instance()
	
	dialog_node.reset_saves = reset_saves
	dialog_node.debug_mode = debug_mode
	
	returned_dialog_node = dialog_node if not canvas_dialog_node else canvas_dialog_node
	
	if not timeline.empty():
		for t in DialogicUtil.get_timeline_list():
			if t['name'] == timeline or t['file'] == timeline:
				dialog_node.timeline = t['file']
				return returned_dialog_node
		dialog_node.dialog_script = {
			"events":[
				{"event_id":'dialogic_001',
				"character":"",
				"portrait":"",
				"text":"[Dialogic Error] Loading dialog [color=red]" + timeline + "[/color]. It seems like the timeline doesn't exists. Maybe the name is wrong?"
				}]
		}
	return returned_dialog_node


## Same as the start method above, but using the last timeline saved.
## 
## @param initial_timeline		The timeline to load in case no save is found.
## @param dialog_scene_path		If you made a custom Dialog scene or moved it from its default path, you can specify its new path here.
## @param debug_mode			Debug is disabled by default but can be enabled if needed.
## @returns						A Dialog node to be added into the scene tree.
static func start_from_save(initial_timeline: String, dialog_scene_path: String="res://addons/dialogic/Dialog.tscn", debug_mode: bool=false):
	var current := get_current_timeline()
	if current.empty():
		current = initial_timeline
	return start(current, false, dialog_scene_path, debug_mode)

## Gets default values for definitions.
## 
## @returns						Dictionary in the format {'variables': [], 'glossary': []}
static func get_default_definitions() -> Dictionary:
	return DialogicSingleton.get_default_definitions()


## Gets currently saved values for definitions.
## 
## @returns						Dictionary in the format {'variables': [], 'glossary': []}
static func get_definitions() -> Dictionary:
	return DialogicSingleton.get_definitions()


## Save current definitions to the filesystem.
## Definitions are automatically saved on timeline start/end
## 
## @returns						Error status, OK if all went well
static func save_definitions():
	# Always try to save as much as possible.
	var err1 = DialogicSingleton.save_definitions()
	var err2 = DialogicSingleton.save_state()

	# Try to combine the two error states in a way that makes sense.
	return err1 if err1 != OK else err2


## Sets whether to use Dialogic's built-in autosave functionality.
static func set_autosave(save: bool) -> void:
	DialogicSingleton.set_autosave(save);


## Gets whether to use Dialogic's built-in autosave functionality.
static func get_autosave() -> bool:
	return DialogicSingleton.get_autosave();


## Resets data to default values. This is the same as calling start with reset_saves to true
static func reset_saves():
	DialogicSingleton.init(true)


## Gets the value for the variable with the given name.
## The returned value is a String but can be easily converted into a number 
## using Godot built-in methods: 
## [`is_valid_float`](https://docs.godotengine.org/en/stable/classes/class_string.html#class-string-method-is-valid-float)
## [`float()`](https://docs.godotengine.org/en/stable/classes/class_float.html#class-float-method-float).
##
## @param name					The name of the variable to find.
## @returns						The variable's value as string, or an empty string if not found.
static func get_variable(name: String) -> String:
	return DialogicSingleton.get_variable(name)


## Sets the value for the variable with the given name.
## The given value will be converted to string using the 
## [`str()`](https://docs.godotengine.org/en/stable/classes/class_string.html) function.
##
## @param name					The name of the variable to edit.
## @param value					The value to set the variable to.
static func set_variable(name: String, value) -> void:
	DialogicSingleton.set_variable(name, value)


## Gets the glossary data for the definition with the given name.
## Returned format:
## { title': '', 'text' : '', 'extra': '' }
##
## @param name					The name of the glossary to find.
## @returns						The glossary data as a Dictionary.
## 								A structure with empty strings is returned if the glossary was not found. 
static func get_glossary(name: String) -> Dictionary:
	return DialogicSingleton.get_glossary(name)


## Sets the data for the glossary of the given name.
## 
## @param name					The name of the glossary to edit.
## @param title					The title to show in the information box.
## @param text					The text to show in the information box.
## @param extra					The extra information at the bottom of the box.
static func set_glossary(name: String, title: String, text: String, extra: String) -> void:
	DialogicSingleton.set_glossary(name, title, text, extra)


## Gets the currently saved timeline.
## Timeline saves are set on timeline start, and cleared on end.
## This means you can keep track of timeline changes and detect when the dialog ends.
##
## @returns						The current timeline filename, or an empty string if none was saved.
static func get_current_timeline() -> String:
	return DialogicSingleton.get_current_timeline()


## Sets the currently saved timeline.
## Use this if you disabled current timeline autosave and want to control it yourself
##
## @param timelinie						The new timeline to save.
static func set_current_timeline(new_timeline: String) -> String:
	return DialogicSingleton.set_current_timeline(new_timeline)


## Export the current Dialogic state.
## This can be used as part of your own saving mechanism if you have one. If you use this,
## you should also disable autosaving.
##
## @return						A dictionary of data that can be later provided to import().
static func export() -> Dictionary:
	return DialogicSingleton.export()


## Import a Dialogic state.
## This can be used as part of your own saving mechanism if you have one. If you use this,
## you should also disable autosaving.
##
## @param data				A dictionary of data as created by export().
static func import(data: Dictionary) -> void:
	DialogicSingleton.import(data)
