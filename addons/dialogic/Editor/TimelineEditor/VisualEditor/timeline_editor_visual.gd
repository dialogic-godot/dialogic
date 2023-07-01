@tool
extends Container

## Visual mode of the timeline editor. 


################################################################################
## 				EDITOR NODES
################################################################################
var TimelineUndoRedo := UndoRedo.new()
var event_node
var sidebar_collapsed := false

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
var _building_timeline := false
var _timeline_changed_while_loading := false


################################################################################
## 				 TIMELINE EVENT MANAGEMENT
################################################################################
var selected_items : Array = []


################################################################################
## 					CREATE/SAVE/LOAD
################################################################################

func something_changed():
	get_parent().current_resource_state = DialogicEditor.ResourceStates.Unsaved


func save_timeline() -> void:
	if !is_inside_tree():
		return
	
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

	get_parent().current_resource.events = new_events
	get_parent().current_resource.events_processed = true
	var error :int = ResourceSaver.save(get_parent().current_resource, get_parent().current_resource.resource_path)
	if error != OK:
		print('[Dialogic] Saving error: ', error)
	
	get_parent().current_resource.set_meta("unsaved", false)
	get_parent().current_resource_state = DialogicEditor.ResourceStates.Saved
	get_parent().editors_manager.resource_helper.rebuild_timeline_directory()


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_timeline()


func load_timeline(resource:DialogicTimeline) -> void:
	if _building_timeline:
		_timeline_changed_while_loading = true
		await batch_loaded
		_timeline_changed_while_loading = false
		_building_timeline = false
	
	clear_timeline_nodes()
	
	if get_parent().current_resource.events.size() == 0:
		pass
	else: 
		if typeof(get_parent().current_resource.events[0]) == TYPE_STRING:
			get_parent().current_resource.events_processed = false
			get_parent().current_resource = get_parent().editors_manager.resource_helper.process_timeline(get_parent().current_resource)
		if get_parent().current_resource.events.size() == 0:
			return
		var data := resource.events
		var page := 1
		var batch_size := 10
		_batches = []
		_building_timeline = true
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
	if _timeline_changed_while_loading:
		return
	if _batches.size() > 0:
		indent_events()
		await get_tree().process_frame
		load_batch(_batches)
		return
	
	if opener_events_stack:
		for ev in opener_events_stack:
			create_end_branch_event(%Timeline.get_child_count(), ev)
	opener_events_stack = []
	indent_events()
	_building_timeline = false
	



func clear_timeline_nodes():
	deselect_all_items()
	for event in %Timeline.get_children():
		event.free()

##################### SETUP ####################################################
################################################################################

func _ready():
	DialogicUtil.get_dialogic_plugin().dialogic_save.connect(save_timeline)
	event_node = load("res://addons/dialogic/Editor/Events/EventBlock/event_block.tscn")
	
	batch_loaded.connect(_on_batch_loaded)


func load_event_buttons() -> void:
	# Clear previous event buttons
	for child in %RightSidebar.get_child(0).get_children():
		if child is FlowContainer:
			for button in child.get_children():
				button.queue_free()
	
	var scripts: Array = get_parent().editors_manager.resource_helper.get_event_scripts()
	
	# Event buttons
	var buttonScene := load("res://addons/dialogic/Editor/TimelineEditor/VisualEditor/AddEventButton.tscn")
	
	var hidden_buttons :Array = DialogicUtil.get_editor_setting('hidden_event_buttons', [])
	var sections := {}
	
	for child in %RightSidebar.get_child(0).get_children():
		child.queue_free()
	
	for event_script in scripts:
		var event_resource: Variant
		
		if typeof(event_script) == TYPE_STRING:
			event_resource = load(event_script).new()
		else:
			event_resource = event_script
		
		if event_resource.disable_editor_button == true: 
			continue
		
		if event_resource.event_name in hidden_buttons: 
			continue
		
		var button :Button = buttonScene.instantiate()
		button.resource = event_resource
		button.visible_name = event_resource.event_name
		button.event_icon = event_resource._get_icon()
		button.set_color(event_resource.event_color)
		button.dialogic_color_name = event_resource.dialogic_color_name
		button.event_sorting_index = event_resource.event_sorting_index
		
		button.button_up.connect(_add_event_button_pressed.bind(event_resource))
		
		if !event_resource.event_category in sections:
			var section := VBoxContainer.new()
			section.name = event_resource.event_category
			
			var section_header := HBoxContainer.new()
			section_header.add_child(Label.new())
			section_header.get_child(0).text = event_resource.event_category
			section_header.get_child(0).size_flags_horizontal = SIZE_SHRINK_BEGIN
			section_header.add_child(HSeparator.new())
			section_header.get_child(1).size_flags_horizontal = SIZE_EXPAND_FILL
			section.add_child(section_header)
			
			var button_container := FlowContainer.new()
			section.add_child(button_container)
			
			sections[event_resource.event_category] = button_container
			%RightSidebar.get_child(0).add_child(section)
			
		
		sections[event_resource.event_category].add_child(button)
		
		# Sort event button
		while event_resource.event_sorting_index < sections[event_resource.event_category].get_child(max(0, button.get_index()-1)).resource.event_sorting_index:
			sections[event_resource.event_category].move_child(button, button.get_index()-1)
	
	var sections_order := DialogicUtil.get_editor_setting('event_section_order', ['Main', 'Logic', 'Timeline', 'Audio', 'Godot','Other', 'Helper'])
	# Sort event sections
	for section in sections_order:
		if %RightSidebar.get_child(0).has_node(section):
			%RightSidebar.get_child(0).move_child(%RightSidebar.get_child(0).get_node(section), sections_order.find(section))
	
	# Resize RightSidebar
	var _scale := DialogicUtil.get_editor_scale()
	%RightSidebar.custom_minimum_size.x = 50 * _scale
	
	$View.split_offset = -200*_scale
	_on_right_sidebar_resized()


#################### CLEANUP ###################################################
################################################################################

func _exit_tree() -> void:
	# Explicitly free any open cache resources on close, so we don't get leaked resource errors on shutdown
	clear_timeline_nodes()


################# DRAG&DROP + DRAGGING EVENTS ###################################
#################################################################################


# SIGNAL handles input on the events mainly for selection and moving events
func _on_event_block_gui_input(event, item: Node):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			if not _is_item_selected(item) and not len(selected_items) > 1:
				select_item(item)

		else:
			if len(selected_items) > 1:
				select_item(item)
	
	if len(selected_items) > 0 and event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if !%TimelineArea.dragging:
				%TimelineArea.start_dragging(%TimelineArea.DragTypes.ExistingEvents, get_events_indexed(selected_items, EndBranchMode.Only_Single))


func _on_timeline_area_drag_completed(type:int, index:int, data:Variant) -> void:
	if type == %TimelineArea.DragTypes.NewEvent:
		var resource :DialogicEvent = data.duplicate()
		resource._load_custom_defaults()
		
		TimelineUndoRedo.create_action("[D] Add "+resource.event_name+" event.")
		if resource.can_contain_events:
			TimelineUndoRedo.add_do_method(add_event_with_end_branch.bind(resource, index, true, true))
			TimelineUndoRedo.add_undo_method(remove_events_at_index.bind(index, 2))
		else:
			TimelineUndoRedo.add_do_method(add_event_node.bind(resource, index, true, true))
			TimelineUndoRedo.add_undo_method(remove_events_at_index.bind(index, 1))
		TimelineUndoRedo.commit_action()
	
	elif type == %TimelineArea.DragTypes.ExistingEvents:
		# if the index is after some selected events, correct it
		var c := 0
		for i in data.keys():
			if i <index: c += 1
		
		TimelineUndoRedo.create_action("[D] Move event(s).")
		TimelineUndoRedo.add_do_method(delete_events_indexed.bind(data))
		TimelineUndoRedo.add_do_method(add_events_at_index.bind(data.values(), index-c))
		
		TimelineUndoRedo.add_undo_method(remove_events_at_index.bind(index-c, len(data.keys())))
		TimelineUndoRedo.add_undo_method(add_events_indexed.bind(get_events_indexed(selected_items)))
		TimelineUndoRedo.commit_action()
	
	something_changed()
	scroll_to_piece(index)
	indent_events()

#################### SHORTCUTS #################################################
################################################################################

func _input(event:InputEvent) -> void:
	# some shortcuts need to get handled in the common input event
	# especially CTRL-based
	# because certain godot controls swallow events (like textedit)
	# we protect this with is_visible_in_tree to not 
	# invoke a shortcut by accident
	
	if get_viewport().gui_get_focus_owner() is TextEdit || get_viewport().gui_get_focus_owner() is LineEdit: 
		return
	if !((event is InputEventKey or !event is InputEventWithModifiers) and is_visible_in_tree()):
		return
	if "pressed" in event:
		if !event.pressed:
			return
	match event.as_text():
		"Ctrl+Z": # UNDO
			TimelineUndoRedo.undo()
			indent_events()
			get_viewport().set_input_as_handled()
		
		"Ctrl+Shift+Z", "Ctrl+Y": # REDO
			TimelineUndoRedo.redo()
			indent_events()
			get_viewport().set_input_as_handled()
		
		"Up": #select previous
			if (len(selected_items) == 1):
				var prev := max(0, selected_items[0].get_index() - 1)
				var prev_node := %Timeline.get_child(prev)
				if (prev_node != selected_items[0]):
					selected_items = []
					select_item(prev_node)
				get_viewport().set_input_as_handled()
		
		"Down": #select next
			if (len(selected_items) == 1):
				var next := min(%Timeline.get_child_count() - 1, selected_items[0].get_index() + 1)
				var next_node := %Timeline.get_child(next)
				if (next_node != selected_items[0]):
					selected_items = []
					select_item(next_node)
				get_viewport().set_input_as_handled()
		
		"Delete":
			if (len(selected_items) != 0):
				var events_indexed := get_events_indexed(selected_items)
				TimelineUndoRedo.create_action("[D] Deleting "+str(len(selected_items))+" event(s).")
				TimelineUndoRedo.add_do_method(delete_events_indexed.bind(events_indexed))
				TimelineUndoRedo.add_undo_method(add_events_indexed.bind(events_indexed))
				TimelineUndoRedo.commit_action()
				get_viewport().set_input_as_handled()
		
		"Ctrl+T": # Add text event
			_add_event_button_pressed(DialogicTextEvent.new())
			get_viewport().set_input_as_handled()
		
		"Ctrl+A": # select all
			if (len(selected_items) != 0):
				select_all_items()
			get_viewport().set_input_as_handled()
		
		"Ctrl+Shift+A": # deselect all
			if (len(selected_items) != 0):
				deselect_all_items()
			get_viewport().set_input_as_handled()
		
		"Ctrl+C":
			copy_selected_events()
			get_viewport().set_input_as_handled()
		
		"Ctrl+V":
			var events_list := paste_check()
			var paste_position := -1
			if selected_items:
				paste_position = selected_items[-1].get_index()+1
			else:
				paste_position = %Timeline.get_child_count()-1
			if events_list:
				TimelineUndoRedo.create_action("[D] Pasting "+str(len(events_list))+" event(s).")
				TimelineUndoRedo.add_do_method(add_events_at_index.bind(events_list, paste_position))
				TimelineUndoRedo.add_undo_method(remove_events_at_index.bind(paste_position+1, len(events_list)))
				TimelineUndoRedo.commit_action()
				get_viewport().set_input_as_handled()
		
		"Ctrl+X":
			var events_indexed := get_events_indexed(selected_items)
			TimelineUndoRedo.create_action("[D] Cut "+str(len(selected_items))+" event(s).")
			TimelineUndoRedo.add_do_method(cut_events_indexed.bind(events_indexed))
			TimelineUndoRedo.add_undo_method(add_events_indexed.bind(events_indexed))
			TimelineUndoRedo.commit_action()
			get_viewport().set_input_as_handled()
		
		"Ctrl+D":
			if len(selected_items) > 0:
				var events := get_events_indexed(selected_items).values()
				var at_index :int= selected_items[-1].get_index()
				TimelineUndoRedo.create_action("[D] Duplicate "+str(len(events))+" event(s).")
				TimelineUndoRedo.add_do_method(add_events_at_index.bind(events, at_index))
				TimelineUndoRedo.add_undo_method(remove_events_at_index.bind(at_index, len(events)))
				TimelineUndoRedo.commit_action()
			get_viewport().set_input_as_handled()
		
		"Alt+Up":
			if len(selected_items) > 0:
				TimelineUndoRedo.create_action("[D] Move event(s) up.")
				TimelineUndoRedo.add_do_method(move_blocks_by_index.bind(selected_items.map(func(x):return x.get_index()), -1))
				TimelineUndoRedo.add_do_method(indent_events)
				TimelineUndoRedo.add_do_method(something_changed)
				TimelineUndoRedo.add_undo_method(move_blocks_by_index.bind(selected_items.map(func(x):return x.get_index()-1), 1))
				TimelineUndoRedo.add_undo_method(indent_events)
				TimelineUndoRedo.add_undo_method(something_changed)
				TimelineUndoRedo.commit_action()
				
				get_viewport().set_input_as_handled()
		
		"Alt+Down":
			if len(selected_items) > 0:
				TimelineUndoRedo.create_action("[D] Move event(s) down.")
				TimelineUndoRedo.add_do_method(move_blocks_by_index.bind(selected_items.map(func(x):return x.get_index()), 1))
				TimelineUndoRedo.add_do_method(indent_events)
				TimelineUndoRedo.add_do_method(something_changed)
				TimelineUndoRedo.add_undo_method(move_blocks_by_index.bind(selected_items.map(func(x):return x.get_index()+1), -1))
				TimelineUndoRedo.add_undo_method(indent_events)
				TimelineUndoRedo.add_undo_method(something_changed)
				TimelineUndoRedo.commit_action()
				
				get_viewport().set_input_as_handled()
			


#################### DELETING, COPY, PASTE #####################################
################################################################################

enum EndBranchMode {Force_No_Single, Only_Single}
# Force_No_Single = End branches are effected if their parent is selected, not alone
#    -> for delete, copy, cut, paste (to avoid lonly end branches)
# Only_Single = Single End branches are allowed alone and are not effected if only the parent is selected
#    -> for moving events

func get_events_indexed(events:Array, end_branch_mode:=EndBranchMode.Force_No_Single) -> Dictionary:
	var indexed_dict := {}
	for event in events:
		# do not collect selected end branches (e.g. on delete, copy, etc.)
		if event.resource is DialogicEndBranchEvent and end_branch_mode == EndBranchMode.Force_No_Single:
			continue
		
		indexed_dict[event.get_index()] = event.resource.to_text()
		
		# store an end branch if it is selected or connected to a selected event
		if end_branch_mode == EndBranchMode.Force_No_Single:
			if 'end_node' in event and event.end_node:
				event = event.end_node
				indexed_dict[event.get_index()] = event.resource.to_text()
		
		if event.resource is DialogicEndBranchEvent:
			if event.parent_node in events: # add local index
				indexed_dict[event.get_index()] += str(events.find(event.parent_node))
			else: # add global index
				indexed_dict[event.get_index()] += '#'+str(event.parent_node.get_index())
	return indexed_dict


func select_indexed_events(indexed_events:Dictionary) -> void:
	selected_items = []
	for event_index in indexed_events.keys():
		selected_items.append(%Timeline.get_child(event_index))


func add_events_indexed(indexed_events:Dictionary) -> void:
	var indexes := indexed_events.keys()
	indexes.sort()

	var events := []
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
		event_resource.set_meta('editor_character_directory', get_parent().editors_manager.resource_helper.character_directory)
		event_resource.from_text(indexed_events[event_idx])
		if event_resource is DialogicEndBranchEvent:
			var idx :String= indexed_events[event_idx].trim_prefix('<<END BRANCH>>')
			if idx.begins_with('#'): # a global index
				events.append(create_end_branch_event(%Timeline.get_child_count(), %Timeline.get_child(int(idx.trim_prefix('#')))))
			else: # a local index (index in the added events list)
				events.append(create_end_branch_event(%Timeline.get_child_count(), events[int(idx)]))
			%Timeline.move_child(events[-1], event_idx)
		else:
			events.append(add_event_node(event_resource))
			%Timeline.move_child(events[-1], event_idx)
		
	selected_items = events
	visual_update_selection()
	indent_events()


func delete_events_indexed(indexed_events:Dictionary) -> void:
	select_indexed_events(indexed_events)
	delete_selected_events()
	indent_events()


func delete_selected_events() -> void:
	if len(selected_items) == 0:
		return
	
	# get next element
	var next := min(%Timeline.get_child_count() - 1, selected_items[-1].get_index() + 1)
	var next_node := %Timeline.get_child(next)
	if _is_item_selected(next_node):
		next_node = null
	
	for event in selected_items:
		if 'end_node' in event and event.end_node != null and is_instance_valid(event.end_node):
			if !is_instance_valid(event.end_node.get_parent()): return
			event.end_node.get_parent().remove_child(event.end_node)
			event.end_node.queue_free()
		if is_instance_valid(event):
			if !is_instance_valid(event.get_parent()): return
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


func cut_selected_events() -> void:
	copy_selected_events()
	delete_selected_events()
	indent_events()


func cut_events_indexed(indexed_events:Dictionary) -> void:
	select_indexed_events(indexed_events)
	cut_selected_events()
	indent_events()


func copy_selected_events() -> void:
	if len(selected_items) == 0:
		return
	var event_copy_array := []
	for item in selected_items:
		event_copy_array.append(item.resource.to_text())
		if item.resource is DialogicEndBranchEvent:
			if item.parent_node in selected_items: # add local index
				event_copy_array[-1] += str(selected_items.find(item.parent_node))
			else: # add global index
				event_copy_array[-1] += '#'+str(item.parent_node.get_index())
	var _json := JSON.new()
	DisplayServer.clipboard_set(_json.stringify(
		{
			"events":event_copy_array,
			"project_name": ProjectSettings.get_setting("application/config/name")
		}))


func paste_check() -> Array:
	var _json := JSON.new()
	var clipboard_parse :Variant= _json.parse(DisplayServer.clipboard_get())
	if clipboard_parse == OK:
		clipboard_parse = _json.get_data()
		if clipboard_parse.has("project_name"):
			if clipboard_parse.project_name != ProjectSettings.get_setting("application/config/name"):
				print("[D] Be careful when copying from another project!")
		if clipboard_parse.has('events'):
			return clipboard_parse.events
	return []


func remove_events_at_index(at_index:int, amount:int = 1)-> void:
	selected_items = []
	something_changed()
	for i in range(0, amount):
		selected_items.append(%Timeline.get_child(at_index + i))
	delete_selected_events()
	indent_events()


func add_events_at_index(event_list:Array, at_index:int) -> void:	
	var new_items := []
	for c in range(len(event_list)):
		var item :String = event_list[c]
		var resource: Variant
		if get_parent().editors_manager.resource_helper:
			for i in get_parent().editors_manager.resource_helper.get_event_scripts():
				if i._test_event_string(item):
					resource = i.duplicate()
					break
			resource.set_meta('editor_character_directory', get_parent().editors_manager.resource_helper.character_directory)
			resource.from_text(item)
		else:
			printerr("[Dialogic] Unable to access resource_helper!")
			continue
		if resource is DialogicEndBranchEvent:
			var idx :String= item.trim_prefix('<<END BRANCH>>')
			if idx.begins_with('#'): # a global index
				new_items.append(create_end_branch_event(at_index+c, %Timeline.get_child(int(idx.trim_prefix('#')))))
			else: # a local index (index in the added events list)
				new_items.append(create_end_branch_event(at_index+c, new_items[int(idx)]))
		else:
			new_items.append(add_event_node(resource, at_index+c))
	selected_items = new_items
	something_changed()
	sort_selection()
	visual_update_selection()
	indent_events()


#################### BLOCK SELECTION ###########################################
################################################################################

func _is_item_selected(item: Node) -> bool:
	return item in selected_items


func select_item(item: Node, multi_possible:bool = true) -> void:
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
			var index :int= selected_items[-1].get_index()
			var goal_idx := item.get_index()
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
func visual_update_selection() -> void:
	for item in %Timeline.get_children():
		item.visual_deselect()
		if 'end_node' in item and item.end_node != null:
			item.end_node.unhighlight()
	for item in selected_items:
		item.visual_select()
		if 'end_node' in item and item.end_node != null:
			item.end_node.highlight()


## Sorts the selection using 'custom_sort_selection'
func sort_selection() -> void:
	selected_items.sort_custom(custom_sort_selection)


## Compares two event blocks based on their position in the timeline
func custom_sort_selection(item1, item2) -> bool:
	return item1.get_index() < item2.get_index()


func select_all_items() -> void:
	selected_items = []
	for event in %Timeline.get_children():
		selected_items.append(event)
	visual_update_selection()


func deselect_all_items() -> void:
	selected_items = []
	visual_update_selection()

############ CREATING NEW EVENTS USING THE BUTTONS #############################
################################################################################

# Event Creation signal for buttons
func _add_event_button_pressed(event_resource:DialogicEvent):
	if %TimelineArea.get_global_rect().has_point(get_global_mouse_position()):
		return
	
	var at_index := -1
	if selected_items:
		at_index = selected_items[-1].get_index()+1
	else:
		at_index = %Timeline.get_child_count()
	
	var resource := event_resource.duplicate()
	resource._load_custom_defaults()
	
	resource.created_by_button = true
	
	TimelineUndoRedo.create_action("[D] Add "+event_resource.event_name+" event.")
	if event_resource.can_contain_events:
		TimelineUndoRedo.add_do_method(add_event_with_end_branch.bind(resource, at_index, true, true))
		TimelineUndoRedo.add_undo_method(remove_events_at_index.bind(at_index, 2))
	else:
		TimelineUndoRedo.add_do_method(add_event_node.bind(resource, at_index, true, true))
		TimelineUndoRedo.add_undo_method(remove_events_at_index.bind(at_index, 1))
	TimelineUndoRedo.commit_action()
	
	resource.created_by_button = false
	
	something_changed()
	scroll_to_piece(at_index)
	indent_events()


################# CREATING THE TIMELINE ########################################
################################################################################

# Adding an event to the timeline
func add_event_node(event_resource:DialogicEvent, at_index:int = -1, auto_select: bool = false, indent: bool = false) -> Control:
	if event_resource is DialogicEndBranchEvent:
		print("wait what")
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
	
	# Indent on create
	if indent:
		indent_events()
	
	if not _building_timeline:
		piece.focus()
	
	return piece


func create_end_branch_event(at_index:int, parent_node:Node) -> Node:
	var end_branch_event :Control = load("res://addons/dialogic/Editor/Events/BranchEnd.tscn").instantiate()
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
	var event := add_event_node(resource, at_index, auto_select, indent)
	create_end_branch_event(at_index+1, event)


##################### BLOCK GETTERS ############################################
################################################################################

func get_block_above(block:Node) -> Node:
	if block.get_index() > 0:
		return %Timeline.get_child(block.get_index() - 1)
	return null


func get_block_below(block:Node) -> Node:
	if block.get_index() < %Timeline.get_child_count() - 1:
		return %Timeline.get_child(block.get_index() + 1)
	return null


##################### BLOCK MOVEMENT ###########################################
################################################################################

func move_blocks_by_index(block_idxs:Array, offset:int):
	move_blocks(block_idxs.map(func(x): return %Timeline.get_child(x)), offset)


func move_blocks(blocks:Array, offset:int) -> void:
	if offset > 0:
		blocks = blocks.duplicate()
		blocks.reverse()
	for block in blocks:
		var to_idx := max(min(block.get_index()+offset, %Timeline.get_child_count()-1), 0)
		if !%Timeline.get_child(to_idx) in blocks:
			move_block_to_index(block.get_index(), to_idx)


func move_block_up(block:Node) -> void:
	if block.get_index() < 1: return
	%Timeline.move_child(block, block.get_index() - 1)
	%TimelineArea.queue_redraw()


func move_block_down(block:Node) -> void:
	%Timeline.move_child(block, block.get_index() + 1)
	%TimelineArea.queue_redraw()


func move_block_to_index(block_index:int, index:int) -> void:
	%Timeline.move_child(%Timeline.get_child(block_index), index)
	something_changed()
	indent_events()



################### VISIBILITY/VISUALS #########################################
################################################################################

func scroll_to_piece(piece_index:int) -> void:
	var height := 0
	for i in range(0, piece_index):
		height += %Timeline.get_child(i).size.y
	if height < %TimelineArea.scroll_vertical or height > %TimelineArea.scroll_vertical+%TimelineArea.size.y-(200*DialogicUtil.get_editor_scale()):
		%TimelineArea.scroll_vertical = height


func indent_events() -> void:
	var indent: int = 0
	var event_list: Array = %Timeline.get_children()
	
	if event_list.size() < 2:
		return
	
	var currently_hidden := false
	var hidden_count := 0
	var hidden_until :Control= null
	
	# will be applied to the indent after the current event
	var delayed_indent: int = 0
	
	for event in event_list:
		if (not "resource" in event):
			continue
		
		if (not currently_hidden) and event.resource.can_contain_events and event.end_node and event.collapsed:
			currently_hidden = true
			hidden_until = event.end_node
			hidden_count = 0
		elif currently_hidden and event == hidden_until:
			event.update_hidden_events_indicator(hidden_count)
			currently_hidden = false
			hidden_until = null
		elif currently_hidden:
			event.hide()
			hidden_count += 1
		else:
			event.show()
			if event.resource is DialogicEndBranchEvent:
				event.update_hidden_events_indicator(0)
		
		delayed_indent = 0
		
		if event.resource.can_contain_events:
			delayed_indent = 1
		
		if event.resource.needs_parent_event:
			var current_block_above := get_block_above(event)
			while current_block_above != null and current_block_above.resource is DialogicEndBranchEvent:
				if current_block_above.parent_node == event:
					break
				current_block_above = get_block_above(current_block_above.parent_node)
				
			if current_block_above != null and event.resource.is_expected_parent_event(current_block_above.resource):
				indent += 1
				event.set_warning()
			else:
				event.set_warning('This event needs a specific parent event!')
		
		elif event.resource is DialogicEndBranchEvent:
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



################ SPECIAL BLOCK OPERATIONS ######################################
################################################################################

func _on_event_popup_menu_index_pressed(index:int) -> void:
	var item :Control = %EventPopupMenu.current_event
	if index == 0:
		if not item.resource.help_page_path.is_empty():
			OS.shell_open(item.resource.help_page_path)
	elif index == 2 or index == 3:
		if index == 2:
			TimelineUndoRedo.create_action("[D] Move event up.")
			TimelineUndoRedo.add_do_method(move_blocks_by_index.bind([item].map(func(x):return x.get_index()), -1))
			TimelineUndoRedo.add_undo_method(move_blocks_by_index.bind([item].map(func(x):return x.get_index()-1), 1))
		else:
			TimelineUndoRedo.create_action("[D] Move event down.")
			TimelineUndoRedo.add_do_method(move_blocks_by_index.bind([item].map(func(x):return x.get_index()), 1))
			TimelineUndoRedo.add_undo_method(move_blocks_by_index.bind([item].map(func(x):return x.get_index()+1), -1))
		TimelineUndoRedo.add_do_method(indent_events)
		TimelineUndoRedo.add_do_method(something_changed)
		TimelineUndoRedo.add_undo_method(indent_events)
		TimelineUndoRedo.add_undo_method(something_changed)
		TimelineUndoRedo.commit_action()
	elif index == 5:
		var events_indexed := get_events_indexed([item])
		TimelineUndoRedo.create_action("[D] Deleting 1 event.")
		TimelineUndoRedo.add_do_method(delete_events_indexed.bind(events_indexed))
		TimelineUndoRedo.add_undo_method(add_events_indexed.bind(events_indexed))
		TimelineUndoRedo.commit_action()
		indent_events()
		something_changed()


func _on_right_sidebar_resized():
	var _scale := DialogicUtil.get_editor_scale()
	if %RightSidebar.size.x < 160*_scale and !sidebar_collapsed:
		sidebar_collapsed = true
		for section in %RightSidebar.get_node('EventContainer').get_children():
			for con in section.get_children():
				if con.get_child_count() == 0:
					continue
				if con.get_child(0) is Label:
					con.get_child(0).hide()
				elif con.get_child(0) is Button:
					for button in con.get_children():
						button.toggle_name(false)
		
	elif %RightSidebar.size.x > 160*_scale and sidebar_collapsed:
		sidebar_collapsed = false
		for section in %RightSidebar.get_node('EventContainer').get_children():
			for con in section.get_children():
				if con.get_child_count() == 0:
					continue
				if con.get_child(0) is Label:
					con.get_child(0).show()
				elif con.get_child(0) is Button:
					for button in con.get_children():
						button.toggle_name(true)
