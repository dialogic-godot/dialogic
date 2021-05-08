tool
extends ScrollContainer

onready var nodes = {
	'themes': $VBoxContainer/HBoxContainer3/VBoxContainer/VBoxContainer/HBoxContainer/ThemeOptionButton,
	'advanced_themes': $VBoxContainer/HBoxContainer3/VBoxContainer/VBoxContainer/HBoxContainer2/AdvancedThemes,
	'translations': $VBoxContainer/HBoxContainer3/VBoxContainer/VBoxContainer2/HBoxContainer6/Translations,
	'new_lines': $VBoxContainer/HBoxContainer3/VBoxContainer/VBoxContainer2/HBoxContainer2/NewLines,
	'remove_empty_messages': $VBoxContainer/HBoxContainer3/VBoxContainer/VBoxContainer2/HBoxContainer/RemoveEmptyMessages,
	'auto_color_names': $VBoxContainer/HBoxContainer3/VBoxContainer/VBoxContainer2/HBoxContainer3/AutoColorNames,
	'propagate_input': $VBoxContainer/HBoxContainer3/VBoxContainer/VBoxContainer2/HBoxContainer4/PropagateInput,
	'dim_characters': $VBoxContainer/HBoxContainer3/VBoxContainer/VBoxContainer2/HBoxContainer5/DimCharacters,
	'save_current_timeline': $VBoxContainer/HBoxContainer3/VBoxContainer/VBoxContainer3/HBoxContainer/SaveCurrentTimeline,
	'clear_current_timeline': $VBoxContainer/HBoxContainer3/VBoxContainer/VBoxContainer3/HBoxContainer2/ClearCurrentTimeline,
	'save_definitions_on_start': $VBoxContainer/HBoxContainer3/VBoxContainer/VBoxContainer3/HBoxContainer3/SaveDefinitionsOnStart,
	'save_definitions_on_end': $VBoxContainer/HBoxContainer3/VBoxContainer/VBoxContainer3/HBoxContainer4/SaveDefinitionsOnEnd,
}

var THEME_KEYS := [
	'advanced_themes',
	]

var DIALOG_KEYS := [
	'translations',
	'new_lines', 
	'remove_empty_messages',
	'auto_color_names',
	'propagate_input',
	'dim_characters',
	]

var SAVING_KEYS := [
	'save_current_timeline', 
	'clear_current_timeline',
	'save_definitions_on_start',
	'save_definitions_on_end',
	]

func _ready():
	update_data()
	
	# Themes
	nodes['themes'].connect('item_selected', self, '_on_default_theme_selected')
	# TODO move to theme section later
	nodes['advanced_themes'].connect('toggled', self, '_on_item_toggled', ['dialog', 'advanced_themes'])
	
	for k in DIALOG_KEYS:
		nodes[k].connect('toggled', self, '_on_item_toggled', ['dialog', k])
	
	for k in SAVING_KEYS:
		nodes[k].connect('toggled', self, '_on_item_toggled', ['saving', k])


func update_data():
	var settings = DialogicResources.get_settings_config()
	refresh_themes(settings)
	load_values(settings, "dialog")
	load_values(settings, "saving")


func load_values(settings: ConfigFile, section: String):
	for k in DIALOG_KEYS:
		if settings.has_section_key(section, k):
			nodes[k].pressed = settings.get_value(section, k)


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


func _on_item_toggled(value: bool, section: String, key: String):
	set_value(section, key, value)


# Reading and saving data to the settings file
func set_value(section, key, value):
	DialogicResources.set_settings_value(section, key, value)
