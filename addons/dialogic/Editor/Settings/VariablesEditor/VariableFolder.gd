tool
extends PanelContainer

export (bool) var MainFolder = false
var folder_scene = "res://addons/dialogic/Editor/Settings/VariablesEditor/VariableFolder.tscn"
var field_scene = "res://addons/dialogic/Editor/Settings/VariablesEditor/VariableField.tscn"

var drag_preview = null

var parent_folder = null
################################################################################
##				FUNCTIONALITY
################################################################################
func get_name() -> String:
	return $'%NameEdit'.text

func get_data() -> Dictionary:
	var data = {}
	for child in $'%Content'.get_children():
		data[child.get_name()] = child.get_data()
	return data

func load_data(folder_name, data:Dictionary, _parent_folder:Control = null) -> void:
	if not MainFolder:
		$'%NameEdit'.text = folder_name
		parent_folder = _parent_folder
	else:
		clear()
	
	add_data(data)

func add_data(data) -> void:
	for key in data.keys():
		if typeof(data[key]) == TYPE_DICTIONARY:
			var folder = load(folder_scene).instance()
			$'%Content'.add_child(folder)
			folder.load_data(key, data[key], self)
		else:
			var field = load(field_scene).instance()
			$'%Content'.add_child(field)
			field.load_data(key, data[key], self)

func search(term:String) -> bool:
	var found_anything = false
	for child in $'%Content'.get_children():
		if child.has_method('search'):
			var res = child.search(term)
			if not found_anything:
				found_anything = res

		elif term.empty():
			child.show()
		elif child.has_method('get_name'):
			child.visible = term in  child.get_name().to_lower()
			if not found_anything:
				found_anything = child.visible
	
	if not term.empty() and not found_anything and not MainFolder:
		hide()
	else:
		show()
	
	return found_anything

func get_drag_data(position):
	if MainFolder:
		return null
	
	var data = {
		'data':{},
		'node':self
	}
	data.data[get_name()] = get_data()
	
	var prev = load("res://addons/dialogic/Editor/Settings/VariablesEditor/Preview.tscn").instance()
	prev.set_text(get_name())
	set_drag_preview(prev)

	return data

func can_drop_data(position, data):
	if typeof(data) == TYPE_DICTIONARY and data.has('data') and data.has('node'):
		return true
	return false

func drop_data(position, data):
	# safety that should prevent dragging a folder into itself
	var fold = self
	while fold != null:
		if fold == data.node:
			return
		fold = fold.parent_folder
	
	# if everything is good, then add new data and delete old one
	add_data(data.data)
	data.node.queue_free()

func _on_VariableFolder_gui_input(event):
	if get_viewport().gui_is_dragging():
		if get_global_rect().has_point(get_global_mouse_position()):
			if not drag_preview: 
				drag_preview = Control.new()
				drag_preview.rect_min_size.y = 30
				$'%Content'.add_child(drag_preview)
				$'%Content'.move_child(drag_preview, $'%Content'.get_child_count())
			self_modulate = get_color("accent_color", "Editor")
	else:
		undrag()

func _on_VariableFolder_mouse_exited():
	undrag()


func undrag():
	if drag_preview != null:
		drag_preview.queue_free()
		drag_preview = null
	self_modulate = Color.white

################################################################################
##				UI
################################################################################
func _ready():
	update()

func update():
	if MainFolder:
		$'%DeleteButton'.hide()
		$'%DuplicateButton'.hide()
		$'%FoldButton'.hide()
		$'%NameEdit'.text = "Variables"
		$'%NameEdit'.editable = false
		$'%SearchBar'.show()
		$'%Dragger'.hide()
	
	$'%Dragger'.texture = get_icon("TripleBar", "EditorIcons")
	$'%NameEdit'.add_color_override("font_color_uneditable", get_color('font_color', 'Label'))
	get_node('%DeleteButton').icon = get_icon("Remove", "EditorIcons")
	get_node('%DeleteButton').hint_tooltip = "Delete folder"
	get_node('%DuplicateButton').icon = get_icon("Duplicate", "EditorIcons")
	get_node('%DuplicateButton').hint_tooltip = "Duplicate folder"
	get_node('%NewFolder').icon = get_icon("Folder", "EditorIcons")
	get_node('%NewFolder').hint_tooltip = "Add new folder"
	get_node('%NewVariable').icon = get_icon("Add", "EditorIcons")
	get_node('%NewVariable').hint_tooltip = "Add new variable"
	get_node('%FoldButton').icon = get_icon("GuiVisibilityVisible", "EditorIcons")
	get_node('%FoldButton').hint_tooltip = "Hide/Show content"


func clear():
	for child in $'%Content'.get_children():
		child.queue_free()


func _on_DeleteButton_pressed():
	queue_free()


func _on_DuplicateButton_pressed():
	parent_folder.add_data({get_name()+'_duplicate':get_data()})


func _on_NewFolder_pressed():
	add_data({'New Folder':{}})


func _on_NewVariable_pressed():
	add_data({'New Variable':""})


func _on_FoldButton_toggled(button_pressed):
	$'%Content'.visible = button_pressed
	
	if button_pressed:
		get_node('%FoldButton').icon = get_icon("GuiVisibilityVisible", "EditorIcons")
	else:
		get_node('%FoldButton').icon = get_icon("GuiVisibilityHidden", "EditorIcons")


func _on_NameEdit_text_entered(new_text):
	$'%NameEdit'.editable = false


func _on_NameEdit_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.doubleclick:
		if not MainFolder:
			$'%NameEdit'.editable = true


func _on_NameEdit_focus_exited():
	$'%NameEdit'.editable = false


func _on_SearchBar_text_changed(new_text):
	search(new_text.to_lower())

