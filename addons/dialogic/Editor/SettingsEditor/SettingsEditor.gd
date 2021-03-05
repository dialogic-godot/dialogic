tool
extends ScrollContainer

onready var nodes = {
	'themes': $VBoxContainer/HBoxContainer/ThemeOptionButton
}

func _ready():
	update_data()
	
	nodes['themes'].connect('item_selected', self, '_on_default_theme_selected')


func update_data():
	refresh_themes()


func refresh_themes():
	nodes['themes'].clear()
	var settings = DialogicUtil.get_settings()
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


# Reading and saving data to the settings file
func set_value(section, key, value):
	var config = ConfigFile.new()
	var file = DialogicUtil.get_path('SETTINGS_FILE')
	var err = config.load(file)
	if err == OK:
		config.set_value(section, key, value)
		config.save(file)
