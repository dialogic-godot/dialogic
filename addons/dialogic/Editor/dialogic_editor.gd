@tool
class_name DialogicEditor
extends Control

## Base class for all dialogic editors. 

# These signals will automatically be emitted if current_resource_state is changed.
signal resource_saved()
signal resource_unsaved()

var current_resource: Resource

## State of the current resource
enum ResourceStates {Saved, Unsaved}
var current_resource_state: ResourceStates:
	set(value):
		current_resource_state = value
		if value == ResourceStates.Saved:
			resource_saved.emit()
		else:
			resource_unsaved.emit()

var editors_manager: Control
# text displayed on the current resource label on non-resource editors
var alternative_text: String = ""

## Overwrite. Register to the editor manager in here.
func _register() -> void:
	pass


## If this editor supports editing resources, load them here (overwrite in subclass)
func _open_resource(resource:Resource) -> void:
	pass


## If this editor supports editing resources, save them here (overwrite in subclass)
func _save_resource() -> void:
	pass


## Overwrite. Called when this editor is shown. (show() doesn't have to be called)
func _open(extra_info:Variant = null) -> void:
	pass


## Overwrite. Called when another editor is opened. (hide() doesn't have to be called)
func _close():
	pass


## Overwrite. Called to clear all current state and resource from the editor.
## Although rarely used, sometimes you just want NO timeline to be open.
func _clear():
	pass
