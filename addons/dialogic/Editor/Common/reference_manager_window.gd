@tool
extends Window

@onready var editors_manager := get_node("../Margin/EditorsManager")

enum Where {EVERYWHERE, BY_CHARACTER, TEXTS_ONLY}
enum Types {TEXT, VARIABLE, PORTRAIT, CHARACTER_NAME, TIMELINE_NAME}

var icon_button :Button = null

func _ready():
	icon_button = editors_manager.add_icon_button(get_theme_icon("Unlinked", "EditorIcons"), 'Manage Broken References')
	icon_button.pressed.connect(open)
	
	var dot := Sprite2D.new()
	dot.texture = get_theme_icon("GuiGraphNodePort", "EditorIcons")
	dot.scale = Vector2(0.8, 0.8)
	dot.z_index = 10
	dot.position = Vector2(icon_button.size.x*0.9, icon_button.size.x*0.05)
	dot.modulate = get_theme_color("warning_color", "Editor").lightened(0.5)
	
	icon_button.add_child(dot)
	
	update_indicator()
	hide()


func add_ref_change(old_name:String, new_name:String, type:Types, where :=Where.TEXTS_ONLY, character_names:=[], whole_words:=false, case_sensitive:=false, previous:Dictionary = {}):
	var regexes := []
	var category_name := ""
	match type:
		Types.TEXT:
			category_name = "Texts"
			regexes = ['(?<replace>'+old_name.replace('/', '\\/')+')']
			if !case_sensitive:
				regexes[0] = '(?i)'+regexes[0]
			if whole_words:
				regexes = ['\\b'+regexes[0]+'\\b']

		Types.VARIABLE:
			regexes = ['{(?<replace>\\s*'+old_name.replace('/', '\\/')+'\\s*)}', 'var\\s*=\\s*"(?<replace>\\s*'+old_name.replace('/', '\\/')+'\\s*)"']
			category_name = "Variables"
		
		Types.PORTRAIT:
			regexes = ['(?m)^[^:(]*\\((?<replace>'+old_name.replace('/', '\\/')+')\\)', '\\[\\s*portrait\\s*=(?<replace>\\s*'+old_name.replace('/', '\\/')+'\\s*)\\]']
			category_name = "Portraits by "+character_names[0]
	
	if where != Where.BY_CHARACTER:
		character_names = []
	
	# previous is only given when an existing item is edited
	# in that case the old one is removed first
	var idx := len($Manager.reference_changes)
	if previous in $Manager.reference_changes:
		idx = $Manager.reference_changes.find(previous)
		$Manager.reference_changes.erase(previous)
	
	if _check_for_ref_change_cycle(old_name, new_name, category_name):
		update_indicator()
		return
	
	$Manager.reference_changes.insert(idx, 
		{'what':old_name,
		'forwhat':new_name,
		'regex': regexes,
		'regex_replacement':new_name,
		'category':category_name, 
		'character_names':character_names,
		'texts_only':where == Where.TEXTS_ONLY,
		'type':type
		})
	
	update_indicator()
	
	if visible:
		$Manager.open()


func _check_for_ref_change_cycle(old_name:String, new_name:String, category:String) -> bool:
	for ref in $Manager.reference_changes:
		if ref['forwhat'] == old_name and ref['category'] == category:
			if new_name == ref['what']:
				$Manager.reference_changes.erase(ref)
			else:
				$Manager.reference_changes[$Manager.reference_changes.find(ref)]['forwhat'] = new_name
			return true
	return false


func add_variable_ref_change(old_name:String, new_name:String) -> void:
	add_ref_change(old_name, new_name, Types.VARIABLE, Where.EVERYWHERE)
	

func add_portrait_ref_change(old_name:String, new_name:String, character_names:PackedStringArray) -> void:
	add_ref_change(old_name, new_name, Types.PORTRAIT, Where.BY_CHARACTER, character_names)


func open() -> void:
	popup_centered_ratio(0.4)
	move_to_foreground()
	grab_focus()
	$Manager.open()


func _on_close_requested() -> void:
	hide()
	$Manager.close()
	update_indicator()


func update_indicator() -> void:
	if $Manager.reference_changes.is_empty():
		icon_button.get_child(0).hide()
	
