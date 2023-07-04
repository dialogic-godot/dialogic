@tool
extends Window

@onready var editors_manager := get_node("../Margin/EditorsManager")

func _ready():
	var button:Button = editors_manager.add_icon_button(get_theme_icon("FileDead", "EditorIcons"), 'Manage Broken References')
	button.pressed.connect(open)
	hide()


func add_variable_ref_change(old_name:String, new_name:String) -> void:
	if _check_for_ref_change_cycle(old_name, new_name, "Variables"):
		return
	
	$ReferenceManager.reference_changes.append(
		{'what':old_name,
		'forwhat':new_name,
		'regex':['{(?<replace>\\s*'+old_name+'\\s*)}', 'var\\s*=\\s*"(?<replace>\\s*'+old_name+'\\s*)"'],
		'regex_replacement':new_name,
		'category':'Variables'}
	)
	if visible:
		$ReferenceManager.open()


func add_portrait_ref_change(old_name:String, new_name:String, character_names:PackedStringArray):
	
	if _check_for_ref_change_cycle(old_name, new_name, 'Portrait of '+ character_names[0]):
		return
	
	$ReferenceManager.reference_changes.append(
		{'what':old_name,
		'forwhat':new_name,
		'regex':['^[^:(]*\\((?<replace>'+old_name+')\\)', '\\[\\s*portrait\\s*=(?<replace>\\s*'+old_name+'\\s*)\\]'],
		'regex_replacement':new_name,
		'category':'Portrait of '+ character_names[0], 
		'character_names':character_names,
		}
	)
	if visible:
		$ReferenceManager.open()

func _check_for_ref_change_cycle(old_name:String, new_name:String, category:String) -> bool:
	for ref in $ReferenceManager.reference_changes:
		if ref['forwhat'] == old_name and ref['category'] == category:
			if new_name == ref['what']:
				$ReferenceManager.reference_changes.erase(ref)
			else:
				ref['forwhat'] = new_name
			return true
	return false


func open():
	popup_centered_ratio(0.4)
	move_to_foreground()
	grab_focus()
	$ReferenceManager.open()


func _on_close_requested():
	hide()
	$ReferenceManager.close()
	
