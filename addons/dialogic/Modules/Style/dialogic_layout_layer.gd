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


## @deprecated
## TODO: Remove when dropping support for pre alpha 21 Styles
### If [code]true[/code] [method _apply_export_overrides] is called on _ready(). [br]
### When a layer is used in a style, [method _apply_export_overrides] is called
### by the base layer on style changes. However when a style is made custom,
### you might want them to either still be applied (set to [code]true[/code]) or edit settings directly on their nodes going forward (set to [code]false[/code]).
### This is turned on automatically when making the custom.
var apply_overrides_on_ready := false

## @deprecated
## TODO: Remove when dropping support for pre alpha 21 Styles
var this_folder: String = get_script().resource_path.get_base_dir()


## Emitted after dialogic has applied export_overrides
@warning_ignore("unused_signal") # emitted by DialogicUtil.apply_scene_export_overrides()
signal overrides_applied


func _init() -> void:
	## This is to attempt upgrading old style scenes to the new system.
	if not has_meta("export_overrides"):
		update_export_overrides()


func _get_base_export_overrides() -> Array[Dictionary]:
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
## TODO: Remove when dropping support for pre alpha 21 Styles
## Override this and load all your exported settings (apply them to the scene) TODO: REMOVE
func _apply_export_overrides() -> void:
	pass


## @deprecated
## TODO: Remove when dropping support for pre alpha 21 Styles
func apply_export_overrides() -> void:
	_apply_export_overrides()


## @deprecated
## TODO: Remove when dropping support for pre alpha 21 Styles
## Use this to get potential global settings. TODO: REMOVE
func get_global_setting(setting_name:StringName, default:Variant) -> Variant:
	return get_parent().get_global_setting(setting_name, default)


## @deprecated
## TODO: Remove when dropping support for pre alpha 21 Styles
func update_export_overrides() -> Array[Dictionary]:
	var properties: Array[Dictionary] = self.script.get_script_property_list()
	var settings: Array[Dictionary] = []

	var current_group := {}
	var current_subgroup := {}

	for i in properties:
		if i["usage"] & PROPERTY_USAGE_CATEGORY == PROPERTY_USAGE_CATEGORY:
			continue

		if i["usage"] & PROPERTY_USAGE_GROUP == PROPERTY_USAGE_GROUP:
			settings.append({"type":"Category", "name":i.get("name", "General")})
			current_group = i
			current_subgroup = {}

		elif i["usage"] & PROPERTY_USAGE_SUBGROUP == PROPERTY_USAGE_SUBGROUP:
			settings.append({"type":"Node", "name":".", "display_name":i.get("name", "")},)
			current_subgroup = i

		elif i["usage"] & PROPERTY_USAGE_EDITOR == PROPERTY_USAGE_EDITOR:
			if current_group.get("name", "") == "Private":
				continue

			if current_group.is_empty():
				settings.append({"type":"Category", "name":"General"})
				current_group = {"name":"General"}

			if current_subgroup.is_empty():
				settings.append({"type":"Node", "name":".", "display_name":"General"})
				current_subgroup = {"name":"General"}

			settings.append({"type":"Property", "name":i.get("name", "")},
		)
	set_meta("export_overrides", settings)
	#print("[Dialogic] Updated layer scene exports: ", get_script().resource_path)

	return settings
