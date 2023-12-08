@tool
extends VBoxContainer


func _ready() -> void:
	if owner.get_parent() is SubViewport:
		return

	get_parent().set_tab_title(get_index(), "Unique Identifiers")
	get_parent().set_tab_icon(get_index(), get_theme_icon("Unlinked", "EditorIcons"))

	owner.get_parent().visibility_changed.connect(func(): if is_visible_in_tree(): open())
	get_parent().tab_changed.connect(func(tab:int): if tab == get_index(): open())


func open() -> void:
	fill_table()


func fill_table() -> void:
	var t: Tree = %IdentifierTable
	t.set_column_expand(1, true)
	t.clear()
	t.create_item()

	for d in [["Characters", 'dch'], ["Timelines", "dtl"]]:
		var directory := DialogicResourceUtil.get_directory(d[1])
		var directory_item := t.create_item()
		directory_item.set_text(0, d[0])
		directory_item.set_metadata(0, d[1])
		for key in directory:
			var item := t.create_item(directory_item)
			item.set_text(0, directory[key])
			item.set_text(1, key)
			item.set_editable(1, true)


func _on_identifier_table_item_edited() -> void:
	var item: TreeItem = %IdentifierTable.get_edited()
	var new_identifier : String = item.get_text(1)
	if new_identifier.is_empty():
		item.set_text(1, DialogicResourceUtil.get_unique_identifier(item.get_text(0)))
		return

	DialogicResourceUtil.change_unique_identifier(item.get_text(0), new_identifier)

	print(DialogicResourceUtil.get_directory(item.get_parent().get_metadata(0)))
