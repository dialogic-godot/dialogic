tool
extends PanelContainer

var editor_reference
var editorPopup
var preview = ""
var action_selected = 'none'
var joining_position
var available_positions = ['left', 'middle', 'right'] #TODO: I should use this or enum instead of hard coding the position options. 
var character_selected = ''
	
func _ready():
	var actionMenu = $VBoxContainer/Header/ActionSelector.get_popup()
	actionMenu.connect("id_pressed", self, "_on_option_selected")
	$VBoxContainer/HBoxContainer/JoinIn.visible = false
	$VBoxContainer/HBoxContainer/Leave.visible = false
	$VBoxContainer/HBoxContainer/LeaveAll.visible = false
	
	var positionMenu = $VBoxContainer/HBoxContainer/JoinIn/MenuPosition.get_popup()
	positionMenu.connect("id_pressed", self, "_on_position_selected")

func _on_position_selected(option):
  set_character_position(option)

func load_character_position(name):
	print('Loading character joining in: ', name)
	var index_position = 0
	match name:
		'left':
			index_position = 0
		'middle':
			index_position = 1
		'right':
			index_position = 2
	set_character_position(index_position)

func set_character_position(index):
	match index:
		0:
			joining_position = 'left'
			$VBoxContainer/HBoxContainer/JoinIn/MenuPosition.text = 'Left'
		1:
			joining_position = 'middle'
			$VBoxContainer/HBoxContainer/JoinIn/MenuPosition.text = 'Middle'
		2:
			joining_position = 'right'
			$VBoxContainer/HBoxContainer/JoinIn/MenuPosition.text = 'Right'
	preview = character_selected + ', ' + joining_position
	return joining_position

func _on_option_selected(option):
	match option:
		0:
			join_in()
		1:
			leave()
		2:
			leave_all()
	# TODO: check if the content is hidden and if this changes it should expand the module

func join_in():
	action_selected = 'joinin'
	$VBoxContainer/Header/ActionSelector.text = "[Join in]"
	$VBoxContainer/HBoxContainer/JoinIn.visible = true
	$VBoxContainer/HBoxContainer/Leave.visible = false
	$VBoxContainer/HBoxContainer/LeaveAll.visible = false

func leave():
	action_selected = 'leave'
	$VBoxContainer/Header/ActionSelector.text = "[Leave]"
	$VBoxContainer/HBoxContainer/JoinIn.visible = false
	$VBoxContainer/HBoxContainer/Leave.visible = true
	$VBoxContainer/HBoxContainer/LeaveAll.visible = false

func leave_all():
	action_selected = 'leaveall'
	$VBoxContainer/Header/ActionSelector.text = "[Leave all]"
	$VBoxContainer/HBoxContainer/JoinIn.visible = false
	$VBoxContainer/HBoxContainer/Leave.visible = false
	$VBoxContainer/HBoxContainer/LeaveAll.visible = true
	preview = ''
