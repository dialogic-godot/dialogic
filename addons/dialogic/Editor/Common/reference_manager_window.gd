@tool
extends Window

## This window manages communication with the replacement manager it contains.
## Other scripts can call the add_ref_change() method to register changes directly
##   or use the helpers add_variable_ref_change() and add_portrait_ref_change()

@onready var editors_manager := get_node("../Margin/EditorsManager")

enum Where {EVERYWHERE, BY_CHARACTER, TEXTS_ONLY}
enum Types {TEXT, VARIABLE, PORTRAIT, CHARACTER_NAME, TIMELINE_NAME}

var icon_button :Button = null


func _ready() -> void:
	if owner.get_parent() is SubViewport:
		return
	icon_button = editors_manager.add_icon_button(get_theme_icon("Unlinked", "EditorIcons"), 'Manage Broken References')
	icon_button.pressed.connect(open)
	
	var dot := Sprite2D.new()
	dot.texture = get_theme_icon("GuiGraphNodePort", "EditorIcons")
	dot.scale = Vector2(0.8, 0.8)
	dot.z_index = 10
	dot.position = Vector2(icon_button.size.x*0.8, icon_button.size.x*0.2)
	dot.modulate = get_theme_color("warning_color", "Editor").lightened(0.5)
	
	icon_button.add_child(dot)
	
	var old_changes :Array = DialogicUtil.get_editor_setting('reference_changes', [])
	if !old_changes.is_empty():
		$Manager.reference_changes = old_changes
	
	update_indicator()
	
	hide()
	
	get_parent().plugin_reference.get_editor_interface().get_file_system_dock().files_moved.connect(_on_file_moved)
	get_parent().get_node('ResourceRenameWarning').confirmed.connect(open)


func add_ref_change(old_name:String, new_name:String, type:Types, where:=Where.TEXTS_ONLY, character_names:=[], 
					whole_words:=false, case_sensitive:=false, previous:Dictionary = {}) -> void:
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
		
		Types.CHARACTER_NAME:
			# for reference: ((Join|Leave|Update) )?(?<replace>NAME)(?!\B)(?(1)|(?!([^:\n]|\\:)*(\n|$)))
			regexes = ['((Join|Leave|Update) )?(?<replace>'+old_name+')(?!\\B)(?(1)|(?!([^:\\n]|\\\\:)*(\\n|$)))']
			category_name = "Renamed Character Files"
		
		Types.TIMELINE_NAME:
			regexes = ['timeline ?= ?" ?(?<replace>'+old_name+') ?"']
			category_name = "Renamed Timeline Files"
	
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


## Checks for reference cycles or chains. 
## E.g. if you first rename a portrait from "happy" to "happy1" and then to "Happy/happy1"
## This will make sure only a change "happy" -> "Happy/happy1" is remembered 
## This is very important for correct replacement
func _check_for_ref_change_cycle(old_name:String, new_name:String, category:String) -> bool:
	for ref in $Manager.reference_changes:
		if ref['forwhat'] == old_name and ref['category'] == category:
			if new_name == ref['what']:
				$Manager.reference_changes.erase(ref)
			else:
				$Manager.reference_changes[$Manager.reference_changes.find(ref)]['forwhat'] = new_name
				$Manager.reference_changes[$Manager.reference_changes.find(ref)]['regex_replacement'] = new_name
			return true
	return false


## Helper for adding variable ref changes
func add_variable_ref_change(old_name:String, new_name:String) -> void:
	add_ref_change(old_name, new_name, Types.VARIABLE, Where.EVERYWHERE)


## Helper for adding portrait ref changes
func add_portrait_ref_change(old_name:String, new_name:String, character_names:PackedStringArray) -> void:
	add_ref_change(old_name, new_name, Types.PORTRAIT, Where.BY_CHARACTER, character_names)


## Helper for adding character name ref changes
func add_character_name_ref_change(old_name:String, new_name:String) -> void:
	add_ref_change(old_name, new_name, Types.CHARACTER_NAME, Where.EVERYWHERE)


## Helper for adding timeline name ref changes
func add_timeline_name_ref_change(old_name:String, new_name:String) -> void:
	add_ref_change(old_name, new_name, Types.TIMELINE_NAME, Where.EVERYWHERE)


func open() -> void:
	popup_centered_ratio(0.5)
	move_to_foreground()
	grab_focus()
	$Manager.open()


func _on_close_requested() -> void:
	hide()
	$Manager.close()
	update_indicator()


func update_indicator() -> void:
	icon_button.get_child(0).visible = !$Manager.reference_changes.is_empty()
	for i in $Manager.reference_changes:
		i.item = null
	DialogicUtil.set_editor_setting('reference_changes', $Manager.reference_changes)


## FILE MOVEMENT:
func _on_file_moved(old_file:String, new_file:String) -> void:
	if old_file.ends_with('.dch') and new_file.ends_with('.dch'):
		if old_file.get_file() != new_file.get_file():
			add_character_name_ref_change(old_file.get_file().trim_suffix('.dch'), new_file.get_file().trim_suffix('.dch'))
			get_parent().get_node('ResourceRenameWarning').popup_centered()
	elif old_file.ends_with('.dtl') and new_file.ends_with('.dtl'):
		if old_file.get_file() != new_file.get_file():
			add_timeline_name_ref_change(old_file.get_file().trim_suffix('.dtl'), new_file.get_file().trim_suffix('.dtl'))
			get_parent().get_node('ResourceRenameWarning').popup_centered()
