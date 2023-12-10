@tool
extends VBoxContainer


func _ready() -> void:
	if owner.get_parent() is SubViewport:
		return

	get_parent().set_tab_title(get_index(), "Unique Identifiers")
	get_parent().set_tab_icon(get_index(), get_theme_icon("CryptoKey", "EditorIcons"))


	owner.get_parent().visibility_changed.connect(func(): if is_visible_in_tree(): open())
	get_parent().tab_changed.connect(func(tab:int): print(tab); if tab == get_index(): open())

	#get_theme_icon("Info", "EditorIcons")
	#get_theme_icon("Instance", "EditorIcons")
	#get_theme_icon("Key", "EditorIcons")
	#get_theme_icon("Key", "EditorIcons")
	#get_theme_icon("Pin", "EditorIcons")
	#get_theme_icon("FileAccess", "EditorIcons")

func open() -> void:
	print("open")
	fill_table()


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
	if new_identifier.is_empty():
		item.set_text(1, item.get_metadata(1))
		return
	DialogicResourceUtil.change_unique_identifier(item.get_text(0), new_identifier)

	print(DialogicResourceUtil.get_directory(item.get_parent().get_metadata(0)))
	match item.get_parent().get_metadata(0):
		'dch':
			owner.get_parent().add_character_name_ref_change(item.get_metadata(1), new_identifier)
		'dtl':
			owner.get_parent().add_timeline_name_ref_change(item.get_metadata(1), new_identifier)

	item.set_metadata(1, new_identifier)


func _on_identifier_table_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	print(column)
	item.select(column)
	%IdentifierTable.edit_selected()
