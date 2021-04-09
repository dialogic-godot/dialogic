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

## Gets a DialogicNode instance to be added to the tree
## This instance can then be added to the tree using add_child()
## To start the timeline, use the start method from the returned node
static func get_instance():
	var dialog : = load("res://addons/dialogic/Dialog.tscn")
	return dialog.instance()


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
func save_definitions():
	return DialogicSingleton.save_definitions()


## Resets data to default values. This is the same as calling start with reset_saves to true
func reset_saves():
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
