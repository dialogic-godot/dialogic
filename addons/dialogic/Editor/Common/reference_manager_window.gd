@tool
extends Window

@onready var editors_manager := get_node("../Margin/EditorsManager")

enum Where {Everywhere, ByCharacter, TextsOnly}
enum Types {Text, Variable, Portrait, CharacterName, TimelineName}

func _ready():
	var button:Button = editors_manager.add_icon_button(get_theme_icon("FileDead", "EditorIcons"), 'Manage Broken References')
	button.pressed.connect(open)
	hide()


func add_ref_change(old_name:String, new_name:String, type:Types, where :=Where.TextsOnly, character_names:=[], whole_words:=false, case_sensitive:=false, previous:Dictionary = {}):
	var regexes := []
	var category_name := ""
	match type:
		Types.Text:
			category_name = "Texts"
			regexes = ['(?<replace>'+old_name.replace('/', '\\/')+')']
			if !case_sensitive:
				regexes[0] = '(?i)'+regexes[0]
			if whole_words:
				regexes = ['\\b'+regexes[0]+'\\b']

		Types.Variable:
			regexes = ['{(?<replace>\\s*'+old_name.replace('/', '\\/')+'\\s*)}', 'var\\s*=\\s*"(?<replace>\\s*'+old_name.replace('/', '\\/')+'\\s*)"']
			category_name = "Variables"
		
		Types.Portrait:
			regexes = ['(?m)^[^:(]*\\((?<replace>'+old_name.replace('/', '\\/')+')\\)', '\\[\\s*portrait\\s*=(?<replace>\\s*'+old_name.replace('/', '\\/')+'\\s*)\\]']
			category_name = "Portraits by "+character_names[0]
	
	if where != Where.ByCharacter:
		character_names = []
	
	var idx := len($Manager.reference_changes)
	if previous in $Manager.reference_changes:
		idx = $Manager.reference_changes.find(previous)
		$Manager.reference_changes.erase(previous)
	
	if _check_for_ref_change_cycle(old_name, new_name, category_name):
		return
	
	$Manager.reference_changes.insert(idx, 
		{'what':old_name,
		'forwhat':new_name,
		'regex': regexes,
		'regex_replacement':new_name,
		'category':category_name, 
		'character_names':character_names,
		'texts_only':where == Where.TextsOnly,
		'type':type
		})
	
	if visible:
		$Manager.open()


func _check_for_ref_change_cycle(old_name:String, new_name:String, category:String) -> bool:
	for ref in $Manager.reference_changes:
		if ref['forwhat'] == old_name and ref['category'] == category:
			if new_name == ref['what']:
				$Manager.reference_changes.erase(ref)
			else:
				ref['forwhat'] = new_name
			return true
	return false


func add_variable_ref_change(old_name:String, new_name:String) -> void:
	add_ref_change(old_name, new_name, Types.Variable, Where.Everywhere)
	

func add_portrait_ref_change(old_name:String, new_name:String, character_names:PackedStringArray):
	add_ref_change(old_name, new_name, Types.Portrait, Where.ByCharacter, character_names)




func open():
	popup_centered_ratio(0.4)
	move_to_foreground()
	grab_focus()
	$Manager.open()


func _on_close_requested():
	hide()
	$Manager.close()
	
