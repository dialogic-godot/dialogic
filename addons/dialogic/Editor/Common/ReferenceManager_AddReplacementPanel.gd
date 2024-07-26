@tool
extends PanelContainer


enum Modes {EDIT, ADD}

var mode := Modes.EDIT
var item: TreeItem = null


func _ready() -> void:
	hide()
	%Character.resource_icon = load("res://addons/dialogic/Editor/Images/Resources/character.svg")
	%Character.get_suggestions_func = get_character_suggestions

	%WholeWords.icon = get_theme_icon("FontItem", "EditorIcons")
	%MatchCase.icon = get_theme_icon("MatchCase", "EditorIcons")

func _on_add_pressed() -> void:
	if visible:
		if mode == Modes.ADD:
			hide()
			return
		elif mode == Modes.EDIT:
			save()

	%AddButton.text = "Add"
	mode = Modes.ADD
	show()
	%Type.selected = 0
	_on_type_item_selected(0)
	%Where.selected = 2
	_on_where_item_selected(2)
	%Old.text = ""
	%New.text = ""


func open_existing(_item:TreeItem, info:Dictionary):
	mode = Modes.EDIT
	item = _item
	show()
	%AddButton.text = "Update"
	%Type.selected = info.type
	_on_type_item_selected(info.type)
	if !info.character_names.is_empty():
		%Where.selected = 1
		%Character.set_value(info.character_names[0])
	else:
		%Where.selected = 0
	_on_where_item_selected(%Where.selected)

	%Old.text = info.what
	%New.text = info.forwhat

func _on_type_item_selected(index:int) -> void:
	match index:
		0:
			%Where.select(0)
			%Where.set_item_disabled(0, false)
			%Where.set_item_disabled(1, false)
			%Where.set_item_disabled(2, true)
		1:
			%Where.select(0)
			%Where.set_item_disabled(0, false)
			%Where.set_item_disabled(1, false)
			%Where.set_item_disabled(2, true)
		2:
			%Where.select(1)
			%Where.set_item_disabled(0, true)
			%Where.set_item_disabled(1, false)
			%Where.set_item_disabled(2, true)
		3,4:
			%Where.select(0)
			%Where.set_item_disabled(0, false)
			%Where.set_item_disabled(1, true)
			%Where.set_item_disabled(2, true)
	%PureTextFlags.visible = index == 0
	_on_where_item_selected(%Where.selected)


func _on_where_item_selected(index:int) -> void:
	%Character.visible = index == 1


func get_character_suggestions(search_text:String) -> Dictionary:
	var suggestions := {}

	#override the previous _character_directory with the meta, specifically for searching otherwise new nodes wont work
	var _character_directory := DialogicResourceUtil.get_character_directory()

	var icon := load("res://addons/dialogic/Editor/Images/Resources/character.svg")
	suggestions['(No one)'] = {'value':null, 'editor_icon':["GuiRadioUnchecked", "EditorIcons"]}

	for resource in _character_directory.keys():
		suggestions[resource] = {
				'value' 	: resource,
				'tooltip' 	: _character_directory[resource],
				'icon' 		: icon.duplicate()}
	return suggestions


func save() -> void:
	if %Old.text.is_empty() or %New.text.is_empty():
		return
	if %Where.selected == 1 and %Character.current_value == null:
		return

	var previous := {}
	if mode == Modes.EDIT:
		previous = item.get_metadata(0)
		item.get_parent()
		item.free()

	var ref_manager := find_parent('ReferenceManager')
	var character_names := []
	if %Character.current_value != null:
		character_names = [%Character.current_value]
	ref_manager.add_ref_change(%Old.text, %New.text, %Type.selected, %Where.selected, character_names, %WholeWords.button_pressed, %MatchCase.button_pressed, previous)
	hide()
