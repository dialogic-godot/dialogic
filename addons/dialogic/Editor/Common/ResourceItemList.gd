class_name ResourceListItem extends Object
var text: String
var index: int = -1
var icon: Texture
var metadata: String
var tooltip: String


func add_to_item_list(item_list: ItemList, current_file: String) -> void:
	item_list.add_item(text, icon)
	item_list.set_item_metadata(item_list.item_count - 1, metadata)
	item_list.set_item_tooltip(item_list.item_count - 1, tooltip)


func current_file(sidebar: Control, resource_list: ItemList, current_file: String) -> void:
	if metadata == current_file:
		resource_list.select(index)
		resource_list.set_item_custom_fg_color(
			index, resource_list.get_theme_color("accent_color", "Editor")
		)
		sidebar.find_child("CurrentResource").text = metadata.get_file()
