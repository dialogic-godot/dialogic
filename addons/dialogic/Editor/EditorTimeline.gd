tool
extends HSplitContainer

var editor_reference
var timeline_name: String = "" # The currently opened timeline name (for saving)

onready var dialog_list = $EventTools/VBoxContainer2/DialogItemList

func _ready():
	$EventTools/VBoxContainer2/DialogItemList.connect('item_rmb_selected', self, '_on_DialogItemList_item_rmb_selected')


# Popup menu with options for a timeline
func _on_DialogItemList_item_rmb_selected(index, at_position):
	editor_reference.get_node('TimelinePopupMenu').rect_position = get_viewport().get_mouse_position()
	editor_reference.get_node('TimelinePopupMenu').popup()
	timeline_name = dialog_list.get_item_text(index)
