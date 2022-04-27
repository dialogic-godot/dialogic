tool
extends PopupMenu

## This serves as a builder for the popup menu
## Its behaviour is inside the timeline editor, since
## this node doesn't need its context at all.

# ItemType and item generation have a 1:1 relationship
# Use get_item_index(ItemType) to get the idx of that item
enum ItemType {
	TITLE,
	EDIT,
	DUPLICATE,
	REMOVE,
	HELP,
	MOVE_UP,
	MOVE_DOWN,
	}

var used_event:Resource setget set_event
var shortcuts = load("res://addons/dialogic/Editor/shortcuts.gd")

func _enter_tree() -> void:
	var remove_shortcut = shortcuts.get_shortcut("remove")
	var duplicate_shortcut = shortcuts.get_shortcut("duplicate")
	
	add_separator("{EventName}", ItemType.TITLE)
	add_icon_item(get_icon("Edit", "EditorIcons"), "Edit in Inspector", ItemType.EDIT)
	
	add_shortcut(duplicate_shortcut, ItemType.DUPLICATE)
	set_item_icon(get_item_index(ItemType.DUPLICATE), get_icon("ActionCopy", "EditorIcons"))
	set_item_text(get_item_index(ItemType.DUPLICATE), "Duplicate")
	
	add_shortcut(remove_shortcut, ItemType.REMOVE)
	set_item_icon(get_item_index(ItemType.REMOVE), get_icon("Remove", "EditorIcons"))
	set_item_text(get_item_index(ItemType.REMOVE), "Remove")
	
	
	add_icon_item(get_icon("Help", "EditorIcons"), "Documentation", ItemType.HELP)
	add_separator()
	add_icon_item(get_icon("ArrowUp", "EditorIcons"), "Move up", ItemType.MOVE_UP)
	add_icon_item(get_icon("ArrowDown", "EditorIcons"), "Move down", ItemType.MOVE_DOWN)
	
	get_stylebox("panel").set("bg_color", get_color("base_color", "Editor"))
	add_color_override('font_color_hover', get_color("accent_color", "Editor"))
	add_stylebox_override('hover', StyleBoxEmpty.new())


func set_title(title:String) -> void:
	set_item_text(get_item_index(ItemType.TITLE), title)


func set_event(event:Resource) -> void:
	used_event = event
	var event_name:String = "{EventName}"
	if used_event:
		event_name = str(used_event.get("event_name"))
	set_title(event_name)
