@tool
extends Container

## Visual mode of the timeline editor.


################## EDITOR NODES ################################################
################################################################################
var TimelineUndoRedo := UndoRedo.new()
@onready var timeline_editor := get_parent().get_parent()
var event_node
var sidebar_collapsed := false

################## SIGNALS #####################################################
################################################################################
signal selection_updated
signal batch_loaded
signal timeline_loaded


################## TIMELINE LOADING ############################################
################################################################################
var _batches := []
var _building_timeline := false
var _timeline_changed_while_loading := false
var _initialized := false

################## TIMELINE EVENT MANAGEMENT ###################################
################################################################################
var selected_items : Array = []
var drag_allowed := false


#region CREATE/SAVE/LOAD
################################################################################

func something_changed() -> void:
	timeline_editor.current_resource_state = DialogicEditor.ResourceStates.UNSAVED


func save_timeline() -> void:
	if !is_inside_tree():
		return

	# return if resource is unchanged
	if timeline_editor.current_resource_state != DialogicEditor.ResourceStates.UNSAVED:
		return

	# create a list of text versions of all the events with the right indent
	var new_events := []
	var indent := 0
	for event in %Timeline.get_children():
		if 'event_name' in event.resource:
			event.resource.update_text_version()
			new_events.append(event.resource)

	if !timeline_editor.current_resource:
		return

	timeline_editor.current_resource.events = new_events
	timeline_editor.current_resource.events_processed = true
	var error: int = ResourceSaver.save(timeline_editor.current_resource, timeline_editor.current_resource.resource_path)

	if error != OK:
		print('[Dialogic] Saving error: ', error)

	timeline_editor.current_resource.set_meta("unsaved", false)
	timeline_editor.current_resource_state = DialogicEditor.ResourceStates.SAVED
	DialogicResourceUtil.update_directory('dtl')


func _notification(what:int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_timeline()


func load_timeline(resource:DialogicTimeline) -> void:
	if _building_timeline:
		_timeline_changed_while_loading = true
		await batch_loaded
		_timeline_changed_while_loading = false
		_building_timeline = false

	clear_timeline_nodes()

	if timeline_editor.current_resource.events.size() == 0:
		pass
	else:
		await timeline_editor.current_resource.process()

		if timeline_editor.current_resource.events.size() == 0:
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


func batch_events(array: Array, size: int, batch_number: int) -> Array:
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


func _on_batch_loaded() -> void:
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
	update_content_list()
	_building_timeline = false


func clear_timeline_nodes() -> void:
	deselect_all_items()
	for event in %Timeline.get_children():
		event.free()
#endregion


#region SETUP
################################################################################

func _ready() -> void:
	DialogicUtil.get_dialogic_plugin().dialogic_save.connect(save_timeline)
	event_node = load("res://addons/dialogic/Editor/Events/EventBlock/event_block.tscn")

	batch_loaded.connect(_on_batch_loaded)

	await find_parent('EditorView').ready
	timeline_editor.editors_manager.sidebar.content_item_activated.connect(_on_content_item_clicked)
	%Timeline.child_order_changed.connect(update_content_list)

	var editor_scale := DialogicUtil.get_editor_scale()
	%RightSidebar.size.x = DialogicUtil.get_editor_setting("dialogic/editor/right_sidebar_width", 200 * editor_scale)
	$View.split_offset = -DialogicUtil.get_editor_setting("dialogic/editor/right_sidebar_width", 200 * editor_scale)
	sidebar_collapsed = DialogicUtil.get_editor_setting("dialogic/editor/right_sidebar_collapsed", false)

	load_event_buttons()
	_on_right_sidebar_resized()
	_initialized = true


func load_event_buttons() -> void:
	sidebar_collapsed = DialogicUtil.get_editor_setting("dialogic/editor/right_sidebar_collapsed", false)

	# Clear previous event buttons
	for child in %RightSidebar.get_child(0).get_children():

		if child is FlowContainer:

			for button in child.get_children():
				button.queue_free()


	for child in %RightSidebar.get_child(0).get_children():
		child.get_parent().remove_child(child)
		child.queue_free()

	# Event buttons
	var button_scene := load("res://addons/dialogic/Editor/TimelineEditor/VisualEditor/AddEventButton.tscn")

	var scripts := DialogicResourceUtil.get_event_cache()
	var hidden_buttons :Array = DialogicUtil.get_editor_setting('hidden_event_buttons', [])
	var sections := {}

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

		var button: Button = button_scene.instantiate()
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
			section_header.get_child(0).theme_type_variation = "DialogicSection"
			section_header.add_child(HSeparator.new())
			section_header.get_child(1).size_flags_horizontal = SIZE_EXPAND_FILL
			section.add_child(section_header)

			var button_container := FlowContainer.new()
			section.add_child(button_container)

			sections[event_resource.event_category] = button_container
			%RightSidebar.get_child(0).add_child(section, true)

		sections[event_resource.event_category].add_child(button)
		button.toggle_name(!sidebar_collapsed)

		# Sort event button
		while event_resource.event_sorting_index < sections[event_resource.event_category].get_child(max(0, button.get_index()-1)).resource.event_sorting_index:
			sections[event_resource.event_category].move_child(button, button.get_index()-1)

	# Sort event sections
	var sections_order :Array= DialogicUtil.get_editor_setting('event_section_order',
			['Main', 'Flow', 'Logic', 'Audio', 'Visual','Other', 'Helper'])

	sections_order.reverse()
	for section_name in sections_order:
		if %RightSidebar.get_child(0).has_node(section_name):
			%RightSidebar.get_child(0).move_child(%RightSidebar.get_child(0).get_node(section_name), 0)

	# Resize RightSidebar
	%RightSidebar.custom_minimum_size.x = 50 * DialogicUtil.get_editor_scale()

	_on_right_sidebar_resized()
#endregion


#region CONTENT LIST
################################################################################

func _on_content_item_clicked(label:String) -> void:
	if label == "~ Top":
		%TimelineArea.scroll_vertical = 0
		return

	for event in %Timeline.get_children():
		if 'event_name' in event.resource and event.resource is DialogicLabelEvent:
			if event.resource.name == label:
				scroll_to_piece(event.get_index())
				return


func update_content_list() -> void:
	if not is_inside_tree():
		return

	var labels: PackedStringArray = []

	for event in %Timeline.get_children():

		if 'event_name' in event.resource and event.resource is DialogicLabelEvent:
			labels.append(event.resource.name)

	timeline_editor.editors_manager.sidebar.update_content_list(labels)


#endregion


#region DRAG & DROP + DRAGGING EVENTS
#################################################################################

# SIGNAL handles input on the events mainly for selection and moving events
func _on_event_block_gui_input(event: InputEvent, item: Node) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			if len(selected_items) > 1 and item in selected_items and !Input.is_key_pressed(KEY_CTRL):
				pass
			elif not _is_item_selected(item) and not len(selected_items) > 1:
				select_item(item)
			elif len(selected_items) > 1 or Input.is_key_pressed(KEY_CTRL):
				select_item(item)

			drag_allowed = true

	if len(selected_items) > 0 and event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if !%TimelineArea.dragging and !get_viewport().gui_is_dragging() and drag_allowed:
				sort_selection()
				%TimelineArea.start_dragging(%TimelineArea.DragTypes.EXISTING_EVENTS, selected_items)


## Activated by TimelineArea drag_completed
func _on_timeline_area_drag_completed(type:int, index:int, data:Variant) -> void:
	if type == %TimelineArea.DragTypes.NEW_EVENT:
		var resource :DialogicEvent = data.duplicate()
		resource._load_custom_defaults()

		add_event_undoable(resource, index)

	elif type == %TimelineArea.DragTypes.EXISTING_EVENTS:
		if not (len(data) == 1 and data[0].get_index()+1 == index):
			move_blocks_to_index(data, index)

	await get_tree().process_frame
	something_changed()
	scroll_to_piece(index)
	indent_events()
#endregion


#region CREATING THE TIMELINE
################################################################################
# Adding an event to the timeline
func add_event_node(event_resource:DialogicEvent, at_index:int = -1, auto_select: bool = false, indent: bool = false) -> Control:
	if event_resource is DialogicEndBranchEvent:
		return create_end_branch_event(at_index, %Timeline.get_child(0))

	if event_resource['event_node_ready'] == false:
		if event_resource['event_node_as_text'] != "":
			event_resource._load_from_string(event_resource['event_node_as_text'])

	var block: Control = event_node.instantiate()
	block.resource = event_resource
	event_resource._editor_node = block
	event_resource._enter_visual_editor(timeline_editor)
	block.content_changed.connect(something_changed)

	if event_resource.event_name == "Label":
		block.content_changed.connect(update_content_list)
	if at_index == -1:
		if len(selected_items) != 0:
			selected_items[0].add_sibling(block)
		else:
			%Timeline.add_child(block)
	else:
		%Timeline.add_child(block)
		%Timeline.move_child(block, at_index)

	block.gui_input.connect(_on_event_block_gui_input.bind(block))

	# Building editing part
	block.build_editor(true, event_resource.expand_by_default)

	if auto_select:
		select_item(block, false)

	# Indent on create
	if indent:
		indent_events()

	return block


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
func add_event_with_end_branch(resource, at_index:int=-1, auto_select:bool = false, indent:bool = false) -> void:
	var event := add_event_node(resource, at_index, auto_select, indent)
	create_end_branch_event(at_index+1, event)


## Adds an event (either single nodes or with end branches) to the timeline with UndoRedo support
func add_event_undoable(event_resource: DialogicEvent, at_index: int = -1) -> void:
		TimelineUndoRedo.create_action("[D] Add "+event_resource.event_name+" event.")
		if event_resource.can_contain_events:
			TimelineUndoRedo.add_do_method(add_event_with_end_branch.bind(event_resource, at_index, true, true))
			TimelineUndoRedo.add_undo_method(delete_events_at_index.bind(at_index, 2))
		else:
			TimelineUndoRedo.add_do_method(add_event_node.bind(event_resource, at_index, true, true))
			TimelineUndoRedo.add_undo_method(delete_events_at_index.bind(at_index, 1))
		TimelineUndoRedo.commit_action()
#endregion


#region DELETING, COPY, PASTE
################################################################################

## Lists the given events (as text) based on their indexes.
## This is used to store info for undo/redo.
## Based on the action you might want to include END_BRANCHES or not (see EndBranchMode)
func get_events_indexed(events:Array) -> Dictionary:
	var indexed_dict := {}
	for event in events:
		# do not collect selected end branches (e.g. on delete, copy, etc.)
		if event.resource is DialogicEndBranchEvent:
			continue

		indexed_dict[event.get_index()] = event.resource.to_text()

		# store an end branch if it is selected or connected to a selected event
		if 'end_node' in event and event.end_node:
			event = event.end_node
			indexed_dict[event.get_index()] = event.resource.to_text()
		elif event.resource is DialogicEndBranchEvent:
			if event.parent_node in events: # add local index
				indexed_dict[event.get_index()] += str(events.find(event.parent_node))
			else: # add global index
				indexed_dict[event.get_index()] += '#'+str(event.parent_node.get_index())
	return indexed_dict


## Returns an indexed dictionary of [amount] events at [index]
func get_events_at_index_indexed(index:int, amount:int) -> Dictionary:
	var events := []

	for i in range(amount):
		events.append(%Timeline.get_child(index+i))

	return get_events_indexed(events)


## Selects events based on an indexed dictionary
func select_events_indexed(indexed_events:Dictionary) -> void:
	selected_items = []
	for event_index in indexed_events.keys():
		selected_items.append(%Timeline.get_child(event_index))


## Adds events based on an indexed dictionary
func add_events_indexed(indexed_events:Dictionary) -> void:
	# sort the dictionaries indexes just in case
	var indexes := indexed_events.keys()
	indexes.sort()

	var events := []
	for event_idx in indexes:
		# first get a new resource from the text version
		var event_resource :DialogicEvent
		for i in DialogicResourceUtil.get_event_cache():
			if i._test_event_string(indexed_events[event_idx]):
				event_resource = i.duplicate()
				break

		event_resource.from_text(indexed_events[event_idx])

		# now create the visual block.
		deselect_all_items()
		if event_resource is DialogicEndBranchEvent:
			var idx :String = indexed_events[event_idx].trim_prefix('<<END BRANCH>>')
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
	something_changed()


## Deletes events based on an indexed dictionary
func delete_events_indexed(indexed_events:Dictionary) -> void:
	if indexed_events.is_empty():
		return

	var idx_shift := 0
	for idx in indexed_events:
		if 'end_node' in %Timeline.get_child(idx-idx_shift) and %Timeline.get_child(idx-idx_shift).end_node != null and is_instance_valid(%Timeline.get_child(idx-idx_shift).end_node):
			%Timeline.get_child(idx-idx_shift).end_node.parent_node = null
		if %Timeline.get_child(idx-idx_shift) != null and is_instance_valid(%Timeline.get_child(idx-idx_shift)):
			if %Timeline.get_child(idx-idx_shift) in selected_items:
				selected_items.erase(%Timeline.get_child(idx-idx_shift))
			%Timeline.get_child(idx-idx_shift).queue_free()
			%Timeline.get_child(idx-idx_shift).get_parent().remove_child(%Timeline.get_child(idx-idx_shift))
			idx_shift += 1

	indent_events()
	something_changed()


func delete_selected_events() -> void:
	# try to find which item to select afterwards
	var next_node := %Timeline.get_child(mini(%Timeline.get_child_count() - 1, selected_items[-1].get_index() + 1))
	if _is_item_selected(next_node):
		next_node = null

	delete_events_indexed(get_events_indexed(selected_items))

	# select next
	if next_node != null:
		select_item(next_node, false)
	elif %Timeline.get_child_count() > 0:
		next_node = %Timeline.get_child(max(0, %Timeline.get_child_count() - 1))
		select_item(next_node, false)
	else:
		deselect_all_items()


func cut_events_indexed(indexed_events:Dictionary) -> void:
	select_events_indexed(indexed_events)
	copy_selected_events()
	delete_events_indexed(indexed_events)


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
	DisplayServer.clipboard_set(var_to_str({
			"events":event_copy_array,
			"project_name": ProjectSettings.get_setting("application/config/name")
		}))


func get_clipboard_data() -> Array:
	var clipboard_parse :Variant= str_to_var(DisplayServer.clipboard_get())

	if clipboard_parse is Dictionary:
		if clipboard_parse.has("project_name"):
			if clipboard_parse.project_name != ProjectSettings.get_setting("application/config/name"):
				print("[D] Be careful when copying from another project!")
		if clipboard_parse.has('events'):
			return clipboard_parse.events
	return []


func add_events_at_index(event_list:Array, at_index:int) -> void:
	var new_indexed_events := {}

	for i in range(len(event_list)):
		new_indexed_events[at_index+i] = event_list[i]

	add_events_indexed(new_indexed_events)


func delete_events_at_index(at_index:int, amount:int = 1)-> void:
	var new_indexed_events := {}
	# delete_events_indexed actually only needs the keys, so we give trash as values
	for i in range(amount):
		new_indexed_events[at_index+i] = ""
	delete_events_indexed(new_indexed_events)
	indent_events()

#endregion


#region BLOCK SELECTION
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
	%TimelineArea.queue_redraw()


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
#endregion


#region CREATING NEW EVENTS USING THE BUTTONS
################################################################################

# Event Creation signal for buttons
# If force_resource is true, the event will be added with the actual resource
func _add_event_button_pressed(event_resource:DialogicEvent, force_resource := false):
	if %TimelineArea.get_global_rect().has_point(get_global_mouse_position()) and !force_resource:
		return

	var at_index := -1
	if selected_items:
		at_index = selected_items[-1].get_index()+1
	else:
		at_index = %Timeline.get_child_count()

	var resource :DialogicEvent = null
	if force_resource:
		resource = event_resource
	else:
		resource = event_resource.duplicate()
		resource._load_custom_defaults()

	resource.created_by_button = true

	add_event_undoable(resource, at_index)

	resource.created_by_button = false

	something_changed()
	scroll_to_piece(at_index)
	indent_events()
#endregion


#region BLOCK GETTERS
################################################################################

func get_block_above(block:Node) -> Node:
	if block.get_index() > 0:
		return %Timeline.get_child(block.get_index() - 1)
	return null


func get_block_below(block:Node) -> Node:
	if block.get_index() < %Timeline.get_child_count() - 1:
		return %Timeline.get_child(block.get_index() + 1)
	return null
#endregion


#region BLOCK MOVEMENT
################################################################################


func move_blocks_to_index(blocks:Array, index:int):
	# the amount of events that were BEFORE the new index (thus shifting the index)
	var index_shift := 0
	for event in blocks:
		if event.resource is DialogicEndBranchEvent:
			if !event.parent_node in blocks:
				if index <= event.parent_node.get_index():
					return
		if "end_node" in event and event.end_node:
			if !event.end_node in blocks:
				if event.end_node.get_index() == event.get_index()+1:
					blocks.append(event.end_node)
				else:
					return
		index_shift += int(event.get_index() < index)

	var do_indexes := {}
	var undo_indexes := {}

	var event_count := 0
	for event in blocks:
		do_indexes[event.get_index()] = index + event_count
		undo_indexes[index -index_shift+event_count] = event.get_index()+index_shift*int(index < event.get_index())#+int((index -index_shift+event_count) < event.get_index())
		event_count += 1

	# complex check to avoid tangling conditions & choices
	for idx in do_indexes:
		var event := %Timeline.get_child(idx)
		if !event.resource is DialogicEndBranchEvent and !event.resource.can_contain_events:
				continue

		if event.resource is DialogicEndBranchEvent:
			if !event.parent_node or event.parent_node.get_index() in do_indexes:
				continue
		elif event.resource.can_contain_events:
			if !event.end_node or event.end_node.get_index() in do_indexes:
				continue

		var check_from := 0
		var check_to := 0

		if event.resource is DialogicEndBranchEvent:
			check_from = event.parent_node.get_index()+1
			check_to = index
		else:
			check_from = index
			check_to = event.end_node.get_index()

		for c_idx in range(check_from, check_to):
			if c_idx in do_indexes:
				continue
			var c_event := %Timeline.get_child(c_idx)
			if c_event.resource is DialogicEndBranchEvent and c_event.parent_node.get_index() < check_from:
				return
			if c_event.resource.can_contain_events and c_event.end_node.get_index() > check_to:
				return

	TimelineUndoRedo.create_action('[D] Move events.')
	TimelineUndoRedo.add_do_method(move_events_by_indexes.bind(do_indexes))
	TimelineUndoRedo.add_undo_method(move_events_by_indexes.bind(undo_indexes))
	TimelineUndoRedo.commit_action()


func move_events_by_indexes(index_dict:Dictionary) -> void:
	var sorted_indexes := index_dict.keys()
	sorted_indexes.sort()

	var evts := {}
	var count := 0
	for idx in sorted_indexes:
		evts[idx] =%Timeline.get_child(idx-count)
		%Timeline.remove_child(%Timeline.get_child(idx-count))
		count += 1
		if idx < index_dict[idx]:
			index_dict[idx] -= len(sorted_indexes.filter(func(x):return x<=index_dict[idx]-count-1))

	for idx in sorted_indexes:
		%Timeline.add_child(evts[idx])
		%Timeline.move_child(evts[idx], index_dict[idx])

	indent_events()
	visual_update_selection()
	something_changed()


func offset_blocks_by_index(blocks:Array, offset:int):
	var do_indexes := {}
	var undo_indexes := {}

	for event in blocks:
		if event.resource is DialogicEndBranchEvent:
			if !event.parent_node in blocks:
				if event.get_index()+offset+int(offset>0) <= event.parent_node.get_index():
					continue
		if "end_node" in event and event.end_node:
			if !event.end_node in blocks:
				if event.get_index()+offset+int(offset>0) > event.end_node.get_index():
					if event.end_node.get_index() == event.get_index()+1:
						blocks.append(event.end_node)
					else:
						return
		do_indexes[event.get_index()] = event.get_index()+offset+int(offset>0)
		undo_indexes[event.get_index()+offset] = event.get_index()+int(offset<0)


	TimelineUndoRedo.create_action("[D] Move events.")
	TimelineUndoRedo.add_do_method(move_events_by_indexes.bind(do_indexes))
	TimelineUndoRedo.add_undo_method(move_events_by_indexes.bind(undo_indexes))

	TimelineUndoRedo.commit_action()
#endregion


#region VISIBILITY/VISUALS
################################################################################

func scroll_to_piece(piece_index:int) -> void:
	await get_tree().process_frame
	var height: float = %Timeline.get_child(min(piece_index, %Timeline.get_child_count()-1)).position.y
	if height < %TimelineArea.scroll_vertical or height > %TimelineArea.scroll_vertical+%TimelineArea.size.y:
		%TimelineArea.scroll_vertical = height


func indent_events() -> void:
	var indent: int = 0
	var event_list: Array = %Timeline.get_children()

	if event_list.size() < 2:
		return

	var currently_hidden := false
	var hidden_count := 0
	var hidden_until: Control = null

	# will be applied to the indent after the current event
	var delayed_indent: int = 0

	for block in event_list:
		if (not "resource" in block):
			continue

		if (not currently_hidden) and block.resource.can_contain_events and block.end_node and block.collapsed:
			currently_hidden = true
			hidden_until = block.end_node
			hidden_count = 0
		elif currently_hidden and block == hidden_until:
			block.update_hidden_events_indicator(hidden_count)
			currently_hidden = false
			hidden_until = null
		elif currently_hidden:
			block.hide()
			hidden_count += 1
		else:
			block.show()
			if block.resource is DialogicEndBranchEvent:
				block.update_hidden_events_indicator(0)

		delayed_indent = 0

		if block.resource.can_contain_events:
			delayed_indent = 1

		if block.resource.wants_to_group:
			indent += 1

		elif block.resource is DialogicEndBranchEvent:
			block.parent_node_changed()
			delayed_indent -= 1
			if block.parent_node.resource.wants_to_group:
				delayed_indent -= 1

		if indent >= 0:
			block.set_indent(indent)
		else:
			block.set_indent(0)
		indent += delayed_indent

	await get_tree().process_frame
	await get_tree().process_frame
	%TimelineArea.queue_redraw()


#region SPECIAL BLOCK OPERATIONS
################################################################################

func _on_event_popup_menu_index_pressed(index:int) -> void:
	var item :Control = %EventPopupMenu.current_event
	if index == 0:
		if not item in selected_items:
			selected_items = [item]
		duplicate_selected()
	elif index == 2:
		if not item.resource.help_page_path.is_empty():
			OS.shell_open(item.resource.help_page_path)
	elif index == 3:
		find_parent('EditorView').plugin_reference.get_editor_interface().set_main_screen_editor('Script')
		find_parent('EditorView').plugin_reference.get_editor_interface().edit_script(item.resource.get_script(), 1, 1)
	elif index == 5 or index == 6:
		if index == 5:
			offset_blocks_by_index(selected_items, -1)
		else:
			offset_blocks_by_index(selected_items, +1)

	elif index == 8:
		var events_indexed : Dictionary
		if item in selected_items:
			events_indexed =  get_events_indexed(selected_items)
		else:
			events_indexed =  get_events_indexed([item])
		TimelineUndoRedo.create_action("[D] Deleting 1 event.")
		TimelineUndoRedo.add_do_method(delete_events_indexed.bind(events_indexed))
		TimelineUndoRedo.add_undo_method(add_events_indexed.bind(events_indexed))
		TimelineUndoRedo.commit_action()
		indent_events()


func _on_right_sidebar_resized() -> void:
	var _scale := DialogicUtil.get_editor_scale()

	if %RightSidebar.size.x < 160 * _scale and (not sidebar_collapsed or not _initialized):
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


	elif %RightSidebar.size.x > 160 * _scale and (sidebar_collapsed or not _initialized):
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

	if _initialized:
		DialogicUtil.set_editor_setting("dialogic/editor/right_sidebar_width", %RightSidebar.size.x)
		DialogicUtil.set_editor_setting("dialogic/editor/right_sidebar_collapsed", sidebar_collapsed)

#endregion


#region SHORTCUTS
################################################################################

func duplicate_selected() -> void:
	if len(selected_items) > 0:
		var events := get_events_indexed(selected_items).values()
		var at_index: int = selected_items[-1].get_index()+1
		TimelineUndoRedo.create_action("[D] Duplicate "+str(len(events))+" event(s).")
		TimelineUndoRedo.add_do_method(add_events_at_index.bind(events, at_index))
		TimelineUndoRedo.add_undo_method(delete_events_at_index.bind(at_index, len(events)))
		TimelineUndoRedo.commit_action()


func _input(event:InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed == false:
		drag_allowed = false

	# we protect this with is_visible_in_tree to not
	# invoke a shortcut by accident
	if !((event is InputEventKey or !event is InputEventWithModifiers) and is_visible_in_tree()):
		return


	if "pressed" in event:
		if !event.pressed:
			return


	## Some shortcuts should always work
	match event.as_text():
		"Ctrl+T": # Add text event
			_add_event_button_pressed(DialogicTextEvent.new(), true)
			get_viewport().set_input_as_handled()

		"Ctrl+Shift+T", "Ctrl+Alt+T", "Ctrl+Option+T": # Add text event with current or previous character
			get_viewport().set_input_as_handled()
			var ev := DialogicTextEvent.new()
			ev.character = get_previous_character(event.as_text() == "Ctrl+Alt+T" or event.as_text() == "Ctrl+Option+T")
			_add_event_button_pressed(ev, true)

		"Ctrl+E": # Add character join event
			_add_event_button_pressed(DialogicCharacterEvent.new(), true)
			get_viewport().set_input_as_handled()

		"Ctrl+Shift+E": # Add character update event
			var ev := DialogicCharacterEvent.new()
			ev.action = DialogicCharacterEvent.Actions.UPDATE
			_add_event_button_pressed(ev, true)
			get_viewport().set_input_as_handled()

		"Ctrl+Alt+E", "Ctrl+Option+E": # Add character leave event
			var ev := DialogicCharacterEvent.new()
			ev.action = DialogicCharacterEvent.Actions.LEAVE
			_add_event_button_pressed(ev, true)
			get_viewport().set_input_as_handled()

		"Ctrl+J": # Add jump event
			_add_event_button_pressed(DialogicJumpEvent.new(), true)
			get_viewport().set_input_as_handled()
		"Ctrl+L": # Add label event
			_add_event_button_pressed(DialogicLabelEvent.new(), true)
			get_viewport().set_input_as_handled()

	## Some shortcuts should be disabled when writing text.
	var focus_owner : Control = get_viewport().gui_get_focus_owner()
	if focus_owner is TextEdit or focus_owner is LineEdit or (focus_owner is Button and focus_owner.get_parent_control().name == "Spin"):
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
				var prev := maxi(0, selected_items[0].get_index() - 1)
				var prev_node := %Timeline.get_child(prev)
				if (prev_node != selected_items[0]):
					selected_items = []
					select_item(prev_node)
				get_viewport().set_input_as_handled()

		"Down": #select next
			if (len(selected_items) == 1):
				var next := mini(%Timeline.get_child_count() - 1, selected_items[0].get_index() + 1)
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
			var events_list := get_clipboard_data()
			var paste_position := -1
			if selected_items:
				paste_position = selected_items[-1].get_index()+1
			else:
				paste_position = %Timeline.get_child_count()-1
			if events_list:
				TimelineUndoRedo.create_action("[D] Pasting "+str(len(events_list))+" event(s).")
				TimelineUndoRedo.add_do_method(add_events_at_index.bind(events_list, paste_position))
				TimelineUndoRedo.add_undo_method(delete_events_at_index.bind(paste_position+1, len(events_list)))
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
			duplicate_selected()
			get_viewport().set_input_as_handled()

		"Alt+Up", "Option+Up":
			if len(selected_items) > 0:
				offset_blocks_by_index(selected_items, -1)

				get_viewport().set_input_as_handled()

		"Alt+Down", "Option+Down":
			if len(selected_items) > 0:
				offset_blocks_by_index(selected_items, +1)

				get_viewport().set_input_as_handled()


func get_previous_character(double_previous := false) -> DialogicCharacter:
	var character :DialogicCharacter = null
	var idx :int = %Timeline.get_child_count()
	if idx == 0:
		return null
	if len(selected_items):
		idx = selected_items[0].get_index()
	var one_skipped := false
	idx += 1
	for i in range(selected_items[0].get_index()+1):
		idx -= 1
		if !('resource' in %Timeline.get_child(idx) and 'character' in %Timeline.get_child(idx).resource):
			continue
		if %Timeline.get_child(idx).resource.character == null:
			continue
		if double_previous:
			if %Timeline.get_child(idx).resource.character == character:
				continue
			if character != null:
				if one_skipped:
					one_skipped = false
				else:
					character = %Timeline.get_child(idx).resource.character
					break
			character = %Timeline.get_child(idx).resource.character
		else:
			character = %Timeline.get_child(idx).resource.character
			break
	return character

#endregion
