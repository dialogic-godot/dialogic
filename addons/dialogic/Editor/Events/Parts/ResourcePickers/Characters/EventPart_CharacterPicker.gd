tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!

export (bool) var allow_no_character := false

## node references
onready var picker_menu = $HBox/MenuButton
onready var no_character_button = $NoCharacterContainer/NoCharacterButton
onready var no_character_container = $NoCharacterContainer

# theme
var no_character_icon
var all_characters_icon
var single_character_icon


func _ready():
	if DialogicUtil.get_character_list().size() > 0:
		picker_menu.show()
		no_character_container.hide()
	else:
		picker_menu.hide()
		no_character_container.show()
		var editor_reference = find_parent('EditorView')
		no_character_button.connect('pressed', editor_reference.get_node('MainPanel/MasterTreeContainer/MasterTree'), 'new_character')
	
	# So... not having real events makes me do this kind of hacks
	# I hope to improve how events work, but in the mean time
	# this is what I have to do to get by :') 
	var event_node = get_node('../../../../../../../..')
	if event_node.get_node_or_null('AllowNoCharacter'):
		allow_no_character = true
		no_character_container.hide()#We dont want the button on text events
	
	# Connections
	picker_menu.connect("about_to_show", self, "_on_PickerMenu_about_to_show")
	
	# Themeing
	no_character_icon = get_icon("GuiRadioUnchecked", "EditorIcons")
	all_characters_icon = get_icon("GuiEllipsis", "EditorIcons")
	single_character_icon = load("res://addons/dialogic/Images/Resources/character.svg")
	

# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	allow_no_character = data['event_id'] != 'dialogic_002'
	# Now update the ui nodes to display the data. 
	update_to_character()


# has to return the wanted preview, only useful for body parts
func get_preview():
	return ''


# helper to not have the same code everywhere
func update_to_character():
	if event_data['character'] != '':
		if event_data['character'] == '[All]':
			picker_menu.text = "All characters"
			picker_menu.reset_modulation()
			picker_menu.custom_icon = all_characters_icon
		else:
			for ch in DialogicUtil.get_character_list():
				if ch['file'] == event_data['character']:
					picker_menu.text = ch['name']
					picker_menu.custom_icon_modulation = ch['color']
					picker_menu.custom_icon = single_character_icon
	else:
		if allow_no_character:
			picker_menu.text = 'No Character'
			picker_menu.custom_icon = no_character_icon
		else:
			picker_menu.text = 'Select Character'
			picker_menu.custom_icon = single_character_icon
		picker_menu.reset_modulation()

# when an index is selected on one of the menus.
func _on_PickerMenu_selected(index, menu):
	var metadata = menu.get_item_metadata(index)
	if event_data['character'] != metadata.get('file',''):
		if event_data.get('event_id') == 'dialogic_002':
			if event_data.get('type') == 0:
				event_data['portrait'] = 'Default'
			elif event_data.get('type') == 2:
				event_data['portrait'] = "(Don't change)"
	event_data['character'] = metadata.get('file','')
	
	update_to_character()
	
	# informs the parent about the changes!
	data_changed()


func _on_PickerMenu_about_to_show():
	build_PickerMenu()


func build_PickerMenu():
	picker_menu.get_popup().clear()
	var folder_structure = DialogicUtil.get_characters_folder_structure()

	## building the root level
	build_PickerMenuFolder(picker_menu.get_popup(), folder_structure, "MenuButton")


# is called recursively to build all levels of the folder structure
func build_PickerMenuFolder(menu:PopupMenu, folder_structure:Dictionary, current_folder_name:String):
	var index = 0
	
	## THIS IS JUST FOR THE ROOT FOLDER
	if menu == picker_menu.get_popup():
		if event_data.get('event_id', 'dialogic_001') != 'dialogic_002':
			menu.add_item('No character')
			menu.set_item_metadata(index, {'file':''})
			menu.set_item_icon(index, no_character_icon)
			index += 1

		# in case this is a leave event
		if event_data.get('type', 0) == 1:
			menu.add_item('All characters')
			menu.set_item_metadata(index, {'file': '[All]'})
			menu.set_item_icon(index, all_characters_icon)
			index += 1
	
	
	for folder_name in folder_structure['folders'].keys():
		var submenu = PopupMenu.new()
		var submenu_name = build_PickerMenuFolder(submenu, folder_structure['folders'][folder_name], folder_name)
		submenu.name = submenu_name
		menu.add_submenu_item(folder_name, submenu_name)
		menu.set_item_icon(index, get_icon("Folder", "EditorIcons"))
		menu.add_child(submenu)
		index += 1
		
		# give it the right style
		picker_menu.update_submenu_style(submenu)
	
	var files_info = DialogicUtil.get_characters_dict()
	for file in folder_structure['files']:
		menu.add_item(files_info[file]['name'])
		# this doesn't work right now, because it doesn't have the editor_reference. Would be nice though
		#menu.set_item_icon(index, editor_reference.get_node("MainPanel/MasterTreeContainer/MasterTree").character_icon)
		menu.set_item_icon(index, single_character_icon)
		menu.set_item_metadata(index, {'file':file})
		index += 1
	
	if not menu.is_connected("index_pressed", self, "_on_PickerMenu_selected"):
		menu.connect("index_pressed", self, '_on_PickerMenu_selected', [menu])
	
	return current_folder_name
