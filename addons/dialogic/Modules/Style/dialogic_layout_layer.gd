@tool
@icon("layout_layer_icon.svg")
class_name DialogicLayoutLayer
extends Control

## Base class that should be extended by custom dialogic layout layers.

## If [code]true[/code] the layer is hidden and it's processing disabled.
@export var disabled := false:
	set(d):
		disabled = d
		visible = not disabled


## TODO remove
## @deprecated
### If [code]true[/code] [method _apply_export_overrides] is called on _ready(). [br]
### When a layer is used in a style, [method _apply_export_overrides] is called
### by the base layer on style changes. However when a style is made custom,
### you might want them to either still be applied (set to [code]true[/code]) or edit settings directly on their nodes going forward (set to [code]false[/code]).
### This is turned on automatically when making the custom.
var apply_overrides_on_ready := false

## @deprecated
var this_folder: String = get_script().resource_path.get_base_dir()


## Emitted after dialogic has applied customization
@warning_ignore("unused_signal") # emitted by DialogicUtil.apply_scene_export_overrides()
signal customization_applied


func _get_base_customization() -> Array[Dictionary]:
	return [
		{"type":"Category", "name":"Layer"},
		{"type":"Node", "name":".", "display_name":"General"},
		{"type":"Property", "name":"disabled", "display_name":"Disabled", "tooltip":"If disabled, the layer is hidden and processing is disabled."},
		{"type":"Property", "name":"theme", "display_name":"Theme", "tooltip":"Set the theme of this layer if you know your way around godot themes."},
		{"type":"Property", "name":"texture_filter", "display_name":"Texture Filter", "tooltip":"If you use pixel-art textures, set this to 'Nearest' so they are not blurry."}
		]


func _ready() -> void:
	### TODO: REMOVE
	if apply_overrides_on_ready and not Engine.is_editor_hint():
		_apply_export_overrides()


## @deprecated
## Override this and load all your exported settings (apply them to the scene) TODO: REMOVE
func _apply_export_overrides() -> void:
	pass


## @deprecated
func apply_export_overrides() -> void:
	_apply_export_overrides()


## @deprecated
## Use this to get potential global settings. TODO: REMOVE
func get_global_setting(setting_name:StringName, default:Variant) -> Variant:
	return get_parent().get_global_setting(setting_name, default)
