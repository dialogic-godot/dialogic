tool
extends ScrollContainer

var editor_reference

onready var nodes = {
	# Theme
	'themes': $VBoxContainer/HBoxContainer3/VBoxContainer/VBoxContainer/HBoxContainer/ThemePicker,
	'canvas_layer' : $VBoxContainer/HBoxContainer3/VBoxContainer/VBoxContainer/HBoxContainer3/CanvasLayer,
	
	# Dialog
	'text_event_audio_default_bus' : $VBoxContainer/HBoxContainer3/VBoxContainer/VBoxContainer2/TextAudioDefaultBus/AudioBus,

	# Input Settings
	'delay_after_options': $VBoxContainer/HBoxContainer3/VBoxContainer2/VBoxContainer/HBoxContainer/LineEdit,
	'default_action_key': $VBoxContainer/HBoxContainer3/VBoxContainer2/VBoxContainer/HBoxContainer2/DefaultActionKey,
	'choice_hotkey_1': $'VBoxContainer/HBoxContainer3/VBoxContainer2/VBoxContainer/HBoxContainer4/Choice1Hotkey',
	'choice_hotkey_2': $'VBoxContainer/HBoxContainer3/VBoxContainer2/VBoxContainer/HBoxContainer5/Choice2Hotkey',
	'choice_hotkey_3': $'VBoxContainer/HBoxContainer3/VBoxContainer2/VBoxContainer/HBoxContainer6/Choice3Hotkey',
	'choice_hotkey_4': $'VBoxContainer/HBoxContainer3/VBoxContainer2/VBoxContainer/HBoxContainer7/Choice4Hotkey',
	
	# Custom Events
	'new_custom_event_open':$VBoxContainer/HBoxContainer3/VBoxContainer2/CustomEvents/HBoxContainer/NewCustomEvent, 
	'new_custom_event_section': $VBoxContainer/HBoxContainer3/VBoxContainer2/CustomEvents/CreateCustomEventSection, 
	'new_custom_event_name': $VBoxContainer/HBoxContainer3/VBoxContainer2/CustomEvents/CreateCustomEventSection/CeName,
	'new_custom_event_directory': $VBoxContainer/HBoxContainer3/VBoxContainer2/CustomEvents/CreateCustomEventSection/CeDirectory,
	'new_custom_event_id': $VBoxContainer/HBoxContainer3/VBoxContainer2/CustomEvents/CreateCustomEventSection/CeEventId,
	'new_custom_event_create':$VBoxContainer/HBoxContainer3/VBoxContainer2/CustomEvents/CreateCustomEventSection/HBoxContainer/CreateCustomEvent,
	'new_custom_event_cancel':$VBoxContainer/HBoxContainer3/VBoxContainer2/CustomEvents/CreateCustomEventSection/HBoxContainer/CancelCustomEvent,
	
	# History Settings
	'text_arrivals': $VBoxContainer/HBoxContainer3/VBoxContainer2/HistorySettings/GridContainer/LogBox/LineEdit,
	'text_exits': $VBoxContainer/HBoxContainer3/VBoxContainer2/HistorySettings/GridContainer/LogBox2/LineEdit,
	'history_button_position': $VBoxContainer/HBoxContainer3/VBoxContainer2/HistorySettings/GridContainer/PositionSelector,
	'history_character_delimiter': $VBoxContainer/HBoxContainer3/VBoxContainer2/HistorySettings/GridContainer/CharacterDelimiter,
	'history_screen_margin_x': $VBoxContainer/HBoxContainer3/VBoxContainer2/HistorySettings/GridContainer/BoxMargin/MarginX,
	'history_screen_margin_y': $VBoxContainer/HBoxContainer3/VBoxContainer2/HistorySettings/GridContainer/BoxMargin/MarginY,
	'history_container_margin_x': $VBoxContainer/HBoxContainer3/VBoxContainer2/HistorySettings/GridContainer/ContainerMargin/MarginX,
	'history_container_margin_y': $VBoxContainer/HBoxContainer3/VBoxContainer2/HistorySettings/GridContainer/ContainerMargin/MarginY,
	# Animations
	'default_join_animation':$VBoxContainer/HBoxContainer3/VBoxContainer/VBoxContainer4/DefaultJoinAnimation/JoinAnimationPicker,
	'default_join_animation_length':$VBoxContainer/HBoxContainer3/VBoxContainer/VBoxContainer4/DefaultJoinAnimation/AnimationLengthPicker,
	'default_leave_animation':$VBoxContainer/HBoxContainer3/VBoxContainer/VBoxContainer4/DefaultLeaveAnimation/LeaveAnimationPicker,
	'default_leave_animation_length':$VBoxContainer/HBoxContainer3/VBoxContainer/VBoxContainer4/DefaultLeaveAnimation/AnimationLengthPicker,
	}

var THEME_KEYS := [
	'canvas_layer',
	]

var INPUT_KEYS := [
	'delay_after_options',
	'default_action_key',
	'choice_hotkey_1',
	'choice_hotkey_2',
	'choice_hotkey_3',
	'choice_hotkey_4',
	]

var HISTORY_KEYS := [
	'text_arrivals',
	'text_exits',
	'history_button_position',
	'history_character_delimiter',
	'history_screen_margin_x',
	'history_screen_margin_y',
	'history_container_margin_x',
	'history_container_margin_y'
]

var ANIMATION_KEYS := [
	'default_join_animation', 
	'default_join_animation_length',
	'default_leave_animation',
	'default_leave_animation_length'
]

func _ready():
	editor_reference = find_parent('EditorView')
	update_bus_selector()
	
	update_data()
	
	# Themes
	nodes['themes'].connect('about_to_show', self, 'build_PickerMenu')
	nodes['themes'].custom_icon = load("res://addons/dialogic/Images/Resources/theme.svg")
	# TODO move to theme section later
	nodes['canvas_layer'].connect('value_changed', self, '_on_canvas_layer_text_changed')

	# Input
	nodes['delay_after_options'].connect('text_changed', self, '_on_delay_options_text_changed')
	nodes['default_action_key'].connect('pressed', self, '_on_default_action_key_presssed')
	nodes['default_action_key'].connect('item_selected', self, '_on_default_action_key_item_selected')
	
	# Connect hotkey settings 1-4
	for i in range(1, 5):
		var key = str('choice_hotkey_', i)
		nodes[key].connect('pressed', self, '_on_hotkey_action_key_presssed', [key])
		nodes[key].connect('item_selected', self, '_on_default_action_key_item_selected', [key])
	
	AudioServer.connect("bus_layout_changed", self, "update_bus_selector")
	nodes['text_event_audio_default_bus'].connect('item_selected', self, '_on_text_audio_default_bus_item_selected')
	
	## History timeline connections
	nodes['history_button_position'].connect('item_selected', self, '_on_button_history_button_position_selected')
	nodes['history_character_delimiter'].connect('text_changed', self, '_on_text_changed', ['history', 'history_character_delimiter'])
	nodes['text_arrivals'].connect('text_changed', self, '_on_text_changed', ['history', 'text_arrivals'])
	nodes['text_exits'].connect('text_changed', self, '_on_text_changed', ['history', 'text_exits'])
	
	for button in ['history_button_position']:
		var button_positions_popup = nodes[button].get_popup()
		button_positions_popup.clear()
		button_positions_popup.add_icon_item(
			get_icon("ControlAlignTopLeft", "EditorIcons"), "Top Left", 0)
		button_positions_popup.add_icon_item(
			get_icon("ControlAlignTopCenter", "EditorIcons"), "Top Center", 1)
		button_positions_popup.add_icon_item(
			get_icon("ControlAlignTopRight", "EditorIcons"), "Top Right", 2)
		button_positions_popup.add_separator()
		button_positions_popup.add_icon_item(
			get_icon("ControlAlignLeftCenter", "EditorIcons"), "Center Left", 3)
		button_positions_popup.add_icon_item(
			get_icon("ControlAlignCenter", "EditorIcons"), "Center", 4)
		button_positions_popup.add_icon_item(
			get_icon("ControlAlignRightCenter", "EditorIcons"), "Center Right", 5)
		button_positions_popup.add_separator()
		button_positions_popup.add_icon_item(
			get_icon("ControlAlignBottomLeft", "EditorIcons"), "Bottom Left", 6)
		button_positions_popup.add_icon_item(
			get_icon("ControlAlignBottomCenter", "EditorIcons"), "Bottom Center", 7)
		button_positions_popup.add_icon_item(
			get_icon("ControlAlignBottomRight", "EditorIcons"), "Bottom Right", 8)
	
	nodes['history_screen_margin_x'].connect("value_changed", self, '_spinbox_val_changed', ['history_screen_margin_x'])
	nodes['history_screen_margin_y'].connect("value_changed", self, '_spinbox_val_changed', ['history_screen_margin_y'])
	nodes['history_container_margin_x'].connect("value_changed", self, '_spinbox_val_changed', ['history_container_margin_x'])
	nodes['history_container_margin_y'].connect("value_changed", self, '_spinbox_val_changed', ['history_container_margin_y'])
	
	## The custom event section
	nodes['new_custom_event_open'].connect("pressed", self, "new_custom_event_pressed")
	nodes['new_custom_event_section'].hide()
	nodes['new_custom_event_name'].connect("text_changed", self, "custom_event_name_entered")
	nodes['new_custom_event_id'].connect("text_changed", self, "custom_event_id_entered")
	nodes['new_custom_event_cancel'].connect("pressed", self, "cancel_custom_event")
	nodes['new_custom_event_create'].connect("pressed", self, "create_custom_event")
	$VBoxContainer/HBoxContainer3/VBoxContainer2/CustomEvents/HBoxContainer/Message.set('custom_colors/font_color', get_color("error_color", "Editor"))
	$VBoxContainer/HBoxContainer3/VBoxContainer2/CustomEvents/HBoxContainer/CustomEventsDocs.icon = get_icon("HelpSearch", "EditorIcons")
	$VBoxContainer/HBoxContainer3/VBoxContainer2/CustomEvents/HBoxContainer/CustomEventsDocs.connect("pressed", self, 'open_custom_event_docs')
	
	## The Animation Section
	nodes['default_join_animation'].connect('about_to_show', self, '_on_AnimationDefault_about_to_show', [nodes['default_join_animation'], '_in'])
	nodes['default_leave_animation'].connect('about_to_show', self, '_on_AnimationDefault_about_to_show', [nodes['default_leave_animation'], 'out'])
	nodes['default_join_animation'].get_popup().connect('index_pressed', self, '_on_AnimationDefault_index_pressed', [nodes['default_join_animation'], 'default_join_animation'])
	nodes['default_leave_animation'].get_popup().connect('index_pressed', self, '_on_AnimationDefault_index_pressed', [nodes['default_leave_animation'], 'default_leave_animation'])
	nodes['default_join_animation'].custom_icon = get_icon("Animation", "EditorIcons")
	nodes['default_leave_animation'].custom_icon = get_icon("Animation", "EditorIcons")
	nodes['default_join_animation_length'].connect('value_changed', self, '_on_AnimationDefaultLength_value_changed', ['default_join_animation_length'])
	nodes['default_leave_animation_length'].connect('value_changed', self, '_on_AnimationDefaultLength_value_changed', ['default_leave_animation_length'])

func update_data():
	# Reloading the settings
	var settings = DialogicResources.get_settings_config()
	nodes['themes'].text = DialogicUtil.get_theme_dict()[settings.get_value("theme", "default", "default-theme.cfg")].get('name')
	nodes['canvas_layer'].value = int(settings.get_value("theme", "canvas_layer", '1'))
	load_values(settings, "input", INPUT_KEYS)
	load_values(settings, "history", HISTORY_KEYS)
	load_values(settings, "animations", ANIMATION_KEYS)
	select_bus(settings.get_value("dialog", 'text_event_audio_default_bus', "Master"))


func load_values(settings: ConfigFile, section: String, key: Array):
	for k in key:
		if settings.has_section_key(section, k):
			if nodes[k] is LineEdit:
				nodes[k].text = settings.get_value(section, k)
			elif nodes[k] is OptionButton or nodes[k] is MenuButton:
				nodes[k].text = settings.get_value(section, k)
				if section == 'animations':
					nodes[k].text = DialogicUtil.beautify_filename(nodes[k].text)
			elif nodes[k] is SpinBox:
				nodes[k].value = settings.get_value(section, k)
			else:
				nodes[k].pressed = settings.get_value(section, k, false)


func refresh_themes(settings: ConfigFile):
	# TODO move to theme section later
	nodes['themes'].clear()
	var theme_list = DialogicUtil.get_sorted_theme_list()
	var theme_indexes = {}
	var index = 0
	for theme in theme_list:
		nodes['themes'].add_item(theme['name'])
		nodes['themes'].set_item_metadata(index, {'file': theme['file']})
		theme_indexes[theme['file']] = index
		index += 1
	
	# Only one item added, then save as default
	if index == 1: 
		set_value('theme', 'default', theme_list[0]['file'])
	
	# More than one theme? Select which the default one is
	if index > 1:
		if settings.has_section_key('theme', 'default'):
			nodes['themes'].select(theme_indexes[settings.get_value('theme', 'default', null)])
		else:
			# Fallback
			set_value('theme', 'default', theme_list[0]['file'])







func _on_delay_options_text_changed(text):
	set_value('input', 'delay_after_options', text)


func _on_item_toggled(value: bool, section: String, key: String):
	set_value(section, key, value)


func _on_button_history_button_position_selected(index):
	set_value('history', 'history_button_position', str(index))


func _spinbox_val_changed(newValue :float, spinbox_name):
	set_value('history', spinbox_name, newValue)


func _on_default_action_key_presssed(settingName = 'default_action_key') -> void:
	var settings = DialogicResources.get_settings_config()
	nodes[settingName].clear()
	nodes[settingName].add_item(settings.get_value('input', settingName, 'dialogic_default_action'))
	for prop in ProjectSettings.get_property_list():
		if prop.name.begins_with('input/'):
			nodes[settingName].add_item(prop.name.trim_prefix('input/'))
			

func _on_hotkey_action_key_presssed(settingName = 'choice_hotkey_1') -> void:
	var settings = DialogicResources.get_settings_config()
	nodes[settingName].clear()
	nodes[settingName].add_item(settings.get_value('input', settingName, '[None]'))
	nodes[settingName].add_item('[None]')
	for prop in ProjectSettings.get_property_list():
		if prop.name.begins_with('input/'):
			nodes[settingName].add_item(prop.name.trim_prefix('input/'))
	


func _on_default_action_key_item_selected(index, settingName = 'default_action_key') -> void:
	print(nodes[settingName].text)
	set_value('input', settingName, nodes[settingName].text)


func _on_canvas_layer_text_changed(text) -> void:
	set_value('theme', 'canvas_layer', text)


func _on_text_changed(text, section: String, key: String) -> void:
	set_value(section, key, text)
	#set_value('history', 'history_character_delimiter', text)


# Reading and saving data to the settings file
func set_value(section, key, value):
	DialogicResources.set_settings_value(section, key, value)


func update_bus_selector():
	if nodes["text_event_audio_default_bus"] != null:
		var previous_selected_bus_name = ""
		if nodes["text_event_audio_default_bus"].get_item_count():
			previous_selected_bus_name = nodes["text_event_audio_default_bus"].get_item_text(max(0, nodes["text_event_audio_default_bus"].selected))

		nodes["text_event_audio_default_bus"].clear()
		for i in range(AudioServer.bus_count):
			var bus_name = AudioServer.get_bus_name(i)
			nodes["text_event_audio_default_bus"].add_item(bus_name)

			if previous_selected_bus_name == bus_name:
				nodes["text_event_audio_default_bus"].select(i)


func select_bus(text):
	for item_idx in range(nodes["text_event_audio_default_bus"].get_item_count()):
		if nodes["text_event_audio_default_bus"].get_item_text(item_idx) == text:
			nodes["text_event_audio_default_bus"].select(item_idx)
			return
	nodes["text_event_audio_default_bus"].select(0)


func _on_text_audio_default_bus_item_selected(index):
	var text = nodes['text_event_audio_default_bus'].get_item_text(index)
	set_value('dialog', 'text_event_audio_default_bus', text)


################################################################################
##						CUSTOM EVENT SECTION
################################################################################

func open_custom_event_docs():
	editor_reference.get_node("MainPanel/MasterTreeContainer/MasterTree").select_documentation_item("res://addons/dialogic/Documentation/Content/Events/CustomEvents/CreateCustomEvents.md")


func new_custom_event_pressed():
	nodes['new_custom_event_section'].show()
	nodes['new_custom_event_name'].text = ''
	nodes['new_custom_event_directory'].text = ''
	nodes['new_custom_event_id'].text = ''
	
	nodes['new_custom_event_create'].disabled = true
	$VBoxContainer/HBoxContainer3/VBoxContainer2/CustomEvents/HBoxContainer/Message.text = ""


func custom_event_name_entered(text:String):
	nodes['new_custom_event_directory'].text = text
	
	nodes['new_custom_event_create'].disabled = nodes['new_custom_event_id'].text != ''
	$VBoxContainer/HBoxContainer3/VBoxContainer2/CustomEvents/HBoxContainer/Message.text = ""


func custom_event_id_entered(text):
	if nodes['new_custom_event_name'].text != '':
		nodes['new_custom_event_create'].disabled = false
	$VBoxContainer/HBoxContainer3/VBoxContainer2/CustomEvents/HBoxContainer/Message.text = ""


func cancel_custom_event():
	nodes['new_custom_event_section'].hide()
	$VBoxContainer/HBoxContainer3/VBoxContainer2/CustomEvents/HBoxContainer/Message.text = ""


func create_custom_event():
	# do checks for incomplete input
	if nodes['new_custom_event_directory'].text.empty():
		print('[D] No directory specified!')
		$VBoxContainer/HBoxContainer3/VBoxContainer2/CustomEvents/HBoxContainer/Message.text = "Enter a directory name!"
		return
	if nodes['new_custom_event_name'].text.empty():
		print('[D] No name specified!')
		$VBoxContainer/HBoxContainer3/VBoxContainer2/CustomEvents/HBoxContainer/Message.text = "Enter a event name!"
		return
	if nodes['new_custom_event_id'].text.empty():
		print('[D] No id specified!')
		$VBoxContainer/HBoxContainer3/VBoxContainer2/CustomEvents/HBoxContainer/Message.text = "Enter an id!"
		return
	
	# create new directory
	var dir_name = 'res://dialogic/custom-events/'+nodes['new_custom_event_directory'].text
	var dir = Directory.new()
	if dir.dir_exists(dir_name):
		$VBoxContainer/HBoxContainer3/VBoxContainer2/CustomEvents/HBoxContainer/Message.text = "The folder already exists!"
		print("[D] Custom Events folder '"+nodes['new_custom_event_directory'].text+"' already exists!")
		return
	dir.make_dir(dir_name)
	
	# copy all necessary files
	for file in ['EventBlock.tscn', 'Stylebox.tres', 'EventPart_Example.gd', 'EventPart_Example.tscn', 'event_yourname_000.gd']:
		dir.copy("res://addons/dialogic/Example Assets/CustomEvents/"+file, dir_name+"/"+file)
	
	# Updating the script location of the example
	var scene = load(dir_name+"/EventPart_Example.tscn")
	var scene_instance = scene.instance()
	scene_instance.set_script(load(dir_name+"/EventPart_Example.gd"))
	var packed_scene = PackedScene.new()
	packed_scene.pack(scene_instance)
	ResourceSaver.save(dir_name+"/EventPart_Example.tscn", packed_scene)
	
	# rename the event handler script
	dir.rename(dir_name+'/event_yourname_000.gd', dir_name+'/event_'+nodes['new_custom_event_id'].text+'.gd')
	
	# edit the EventBlock scene
	var event_block_scene = load(dir_name+'/EventBlock.tscn').instance(PackedScene.GEN_EDIT_STATE_INSTANCE)
	event_block_scene.event_name = nodes['new_custom_event_name'].text
	event_block_scene.event_data = {'event_id':nodes['new_custom_event_id'].text}
	event_block_scene.event_icon = load("res://addons/dialogic/Images/Event Icons/Main Icons/custom-event.svg")
	var packed = PackedScene.new()
	packed.pack(event_block_scene)
	ResourceSaver.save(dir_name+'/EventBlock.tscn', packed)
	
	# close the section
	nodes['new_custom_event_section'].hide()
	
	# force godot to show the folder
	editor_reference.editor_interface.get_resource_filesystem().scan()
	$VBoxContainer/HBoxContainer3/VBoxContainer2/CustomEvents/HBoxContainer/Message.text = ""


################
## ANIMATION
################
func _on_AnimationDefault_about_to_show(picker, filter):
	picker.get_popup().clear()
	var animations = DialogicAnimaResources.get_available_animations()
	var idx = 0
	for animation_name in animations:
		if filter in animation_name:
			picker.get_popup().add_icon_item(get_icon("Animation", "EditorIcons"), DialogicUtil.beautify_filename(animation_name.get_file()))
			picker.get_popup().set_item_metadata(idx, {'file': animation_name.get_file()})
			idx +=1

func _on_AnimationDefault_index_pressed(index, picker, key):
	set_value('animations', key, picker.get_popup().get_item_metadata(index)['file'])
	picker.text = picker.get_popup().get_item_text(index)

func _on_AnimationDefaultLength_value_changed(value, key):
	set_value('animations', key, value)


##########
## THEME
##########
func build_PickerMenu():
	nodes['themes'].get_popup().clear()
	var folder_structure = DialogicUtil.get_theme_folder_structure()

	## building the root level
	build_PickerMenuFolder(nodes['themes'].get_popup(), folder_structure, "MenuButton")

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
		nodes['themes'].update_submenu_style(submenu)
		index += 1
	
	var files_info = DialogicUtil.get_theme_dict()
	for file in folder_structure['files']:
		menu.add_item(files_info[file]['name'])
		menu.set_item_icon(index, editor_reference.get_node("MainPanel/MasterTreeContainer/MasterTree").theme_icon)
		menu.set_item_metadata(index, {'file':file})
		index += 1
	
	if not menu.is_connected("index_pressed", self, "_on_ThemePicker_index_pressed"):
		menu.connect("index_pressed", self, '_on_ThemePicker_index_pressed', [menu])
	
	return current_folder_name

func _on_ThemePicker_index_pressed(index, menu):
	nodes['themes'].text = menu.get_item_text(index)
	set_value('theme', 'default', menu.get_item_metadata(index)['file'])
