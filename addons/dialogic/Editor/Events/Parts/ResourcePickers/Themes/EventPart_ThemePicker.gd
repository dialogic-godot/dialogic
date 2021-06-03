tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!
export (String) var default_text = "Select Theme"

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
	select_theme()
	
# has to return the wanted preview, only useful for body parts
func get_preview():
	return ''

func select_theme():
	if event_data['set_theme'] != '':
		for theme in DialogicUtil.get_theme_list():
			if theme['file'] == event_data['set_theme']:
				picker_menu.text = theme['name']
	else:
		picker_menu.text = default_text

# when an index is selected on one of the menus.
func _on_PickerMenu_selected(index, menu):
	event_data['set_theme'] = menu.get_item_metadata(index).get('file', '')
	
	select_theme()
	
	# informs the parent about the changes!
	data_changed()


func _on_PickerMenu_about_to_show():
	build_PickerMenu()

func build_PickerMenu():
	picker_menu.get_popup().clear()
	var folder_structure = DialogicUtil.get_theme_folder_structure()

	## building the root level
	build_PickerMenuFolder(picker_menu.get_popup(), folder_structure, "MenuButton")

# is called recursively to build all levels of the folder structure
func build_PickerMenuFolder(menu:PopupMenu, folder_structure:Dictionary, current_folder_name:String):
	var index = 0
	for folder_name in folder_structure['folders'].keys():
		var submenu = PopupMenu.new()
		menu.add_submenu_item(folder_name, build_PickerMenuFolder(submenu, folder_structure['folders'][folder_name], folder_name))
		menu.set_item_icon(index, get_icon("Folder", "EditorIcons"))
		menu.add_child(submenu)
		index += 1
	
	var files_info = DialogicUtil.get_theme_dict()
	for file in folder_structure['files']:
		menu.add_item(files_info[file]['name'])
		menu.set_item_icon(index, editor_reference.get_node("MainPanel/MasterTreeContainer/MasterTree").theme_icon)
		menu.set_item_metadata(index, {'file':file})
		index += 1
	
	if not menu.is_connected("index_pressed", self, "_on_PickerMenu_selected"):
		menu.connect("index_pressed", self, '_on_PickerMenu_selected', [menu])
	
	menu.name = current_folder_name
	return current_folder_name
