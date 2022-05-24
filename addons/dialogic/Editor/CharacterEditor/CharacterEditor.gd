tool
extends Control

####################################################################################################
##							VARIABLES
####################################################################################################
# references
var editor_reference
onready var master_tree = get_node('../MasterTreeContainer/MasterTree')
var portrait_entry = load("res://addons/dialogic/Editor/CharacterEditor/PortraitEntry.tscn")
onready var nodes = {
	'editor': $Split/EditorScroll/Editor,
	'name': $Split/EditorScroll/Editor/NameAndColor/NameLineEdit,
	'color': $Split/EditorScroll/Editor/NameAndColor/ColorPickerButton,
	'display_name_checkbox': $Split/EditorScroll/Editor/DisplayName/CheckBox,
	'display_name': $Split/EditorScroll/Editor/DisplayName/LineEdit,
	'nickname_checkbox': $Split/EditorScroll/Editor/DisplayNickname/CheckBox,
	'nickname': $Split/EditorScroll/Editor/DisplayNickname/LineEdit,
	'description': $Split/EditorScroll/Editor/Description/TextEdit,
	'theme':$Split/EditorScroll/Editor/Theme/ThemeButton,
	
	'file': $Split/EditorScroll/Editor/FileName/LineEdit,
	
	'mirror_portraits_checkbox' : $Split/EditorScroll/Editor/HBoxContainer/MirrorOption/MirrorPortraitsCheckBox,
	'scale': $Split/EditorScroll/Editor/HBoxContainer/Scale,
	'offset_x': $Split/EditorScroll/Editor/HBoxContainer/OffsetX,
	'offset_y': $Split/EditorScroll/Editor/HBoxContainer/OffsetY,
	
	'portrait_search':$Split/EditorScroll/Editor/Portraits/Search,
	'portrait_list': $Split/EditorScroll/Editor/PortraitPanel/VBoxContainer/ScrollContainer/VBoxContainer/PortraitList,
	'new_portrait_button': $Split/EditorScroll/Editor/PortraitPanel/VBoxContainer/Labels/HBoxContainer/NewPortrait,
	'import_from_folder_button': $Split/EditorScroll/Editor/PortraitPanel/VBoxContainer/Labels/HBoxContainer/ImportFromFolder,
	
	'portrait_preview_full': $Split/Preview/Background/FullTextureRect,
	'portrait_preview_real': $Split/Preview/Background/Positioner/RealSizedRect,
	'image_label': $Split/Preview/Background/TLabel10,
}

# data
var opened_character_data
var selected_theme_file = ''

####################################################################################################
##							SCRIPT
####################################################################################################

# connect functions; translate buttons; update styles, etc...
func _ready():
	editor_reference = find_parent('EditorView')

	nodes['new_portrait_button'].text = "  "+DTS.translate("New portrait")
	nodes['import_from_folder_button'].text = "  "+DTS.translate("Import folder")
	
	# connecting signals
	nodes['name'].connect('text_changed', self, '_on_name_changed')
	nodes['name'].connect('focus_exited', self, '_update_name_on_tree')
	nodes['color'].connect('color_changed', self, '_on_color_changed')
	nodes['display_name_checkbox'].connect('toggled', self, '_on_display_name_toggled')
	nodes['nickname_checkbox'].connect('toggled', self, '_on_nickname_toggled')
	nodes['theme'].connect("about_to_show", self, "build_ThemePickerMenu")
	
	nodes['portrait_search'].connect('text_changed', self, '_on_PortraitSearch_text_changed')
	nodes['portrait_search'].right_icon = get_icon("Search", "EditorIcons")
	nodes['import_from_folder_button'].connect('pressed', self, '_on_Import_Portrait_Folder_Button_pressed')
	nodes['new_portrait_button'].connect('pressed', self, '_on_New_Portrait_Button_pressed')
	
	# updating styles
	var style = $Split/EditorScroll.get('custom_styles/bg')
	style.set('bg_color', get_color("base_color", "Editor"))
	nodes['new_portrait_button'].icon = get_icon("Add", "EditorIcons")
	nodes['import_from_folder_button'].icon = get_icon("Folder", "EditorIcons")
	$Split/EditorScroll/Editor/Portraits/Title.set('custom_fonts/font', get_font("doc_title", "EditorFonts"))
	$Split/EditorScroll/Editor/PortraitPanel.set('custom_styles/panel', get_stylebox("Background", "EditorStyles"))
	
	# loading default setup
	_on_PreviewMode_item_selected(DialogicResources.get_settings_value('editor', 'character_preview_mode', 1))
	$Split/Preview/Background/PreviewMode.select(DialogicResources.get_settings_value('editor', 'character_preview_mode', 1))
	$Split/Preview/Background/PreviewMode.set_item_text(0, DTS.translate("Full View"))
	$Split/Preview/Background/PreviewMode.set_item_text(1, DTS.translate("Actual Size"))

# removes all input for a new character
func clear_character_editor():
	nodes['file'].text = ''
	nodes['name'].text = ''
	nodes['color'].color = Color('#ffffff')
	nodes['display_name_checkbox'].pressed = false
	nodes['display_name'].text = ''
	nodes['nickname_checkbox'].pressed = false
	nodes['nickname'].text = ''
	nodes['description'].text = ''
	nodes['theme'].text = 'No custom theme'
	selected_theme_file = ''
	
	nodes['portrait_search'].text = ''
	nodes['portraits'] = []
	nodes['scale'].value = 100
	nodes['mirror_portraits_checkbox'].pressed = false
	nodes['offset_x'].value = 0
	nodes['offset_y'].value = 0

	# Clearing portraits
	for p in nodes['portrait_list'].get_children():
		p.queue_free()
	nodes['portrait_preview_full'].texture = null
	nodes['portrait_preview_real'].texture = null
	nodes['portrait_preview_real'].rect_scale = Vector2(1, 1)

# creates new character data
func create_character():
	var character_file = 'character-' + str(OS.get_unix_time()) + '.json'
	var character = {
		'color': '#ffffff',
		'id': character_file,
		'portraits': [],
		'mirror_portraits' :false
	}
	DialogicResources.set_character(character)
	character['metadata'] = {'file': character_file}
	return character

####################################################################################################
##							SAVING AND LOADING
####################################################################################################

# returns all of the current data in the format it's saved as
func generate_character_data_to_save():
	var portraits = []
	for p in nodes['portrait_list'].get_children():
		var entry = {}
		entry['name'] = p.get_node("NameEdit").text
		entry['path'] = p.get_node("PathEdit").text
		portraits.append(entry)
	var info_to_save = {
		'id': nodes['file'].text,
		'color': '#' + nodes['color'].color.to_html(),
		'display_name_bool': nodes['display_name_checkbox'].pressed,
		'display_name': nodes['display_name'].text,
		'nickname_bool': nodes['nickname_checkbox'].pressed,
		'nickname': nodes['nickname'].text,
		'description': nodes['description'].text,
		'theme': selected_theme_file, 
		
		'portraits': portraits,
		'scale': nodes['scale'].value,
		'mirror_portraits': nodes["mirror_portraits_checkbox"].pressed,
		'offset_x': nodes['offset_x'].value,
		'offset_y': nodes['offset_y'].value,
	}
	# Adding name later for cases when no name is provided
	if nodes['name'].text != '':
		info_to_save['name'] = nodes['name'].text
	
	return info_to_save

# save the currently opened data
func save_character():
	var info_to_save = generate_character_data_to_save()
	if info_to_save['id']:
		DialogicResources.set_character(info_to_save)
		opened_character_data = info_to_save

# load data in
func load_character(filename: String):
	clear_character_editor()
	var data = DialogicResources.get_character_json(filename)
	opened_character_data = data
	nodes['file'].text = data['id']
	nodes['name'].text = data.get('name', '')
	nodes['color'].color = Color(data.get('color','#ffffffff'))
	nodes['display_name_checkbox'].pressed = data.get('display_name_bool', false)
	nodes['display_name'].text = data.get('display_name', '')
	nodes['nickname_checkbox'].pressed = data.get('nickname_bool', false)
	nodes['nickname'].text = data.get('nickname', '')
	nodes['description'].text = data.get('description', '')
	refresh_themes_and_select(data.get('theme', ''))
	
	nodes['scale'].value = float(data.get('scale', 100))
	#nodes['nickname'].visible
	nodes['offset_x'].value = data.get('offset_x', 0)
	nodes['offset_y'].value = data.get('offset_y', 0)
	nodes['mirror_portraits_checkbox'].pressed = data.get('mirror_portraits', false)
	nodes['portrait_preview_full'].flip_h = data.get('mirror_portraits', false)
	nodes['portrait_preview_real'].flip_h = data.get('mirror_portraits', false)
	nodes['portrait_preview_real'].rect_scale = Vector2(
					float(data.get('scale', 100))/100, float(data.get('scale', 100))/100)
	
	# Portraits
	var default_portrait = create_portrait_entry()
	default_portrait.get_node('NameEdit').text = 'Default'
	default_portrait.get_node('NameEdit').editable = false
	if opened_character_data.has('portraits'):
		for p in opened_character_data['portraits']:
			var current_item
			if p['name'] == 'Default':
				default_portrait.get_node('PathEdit').text = p['path']
				default_portrait.update_preview(p['path'])
				current_item = default_portrait
			else:
				current_item = create_portrait_entry(p['name'], p['path'])
			

####################################################################################################
##							UI FUNCTIONS
####################################################################################################


func _on_PortraitSearch_text_changed(text):
	for portrait_item in nodes['portrait_list'].get_children():
		if text.empty() or text.to_lower() in portrait_item.get_node("NameEdit").text.to_lower() or text.to_lower() in portrait_item.get_node("PathEdit").text.to_lower():
			portrait_item.show()
		else:
			portrait_item.hide()

func refresh_themes_and_select(file):
	selected_theme_file = file

	if file == '' or file == 'No custom theme':
		nodes['theme'].text = "No custom theme"
		nodes['theme'].custom_icon = get_icon("GuiRadioUnchecked", "EditorIcons")
	else:
		nodes['theme'].text = DialogicUtil.get_theme_dict()[file]['name']
		nodes['theme'].custom_icon = editor_reference.get_node("MainPanel/MasterTreeContainer/MasterTree").theme_icon

func build_ThemePickerMenu():
	nodes['theme'].get_popup().clear()
	var folder_structure = DialogicUtil.get_theme_folder_structure()

	## building the root level
	build_PickerMenuFolder(nodes['theme'].get_popup(), folder_structure, "MenuButton")

# is called recursively to build all levels of the folder structure
func build_PickerMenuFolder(menu:PopupMenu, folder_structure:Dictionary, current_folder_name:String):
	var index = 0
	
	if menu == nodes["theme"].get_popup():
		menu.add_item('No custom theme')
		menu.set_item_icon(index, get_icon("GuiRadioUnchecked", "EditorIcons"))
		menu.set_item_metadata(index, {"file":""})
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
		nodes['theme'].update_submenu_style(submenu)
	
	var files_info = DialogicUtil.get_theme_dict()
	for file in folder_structure['files']:
		menu.add_item(files_info[file]['name'])
		menu.set_item_icon(index, editor_reference.get_node("MainPanel/MasterTreeContainer/MasterTree").theme_icon)
		menu.set_item_metadata(index, {'file':file})
		index += 1
	
	if not menu.is_connected("index_pressed", self, "_on_theme_selected"):
		menu.connect("index_pressed", self, '_on_theme_selected', [menu])
	
	return current_folder_name


func _on_theme_selected(index, menu):
	refresh_themes_and_select(menu.get_item_metadata(index).get('file', ''))
	

func _on_display_name_toggled(button_pressed):
	nodes['display_name'].visible = button_pressed
	if button_pressed: nodes['display_name'].grab_focus()


func _on_nickname_toggled(button_pressed):
	nodes['nickname'].visible = button_pressed
	if button_pressed: nodes['nickname'].grab_focus()

func is_selected(file: String):
	return nodes['file'].text == file


func _on_name_changed(value):
	save_character()


func _update_name_on_tree():
	var item = master_tree.get_selected()
	item.set_text(0, nodes['name'].text)
	master_tree.build_characters(nodes['file'].text)
	

func _input(event):
	if event is InputEventKey and event.pressed:
		if nodes['name'].has_focus():
			if event.scancode == KEY_ENTER:
				nodes['name'].release_focus()


func _on_color_changed(color):
	var item = master_tree.get_selected()
	item.set_icon_modulate(0, color)



# Portraits
func _on_New_Portrait_Button_pressed():
	create_portrait_entry('', '', true)


func create_portrait_entry(p_name = '', path = '', grab_focus = false):
	if grab_focus and nodes['portrait_list'].get_child_count() == 1 and nodes['portrait_list'].get_child(0).get_node("PathEdit").text == '':
		nodes['portrait_list'].get_child(0)._on_ButtonSelect_pressed()
		return
	
	var p = portrait_entry.instance()
	p.editor_reference = editor_reference
	p.image_node = nodes['portrait_preview_full']
	p.image_node2 = nodes['portrait_preview_real']
	p.image_label = nodes['image_label']
	var p_list = nodes['portrait_list']
	p_list.add_child(p)
	if p_name != '':
		p.get_node("NameEdit").text = p_name
	if path != '':
		p.get_node("PathEdit").text = path
	if grab_focus:
		p.get_node("NameEdit").grab_focus()
		p._on_ButtonSelect_pressed()
	return p


func _on_Import_Portrait_Folder_Button_pressed():
	editor_reference.godot_dialog("*", EditorFileDialog.MODE_OPEN_DIR)
	editor_reference.godot_dialog_connect(self, "_on_dir_selected", "dir_selected")


func _on_dir_selected(path, target):
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				var file_lower = file_name.to_lower()
				if '.svg' in file_lower or '.png' in file_lower:
					if not '.import' in file_lower:
						var final_name = path+ "/" + file_name
						create_portrait_entry(DialogicResources.get_filename_from_path(file_name), final_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")


func _on_MirrorPortraitsCheckBox_toggled(button_pressed):
	nodes['portrait_preview_full'].flip_h = button_pressed
	nodes['portrait_preview_real'].flip_h = button_pressed


func _on_Scale_value_changed(value):
	#nodes['portrait_preview_real'].rect_position = ($Split/Preview/Background/Positioner.rect_position-nodes['portrait_preview_real'].rect_size*Vector2(0.5,1))
	nodes['portrait_preview_real'].rect_size = Vector2()
	nodes['portrait_preview_real'].rect_scale = Vector2(
					float(value)/100, float(value)/100)

func _on_PreviewMode_item_selected(index):
	if index == 0:
		nodes['portrait_preview_real'].hide()
		nodes['portrait_preview_full'].show()
	if index == 1:
		nodes['portrait_preview_real'].show()
		nodes['portrait_preview_full'].hide()
	DialogicResources.set_settings_value('editor', 'character_preview_mode', index)

