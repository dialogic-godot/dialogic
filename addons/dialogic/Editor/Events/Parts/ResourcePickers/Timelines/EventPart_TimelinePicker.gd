tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!

## node references
onready var picker_menu = $MenuButton

# used to connect the signals
func _ready():
	picker_menu.connect("about_to_show", self, "_on_PickerMenu_about_to_show")


# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	# Now update the ui nodes to display the data. 
	if event_data['change_timeline'] != '':
		for c in DialogicUtil.get_timeline_list():
			if c['file'] == event_data['change_timeline']:
				picker_menu.text = c['name']
	else:
		picker_menu.text = 'Select Timeline'


# has to return the wanted preview, only useful for body parts
func get_preview():
	return ''


# when an index is selected on one of the menus.
func _on_PickerMenu_selected(index, menu):
	var text = menu.get_item_text(index)
	var metadata = menu.get_item_metadata(index)
	picker_menu.text = text
	event_data['change_timeline'] = metadata['file']
	
	# informs the parent about the changes!
	data_changed()


func _on_PickerMenu_about_to_show():
	build_PickerMenu()


func build_PickerMenu():
	picker_menu.get_popup().clear()
	var folder_structure = DialogicUtil.get_timelines_folder_structure()

	## building the root level
	build_PickerMenuFolder(picker_menu.get_popup(), folder_structure, "MenuButton")


# is called recursively to build all levels of the folder structure
func build_PickerMenuFolder(menu:PopupMenu, folder_structure:Dictionary, current_folder_name:String):
	var index = 0
	for folder_name in folder_structure['folders'].keys():
		var submenu = PopupMenu.new()
		var submenu_name = build_PickerMenuFolder(submenu, folder_structure['folders'][folder_name], folder_name)
		submenu.name = submenu_name
		menu.add_submenu_item(folder_name, submenu_name)
		menu.set_item_icon(index, get_icon("Folder", "EditorIcons"))
		menu.add_child(submenu)
		index += 1
	
	var files_info = DialogicUtil.get_timeline_dict()
	for file in folder_structure['files']:
		menu.add_item(files_info[file]['name'])
		menu.set_item_icon(index, editor_reference.get_node("MainPanel/MasterTreeContainer/MasterTree").timeline_icon)
		menu.set_item_metadata(index, {'file':file})
		index += 1
	
	if not menu.is_connected("index_pressed", self, "_on_PickerMenu_selected"):
		menu.connect("index_pressed", self, '_on_PickerMenu_selected', [menu])
	
	return current_folder_name
