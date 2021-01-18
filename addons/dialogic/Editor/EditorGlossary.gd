tool
extends HSplitContainer

var editor_reference
var glossary


onready var nodes = {
	'name': $ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/LineEdit3,
	'title': $ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/LineEdit,
	'body': $ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/RichTextLabel,
	'extra': $ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/LineEdit2
}


func _ready():
	glossary = DialogicUtil.load_glossary()
	refresh_list()


func _on_NewEntryButton_pressed():
	var index = 0
	var new_entry_id = 'entry-' + DialogicUtil.generate_random_id()
	var add_new = true
	glossary[new_entry_id] = {
		'file': new_entry_id + '.json',
		'name': new_entry_id,
		'title': '',
		'body': '',
		'extra': '',
		'color': '#000000'
	}
	DialogicUtil.save_glossary(glossary)
	refresh_list()


func refresh_list():
	$VBoxContainer/ItemList.clear()
	#var icon = load("res://addons/dialogic/Images/character.svg")
	var index = 0
	for entry in glossary:
		var e = glossary[entry]
		$VBoxContainer/ItemList.add_item(e['name'], get_icon("MultiLine", "EditorIcons"))
		$VBoxContainer/ItemList.set_item_metadata(index, {'file': e['file']})
		index += 1


func _on_ItemList_item_rmb_selected(index, at_position):
	editor_reference.get_node("GlossaryPopupMenu").rect_position = get_viewport().get_mouse_position()
	editor_reference.get_node("GlossaryPopupMenu").popup()


func _on_ItemList_item_selected(index):
	var selected = $VBoxContainer/ItemList.get_item_text(index)
	var entry_id = $VBoxContainer/ItemList.get_item_metadata(index)['file'].replace('.json', '')
	update_editor(glossary[entry_id])


func _on_GlossaryPopupMenu_id_pressed(id):
	if id == 0:
		OS.shell_open(ProjectSettings.globalize_path(DialogicUtil.get_path('WORKING_DIR')))
	if id == 1:
		editor_reference.get_node("RemoveGlossaryConfirmation").popup_centered()


func _on_RemoveGlossaryConfirmation_confirmed():
	var selected = $VBoxContainer/ItemList.get_selected_items()[0]
	var entry_id = $VBoxContainer/ItemList.get_item_metadata(selected)['file'].replace('.json', '')
	for entry in glossary:
		if entry == entry_id:
			glossary.erase(entry)
	DialogicUtil.save_glossary(glossary)
	print('[-] Removing ', $VBoxContainer/ItemList.get_item_metadata(selected)['file'])

	#$CharacterEditor/HBoxContainer/Container.visible = false
	clear_editor()
	refresh_list()


func save_glossary():
	DialogicUtil.save_glossary(glossary)


func update_editor(data):
	nodes['name'].text = data['name']
	nodes['title'].text = data['title']
	nodes['body'].text = data['body']
	nodes['extra'].text = data['extra']


func clear_editor():
	nodes['name'].text = ''
	nodes['title'].text = ''
	nodes['body'].text = ''
	nodes['extra'].text = ''
