tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!

export (bool) var allow_no_character := false

## node references
onready var picker_menu = $HBox/MenuButton
onready var icon = $HBox/Icon


func _ready():
	# So... not having real events makes me do this kind of hacks
	# I hope to improve how events work, but in the mean time
	# this is what I have to do to get by :') 
	var event_node = get_node('../../../../../../../..')
	if event_node.get_node_or_null('AllowNoCharacter'):
		allow_no_character = true
	
	# Connections
	picker_menu.connect("about_to_show", self, "_on_PickerMenu_about_to_show")


# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
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
			icon.modulate = Color.white
		else:
			for ch in DialogicUtil.get_character_list():
				if ch['file'] == event_data['character']:
					picker_menu.text = ch['name']
					icon.modulate = ch['color']
	else:
		if allow_no_character:
			picker_menu.text = 'No Character'
		else:
			picker_menu.text = 'Select Character'
		icon.modulate = Color.white


# when an index is selected on one of the menus.
func _on_PickerMenu_selected(index, menu):
	var metadata = menu.get_item_metadata(index)
	
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
		if allow_no_character:
			menu.add_item('No character')
			menu.set_item_metadata(index, {'file':''})
			menu.set_item_icon(index, get_icon("GuiRadioUnchecked", "EditorIcons"))
			index += 1

		# in case this is a leave event
		if event_data['event_id'] == 'dialogic_003':
			menu.add_item('All characters')
			menu.set_item_metadata(index, {'file': '[All]'})
			menu.set_item_icon(index, get_icon("GuiEllipsis", "EditorIcons"))
			index += 1
		
	
	
	
	for folder_name in folder_structure['folders'].keys():
		var submenu = PopupMenu.new()
		menu.add_submenu_item(folder_name, build_PickerMenuFolder(submenu, folder_structure['folders'][folder_name], folder_name))
		menu.set_item_icon(index, get_icon("Folder", "EditorIcons"))
		menu.add_child(submenu)
		index += 1
	
	var files_info = DialogicUtil.get_characters_dict()
	for file in folder_structure['files']:
		menu.add_item(files_info[file]['name'])
		# this doesn't work right now, because it doesn't have the editor_reference. Would be nice though
		#menu.set_item_icon(index, editor_reference.get_node("MainPanel/MasterTreeContainer/MasterTree").character_icon)
		menu.set_item_icon(index, load("res://addons/dialogic/Images/Resources/character.svg"))
		menu.set_item_metadata(index, {'file':file})
		index += 1
	
	if not menu.is_connected("index_pressed", self, "_on_PickerMenu_selected"):
		menu.connect("index_pressed", self, '_on_PickerMenu_selected', [menu])
	
	menu.name = current_folder_name
	return current_folder_name
