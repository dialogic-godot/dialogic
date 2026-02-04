@tool
extends Control

var plugin_reference : EditorPlugin

var scene_root: Node

func _ready() -> void:
	plugin_reference.scene_changed.connect(_on_scene_changed)
	plugin_reference.scene_changed.connect(_on_scene_changed)

	%Internal.add_theme_color_override("font_color", get_theme_color("warning_color", "Editor"))
	%Title.add_theme_font_override("font", get_theme_font("bold", "EditorFonts"))
	%Title.add_theme_font_size_override("font_size", get_theme_font_size("font_size", "HeaderLarge"))
	%Title.add_theme_color_override("font_color", get_theme_color("accent_color", "Editor"))

	#var ed := EditorInspector.new()
	#$VBoxContainer.add_child(ed)
	#ed.edit(self)
	#ed.size_flags_vertical = Control.SIZE_EXPAND_FILL




func _on_scene_changed(new_scene_root:Node) -> void:
	if not new_scene_root or not (new_scene_root is DialogicLayoutBase or new_scene_root is DialogicLayoutLayer):
		close()
		hide()
	else:
		show()
		load_scene(new_scene_root)


func load_scene(new_scene_root:Node) -> void:
	scene_root = new_scene_root
	if scene_root.scene_file_path and scene_root.scene_file_path.begins_with("res://addons/dialogic/"):
		%Internal.show()
	else:
		%Internal.hide()
	print(scene_root.get_tree() == get_tree())
	print(scene_root.scene_file_path)
	%PropertyTree.load_data(scene_root.get_meta("style_customization", []), scene_root)


func close():
	scene_root = null



func _on_add_category_pressed() -> void:
	%PropertyTree.add_category_item()


func _on_property_tree_changed() -> void:
	scene_root.set_meta("style_customization", %PropertyTree.get_data())
	EditorInterface.mark_scene_as_unsaved()


func _on_print_pressed() -> void:
	print(%PropertyTree.get_data())
