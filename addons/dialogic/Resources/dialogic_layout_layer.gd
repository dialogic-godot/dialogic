@tool
class_name DialogicLayoutLayer
extends Node

## Base class that should be extended by custom dialogic layout layers.

@export_group("Layer")
## If [code]true[/code] the layer is hidden and it's processing disabled.
@export var disabled := false

## @deprecated
### If [code]true[/code] [method _apply_export_overrides] is called on _ready(). [br]
### When a layer is used in a style, [method _apply_export_overrides] is called
### by the base layer on style changes. However when a style is made custom,
### you might want them to either still be applied (set to [code]true[/code]) or edit settings directly on their nodes going forward (set to [code]false[/code]).
### This is turned on automatically when making the custom.
@export var apply_overrides_on_ready := false

## @deprecated
var this_folder: String = get_script().resource_path.get_base_dir()


func _init() -> void:
	set_meta("base_style_customization", [
		{"type":"Category", "name":"Layer"},
		{"type":"Node", "name":".", "display_name":"General"},
		{"type":"Property", "name":"disabled", "display_name":"Disabled", "tooltip":""}
		])


func _ready() -> void:
	pass

	## TODO: REMOVE
	if apply_overrides_on_ready and not Engine.is_editor_hint():
		_apply_export_overrides()


## @deprecated
## Override this and load all your exported settings (apply them to the scene) TODO: REMOVE
func _apply_export_overrides() -> void:
	pass


func apply_export_overrides() -> void:
	if disabled:
		if "visible" in self:
			set("visible", false)
		process_mode = Node.PROCESS_MODE_DISABLED
	else:
		if "visible" in self:
			set("visible", true)
		process_mode = Node.PROCESS_MODE_INHERIT

	_apply_export_overrides()


## @deprecated
## Use this to get potential global settings. TODO: REMOVE
func get_global_setting(setting_name:StringName, default:Variant) -> Variant:
	return get_parent().get_global_setting(setting_name, default)
