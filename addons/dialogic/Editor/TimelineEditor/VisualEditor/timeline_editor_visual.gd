@tool
extends Container

## Visual mode of the timeline editor. 


################################################################################
## 				EDITOR NODES
################################################################################
var TimelineUndoRedo := UndoRedo.new()
var event_node

################################################################################
## 				 SIGNALS
################################################################################
signal selection_updated
signal batch_loaded
signal timeline_loaded


################################################################################
## 				 TIMELINE LOADING
################################################################################
var _batches := []
var _building_timeline := true


################################################################################
## 				 TIMELINE EVENT MANAGEMENT
################################################################################
var selected_items : Array = []

var move_start_position = null
var moving_piece = null
var piece_was_dragged := false


################################################################################
## 					CREATE/SAVE/LOAD
################################################################################

func something_changed():
	get_parent().current_resource_state = DialogicEditor.ResourceStates.Unsaved


func save_timeline() -> void:
	# return if resource is unchanged
	if get_parent().current_resource_state != DialogicEditor.ResourceStates.Unsaved:
		return
	
	# create a list of text versions of all the events with the right indent
	var new_events := []
	var indent := 0
	
	for event in %Timeline.get_children():
		
		if 'event_name' in event.resource:
			event.resource.update_text_version() 
			new_events.append(event.resource)

	if !get_parent().current_resource:
		return

	get_parent().current_resource.set_events(new_events)
	get_parent().current_resource.events_processed = true
	var error :int = ResourceSaver.save(get_parent().current_resource, get_parent().current_resource.resource_path)
	if error != OK:
		print('[Dialogic] Saving error: ', error)
	
	get_parent().current_resource.set_meta("unsaved", false)
	get_parent().current_resource_state = DialogicEditor.ResourceStates.Saved
	get_parent().editors_manager.resource_helper.rebuild_timeline_directory()


func load_timeline(resource:DialogicTimeline) -> void:
	clear_timeline_nodes()
	_building_timeline = true
	if get_parent().current_resource.events.size() == 0:
		pass
	else: 
		if typeof(get_parent().current_resource.events[0]) == TYPE_STRING:
			get_parent().current_resource.events_processed = false
			get_parent().current_resource = get_parent().editors_manager.resource_helper.process_timeline(get_parent().current_resource)
		if get_parent().current_resource.events.size() == 0:
			return
		var data := resource.get_events()
		var page := 1
		var batch_size := 10
		_batches = []
		while batch_events(data, batch_size, page).size() != 0:
			_batches.append(batch_events(data, batch_size, page))
			page += 1
		batch_loaded.emit()
	# Reset the scroll position
	%TimelineArea.scroll_vertical = 0


func batch_events(array, size, batch_number):
	return array.slice((batch_number - 1) * size, batch_number * size)


# a list of all events like choice and condition events (so they get connected to their end events)
var opener_events_stack := []

func load_batch(data:Array) -> void:
	var current_batch :Array = _batches.pop_front()
	if current_batch:
		for i in current_batch:
			if i is DialogicEndBranchEvent:
				create_end_branch_event(%Timeline.get_child_count(), opener_events_stack.pop_back())
			else:
				var piece := add_event_node(i, %Timeline.get_child_count())
				if i.can_contain_events:
					opener_events_stack.push_back(piece)
	batch_loaded.emit()

func _on_batch_loaded():
	if _batches.size() > 0:
		indent_events()
		await get_tree().process_frame
		load_batch(_batches)
	else:
		if opener_events_stack:
			for ev in opener_events_stack:
				create_end_branch_event(%Timeline.get_child_count(), ev)
		opener_events_stack = []
		indent_events()
		_building_timeline = false
		add_extra_scroll_area_to_timeline()


func clear_timeline_nodes():
	deselect_all_items()
	for event in %Timeline.get_children():
		event.free()

################################################################################
## 					SETUP
################################################################################

func _ready():
	DialogicUtil.get_dialogic_plugin().dialogic_save.connect(save_timeline)
	event_node = load("res://addons/dialogic/Editor/Events/EventBlock/event_block.tscn")
	
	batch_loaded.connect(_on_batch_loaded)
	
	# Margins
	var _scale := DialogicUtil.get_editor_scale()
	var scroll_container :ScrollContainer = $View/ScrollContainer
	scroll_container.custom_minimum_size.x = 200 * _scale
	
	
	if find_parent('EditorView'): # This prevents the view to turn black if you are editing this scene in Godot
		%TimelineArea.get_theme_color("background_color", "CodeEdit")
		
	%TimelineArea.resized.connect(add_extra_scroll_area_to_timeline)


func load_event_buttons() -> void:
	var scripts: Array = get_parent().editors_manager.resource_helper.get_event_scripts()
	
	# Event buttons
	var buttonScene = load("res://addons/dialogic/Editor/TimelineEditor/VisualEditor/AddEventButton.tscn")
	
	for event_script in scripts:
		var event_resource: Variant
		
		if typeof(event_script) == TYPE_STRING:
			event_resource = load(event_script).new()
		else:
			event_resource = event_script
		
		if event_resource.disable_editor_button == true: continue
		var button = buttonScene.instantiate()
		button.resource = event_resource
		button.visible_name = '       ' + event_resource.event_name
		button.event_icon = event_resource._get_icon()
		button.set_color(event_resource.event_color)
		button.dialogic_color_name = event_resource.dialogic_color_name
		button.event_category = event_resource.event_category
		button.event_sorting_index = event_resource.event_sorting_index

		button.button_up.connect(_add_event_button_pressed.bind(event_resource))
		
		get_node("View/ScrollContainer/EventContainer/FlexContainer" + str(button.event_category)).add_child(button)
		while event_resource.event_sorting_index < get_node("View/ScrollContainer/EventContainer/FlexContainer" + str(button.event_category)).get_child(max(0, button.get_index()-1)).resource.event_sorting_index:
			get_node("View/ScrollContainer/EventContainer/FlexContainer" + str(button.event_category)).move_child(button, button.get_index()-1)


################################################################################
##				CLEANUP
################################################################################

func _exit_tree() -> void:
	# Explicitly free any open cache resources on close, so we don't get leaked resource errors on shutdown
	clear_timeline_nodes()


################################################################################
## 				DRAG&DROP + DRAGGING EVENTS
################################################################################
# handles dragging/moving of events
func _process(delta:float) -> void:
	if moving_piece != null:
		var current_position = get_global_mouse_position()
		var node_position = moving_piece.global_position.y
		var height = get_block_height(moving_piece)
		var up_offset = get_block_height(get_block_above(moving_piece))
		var down_offset = get_block_height(get_block_below(moving_piece))
		if up_offset != null:
			up_offset = (up_offset / 2) + 5
			if current_position.y < node_position - up_offset:
				if moving_piece.resource is DialogicEndBranchEvent:
					if moving_piece.parent_node != get_block_above(moving_piece):
						move_block_up(moving_piece)
						piece_was_dragged = true
				else:
					move_block_up(moving_piece)
					piece_was_dragged = true
		if down_offset != null:
			down_offset = height + (down_offset / 2) + 5
			if current_position.y > node_position + down_offset:
				move_block_down(moving_piece)
				piece_was_dragged = true


## INFO: These methods are mainly used by the TimelineArea
# Creates a ghost event for drag and drop
func create_drag_and_drop_event(resource):
	var index = get_index_under_cursor()
	var piece = add_event_node(resource)
	%Timeline.move_child(piece, index)
	moving_piece = piece
	piece_was_dragged = true
	select_item(piece)


func drop_event() -> void:
	if moving_piece != null:
		var at_index = moving_piece.get_index()
		var resource = moving_piece.resource
		moving_piece.queue_free()
		
		_add_event_button_pressed(resource)
		moving_piece = null
		piece_was_dragged = false
		something_changed()


func cancel_drop_event() -> void:
	if moving_piece != null:
		moving_piece = null
		piece_was_dragged = false
		delete_selected_events()
		deselect_all_items()


# SIGNAL handles input on the events mainly for selection and moving events
func _on_event_block_gui_input(event, item: Node):
	if event is InputEventMouseButton and event.button_index == 1:
		if (not event.is_pressed()):
			if (piece_was_dragged and moving_piece != null and move_start_position):
				var to_position = moving_piece.get_index()
				if move_start_position != to_position:
					TimelineUndoRedo.create_action("[D] Moved event (type '"+moving_piece.resource.to_string()+"').")
					TimelineUndoRedo.add_do_method(move_block_to_index.bind(move_start_position, to_position))
					TimelineUndoRedo.add_undo_method(move_block_to_index.bind(to_position, move_start_position))
					
					# in case a something like a choice or condition was moved BELOW it's end node the end_node is moved as well!!!
					if moving_piece.resource.can_contain_events:
						if moving_piece.end_node.get_index() < to_position:
							TimelineUndoRedo.add_do_method(move_block_to_index.bind(moving_piece.end_node.get_index(), to_position))
							TimelineUndoRedo.add_undo_method(move_block_to_index.bind(to_position+1, moving_piece.end_node.get_index()))
					
					# move it back so the DO action works. (Kinda stupid but whatever)
					move_block_to_index(to_position, move_start_position)
					TimelineUndoRedo.commit_action()
	
				move_start_position = null
			
			if (moving_piece != null):
				
				indent_events()
			piece_was_dragged = false
			moving_piece = null
		elif event.is_pressed():
			moving_piece = item
			move_start_position = moving_piece.get_index()
			if not _is_item_selected(item):
				select_item(item)
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
	
	if get_viewport().gui_get_focus_owner() is TextEdit || get_viewport().gui_get_focus_owner() is LineEdit: 
		return
	
	if (event is InputEventKey and event is InputEventWithModifiers and is_visible_in_tree()):
		# CTRL Z ->  UNDO
		if is_event_pressed(event, KEY_Z, false, false, true):
			TimelineUndoRedo.undo()
			indent_events()
			get_viewport().set_input_as_handled()
	if (event is InputEventKey and event is InputEventWithModifiers and is_visible_in_tree()):
		# CTRL +SHIFT+ Z // CTRL + Y -> REDO
		if is_event_pressed(event, KEY_Z, false, true, true) or is_event_pressed(event, KEY_Y, false, false, true):
			TimelineUndoRedo.redo()
			indent_events()
			get_viewport().set_input_as_handled()
	if (event is InputEventKey and event is InputEventWithModifiers and is_visible_in_tree()):
		# UP -> select previous
		if is_event_pressed(event, KEY_UP, false, false, false):
			if (len(selected_items) == 1):
				var prev = max(0, selected_items[0].get_index() - 1)
				var prev_node = %Timeline.get_child(prev)
				if (prev_node != selected_items[0]):
					selected_items = []
					select_item(prev_node)
				get_viewport().set_input_as_handled()
			
		# DOWN -> select next
		if is_event_pressed(event, KEY_DOWN, false, false, false):
			if (len(selected_items) == 1):
				var next = min(%Timeline.get_child_count() - 1, selected_items[0].get_index() + 1)
				var next_node = %Timeline.get_child(next)
				if (next_node != selected_items[0]):
					selected_items = []
					select_item(next_node)
				get_viewport().set_input_as_handled()
			
		# DELETE
		if is_event_pressed(event, KEY_DELETE, false, false, false):
			if (len(selected_items) != 0):
				var events_indexed = get_events_indexed(selected_items)
				TimelineUndoRedo.create_action("[D] Deleting "+str(len(selected_items))+" event(s).")
				TimelineUndoRedo.add_do_method(delete_events_indexed.bind(events_indexed))
				TimelineUndoRedo.add_undo_method(add_events_indexed.bind(events_indexed))
				TimelineUndoRedo.commit_action()
				get_viewport().set_input_as_handled()
			
		# CTRL T -> Add text event
		if is_event_pressed(event, KEY_T, false, false, true):
			_add_event_button_pressed(DialogicTextEvent.new())
			get_viewport().set_input_as_handled()
			
		# CTRL A -> select all
		if is_event_pressed(event, KEY_A, false, false, true):
			if (len(selected_items) != 0):
				select_all_items()
			get_viewport().set_input_as_handled()
		
		# CTRL SHIFT A -> deselect all
		if is_event_pressed(event, KEY_A, false, true, true):
			if (len(selected_items) != 0):
				deselect_all_items()
			get_viewport().set_input_as_handled()
		
		# CTRL C
		if is_event_pressed(event, KEY_C, false, false, true):
			copy_selected_events()
			get_viewport().set_input_as_handled()
		
		# CTRL V
		if is_event_pressed(event, KEY_V, false, false, true):
			var events_list = paste_check()
			var paste_position = -1
			if selected_items:
				paste_position = selected_items[-1].get_index()
			else:
				paste_position = %Timeline.get_child_count()-1
			if events_list:
				TimelineUndoRedo.create_action("[D] Pasting "+str(len(events_list))+" event(s).")
				TimelineUndoRedo.add_do_method(add_events_at_index.bind(events_list, paste_position))
				TimelineUndoRedo.add_undo_method(remove_events_at_index.bind(paste_position+1, len(events_list)))
				TimelineUndoRedo.commit_action()
				get_viewport().set_input_as_handled()
		
		# CTRL X
		if is_event_pressed(event, KEY_X, false, false, true):
			var events_indexed = get_events_indexed(selected_items)
			TimelineUndoRedo.create_action("[D] Cut "+str(len(selected_items))+" event(s).")
			TimelineUndoRedo.add_do_method(cut_events_indexed.bind(events_indexed))
			TimelineUndoRedo.add_undo_method(add_events_indexed.bind(events_indexed))
			TimelineUndoRedo.commit_action()
			get_viewport().set_input_as_handled()
		
		# CTRL D
		if is_event_pressed(event, KEY_D, false, false, true):
			if len(selected_items) > 0:
				var events = get_events_indexed(selected_items).values()
				var at_index = selected_items[-1].get_index()
				TimelineUndoRedo.create_action("[D] Duplicate "+str(len(events))+" event(s).")
				TimelineUndoRedo.add_do_method(add_events_at_index.bind(events, at_index))
				TimelineUndoRedo.add_undo_method(remove_events_at_index.bind(at_index, len(events)))
				TimelineUndoRedo.commit_action()
			get_viewport().set_input_as_handled()
		
		# ALT UP -> move selected up
		if is_event_pressed(event, KEY_UP, true, false, false):
			if (len(selected_items) == 1):
				move_block_up(selected_items[0])
				indent_events()
				get_viewport().set_input_as_handled()
			
		# ALT DOWN -> move selected down
		if is_event_pressed(event, KEY_DOWN, true, false, false):
			if (len(selected_items) == 1):
				move_block_down(selected_items[0])
				indent_events()
				get_viewport().set_input_as_handled()

# helper to make the above methods shorter
func is_event_pressed(event, keycode, alt:bool, shift:bool, ctrl_or_meta:bool):
	return (event.pressed and event.alt_pressed == alt 
			and event.shift_pressed == shift 
			and (event.ctrl_pressed or event.meta_pressed ) == ctrl_or_meta
			and event.keycode == keycode
			and event.echo == false)

## *****************************************************************************
##					 	DELETING, COPY, PASTE
## *****************************************************************************

func get_events_indexed(events:Array) -> Dictionary:
	var indexed_dict = {}
	for event in events:
		if not event.resource is DialogicEndBranchEvent:
			indexed_dict[event.get_index()] = event.resource.to_text()
			if 'end_node' in event and event.end_node:
				indexed_dict[event.end_node.get_index()] = event.end_node.resource.to_text()+str(event.get_index())
	return indexed_dict


func select_indexed_events(indexed_events:Dictionary) -> void:
	selected_items = []
	for event_index in indexed_events.keys():
		selected_items.append(%Timeline.get_child(event_index))


func add_events_indexed(indexed_events:Dictionary) -> void:
	var indexes = indexed_events.keys()
	indexes.sort()

	var events = []
	for event_idx in indexes:
		deselect_all_items()
		
		var event_resource :Variant
		if get_parent().editors_manager.resource_helper:
			for i in get_parent().editors_manager.resource_helper.get_event_scripts():
				if i._test_event_string(indexed_events[event_idx]):
					event_resource = i.duplicate()
					break
		else:
			printerr("[Dialogic] Unable to access resource_helper!")
			continue
		event_resource.from_text(indexed_events[event_idx])
		if event_resource is DialogicEndBranchEvent:
			events.append(create_end_branch_event(%Timeline.get_child_count(), %Timeline.get_child(indexed_events[event_idx].trim_prefix('<<END BRANCH>>').to_int())))
			%Timeline.move_child(events[-1], event_idx)
		else:
			events.append(add_event_node(event_resource))
			%Timeline.move_child(events[-1], event_idx)
		
	selected_items = events
	visual_update_selection()


func delete_events_indexed(indexed_events:Dictionary) -> void:
	select_indexed_events(indexed_events)
	delete_selected_events()


func delete_selected_events():
	if len(selected_items) == 0:
		return
	
	# get next element
	var next = min(%Timeline.get_child_count() - 1, selected_items[-1].get_index() + 1)
	var next_node = %Timeline.get_child(next)
	if _is_item_selected(next_node):
		next_node = null
	
	for event in selected_items:
		if event.resource is DialogicEndBranchEvent:
			continue
		if 'end_node' in event and event.end_node != null:
			event.end_node.get_parent().remove_child(event.end_node)
			event.end_node.queue_free()
		event.get_parent().remove_child(event)
		event.queue_free()
	
	# select next
	if (next_node != null):
		select_item(next_node, false)
	else:
		if (%Timeline.get_child_count() > 0):
			next_node = %Timeline.get_child(max(0, %Timeline.get_child_count() - 1))
			if (next_node != null):
				select_item(next_node, false)
		else:
			deselect_all_items()
	something_changed()
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
		event_copy_array.append(item.resource.to_text())
	var _json = JSON.new()
	DisplayServer.clipboard_set(_json.stringify(
		{
			"events":event_copy_array,
			"project_name": ProjectSettings.get_setting("application/config/name")
		}))


func paste_check():
	var _json = JSON.new()
	var clipboard_parse = _json.parse(DisplayServer.clipboard_get())
	if clipboard_parse == OK:
		clipboard_parse = _json.get_data()
		if clipboard_parse.has("project_name"):
			if clipboard_parse.project_name != ProjectSettings.get_setting("application/config/name"):
				print("[D] Be careful when copying from another project!")
		if clipboard_parse.has('events'):
			return clipboard_parse.events


func remove_events_at_index(at_index:int, amount:int = 1)-> void:
	selected_items = []
	something_changed()
	for i in range(0, amount):
		selected_items.append(%Timeline.get_child(at_index + i))
	delete_selected_events()


func add_events_at_index(event_list:Array, at_index:int) -> void:
	if at_index != -1:
		event_list.reverse()
		selected_items = [%Timeline.get_child(at_index)]
	else:
		selected_items = []
	
	var new_items := []
	for item in event_list:
		if typeof(item) == TYPE_STRING:
			var resource: Variant
			if get_parent().editors_manager.resource_helper:
				for i in get_parent().editors_manager.resource_helper.get_event_scripts():
					if i._test_event_string(item):
						resource = i.duplicate()
						break
			else:
				printerr("[Dialogic] Unable to access resource_helper!")
				continue
			if resource['event_name'] == 'Character' or resource['event_name'] == 'Text':
				resource.set_meta('editor_character_directory', find_parent('EditorView').character_directory)
			resource.from_text(item)
			if item:
				new_items.append(add_event_node(resource))
	selected_items = new_items
	something_changed()
	sort_selection()
	visual_update_selection()
	indent_events()


## *****************************************************************************
##					BLOCK SELECTION
## *****************************************************************************

func _is_item_selected(item: Node):
	return item in selected_items

func select_item(item: Node, multi_possible:bool = true):
	if item == null:
		return

	if Input.is_key_pressed(KEY_CTRL) and multi_possible:
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
				if not %Timeline.get_child(index) in selected_items:
					selected_items.append(%Timeline.get_child(index))
				
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
	for item in %Timeline.get_children():
		item.visual_deselect()
		if 'end_node' in item and item.end_node != null:
			item.end_node.unhighlight()
	for item in selected_items:
		item.visual_select()
		if 'end_node' in item and item.end_node != null:
			item.end_node.highlight()

## Sorts the selection using 'custom_sort_selection'
func sort_selection():
	selected_items.sort_custom(custom_sort_selection)

## Compares two event blocks based on their position in the timeline
func custom_sort_selection(item1, item2):
	return item1.get_index() < item2.get_index()

## Helpers
func select_all_items():
	
	selected_items = []
	for event in %Timeline.get_children():
		selected_items.append(event)
	visual_update_selection()

func deselect_all_items():
	selected_items = []
	visual_update_selection()


## *****************************************************************************
##				CREATING NEW EVENTS USING THE BUTTONS
## *****************************************************************************
# Event Creation signal for buttons
func _add_event_button_pressed(event_resource:DialogicEvent):
	var at_index := -1
	if selected_items:
		at_index = selected_items[-1].get_index()+1
	else:
		at_index = %Timeline.get_child_count()
	
	var remove_event_index := 1
	
	TimelineUndoRedo.create_action("[D] Add "+event_resource.event_name+" event.")
	if event_resource.can_contain_events:
		TimelineUndoRedo.add_do_method(add_event_with_end_branch.bind(event_resource.duplicate(), at_index, true, true))
		TimelineUndoRedo.add_undo_method(remove_events_at_index.bind(at_index, 2))
	else:
		TimelineUndoRedo.add_do_method(add_event_node.bind(event_resource.duplicate(), at_index, true, true))
		TimelineUndoRedo.add_undo_method(remove_events_at_index.bind(at_index, 1))
	TimelineUndoRedo.commit_action()
	
	something_changed()
	scroll_to_piece(at_index)
	indent_events()

## *****************************************************************************
##					 	CREATING THE TIMELINE
## *****************************************************************************
# Adding an event to the timeline
func add_event_node(event_resource:DialogicEvent, at_index:int = -1, auto_select: bool = false, indent: bool = false) -> Control:
	if event_resource is DialogicEndBranchEvent:
		return create_end_branch_event(at_index, %Timeline.get_child(0))
	
	if event_resource['event_node_ready'] == false:
		if event_resource['event_node_as_text'] != "":
			event_resource._load_from_string(event_resource['event_node_as_text'])
	
	var piece :Control = event_node.instantiate()
	piece.resource = event_resource
	event_resource._editor_node = piece
	piece.content_changed.connect(something_changed)
	if at_index == -1:
		if len(selected_items) != 0:
			selected_items[0].add_sibling(piece)
		else:
			%Timeline.add_child(piece)
	else:
		%Timeline.add_child(piece)
		%Timeline.move_child(piece, at_index)
	
	piece.gui_input.connect(_on_event_block_gui_input.bind(piece))
	
	# Building editing part
	piece.build_editor(true, event_resource.expand_by_default)
	
	if auto_select:
		select_item(piece, false)
	
	# Spacing
	add_extra_scroll_area_to_timeline()
	
	# Indent on create
	if indent:
		indent_events()
	
	if not _building_timeline:
		piece.focus()
	
	return piece

func create_end_branch_event(at_index:int, parent_node:Node) -> Node:
	var end_branch_event = load("res://addons/dialogic/Editor/Events/BranchEnd.tscn").instantiate()
	end_branch_event.resource = DialogicEndBranchEvent.new()
	end_branch_event.gui_input.connect(_on_event_block_gui_input.bind(end_branch_event))
	parent_node.end_node = end_branch_event
	end_branch_event.parent_node = parent_node
	end_branch_event.add_end_control(parent_node.resource.get_end_branch_control())
	%Timeline.add_child(end_branch_event)
	%Timeline.move_child(end_branch_event, at_index)
	return end_branch_event

# combination of the above that establishes the correct connection between the event and it's end branch
func add_event_with_end_branch(resource, at_index:int=-1, auto_select:bool = false, indent:bool = false):
	var event = add_event_node(resource, at_index, auto_select, indent)
	create_end_branch_event(at_index+1, event)

## *****************************************************************************
##					 	BLOCK GETTERS
## *****************************************************************************
func get_block_above(block):
	var block_index = block.get_index()
	var item = null
	if block_index > 0:
		item = %Timeline.get_child(block_index - 1)
	return item


func get_block_below(block):
	var block_index = block.get_index()
	var item = null
	if block_index < %Timeline.get_child_count() - 1:
		item = %Timeline.get_child(block_index + 1)
	return item


func get_block_height(block):
	if block != null:
		return block.size.y
	else:
		return null


func get_index_under_cursor():
	var current_position = get_global_mouse_position()
	var top_pos = 0
	for i in range(%Timeline.get_child_count()):
		var c = %Timeline.get_child(i)
		if c.global_position.y < current_position.y:
			top_pos = i
	return top_pos

## *****************************************************************************
##					 	BLOCK MOVEMENT
## *****************************************************************************
func move_block_up(block):
	if block.get_index() < 1: return false
	%Timeline.move_child(block, block.get_index() - 1)
	%TimelineArea.queue_redraw()
	something_changed()
	indent_events()

func move_block_down(block):
	%Timeline.move_child(block, block.get_index() + 1)
	%TimelineArea.queue_redraw()
	something_changed()
	indent_events()

func move_block_to_index(block_index, index):
	%Timeline.move_child(%Timeline.get_child(block_index), index)
	something_changed()
	indent_events()

## *****************************************************************************
##					VISIBILITY/VISUALS
## *****************************************************************************
func scroll_to_piece(piece_index) -> void:
	var height = 0
	for i in range(0, piece_index):
		height += %Timeline.get_child(i).size.y
	if height < %TimelineArea.scroll_vertical or height > %TimelineArea.scroll_vertical+%TimelineArea.size.y-(200*DialogicUtil.get_editor_scale()):
		%TimelineArea.scroll_vertical = height


func indent_events() -> void:
	var indent: int = 0
	var event_list: Array = %Timeline.get_children()

	if event_list.size() < 2:
		return

	var currently_hidden = false
	var hidden_until = null
	
	# will be applied to the indent after the current event
	var delayed_indent: int = 0
	
	for event in event_list:
		if (not "resource" in event):
			continue
			
		if (not currently_hidden) and event.resource.can_contain_events and event.end_node and event.collapsed:
			currently_hidden = true
			hidden_until = event.end_node
		elif currently_hidden and event == hidden_until:
			currently_hidden = false
			hidden_until = null
		elif currently_hidden:
			event.hide()
		else:
			event.show()
		
		delayed_indent = 0
		
		if event.resource.can_contain_events:
			delayed_indent = 1
		
		if event.resource.needs_parent_event:
			var current_block_above = get_block_above(event)
			while current_block_above != null and current_block_above.resource is DialogicEndBranchEvent:
				current_block_above = get_block_above(current_block_above.parent_node)
				
			if current_block_above != null and event.resource.is_expected_parent_event(current_block_above.resource):
				indent += 1
		
		if event.resource is DialogicEndBranchEvent:
			event.parent_node_changed()
			delayed_indent -= 1
			if event.parent_node.resource.needs_parent_event:
				delayed_indent -= 1
		
		if indent >= 0:
			event.set_indent(indent)
		else:
			event.set_indent(0)
		indent += delayed_indent
	
	%TimelineArea.queue_redraw()


func add_extra_scroll_area_to_timeline():
	if %Timeline.get_children().size() > 4:
		%Timeline.custom_minimum_size.y = 0
		%Timeline.size.y = 0
		if %Timeline.size.y + 200 > %TimelineArea.size.y:
			%Timeline.custom_minimum_size = Vector2(0, %Timeline.size.y + 200)


## *****************************************************************************
##				SPECIAL BLOCK OPERATIONS
## *****************************************************************************

func _on_event_popup_menu_index_pressed(index:int) -> void:
	var item :Control = %EventPopupMenu.current_event
	if index == 0:
		if not item.resource.help_page_path.is_empty():
			OS.shell_open(item.resource.help_page_path)
	elif index == 2:
		move_block_up(item)
	elif index == 3:
		move_block_down(item)
	elif index == 5:
		delete_selected_events()
	indent_events()
