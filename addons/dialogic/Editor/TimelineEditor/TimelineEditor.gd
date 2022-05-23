tool
extends VBoxContainer

var current_timeline: DialogicTimeline

var TimelineUndoRedo := UndoRedo.new()

onready var event_node = load("res://addons/dialogic/Editor/Events/Templates/EventNode.tscn")

onready var timeline_area = $View/TimelineArea
onready var timeline = $View/TimelineArea/TimeLine


var hovered_item = null
var selected_style : StyleBoxFlat = load("res://addons/dialogic/Editor/Events/styles/selected_styleboxflat.tres")
var saved_style : StyleBoxFlat
var selected_items : Array = []

var event_scenes : Dictionary = {}

var currently_draged_event_type = null
var move_start_position = null
var moving_piece = null
var piece_was_dragged = false

var event_data

var batches = []
var building_timeline = true

signal selection_updated
signal batch_loaded
signal timeline_loaded

func _ready():
	var dialogic_plugin = get_tree().root.get_node('EditorNode/DialogicPlugin')
	dialogic_plugin.connect('dialogic_save', self, 'save_timeline')

	
	connect("batch_loaded", self, '_on_batch_loaded')
	
	# Margins
	var modifier = ''
	var _scale = DialogicUtil.get_editor_scale(self)
	var scroll_container = $View/ScrollContainer
	scroll_container.rect_min_size.x = 180
	if _scale == 1.25:
		modifier = '-1.25'
		scroll_container.rect_min_size.x = 200
	if _scale == 1.5:
		modifier = '-1.25'
		scroll_container.rect_min_size.x = 200
	if _scale == 1.75:
		modifier = '-1.25'
		scroll_container.rect_min_size.x = 390
	if _scale == 2:
		modifier = '-2'
		scroll_container.rect_min_size.x = 390
	
	
	if find_parent('EditorView'): # This prevents the view to turn black if you are editing this scene in Godot
		var style = timeline_area.get('custom_styles/bg')
		style.set('bg_color', get_color("dark_color_1", "Editor"))
	
	timeline_area.connect('resized', self, 'add_extra_scroll_area_to_timeline', [])
	
	# Event buttons
	var buttonScene = load("res://addons/dialogic/Editor/TimelineEditor/SmallEventButton.tscn")
	var file_list = DialogicUtil.listdir("res://addons/dialogic/Resources/Events/")
	for file in file_list:
		if '.gd' in file:
			var event_script = load("res://addons/dialogic/Resources/Events/" + file)
			var event_resource = event_script.new()
			var button = buttonScene.instance()
			button.resource = event_resource
			button.visible_name = '       ' + event_resource.event_name
			button.set_icon(event_resource.event_icon)
			button.event_color = event_resource.event_color
			button.event_category = event_resource.event_category
			button.event_sorting_index = event_resource.event_sorting_index


		#	if button.event_id == 'dialogic_010':
		#		button.connect('pressed', self, "_on_ButtonQuestion_pressed", [])
		#	elif button.event_id == 'dialogic_012': # Condition
		#		button.connect('pressed', self, "_on_ButtonCondition_pressed", [])
		#	else:
			button.connect('pressed', self, "_add_event_button_pressed", [event_script])

			get_node("View/ScrollContainer/EventContainer/FlexContainer" + str(button.event_category)).add_child(button)
#			while button.get_index() != 0 and button.event_sorting_index < get_node("View/ScrollContainer/EventContainer/FlexContainer" + 
#					str(button.event_category)).get_child(button.get_index()-1).event_sorting_index:
#				get_node("View/ScrollContainer/EventContainer/FlexContainer" + str(button.event_category + 1)).move_child(button, button.get_index()-1)


# handles dragging/moving of events
func _process(delta):
	if moving_piece != null:
		var current_position = get_global_mouse_position()
		var node_position = moving_piece.rect_global_position.y
		var height = get_block_height(moving_piece)
		var up_offset = get_block_height(get_block_above(moving_piece))
		var down_offset = get_block_height(get_block_below(moving_piece))
		if up_offset != null:
			up_offset = (up_offset / 2) + 5
			if current_position.y < node_position - up_offset:
				move_block(moving_piece, 'up')
				piece_was_dragged = true
		if down_offset != null:
			down_offset = height + (down_offset / 2) + 5
			if current_position.y > node_position + down_offset:
				move_block(moving_piece, 'down')
				piece_was_dragged = true


# SIGNAL handles input on the events mainly for selection and moving events
func _on_event_block_gui_input(event, item: Node):
	if event is InputEventMouseButton and event.button_index == 1:
		if (not event.is_pressed()):
			if (piece_was_dragged and moving_piece != null and move_start_position):
				var to_position = moving_piece.get_index()
				if move_start_position != to_position:
					# move it back so the DO action works. (Kinda stupid but whatever)
					move_block_to_index(to_position, move_start_position)
					TimelineUndoRedo.create_action("[D] Moved event (type '"+moving_piece.resource.id+"').")
					TimelineUndoRedo.add_do_method(self, "move_block_to_index", move_start_position, to_position)
					TimelineUndoRedo.add_undo_method(self, "move_block_to_index", to_position, move_start_position)
					TimelineUndoRedo.commit_action()
				move_start_position = null
			else:
				select_item(item)
			if (moving_piece != null):
				
				indent_events()
			piece_was_dragged = false
			moving_piece = null
		elif event.is_pressed():
			moving_piece = item
			move_start_position = moving_piece.get_index()
			if not _is_item_selected(item):
				pass#piece_was_dragged = true
			else:
				piece_was_dragged = false


## *****************************************************************************
##					 	SHORTCUTS
## *****************************************************************************

func _input(event):
	# some shortcuts need to get handled in the common input event
	# especially CTRL-based
	# because certain godot controls swallow events (like textedit)
	# we protect this with is_visible_in_tree to not 
	# invoke a shortcut by accident
	if get_focus_owner() is TextEdit:
		return
	if (event is InputEventKey and event is InputEventWithModifiers and is_visible_in_tree()):
		# CTRL Z # UNDO
		if (event.pressed
			and event.alt == false
			and event.shift == false
			and (event.control == true or event.command == true)
			and event.scancode == KEY_Z
			and event.echo == false
		):
			TimelineUndoRedo.undo()
			indent_events()
			get_tree().set_input_as_handled()
	if (event is InputEventKey and event is InputEventWithModifiers and is_visible_in_tree()):
		# CTRL +SHIFT+ Z # REDO
		if (event.pressed
			and event.alt == false
			and event.shift == true
			and (event.control == true or event.command == true)
			and event.scancode == KEY_Z
			and event.echo == false
		) or (event.pressed
			and event.alt == false
			and event.shift == false
			and (event.control == true or event.command == true)
			and event.scancode == KEY_Y
			and event.echo == false):
			TimelineUndoRedo.redo()
			indent_events()
			get_tree().set_input_as_handled()
	if (event is InputEventKey and event is InputEventWithModifiers and is_visible_in_tree()):
		# UP
		if (event.pressed
			and event.alt == false
			and event.shift == false
			and (event.control == false or event.command == false)
			and event.scancode == KEY_UP
			and event.echo == false
		):
			# select previous
			if (len(selected_items) == 1):
				var prev = max(0, selected_items[0].get_index() - 1)
				var prev_node = timeline.get_child(prev)
				if (prev_node != selected_items[0]):
					selected_items = []
					select_item(prev_node)
				get_tree().set_input_as_handled()

			
		# DOWN
		if (event.pressed
			and event.alt == false
			and event.shift == false
			and (event.control == false or event.command == false)
			and event.scancode == KEY_DOWN
			and event.echo == false
		):
			# select next
			if (len(selected_items) == 1):
				var next = min(timeline.get_child_count() - 1, selected_items[0].get_index() + 1)
				var next_node = timeline.get_child(next)
				if (next_node != selected_items[0]):
					selected_items = []
					select_item(next_node)
				get_tree().set_input_as_handled()
			
		# DELETE
		if (event.pressed
			and event.alt == false
			and event.shift == false
			and (event.control == false or event.command == false)
			and event.scancode == KEY_DELETE
			and event.echo == false
		):
			if (len(selected_items) != 0):
				var events_indexed = get_events_indexed(selected_items)
				TimelineUndoRedo.create_action("[D] Deleting "+str(len(selected_items))+" event(s).")
				TimelineUndoRedo.add_do_method(self, "delete_events_indexed", events_indexed)
				TimelineUndoRedo.add_undo_method(self, "add_events_indexed", events_indexed)
				TimelineUndoRedo.commit_action()
				get_tree().set_input_as_handled()
			
		# CTRL T
		if (event.pressed
			and event.alt == false
			and event.shift == false
			and (event.control == true or event.command == true)
			and event.scancode == KEY_T
			and event.echo == false
		):
			var at_index = -1
			if selected_items:
				at_index = selected_items[-1].get_index()+1
			else:
				at_index = timeline.get_child_count()
			TimelineUndoRedo.create_action("[D] Add Text event.")
			TimelineUndoRedo.add_do_method(self, "create_event", "dialogic_001", {'no-data': true}, true, at_index, true)
			TimelineUndoRedo.add_undo_method(self, "remove_events_at_index", at_index, 1)
			TimelineUndoRedo.commit_action()
			get_tree().set_input_as_handled()
			
		# CTRL A
		if (event.pressed
			and event.alt == false
			and event.shift == false
			and (event.control == true or event.command == true)
			and event.scancode == KEY_A
			and event.echo == false
		):
			if (len(selected_items) != 0):
				select_all_items()
			get_tree().set_input_as_handled()
		
		# CTRL SHIFT A
		if (event.pressed
			and event.alt == false
			and event.shift == true
			and (event.control == true or event.command == true)
			and event.scancode == KEY_A
			and event.echo == false
		):
			if (len(selected_items) != 0):
				deselect_all_items()
			get_tree().set_input_as_handled()
		
		# CTRL C
		if (event.pressed
			and event.alt == false
			and event.shift == false
			and (event.control == true or event.command == true)
			and event.scancode == KEY_C
			and event.echo == false
		):
			copy_selected_events()
			get_tree().set_input_as_handled()
		
		# CTRL V
		if (event.pressed
			and event.alt == false
			and event.shift == false
			and (event.control == true or event.command == true)
			and event.scancode == KEY_V
			and event.echo == false
		):
			var events_list = paste_check()
			var paste_position = -1
			if selected_items:
				paste_position = selected_items[-1].get_index()
			else:
				paste_position = timeline.get_child_count()-1
			TimelineUndoRedo.create_action("[D] Pasting "+str(len(events_list))+" event(s).")
			TimelineUndoRedo.add_do_method(self, "add_events_at_index", events_list, paste_position)
			TimelineUndoRedo.add_undo_method(self, "remove_events_at_index", paste_position+1, len(events_list))
			TimelineUndoRedo.commit_action()
			get_tree().set_input_as_handled()
		
		# CTRL X
		if (event.pressed
			and event.alt == false
			and event.shift == false
			and (event.control == true or event.command == true)
			and event.scancode == KEY_X
			and event.echo == false
		):
			var events_indexed = get_events_indexed(selected_items)
			TimelineUndoRedo.create_action("[D] Cut "+str(len(selected_items))+" event(s).")
			TimelineUndoRedo.add_do_method(self, "cut_events_indexed", events_indexed)
			TimelineUndoRedo.add_undo_method(self, "add_events_indexed", events_indexed)
			TimelineUndoRedo.commit_action()
			get_tree().set_input_as_handled()

		# CTRL D
		if (event.pressed
			and event.alt == false
			and event.shift == false
			and (event.control == true or event.command == true)
			and event.scancode == KEY_D
			and event.echo == false
		):
			
			if len(selected_items) > 0:
				var events = get_events_indexed(selected_items).values()
				var at_index = selected_items[-1].get_index()
				TimelineUndoRedo.create_action("[D] Duplicate "+str(len(events))+" event(s).")
				TimelineUndoRedo.add_do_method(self, "add_events_at_index", events, at_index)
				TimelineUndoRedo.add_undo_method(self, "remove_events_at_index", at_index, len(events))
				TimelineUndoRedo.commit_action()
			get_tree().set_input_as_handled()

func _unhandled_key_input(event):
	if (event is InputEventWithModifiers):
		# ALT UP
		if (event.pressed
			and event.alt == true 
			and event.shift == false 
			and (event.control == false or event.command == false)
			and event.scancode == KEY_UP
			and event.echo == false
		):
			# move selected up
			if (len(selected_items) == 1):
				move_block(selected_items[0], "up")
				indent_events()
				get_tree().set_input_as_handled()
			
		# ALT DOWN
		if (event.pressed
			and event.alt == true 
			and event.shift == false 
			and (event.control == false or event.command == false)
			and event.scancode == KEY_DOWN
			and event.echo == false
		):
			# move selected down
			if (len(selected_items) == 1):
				move_block(selected_items[0], "down")
				indent_events()
				get_tree().set_input_as_handled()

## *****************************************************************************
##					 	DELETING, COPY, PASTE
## *****************************************************************************

func get_events_indexed(events:Array) -> Dictionary:
	var indexed_dict = {}
	for event in events:
		indexed_dict[event.get_index()] = event.event_data.duplicate(true)
	return indexed_dict


func select_indexed_events(indexed_events:Dictionary) -> void:
	selected_items = []
	for event_index in indexed_events.keys():
		selected_items.append(timeline.get_child(event_index))


func add_events_indexed(indexed_events:Dictionary) -> void:
	var indexes = indexed_events.keys()
	indexes.sort()
	var events = []
	for event_idx in indexes:
		deselect_all_items()
		#events.append(create_event(indexed_events[event_idx].event_id, indexed_events[event_idx]))
		timeline.move_child(events[-1], event_idx)
		
	selected_items = events
	visual_update_selection()


func delete_events_indexed(indexed_events:Dictionary) -> void:
	select_indexed_events(indexed_events)
	delete_selected_events()


func delete_selected_events():
	if len(selected_items) == 0:
		return
	
	# get next element
	var next = min(timeline.get_child_count() - 1, selected_items[-1].get_index() + 1)
	var next_node = timeline.get_child(next)
	if _is_item_selected(next_node):
		next_node = null
	
	for event in selected_items:
		event.get_parent().remove_child(event)
		event.queue_free()
	
	# select next
	if (next_node != null):
		select_item(next_node, false)
	else:
		if (timeline.get_child_count() > 0):
			next_node = timeline.get_child(max(0, timeline.get_child_count() - 1))
			if (next_node != null):
				select_item(next_node, false)
		else:
			deselect_all_items()
	
	indent_events()


func cut_selected_events():
	copy_selected_events()
	delete_selected_events()


func cut_events_indexed(indexed_events:Dictionary) -> void:
	select_indexed_events(indexed_events)
	cut_selected_events()


func copy_selected_events():
	if len(selected_items) == 0:
		return
	var event_copy_array = []
	for item in selected_items:
		event_copy_array.append(item.event_data)
	
	OS.clipboard = JSON.print(
		{
			"events":event_copy_array,
			#"dialogic_version": editor_reference.version_string,
			"project_name": ProjectSettings.get_setting("application/config/name")
		})


func paste_check():
	var clipboard_parse = JSON.parse(OS.clipboard).result
	
	if typeof(clipboard_parse) == TYPE_DICTIONARY:
		#if clipboard_parse.has("dialogic_version"):
			#if clipboard_parse['dialogic_version'] != editor_reference.version_string:
				#print("[D] Be careful when copying from older versions!")
		if clipboard_parse.has("project_name"):
			if clipboard_parse['project_name'] != ProjectSettings.get_setting("application/config/name"):
				print("[D] Be careful when copying from another project!")
		if clipboard_parse.has('events'):
			return clipboard_parse['events']


func remove_events_at_index(at_index:int, amount:int = 1)-> void:
	selected_items = []
	for i in range(0, amount):
		selected_items.append(timeline.get_child(at_index + i))
	delete_selected_events()


func add_events_at_index(event_list:Array, at_index:int) -> void:
	if at_index != -1:
		event_list.invert()
		selected_items = [timeline.get_child(at_index)]
	else:
		selected_items = []
	
	var new_items = []
	for item in event_list:
		if typeof(item) == TYPE_DICTIONARY and item.has('event_id'):
			#new_items.append(create_event(item['event_id'], item))
			pass
	selected_items = new_items
	sort_selection()
	visual_update_selection()
	indent_events()


func paste_events_indexed(indexed_events):
	pass


func duplicate_events_indexed(indexed_events):
	pass

## *****************************************************************************
##					 	BLOCK SELECTION
## *****************************************************************************

func _is_item_selected(item: Node):
	return item in selected_items


func select_item(item: Node, multi_possible:bool = true):
	if item == null:
		return

	if Input.is_key_pressed(KEY_CONTROL) and multi_possible:
		# deselect the item if it is selected
		if _is_item_selected(item):
			selected_items.erase(item)
		else:
			selected_items.append(item)
	elif Input.is_key_pressed(KEY_SHIFT) and multi_possible:
		
		if len(selected_items) == 0:
			selected_items = [item]
		else:
			var index = selected_items[-1].get_index()
			var goal_idx = item.get_index()
			while true:
				if index < goal_idx: index += 1
				else: index -= 1
				if not timeline.get_child(index) in selected_items:
					selected_items.append(timeline.get_child(index))
				
				if index == goal_idx:
					break
	else:
		if len(selected_items) == 1:
			if _is_item_selected(item):
				selected_items.erase(item)
			else:
				selected_items = [item]
		else:
			selected_items = [item]
	
	sort_selection()
	
	visual_update_selection()


# checks all the events and sets their styles (selected/deselected)
func visual_update_selection():
	for item in timeline.get_children():
		item.visual_deselect()
	for item in selected_items:
		item.visual_select()


## Sorts the selection using 'custom_sort_selection'
func sort_selection():
	selected_items.sort_custom(self, 'custom_sort_selection')


## Compares two event blocks based on their position in the timeline
func custom_sort_selection(item1, item2):
	return item1.get_index() < item2.get_index()


## Helpers
func select_all_items():
	selected_items = []
	for event in timeline.get_children():
		selected_items.append(event)
	visual_update_selection()


func deselect_all_items():
	selected_items = []
	visual_update_selection()

## *****************************************************************************
##				SPECIAL BLOCK OPERATIONS
## *****************************************************************************

# SIGNAL handles the actions of the small menu on the right
func _on_event_options_action(action: String, item: Node):
	### WORK TODO
	if action == "remove":
		delete_selected_events()
	else:
		move_block(item, action)
	indent_events()


func delete_event(event):
	event.get_parent().remove_child(event)
	event.queue_free()


## *****************************************************************************
##				CREATING NEW EVENTS USING THE BUTTONS
## *****************************************************************************

# Event Creation signal for buttons
func _add_event_button_pressed(event_script):
	var at_index = -1
	if selected_items:
		at_index = selected_items[-1].get_index()+1
	else:
		at_index = timeline.get_child_count()
	TimelineUndoRedo.create_action("[D] Add event.")
	TimelineUndoRedo.add_do_method(self, "add_event_to_timeline", event_script.new(), at_index, true, true)
	TimelineUndoRedo.add_undo_method(self, "remove_events_at_index", at_index, 1)
	TimelineUndoRedo.commit_action()
	scroll_to_piece(at_index)
	indent_events()

# the Question button adds multiple blocks 
func _on_ButtonQuestion_pressed() -> void:
	var at_index = -1
	if selected_items:
		at_index = selected_items[-1].get_index()+1
	else:
		at_index = timeline.get_child_count()
	TimelineUndoRedo.create_action("[D] Add question events.")
	TimelineUndoRedo.add_do_method(self, "create_question", at_index)
	TimelineUndoRedo.add_undo_method(self, "remove_events_at_index", at_index, 4)
	TimelineUndoRedo.commit_action()

func create_question(at_position):
	if at_position == 0: selected_items = []
	else: selected_items = [timeline.get_child(at_position-1)]
	if len(selected_items) != 0:
		# Events are added bellow the selected node
		# So we must reverse the adding order
		#create_event("dialogic_013", {'no-data': true}, true)
		#create_event("dialogic_011", {'no-data': true}, true)
		#create_event("dialogic_011", {'no-data': true}, true)
		#create_event("dialogic_010", {'no-data': true}, true)
		pass
	else:
		#create_event("dialogic_010", {'no-data': true}, true)
		#create_event("dialogic_011", {'no-data': true}, true)
		#create_event("dialogic_011", {'no-data': true}, true)
		#create_event("dialogic_013", {'no-data': true}, true)
		pass


# the Condition button adds multiple blocks 
func _on_ButtonCondition_pressed() -> void:
	var at_index = -1
	if selected_items:
		at_index = selected_items[-1].get_index()+1
	else:
		at_index = timeline.get_child_count()
	TimelineUndoRedo.create_action("[D] Add condition events.")
	TimelineUndoRedo.add_do_method(self, "create_condition", at_index)
	TimelineUndoRedo.add_undo_method(self, "remove_events_at_index", at_index, 2)
	TimelineUndoRedo.commit_action()
	
func create_condition(at_position):
	if at_position == 0: selected_items = []
	else: selected_items = [timeline.get_child(at_position-1)]
	if len(selected_items) != 0:
		# Events are added bellow the selected node
		# So we must reverse the adding order
		#create_event("dialogic_013", {'no-data': true}, true)
		#create_event("dialogic_012", {'no-data': true}, true)
		pass
	else:
		#create_event("dialogic_012", {'no-data': true}, true)
		#create_event("dialogic_013", {'no-data': true}, true)
		pass


## *****************************************************************************
##					 	DRAG AND DROP
## *****************************************************************************

# Creates a ghost event for drag and drop
func create_drag_and_drop_event(resource):
	var index = get_index_under_cursor()
	var piece = add_event_to_timeline(resource)
	currently_draged_event_type = resource
	timeline.move_child(piece, index)
	moving_piece = piece
	piece_was_dragged = true
	#set_event_ignore_save(piece, true)
	select_item(piece)
	return piece


func drop_event():
	if moving_piece != null:
		var at_index = moving_piece.get_index()
		moving_piece.queue_free()
		TimelineUndoRedo.create_action("[D] Add event.")
		TimelineUndoRedo.add_do_method(self, "add_event_to_timeline", currently_draged_event_type, at_index, true, true)
		TimelineUndoRedo.add_undo_method(self, "remove_events_at_index", at_index, 1)
		TimelineUndoRedo.commit_action()
		moving_piece = null
		piece_was_dragged = false
		indent_events()
		add_extra_scroll_area_to_timeline()


func cancel_drop_event():
	if moving_piece != null:
		moving_piece = null
		piece_was_dragged = false
		delete_selected_events()
		deselect_all_items()


## *****************************************************************************
##					 	CREATING THE TIMELINE
## *****************************************************************************
# Adding an event to the timeline
func add_event_to_timeline(event_resource:Resource, at_index:int = -1, auto_select: bool = false, indent: bool = false):
	var piece = event_node.instance()
	var resource = event_resource
	piece.resource = event_resource
	piece.connect('content_changed', self, 'something_changed')
	if at_index == -1:
		if len(selected_items) != 0:
			timeline.add_child_below_node(selected_items[0], piece)
		else:
			timeline.add_child(piece)
	else:
		timeline.add_child(piece)
		timeline.move_child(piece, at_index)

	piece.connect("option_action", self, '_on_event_options_action', [piece])
	piece.connect("gui_input", self, '_on_event_block_gui_input', [piece])
	
	# Buidling editing part
	piece.build_editor()
	
	if auto_select:
		select_item(piece, false)
	
	# Spacing
	add_extra_scroll_area_to_timeline()
	
	# Indent on create
	if indent:
		indent_events()
	
	if not building_timeline:
		piece.focus()
	
	return piece


func new_timeline() -> void:
	save_timeline()
	clear_timeline()
	get_parent().get_parent().get_parent().godot_file_dialog(self,  'create_and_save_new_timeline', '*.dtl; DialogicTimeline', EditorFileDialog.MODE_SAVE_FILE)

# Saving
func save_timeline() -> void:
	var new_events = []
	
	for event in timeline.get_children():
		new_events.append(event.resource)
	
	if current_timeline:
		current_timeline.set_events(new_events)
		ResourceSaver.save(current_timeline.resource_path, current_timeline)
		get_node("%Toolbar").set_resource_saved()
	else:
		if new_events.size() > 0:
			get_parent().get_parent().get_parent().godot_file_dialog(self, 'create_and_save_new_timeline', '*.dtl; DialogicTimeline', EditorFileDialog.MODE_SAVE_FILE)


func create_and_save_new_timeline(path):
	var new_timeline = DialogicTimeline.new()
	new_timeline.resource_path = path
	current_timeline = new_timeline
	save_timeline()
	load_timeline(new_timeline)
	


func load_timeline(object) -> void:
	#print('[D] Load timeline: ', object)
	clear_timeline()
	get_node('%Toolbar/CurrentResource').text = object.resource_path
	current_timeline = object
	var data = object.get_events()
	var page = 1
	var batch_size = 12
	while batch_events(data, batch_size, page).size() != 0:
		batches.append(batch_events(data, batch_size, page))
		page += 1
	load_batch(batches)
	# Reset the scroll position
	timeline_area.scroll_vertical = 0


func something_changed():
	get_node('%Toolbar').set_resource_unsaved()


func batch_events(array, size, batch_number):
	return array.slice((batch_number - 1) * size, batch_number * size - 1)


func load_batch(data):
	#print('[D] Loading batch')
	var current_batch = batches.pop_front()
	if current_batch:
		for i in current_batch:
			add_event_to_timeline(i, timeline.get_child_count())
	emit_signal("batch_loaded")


func _on_batch_loaded():
	if batches.size() > 0:
		yield(get_tree().create_timer(0.01), "timeout")
		load_batch(batches)
	else:
		indent_events()
		building_timeline = false
		emit_signal("timeline_loaded")
	add_extra_scroll_area_to_timeline()


func clear_timeline():
	deselect_all_items()
	for event in timeline.get_children():
		event.free()


## *****************************************************************************
##					 	BLOCK GETTERS
## *****************************************************************************

func get_block_above(block):
	var block_index = block.get_index()
	var item = null
	if block_index > 0:
		item = timeline.get_child(block_index - 1)
	return item


func get_block_below(block):
	var block_index = block.get_index()
	var item = null
	if block_index < timeline.get_child_count() - 1:
		item = timeline.get_child(block_index + 1)
	return item


func get_block_height(block):
	if block != null:
		return block.rect_size.y
	else:
		return null


func get_index_under_cursor():
	var current_position = get_global_mouse_position()
	var top_pos = 0
	for i in range(timeline.get_child_count()):
		var c = timeline.get_child(i)
		if c.rect_global_position.y < current_position.y:
			top_pos = i
	return top_pos


# ordering blocks in timeline
func move_block(block, direction):
	var block_index = block.get_index()
	if direction == 'up':
		if block_index > 0:
			timeline.move_child(block, block_index - 1)
			timeline_area.update()
			return true
	if direction == 'down':
		timeline.move_child(block, block_index + 1)
		timeline_area.update()
		return true
	return false

func move_block_to_index(block_index, index):
	timeline.move_child(timeline.get_child(block_index), index)


## *****************************************************************************
##					 UTILITIES/HELPERS
## *****************************************************************************

# Scrolling
func scroll_to_piece(piece_index) -> void:
	var height = 0
	for i in range(0, piece_index):
		height += timeline.get_child(i).rect_size.y
	if height < timeline_area.scroll_vertical or height > timeline_area.scroll_vertical+timeline_area.rect_size.y-(200*DialogicUtil.get_editor_scale(self)):
		timeline_area.scroll_vertical = height

# Event Indenting
func indent_events() -> void:
	# Now indenting
	var indent: int = 0
	var starter: bool = false
	var event_list: Array = timeline.get_children()
	var question_index: int = 0
	var question_indent = {}
	if event_list.size() < 2:
		return
	# Resetting all the indents
	for event in event_list:
		var indent_node
		
		event.set_indent(0)
		
	# Adding new indents
	for event in event_list:
		# since there are indicators now, not all elements
		# in this list have an event_data property
		if (not "event_data" in event):
			continue
		
		if event.resource.id == 'dialogic_011':
			if question_index > 0:
				indent = question_indent[question_index] + 1
				starter = true
		elif event.resource.id == 'dialogic_010' or event.resource.id == 'dialogic_012':
			indent += 1
			starter = true
			question_index += 1
			question_indent[question_index] = indent
		elif event.resource.id == 'dialogic_013':
			if question_indent.has(question_index):
				indent = question_indent[question_index]
				indent -= 1
				question_index -= 1
				if indent < 0:
					indent = 0
				else:
					event.remove_warning('This event is not connected to any Question or Condition but it should!')
			else:
				event.set_warning('This event is not connected to any Question or Condition but it should!')

		if indent > 0:
			# Keep old behavior for items without template
			if starter:
				event.set_indent(indent - 1)
			else:
				event.set_indent(indent)
		starter = false
	timeline_area.update()


# called from the toolbar
func fold_all_nodes():
	for event in timeline.get_children():
		event.set_expanded(false)
	add_extra_scroll_area_to_timeline()


# called from the toolbar
func unfold_all_nodes():
	for event in timeline.get_children():
		event.set_expanded(true)
	add_extra_scroll_area_to_timeline()


func get_current_events_anchors():
	var anchors = {}
	for event in timeline.get_children():
		if "event_data" in event:
			if event.event_data['event_id'] == 'dialogic_015':
				anchors[event.event_data['id']] = event.event_data['name']
	return anchors


func add_extra_scroll_area_to_timeline():
	if timeline.get_children().size() > 4:
		timeline.rect_min_size.y = 0
		timeline.rect_size.y = 0
		if timeline.rect_size.y + 200 > timeline_area.rect_size.y:
			timeline.rect_min_size = Vector2(0, timeline.rect_size.y + 200)


#func play_timeline():
#	DialogicResources.set_settings_value('QuickTimelineTest', 'timeline_file', timeline_file)
#	editor_reference.editor_interface.play_custom_scene('res://addons/dialogic/Editor/TimelineEditor/TimelineTestingScene.tscn')
