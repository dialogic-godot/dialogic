tool
extends ScrollContainer

onready var nodes = {
	'themes': $VBoxContainer/HBoxContainer3/VBoxContainer/VBoxContainer/HBoxContainer/ThemeOptionButton,
	'new_lines': $VBoxContainer/HBoxContainer3/VBoxContainer/VBoxContainer2/HBoxContainer2/NewLines,
	'remove_empty_messages': $VBoxContainer/HBoxContainer3/VBoxContainer/VBoxContainer2/HBoxContainer/RemoveEmptyMessages
}
func _ready():
	update_data()
	
	nodes['themes'].connect('item_selected', self, '_on_default_theme_selected')
	nodes['new_lines'].connect('toggled', self, '_on_new_line_toggled')
	nodes['remove_empty_messages'].connect('toggled', self, '_on_remove_empty_message_toggled')


func update_data():
	var settings = DialogicUtil.get_settings()
	refresh_themes(settings)
	dialog_options(settings)


func dialog_options(settings):
	if settings.has_section_key('dialog', 'remove_empty_messages'):
		nodes['remove_empty_messages'].pressed = settings.get_value('dialog', 'remove_empty_messages')
	if settings.has_section_key('dialog', 'new_lines'):
		nodes['new_lines'].pressed = settings.get_value('dialog', 'new_lines')


func refresh_themes(settings):
	nodes['themes'].clear()
	var theme_list = DialogicUtil.get_theme_list()
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
			nodes['themes'].select(theme_indexes[settings.get_value('theme', 'default')])
		else:
			# Fallback
			set_value('theme', 'default', theme_list[0]['file'])


func _on_default_theme_selected(index):
	set_value('theme', 'default', nodes['themes'].get_item_metadata(index)['file'])


func _on_remove_empty_message_toggled(value):
	set_value('dialog', 'remove_empty_messages', value)


func _on_new_line_toggled(value):
	set_value('dialog', 'new_lines', value)


# Reading and saving data to the settings file
func set_value(section, key, value):
	var config = ConfigFile.new()
	var file = DialogicUtil.get_path('SETTINGS_FILE')
	var err = config.load(file)
	if err == OK:
		config.set_value(section, key, value)
		config.save(file)
