@tool
extends "res://addons/dialogic/Editor/Common/browser.gd"

enum Types {ALL, STYLES, LAYER, LAYOUT_BASE}
var type_to_str := {Types.STYLES:"Style", Types.LAYER:"Layer", Types.LAYOUT_BASE:"Layout Base"}

var current_type := Types.ALL
var style_part_info: Array[Dictionary]= []
var premade_scenes_reference := {}


func _ready() -> void:
	super()
	collect_style_parts()
	request_reload.connect(reload)


func collect_style_parts() -> void:
	style_part_info.clear()
	premade_scenes_reference.clear()
	for indexer in DialogicUtil.get_indexers():
		for layout_part in indexer._get_layout_parts():
			style_part_info.append(layout_part)
			if not layout_part.get('path', '').is_empty():
				premade_scenes_reference[layout_part['path']] = layout_part


func is_premade_style_part(scene_path:String) -> bool:
	return scene_path in premade_scenes_reference


func browse_styles() -> void:
	current_type = Types.STYLES
	browse()


func browse_layers() -> void:
	current_type = Types.LAYER
	browse()


func browse_layout_bases() -> void:
	current_type = Types.LAYOUT_BASE
	browse()


func browse() -> void:
	open()
	load_items(style_part_info.filter(func(x): return x.type == type_to_str[current_type]))


func reload():
	collect_style_parts()
	browse()
