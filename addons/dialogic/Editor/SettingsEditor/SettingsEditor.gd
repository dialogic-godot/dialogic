tool
extends ScrollContainer

var editor_reference

onready var nodes = {
	# Theme
	'themes': $VBoxContainer/HBoxContainer3/VBoxContainer/VBoxContainer/HBoxContainer/ThemeOptionButton,
	'advanced_themes': $VBoxContainer/HBoxContainer3/VBoxContainer/VBoxContainer/HBoxContainer2/AdvancedThemes,
	'canvas_layer' : $VBoxContainer/HBoxContainer3/VBoxContainer/VBoxContainer/HBoxContainer3/CanvasLayer,
	
	# Dialog
	'new_lines': $VBoxContainer/HBoxContainer3/VBoxContainer/VBoxContainer2/HBoxContainer2/NewLines,
	'remove_empty_messages': $VBoxContainer/HBoxContainer3/VBoxContainer/VBoxContainer2/HBoxContainer/RemoveEmptyMessages,
	'auto_color_names': $VBoxContainer/HBoxContainer3/VBoxContainer/VBoxContainer2/HBoxContainer3/AutoColorNames,
	'propagate_input': $VBoxContainer/HBoxContainer3/VBoxContainer/VBoxContainer2/HBoxContainer4/PropagateInput,
	'dim_characters': $VBoxContainer/HBoxContainer3/VBoxContainer/VBoxContainer2/HBoxContainer5/DimCharacters,
	'text_event_audio_enable': $VBoxContainer/HBoxContainer3/VBoxContainer/VBoxContainer2/HBoxContainer7/EnableVoices,
	'text_event_audio_default_bus' : $VBoxContainer/HBoxContainer3/VBoxContainer/VBoxContainer2/TextAudioDefaultBus/AudioBus,
	'translations': $VBoxContainer/HBoxContainer3/VBoxContainer/VBoxContainer2/HBoxContainer6/Translations,
	
	# Save
	'autosave': $VBoxContainer/HBoxContainer3/VBoxContainer/VBoxContainer3/HBoxContainer/Autosave,
	
	# Input Settings
	'delay_after_options': $VBoxContainer/HBoxContainer3/VBoxContainer2/VBoxContainer/HBoxContainer/LineEdit,
	'default_action_key': $VBoxContainer/HBoxContainer3/VBoxContainer2/VBoxContainer/HBoxContainer2/DefaultActionKey,
	'new_custom_event_open':$VBoxContainer/HBoxContainer3/VBoxContainer2/CustomEvents/HBoxContainer/NewCustomEvent, 
	'new_custom_event_section': $VBoxContainer/HBoxContainer3/VBoxContainer2/CustomEvents/CreateCustomEventSection, 
	'new_custom_event_name': $VBoxContainer/HBoxContainer3/VBoxContainer2/CustomEvents/CreateCustomEventSection/CeName,
	'new_custom_event_directory': $VBoxContainer/HBoxContainer3/VBoxContainer2/CustomEvents/CreateCustomEventSection/CeDirectory,
	'new_custom_event_id': $VBoxContainer/HBoxContainer3/VBoxContainer2/CustomEvents/CreateCustomEventSection/CeEventId,
	'new_custom_event_create':$VBoxContainer/HBoxContainer3/VBoxContainer2/CustomEvents/CreateCustomEventSection/HBoxContainer/CreateCustomEvent,
	'new_custom_event_cancel':$VBoxContainer/HBoxContainer3/VBoxContainer2/CustomEvents/CreateCustomEventSection/HBoxContainer/CancelCustomEvent,
	}

var THEME_KEYS := [
	'advanced_themes',
	'canvas_layer',
	]

var INPUT_KEYS := [
	'delay_after_options',
	'default_action_key'
	]

var DIALOG_KEYS := [
	'translations',
	'new_lines', 
	'remove_empty_messages',
	'auto_color_names',
	'propagate_input',
	'dim_characters',
	'text_event_audio_enable',
	]

var SAVING_KEYS := [
	'autosave', 
	]

func _ready():
	editor_reference = find_parent('EditorView')
	update_bus_selector()
	
	update_data()
	
	# Themes
	nodes['themes'].connect('item_selected', self, '_on_default_theme_selected')
	nodes['delay_after_options'].connect('text_changed', self, '_on_delay_options_text_changed')
	# TODO move to theme section later
	nodes['advanced_themes'].connect('toggled', self, '_on_item_toggled', ['dialog', 'advanced_themes'])
	nodes['canvas_layer'].connect('text_changed', self, '_on_canvas_layer_text_changed')

	nodes['default_action_key'].connect('pressed', self, '_on_default_action_key_presssed')
	nodes['default_action_key'].connect('item_selected', self, '_on_default_action_key_item_selected')
	
	AudioServer.connect("bus_layout_changed", self, "update_bus_selector")
	nodes['text_event_audio_default_bus'].connect('item_selected', self, '_on_text_audio_default_bus_item_selected')
	
	for k in DIALOG_KEYS:
		nodes[k].connect('toggled', self, '_on_item_toggled', ['dialog', k])
	
	for k in SAVING_KEYS:
		nodes[k].connect('toggled', self, '_on_item_toggled', ['saving', k])
		
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
	

func update_data():
	var settings = DialogicResources.get_settings_config()
	nodes['canvas_layer'].text = settings.get_value("theme", "canvas_layer", '1')
	refresh_themes(settings)
	load_values(settings, "dialog", DIALOG_KEYS)
	load_values(settings, "saving", SAVING_KEYS)
	load_values(settings, "input", INPUT_KEYS)
	select_bus(settings.get_value("dialog", 'text_event_audio_default_bus', "Master"))

func load_values(settings: ConfigFile, section: String, key: Array):
	for k in key:
		if settings.has_section_key(section, k):
			if nodes[k] is LineEdit:
				nodes[k].text = settings.get_value(section, k)
			else:
				if k == 'default_action_key':
					nodes['default_action_key'].text = settings.get_value(section, k)
				else:
					nodes[k].pressed = settings.get_value(section, k, false)


func refresh_themes(settings: ConfigFile):
	# TODO move to theme section later
	if settings.has_section_key('dialog', 'advanced_themes'):
		nodes['advanced_themes'].pressed = settings.get_value('dialog', 'advanced_themes')
	
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


func _on_default_theme_selected(index):
	set_value('theme', 'default', nodes['themes'].get_item_metadata(index)['file'])


func _on_delay_options_text_changed(text):
	set_value('input', 'delay_after_options', text)


func _on_item_toggled(value: bool, section: String, key: String):
	set_value(section, key, value)


func _on_default_action_key_presssed() -> void:
	var settings = DialogicResources.get_settings_config()
	nodes['default_action_key'].clear()
	nodes['default_action_key'].add_item(settings.get_value('input', 'default_action_key', '[Default]'))
	nodes['default_action_key'].add_item('[Default]')
	InputMap.load_from_globals()
	for a in InputMap.get_actions():
		nodes['default_action_key'].add_item(a)


func _on_default_action_key_item_selected(index) -> void:
	set_value('input', 'default_action_key', nodes['default_action_key'].text)


func _on_canvas_layer_text_changed(text) -> void:
	set_value('theme', 'canvas_layer', text)


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
	editor_reference.get_node("MainPanel/MasterTreeContainer/MasterTree").select_documentation_item("res://addons/dialogic/Documentation/Content/Events/Custom Events/CreateCustomEvents.md")

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
	
	# rename the event handler script
	dir.rename(dir_name+'/event_yourname_000.gd', dir_name+'/event_'+nodes['new_custom_event_id'].text+'.gd')
	
	# edit the EventBlock scene
	var event_block_scene = load(dir_name+'/EventBlock.tscn').instance(PackedScene.GEN_EDIT_STATE_INSTANCE)
	event_block_scene.event_name = nodes['new_custom_event_name'].text
	event_block_scene.event_data = {'event_id':nodes['new_custom_event_id'].text}
	event_block_scene.event_style = load(dir_name+"/Stylebox.tres")
	event_block_scene.event_icon = load("res://addons/dialogic/Images/Event Icons/Main Icons/custom-event.svg")
	var packed = PackedScene.new()
	packed.pack(event_block_scene)
	ResourceSaver.save(dir_name+'/EventBlock.tscn', packed)
	
	# close the section
	nodes['new_custom_event_section'].hide()
	
	# force godot to show the folder
	editor_reference.editor_interface.get_resource_filesystem().scan()
	$VBoxContainer/HBoxContainer3/VBoxContainer2/CustomEvents/HBoxContainer/Message.text = ""
