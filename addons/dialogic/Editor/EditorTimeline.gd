tool
extends HSplitContainer

var editor_reference
onready var timeline = $TimelineEditor/TimelineArea/TimeLine
onready var dialog_list = $EventTools/VBoxContainer2/DialogItemList

func _ready():
	$EventTools/VBoxContainer2/DialogItemList.connect('item_selected', self, '_on_DialogItemList_item_selected')
	$EventTools/VBoxContainer2/DialogItemList.connect('item_rmb_selected', self, '_on_DialogItemList_item_rmb_selected')


func _on_DialogItemList_item_selected(index):
	editor_reference.manual_save() # Making sure we save before changing tabs
	clear_timeline()
	var selected = dialog_list.get_item_text(index)
	var file = dialog_list.get_item_metadata(index)['file']
	editor_reference.load_timeline(DialogicUtil.get_path('TIMELINE_DIR', file))


# Renaming dialogs
func _on_DialogItemList_item_rmb_selected(index, at_position):
	$TimelinePopupMenu.rect_position = get_viewport().get_mouse_position()
	$TimelinePopupMenu.popup()
	editor_reference.timeline_name = dialog_list.get_item_text(index)


# Clear timeline
func clear_timeline():
	for event in timeline.get_children():
		event.free()


func fold_all_nodes():
	for event in timeline.get_children():
		event.get_node("PanelContainer/VBoxContainer/Header/VisibleToggle").set_pressed(false)


func unfold_all_nodes():
	for event in timeline.get_children():
		event.get_node("PanelContainer/VBoxContainer/Header/VisibleToggle").set_pressed(true)


# ordering blocks in timeline
func _move_block(block, direction):
	var block_index = block.get_index()
	if direction == 'up':
		if block_index > 0:
			timeline.move_child(block, block_index - 1)
			return true
	if direction == 'down':
		timeline.move_child(block, block_index + 1)
		return true
	return false
