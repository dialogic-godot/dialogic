@tool
extends Control

var plugin_reference : EditorPlugin

var scene_root: Node

var unre: EditorUndoRedoManager

func _ready() -> void:
	if get_parent() is SubViewport:
		return

	plugin_reference.scene_changed.connect(_on_scene_changed)
	unre = EditorInterface.get_editor_undo_redo()

	%Internal.add_theme_color_override("font_color", get_theme_color("warning_color", "Editor"))
	%Title.add_theme_font_override("font", get_theme_font("bold", "EditorFonts"))
	%Title.add_theme_font_size_override("font_size", get_theme_font_size("font_size", "HeaderLarge"))
	%Title.add_theme_color_override("font_color", get_theme_color("accent_color", "Editor"))

	%DropInfoLabel.add_theme_stylebox_override("normal", get_theme_stylebox("normal", "LineEdit"))

func _on_scene_changed(new_scene_root:Node) -> void:
	if new_scene_root and (new_scene_root is DialogicLayoutBase or new_scene_root is DialogicLayoutLayer or new_scene_root.has_meta("style_customization")):
		show()
		load_scene(new_scene_root)
	else:
		close()
		hide()


func load_scene(new_scene_root:Node) -> void:
	scene_root = new_scene_root

	# Show warning for internal scenes
	if scene_root.scene_file_path and scene_root.scene_file_path.begins_with("res://addons/dialogic/"):
		%Internal.show()
	else:
		%Internal.hide()

	%PropertyTree.load_data(scene_root.get_meta("style_customization", []))


func close():
	scene_root = null


func _on_add_category_pressed() -> void:
	%PropertyTree.add_category_item()


func _on_property_tree_changed() -> void:
	var new_data: Array = %PropertyTree.get_data()
	var old_data: Array = scene_root.get_meta("style_customization", [])
	unre.create_action("Set Dialogic Style Customization Options")
	unre.add_do_method(scene_root, "set_meta", "style_customization", new_data)
	unre.add_do_method(self, "update_inspector")
	unre.add_do_method(%PropertyTree, "load_data", new_data)
	unre.add_undo_method(scene_root, "set_meta", "style_customization", old_data)
	unre.add_undo_method(%PropertyTree, "load_data", old_data)
	unre.add_undo_method(self, "update_inspector")
	unre.commit_action()
	EditorInterface.mark_scene_as_unsaved()


func update_inspector() -> void:
	var edited_object := EditorInterface.get_inspector().get_edited_object()
	if edited_object is Node and scene_root.is_ancestor_of(edited_object) or scene_root == edited_object:
		# smol hack to force the inspector to update
		EditorInterface.edit_node(self)
		EditorInterface.edit_node(edited_object)


func _on_print_pressed() -> void:
	print(%PropertyTree.get_data())


func property_override_button_clicked(node:Node, property:String) -> void:
	%PropertyTree.highlight_property(node, property)
