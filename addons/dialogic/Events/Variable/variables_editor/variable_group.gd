@tool
extends PanelContainer

@export var MainGroup: bool = false
var GroupScenePath :String = get_script().resource_path.get_base_dir().path_join("variable_group.tscn")
var FieldScenePath :String = get_script().resource_path.get_base_dir().path_join("variable_field.tscn")
var PreviewScenePath :String = get_script().resource_path.get_base_dir().path_join("variable_drag_preview.tscn")

var drag_preview :Control = null

var parent_Group :Control = null


################################################################################
##				FUNCTIONALITY
################################################################################

func get_item_name() -> String:
	return %NameEdit.text

func get_data() -> Dictionary:
	var data = {}
	for child in %Content.get_children():
		data[child.get_item_name()] = child.get_data()
	return data

func load_data(group_name:String , data:Dictionary, _parent_Group:Control = null) -> void:
	if not MainGroup:
		%NameEdit.text = group_name
		parent_Group = _parent_Group
	else:
		clear()
	
	add_data(data)

func add_data(data:Dictionary) -> void:
	for key in data.keys():
		if typeof(data[key]) == TYPE_DICTIONARY:
			var Group :Control = load(GroupScenePath).instantiate()
			%Content.add_child(Group)
			Group.update()
			Group.load_data(key, data[key], self)
		else:
			var field :Control = load(FieldScenePath).instantiate()
			%Content.add_child(field)
			field.load_data(key, data[key], self)

func check_data() -> void:
	var names := []
	for child in %Content.get_children():
		if child.has_method('warning') and not child.is_queued_for_deletion():
			if child.get_item_name() in names:
				child.warning()
			else:
				child.no_warning()
				names.append(child.get_item_name())

func search(term:String) -> bool:
	var found_anything := false
	for child in %Content.get_children():
		if child.has_method('search'):
			var res :bool = child.search(term)
			if not found_anything:
				found_anything = res

		elif term.is_empty():
			child.show()
		elif child.has_method('get_item_name'):
			child.visible = term in  str(child.get_item_name()).to_lower() or term in child.get_data().to_lower()
			if not found_anything:
				found_anything = child.visible
	
	if not term.is_empty() and not found_anything and not MainGroup:
		hide()
	else:
		show()
	
	return found_anything


func _get_drag_data(position:Vector2) -> Variant:
	if MainGroup:
		return null
	
	var data := {
		'data':{},
		'node':self
	}
	data.data[get_item_name()] = get_data()
	
	var prev :Control = load(PreviewScenePath).instantiate()
	prev.set_text("Group: "+get_item_name())
	set_drag_preview(prev)

	return data

func _can_drop_data(position:Vector2, data:Variant) -> bool:
	if typeof(data) == TYPE_DICTIONARY and data.has('data') and data.has('node'):
		return true
	return false

func _drop_data(position:Vector2, data:Variant) -> void:
	# safety that should prevent dragging a Group into itself
	var fold := self
	while fold != null:
		if fold == data.node:
			return
		fold = fold.parent_Group
	
	# if everything is good, then add new data and delete old one
	add_data(data.data)
	data.node.queue_free()
	check_data()

func _on_VariableGroup_gui_input(event:InputEvent) -> void:
	if get_viewport().gui_is_dragging():
		if get_global_rect().has_point(get_global_mouse_position()):
#			if not drag_preview: 
#				drag_preview = Control.new()
#				drag_preview.custom_minimum_size.y = 30
#				%Content.add_child(drag_preview)
#				%Content.move_child(drag_preview, %Content.get_child_count())
			self_modulate = get_theme_color("accent_color", "Editor")
			%DragSpacer.texture = get_theme_icon("WarningPattern", "EditorIcons")
	else:
		undrag()

func _on_VariableGroup_mouse_exited() -> void:
	undrag()


func undrag() -> void:
	if drag_preview != null:
		drag_preview.queue_free()
		drag_preview = null
	self_modulate = Color(1,1,1,1)
	%DragSpacer.texture = null

################################################################################
##				UI
################################################################################
func _ready() -> void:
	update()

func update() -> void:
	if MainGroup:
		%DeleteButton.hide()
		%DuplicateButton.hide()
		%FoldButton.hide()
		%NameEdit.text = "Variables"
		%NameEdit.editable = false
		%NameEdit.focus_mode = FOCUS_NONE
		%SearchBar.show()
		%Dragger.hide()
		%SearchBar.right_icon = get_theme_icon("Search", "EditorIcons")
	
	%Dragger.texture = get_theme_icon("TripleBar", "EditorIcons")
	%NameEdit.add_theme_color_override("font_color_uneditable", get_theme_color('font_color', 'Label'))
	%DeleteButton.icon = get_theme_icon("Remove", "EditorIcons")
	%DeleteButton.tooltip_text = "Delete Group"
	%DuplicateButton.icon = get_theme_icon("Duplicate", "EditorIcons")
	%DuplicateButton.tooltip_text = "Duplicate Group"
	%NewGroup.icon = load("res://addons/dialogic/Editor/Images/Pieces/add-folder.svg")
	%NewGroup.tooltip_text = "Add new Group"
	%NewVariable.icon =  load(self.get_script().get_path().get_base_dir().get_base_dir() + "/add-variable.svg")
	%NewVariable.tooltip_text = "Add new variable"
	%FoldButton.icon = get_theme_icon("GuiVisibilityVisible", "EditorIcons")
	%FoldButton.tooltip_text = "Hide/Show content"
	
	%DragSpacer.modulate = get_theme_color("accent_color", "Editor")
	%DragSpacer.modulate.a = 0.5


func clear() -> void:
	for child in %Content.get_children():
		child.queue_free()

func warning() -> void:
	modulate = get_theme_color("warning_color", "Editor")

func no_warning() -> void:
	modulate = Color(1,1,1,1)

func _on_DeleteButton_pressed() -> void:
	queue_free()


func _on_DuplicateButton_pressed() -> void:
	parent_Group.add_data({get_item_name()+'_duplicate':get_data()})


func _on_NewGroup_pressed() -> void:
	add_data({'New Group':{}})


func _on_NewVariable_pressed() -> void:
	add_data({'New Variable':""})


func _on_FoldButton_toggled(button_pressed:bool) -> void:
	%Content.visible = button_pressed
	%FoldButton.button_pressed = button_pressed
	if button_pressed:
		%FoldButton.icon = get_theme_icon("GuiVisibilityVisible", "EditorIcons")
	else:
		%FoldButton.icon = get_theme_icon("GuiVisibilityHidden", "EditorIcons")


func _on_NameEdit_gui_input(event:InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.double_click:
		if not MainGroup:
			%NameEdit.editable = true

func _on_name_edit_text_submitted(new_text:String) -> void:
	disable_name_edit()

func _on_NameEdit_focus_exited() -> void:
	disable_name_edit()

func disable_name_edit() -> void:
	%NameEdit.editable = false
	check_data()


func _on_SearchBar_text_changed(new_text:String) -> void:
	search(new_text.to_lower())


func _on_spacer_gui_input(event:InputEvent) -> void:
	if MainGroup: return
	if event is InputEventMouseButton and event.double_click:
		_on_FoldButton_toggled(!%FoldButton.button_pressed)
