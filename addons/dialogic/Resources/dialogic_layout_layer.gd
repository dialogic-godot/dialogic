@tool
class_name DialogicLayoutLayer
extends Node

## Base class that should be extended by custom dialogic layout layers.

@export_group('Layer')
@export_subgroup('Disabled')
@export var disabled := false

## This is turned on automatically when the layout is realized [br] [br]
## Turn it off, if you want to modify the settings of the nodes yourself.
@export_group('Private')
@export var apply_overrides_on_ready := false

var this_folder: String = get_script().resource_path.get_base_dir()

func _ready() -> void:
	if apply_overrides_on_ready and not Engine.is_editor_hint():
		_apply_export_overrides()



## Override this and load all your exported settings (apply them to the scene)
func _apply_export_overrides() -> void:
	pass


func apply_export_overrides() -> void:
	if disabled:
		if "visible" in self:
			set('visible', false)
		process_mode = Node.PROCESS_MODE_DISABLED
	else:
		if "visible" in self:
			set('visible', true)
		process_mode = Node.PROCESS_MODE_INHERIT

	_apply_export_overrides()


## Use this to get potential global settings.
func get_global_setting(setting_name:StringName, default:Variant) -> Variant:
	return get_parent().get_global_setting(setting_name, default)
