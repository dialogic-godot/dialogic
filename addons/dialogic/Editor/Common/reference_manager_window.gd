@tool
extends Window

@onready var editors_manager := get_node("../Margin/EditorsManager")

func _ready():
	var button:Button = editors_manager.add_icon_button(get_theme_icon("FileDead", "EditorIcons"), 'Manage Broken References')
	button.pressed.connect(open)
	hide()


func add_variable_ref_change(old_name:String, new_name:String) -> void:
	$ReferenceManager.reference_changes.append(
		{'what':old_name,
		'forwhat':new_name,
		'regex':['{(?<replace>'+old_name+')}'],
		'regex_replacement':new_name,
		'category':'Variables'}
	)


func add_portrait_ref_change(old_name:String, new_name:String, character_name:String):
	$ReferenceManager.reference_changes.append(
		{'what':old_name,
		'forwhat':new_name,
		'regex':['\\((?<replace>'+old_name+')\\)'],
		'regex_replacement':new_name,
		'category':'Portrait of '+ character_name}
	)


func open():
	popup_centered_ratio(0.6)
	move_to_foreground()
	grab_focus()
	$ReferenceManager.open()


func _on_close_requested():
	hide()
	$ReferenceManager.close()
	
