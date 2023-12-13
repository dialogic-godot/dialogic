@tool
extends PanelContainer


func _ready() -> void:
	if owner.get_parent() is SubViewport:
		return

	%TabB.text = "Unique Identifiers"
	%TabB.icon = get_theme_icon("CryptoKey", "EditorIcons")

	owner.get_parent().visibility_changed.connect(func(): if is_visible_in_tree(): open())

	%RenameNotification.add_theme_color_override("font_color", get_theme_color("warning_color", "Editor"))


func open() -> void:
	fill_table()
	%RenameNotification.hide()


func close() -> void:
	pass

func fill_table() -> void:
	var t: Tree = %IdentifierTable
	t.set_column_expand(1, true)
	t.clear()
	t.set_column_title(1, "Identifier")
	t.set_column_title(0, "Resource Path")
	t.set_column_title_alignment(0, 0)
	t.set_column_title_alignment(1, 0)
	t.create_item()

	for d in [["Characters", 'dch'], ["Timelines", "dtl"]]:
		var directory := DialogicResourceUtil.get_directory(d[1])
		var directory_item := t.create_item()
		directory_item.set_text(0, d[0])
		directory_item.set_metadata(0, d[1])
		for key in directory:
			var item: TreeItem = t.create_item(directory_item)
			item.set_text(0, directory[key])
			item.set_text(1, key)
			item.set_editable(1, true)
			item.set_metadata(1, key)
			item.add_button(1, get_theme_icon("Edit", "EditorIcons"), 0, false, "Edit")


func _on_identifier_table_item_edited() -> void:
	var item: TreeItem = %IdentifierTable.get_edited()
	var new_identifier : String = item.get_text(1)


	if new_identifier == item.get_metadata(1):
		return

	if new_identifier.is_empty() or not DialogicResourceUtil.is_identifier_unused(item.get_parent().get_metadata(0), new_identifier):
		item.set_text(1, item.get_metadata(1))
		return

	DialogicResourceUtil.change_unique_identifier(item.get_text(0), new_identifier)

	match item.get_parent().get_metadata(0):
		'dch':
			owner.get_parent().add_character_name_ref_change(item.get_metadata(1), new_identifier)
		'dtl':
			owner.get_parent().add_timeline_name_ref_change(item.get_metadata(1), new_identifier)

	%RenameNotification.show()
	item.set_metadata(1, new_identifier)


func _on_identifier_table_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	item.select(column)
	%IdentifierTable.edit_selected(true)


func _on_help_button_pressed() -> void:
	pass # Replace with function body.
