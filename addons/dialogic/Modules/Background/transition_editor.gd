@tool
extends DialogicEditor

const default_transition_resource : DialogicTransition = preload("res://addons/dialogic/Modules/Background/default_background_transition.tres")

var transitions: Array[DialogicTransition] = []
var current_transition : DialogicTransition = null
var default_transition := ""


enum AddTransitionButtonOptions {
	NewTransition = 2,
	InheritedTransition = 3
}


func _get_title() -> String:
	return "Transition"

func _register() -> void:
	editors_manager.register_simple_editor(self)
	alternative_text = "Change the look of the background transitions in your game"

func _open(extra_info: Variant = null) -> void:
	load_transition_list()


func _close() -> void:
	save_transition_list()
	save_transition()

func _ready() -> void:
	collect_transitions()
	
	setup_ui()

func add_transition(file_path: String, transition: DialogicTransition, inherits: DialogicTransition= null) -> void:
	transition.resource_path = file_path
	transition.inherits = inherits
	
	ResourceSaver.save(transition, file_path)
	transitions.append(transition)
	
	save_transition_list()
	load_transition_list()
	select_transition(transition)

func delete_transition(transition: DialogicTransition) -> void:
	if current_transition == transition:
		current_transition = null
	
	for other_transition in transitions:
		if other_transition.inherits == transition:
			other_transition.realize_inheritance()
			push_warning('[Dialogic] Transition "', other_transition.name,'" had to be realized because it inherited "', transition.name,'" which was deleted!')
	
	if transition.resource_path == default_transition:
		default_transition = ""
	
	transitions.erase(transition)
	save_transition_list()

func realize_transition() -> void:
	current_transition.realize_inheritance()
	
	select_transition(current_transition)

func select_transition(transition: DialogicTransition) -> void:
	DialogicUtil.set_editor_setting('latest_background_transition', transition.name)
	for idx in range(%TransitionList.item_count):
		if %TransitionList.get_item_metadata(idx) == transition:
			%TransitionList.select(idx)
			return

func setup_ui() -> void:
	%AddButton.icon = get_theme_icon("Add", "EditorIcons")
	%DuplicateButton.icon = get_theme_icon("Duplicate", "EditorIcons")
	%InheritanceButton.icon = get_theme_icon("GuiDropdown", "EditorIcons")
	%RemoveButton.icon = get_theme_icon("Remove", "EditorIcons")

	%EditNameButton.icon = get_theme_icon("Edit", "EditorIcons")
	%TestTransitionButton.icon = get_theme_icon("PlayCustom", "EditorIcons")
	%MakeDefaultButton.icon = get_theme_icon("Favorites", "EditorIcons")

	%TransitionList.item_selected.connect(_on_transitionlist_selected)
	%AddButton.get_popup().index_pressed.connect(_on_AddTranstitionMenu_selected)
	%AddButton.about_to_popup.connect(_on_AddTransitionMenu_about_to_popup)
	%InheritanceButton.get_popup().index_pressed.connect(_on_inheritance_index_pressed)
	%TransitionView.hide()
	%NoTransitionView.show()

#region signal hooks
func _on_transitionlist_selected(index: int) -> void:
	load_transition(%TransitionList.get_item_metadata(index))

func _on_AddTransitionMenu_about_to_popup() -> void:
	%AddButton.get_popup().set_item_disabled(3, not %TransitionList.is_anything_selected())

func _on_AddTranstitionMenu_selected(index: int) -> void:
	#TODO: consider making an option to inherrit from a transition on a public repo?
	
	match index:
		AddTransitionButtonOptions.NewTransition:
			var new_transition: DialogicTransition = default_transition_resource.clone()
			
			find_parent('EditorView').godot_file_dialog(
				add_transition_undoable.bind(new_transition),
				'*.tres',
				EditorFileDialog.FILE_MODE_SAVE_FILE,
				"Select folder for new transition")
		
		AddTransitionButtonOptions.InheritedTransition:
			if %TransitionList.get_selected_items().is_empty():
				return
				
			find_parent('EditorView').godot_file_dialog(
				add_transition_undoable.bind(DialogicTransition.new(), current_transition),
				'*.tres',
				EditorFileDialog.FILE_MODE_SAVE_FILE,
				"Select folder for new transition")

func add_transition_undoable(file_path: String, transition: DialogicTransition, inherits: DialogicTransition = null) -> void:
	transition.name = _get_new_name(file_path.get_file().trim_suffix('.'+file_path.get_extension()))
	var undo_redo: EditorUndoRedoManager = DialogicUtil.get_dialogic_plugin().get_undo_redo()
	undo_redo.create_action('Add Transition', UndoRedo.MERGE_ALL)
	undo_redo.add_do_method(self, "add_transition", file_path, transition, inherits)
	undo_redo.add_do_method(self, "load_transition_list")
	undo_redo.add_undo_method(self, "delete_transition", transition)
	undo_redo.add_undo_method(self, "load_transition_list")
	undo_redo.commit_action()
	DialogicUtil.set_editor_setting('latest_background_transition', transition.name)

func _on_inheritance_index_pressed(index:int) -> void:
	if index == 0:
		realize_transition()

func _on_duplicate_button_pressed():
	if !%TransitionList.is_anything_selected():
		return
	
	find_parent('EditorView').godot_file_dialog(
		add_transition_undoable.bind(current_transition.clone(), current_transition),
		'',
		EditorFileDialog.FILE_MODE_SAVE_FILE,
		"Select folder for new transition")

func _on_remove_button_pressed():
	if !%TransitionList.is_anything_selected():
		return

	if current_transition.name == default_transition:
		push_warning("[Dialogic] You cannot delete the default transition!")
		return

	delete_transition(current_transition)
	load_transition_list()

func _on_make_default_button_pressed():
	default_transition = current_transition.resource_path
	save_transition_list()
	load_transition_list()

func _on_create_transition_button_pressed() -> void:
	var new_transition: DialogicTransition = default_transition_resource.clone()
	
	find_parent('EditorView').godot_file_dialog(
		add_transition_undoable.bind(new_transition),
		'*.tres',
		EditorFileDialog.FILE_MODE_SAVE_FILE,
		"Select folder for new transition")

#endregion

func collect_transitions() -> void:
#	for indexer in DialogicUtil.get_indexers():
#		for layout in indexer._get_layout_parts():
#			premade_style_parts[layout['path']] = layout

	var transition_list: Array = ProjectSettings.get_setting('dialogic/transition/transition_list', [])
	for transition in transition_list:
		if ResourceLoader.exists(transition):
			var transition_res := load(transition)
			if transition != null:
				transitions.append(ResourceLoader.load(transition, "DialogicTransition"))
			else:
				print("[Dialogic] Failed to open transition '", transition, "'. Some dependency might be broken.")
		else:
			print("[Dialogic] Failed to open transition '", transition, "'. Might have been moved or deleted.")

	default_transition = ProjectSettings.get_setting('dialogic/transition/default_transition', '')


func load_transition_list() -> void:
	var latest := DialogicUtil.get_editor_setting('latest_background_transition', '')

	%TransitionList.clear()
	var idx := 0
	for transition in transitions:
		%TransitionList.add_item(transition.name, get_theme_icon("PopupMenu", "EditorIcons"))
		if transition.resource_path == default_transition:
			%TransitionList.set_item_icon_modulate(idx, get_theme_color("warning_color", "Editor"))
		if transition.name == latest:
			%TransitionList.select(idx)
			load_transition(transition)
		%TransitionList.set_item_tooltip(idx, transition.resource_path)
		%TransitionList.set_item_metadata(idx, transition)
		idx += 1

	if len(transitions) == 0:
		%TransitionView.hide()
		%NoTransitionView.show()

	elif !%TransitionList.is_anything_selected():
		%TransitionList.select(0)
		load_transition(%TransitionList.get_item_metadata(0))


func save_transition_list() -> void:
	ProjectSettings.set_setting('dialogic/transition/transition_list', transitions.map(func(transition:DialogicTransition): return transition.resource_path))
	ProjectSettings.set_setting('dialogic/transition/default_transition', default_transition)
	ProjectSettings.save()

func save_transition() -> void:
	if current_transition == null:
		return

	print("[Dialogic] Saved ", current_transition.name)
	ResourceSaver.save(current_transition)


func load_transition(transition: DialogicTransition) -> void:
	if current_transition != null:
		current_transition.changed.disconnect(save_transition)
	save_transition()
	current_transition = transition
	if current_transition == null:
		return
	current_transition.changed.connect(save_transition)
	
	%BackgroundTransitionName.text = transition.name
	if transition.resource_path == default_transition:
		%MakeDefaultButton.tooltip_text = "Is Default"
		%MakeDefaultButton.disabled = true
	else:
		%MakeDefaultButton.tooltip_text = "Make Default"
		%MakeDefaultButton.disabled = false
	
	%TransitionEditor.load_transition(transition)
	
	%InheritanceButton.visible = transition.inherits_anything()
	if %InheritanceButton.visible:
		%InheritanceButton.text = "Inherits " + transition.inherits.name
	
	
	DialogicUtil.set_editor_setting('latest_background_transition', transition.name)
	
	%TransitionView.show()
	%NoTransitionView.hide()

func _get_new_name(base_name: String) -> String:
	var new_name_idx := 1
	var found_unique_name := false
	var new_name := base_name
	while not found_unique_name:
		found_unique_name = true
		for transition in transitions:
			if transition.name == new_name:
				new_name_idx += 1
				new_name = base_name+" "+str(new_name_idx)
				found_unique_name = false
	return new_name



