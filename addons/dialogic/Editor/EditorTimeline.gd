tool
extends HSplitContainer

var editor_reference
var timeline_name: String = "" # The currently opened timeline name (for saving)

onready var timeline = $TimelineEditor/TimelineArea/TimeLine
onready var dialog_list = $EventTools/VBoxContainer2/DialogItemList
onready var events_warning = $TimelineEditor/ScrollContainer/EventContainer/EventsWarning


func _ready():
	$EventTools/VBoxContainer2/DialogItemList.connect('item_rmb_selected', self, '_on_DialogItemList_item_rmb_selected')


# Popup menu with options for a timeline
func _on_DialogItemList_item_rmb_selected(index, at_position):
	editor_reference.get_node('TimelinePopupMenu').rect_position = get_viewport().get_mouse_position()
	editor_reference.get_node('TimelinePopupMenu').popup()
	timeline_name = dialog_list.get_item_text(index)


func fold_all_nodes():
	for event in timeline.get_children():
		event.get_node("PanelContainer/VBoxContainer/Header/VisibleToggle").set_pressed(false)


func unfold_all_nodes():
	for event in timeline.get_children():
		event.get_node("PanelContainer/VBoxContainer/Header/VisibleToggle").set_pressed(true)
