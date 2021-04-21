tool
extends ScrollContainer

onready var nodes = {
	'themes': $VBoxContainer/HBoxContainer3/VBoxContainer/VBoxContainer/HBoxContainer/ThemeOptionButton,
	'new_lines': $VBoxContainer/HBoxContainer3/VBoxContainer/VBoxContainer2/HBoxContainer2/NewLines,
	'remove_empty_messages': $VBoxContainer/HBoxContainer3/VBoxContainer/VBoxContainer2/HBoxContainer/RemoveEmptyMessages,
	'auto_color_names': $VBoxContainer/HBoxContainer3/VBoxContainer/VBoxContainer2/HBoxContainer3/AutoColorNames,
	'propagate_input': $VBoxContainer/HBoxContainer3/VBoxContainer/VBoxContainer2/HBoxContainer4/PropagateInput,
	'dim_characters': $VBoxContainer/HBoxContainer3/VBoxContainer/VBoxContainer2/HBoxContainer5/DimCharacters,
	'advanced_themes': $VBoxContainer/HBoxContainer3/VBoxContainer/VBoxContainer2/HBoxContainer6/AdvancedThemes,
}


func _ready():
	update_data()
	
	nodes['themes'].connect('item_selected', self, '_on_default_theme_selected')
	nodes['new_lines'].connect('toggled', self, '_on_new_line_toggled')
	nodes['remove_empty_messages'].connect('toggled', self, '_on_remove_empty_message_toggled')
	nodes['auto_color_names'].connect('toggled', self, '_on_auto_color_names_toggled')
	nodes['propagate_input'].connect('toggled', self, '_on_propagate_input_toggled')
	nodes['dim_characters'].connect('toggled', self, '_on_dim_characters_toggled')
	nodes['advanced_themes'].connect('toggled', self, '_on_advanced_themes_toggled')


func update_data():
	var settings = DialogicResources.get_settings_config()
	refresh_themes(settings)
	dialog_options(settings)


func dialog_options(settings):
	if settings.has_section_key('dialog', 'remove_empty_messages'):
		nodes['remove_empty_messages'].pressed = settings.get_value('dialog', 'remove_empty_messages')
	if settings.has_section_key('dialog', 'new_lines'):
		nodes['new_lines'].pressed = settings.get_value('dialog', 'new_lines')
	if settings.has_section_key('dialog', 'auto_color_names'):
		nodes['auto_color_names'].pressed = settings.get_value('dialog', 'auto_color_names')
	if settings.has_section_key('dialog', 'propagate_input'):
		nodes['propagate_input'].pressed = settings.get_value('dialog', 'propagate_input')
	if settings.has_section_key('dialog', 'dim_characters'):
		nodes['dim_characters'].pressed = settings.get_value('dialog', 'dim_characters')
	if settings.has_section_key('dialog', 'advanced_themes'):
		nodes['advanced_themes'].pressed = settings.get_value('dialog', 'advanced_themes')


func refresh_themes(settings):
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


func _on_remove_empty_message_toggled(value):
	set_value('dialog', 'remove_empty_messages', value)


func _on_new_line_toggled(value):
	set_value('dialog', 'new_lines', value)


func _on_auto_color_names_toggled(value):
	set_value('dialog', 'auto_color_names', value)


func _on_propagate_input_toggled(value):
	set_value('dialog', 'propagate_input', value)


func _on_dim_characters_toggled(value):
	set_value('dialog', 'dim_characters', value)


func _on_advanced_themes_toggled(value):
	set_value('dialog', 'advanced_themes', value)


# Reading and saving data to the settings file
func set_value(section, key, value):
	DialogicResources.set_settings_value(section, key, value)
