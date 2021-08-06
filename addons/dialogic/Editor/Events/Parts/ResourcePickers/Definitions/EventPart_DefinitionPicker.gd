tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!
export (String) var default_text = "Select Definition"

## node references
onready var picker_menu = $MenuButton

var current_popup_menu

# used to connect the signals
func _ready():
	picker_menu.connect("about_to_show", self, "_on_PickerMenu_about_to_show")

# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	# Now update the ui nodes to display the data. 
	select_definition_by_id(data['definition'])
	
# has to return the wanted preview, only useful for body parts
func get_preview():
	return ''

func select_definition_by_id(value_name:String):
	picker_menu.text = value_name if editor_reference.res_values.has(value_name) else default_text

# when an index is selected on one of the menus.
func _on_PickerMenu_selected(index):
	var text = current_popup_menu.get_item_text(index)
	
	picker_menu.text = text
	
	event_data['definition'] = text
	
	printt("_on_PickerMenu_selected", index, event_data)
	
	# informs the parent about the changes!
	data_changed()

func _on_PickerMenu_about_to_show():
	current_popup_menu = picker_menu.get_popup()
	
	# Building the picker menu()
	current_popup_menu.clear()
	
	## building the root level
	#build_PickerMenuFolder(picker_menu.get_popup(), DialogicUtil.get_definitions_folder_structure(), "MenuButton")
	for value in editor_reference.res_values:
		current_popup_menu.add_icon_item(load("res://addons/dialogic/Images/Resources/definition.svg"), value)

	if not current_popup_menu.is_connected("index_pressed", self, "_on_PickerMenu_selected"):
		current_popup_menu.connect("index_pressed", self, "_on_PickerMenu_selected")

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
	
	var files_info = DialogicUtil.get_default_definitions_dict()
	for file in folder_structure['files']:
		if files_info[file]["type"] == 0:
			menu.add_item(files_info[file]['name'])
			menu.set_item_icon(index, load("res://addons/dialogic/Images/Resources/definition.svg"))
			menu.set_item_metadata(index, {'file':file})
			index += 1
	
	if not menu.is_connected("index_pressed", self, "_on_PickerMenu_selected"):
		menu
	
	return current_folder_name
