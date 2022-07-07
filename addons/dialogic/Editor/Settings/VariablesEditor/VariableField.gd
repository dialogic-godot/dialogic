tool
extends PanelContainer

var parent_folder = null

################################################################################
##				FUNCTIONALITY
################################################################################

func get_name() -> String:
	return $'%NameEdit'.text.strip_edges()

func get_data() -> String:
	return $'%ValueEdit'.text

func load_data(var_name:String, var_value:String, _folder:Control) -> void:
	parent_folder = _folder
	$'%NameEdit'.text = var_name
	$'%ValueEdit'.text = var_value

################################################################################
##				DRAGGING
################################################################################

func get_drag_data(position):
	var data = {
		'data':{},
		'node':self
	}
	data.data[get_name()] = get_data()
	
	var prev = load("res://addons/dialogic/Editor/Settings/VariablesEditor/Preview.tscn").instance()
	prev.set_text(get_name())
	set_drag_preview(prev)

	return data

func is_variable():
	return true


func can_drop_data(position, data):
	if typeof(data) == TYPE_DICTIONARY and data.has('data') and data.has('node'):
		return true
	return false

func drop_data(position, data):
	parent_folder.add_data(data.data)
	data.node.queue_free()

################################################################################
##				UI
################################################################################

func _ready():
	$'%DeleteButton'.icon = get_icon("Remove", "EditorIcons")
	$'%Dragger'.texture = get_icon("TripleBar", "EditorIcons")


func _on_DeleteButton_pressed():
	queue_free()


func _on_NameEdit_text_entered(new_text):
	$'%NameEdit'.editable = false


func _on_NameEdit_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.doubleclick:
		$'%NameEdit'.editable = true


func _on_NameEdit_focus_exited():
	$'%NameEdit'.editable = false
