@tool
extends CodeEdit

var _current_timeline

func _ready():
	add_highlighting()


func clear_timeline():
	text = ''


func load_timeline(object) -> void:
	clear_timeline()
	_current_timeline = object
	get_parent().get_node('Toolbar').load_timeline(_current_timeline.resource_path)
	var file = File.new()
	file.open(_current_timeline.resource_path, File.READ)
	text = file.get_as_text()
	file.close()


func save_timeline():
	# Since i'm not using the resource loader to save the timelines from text
	# This should probably notify the editor to reimport the file with the new changes
	var file = File.new()
	file.open(_current_timeline.resource_path, File.WRITE)
	file.store_string(text)
	file.close()


func add_highlighting():
	var editor_settings = DialogicUtil.get_dialogic_plugin().get_editor_interface().get_editor_settings()
	var s = CodeHighlighter.new()
	s.color_regions = {
		'[ ]': editor_settings.get('text_editor/theme/highlighting/function_color'),
		'< >': editor_settings.get('text_editor/theme/highlighting/function_color'),
		'" "': editor_settings.get('text_editor/theme/highlighting/string_color'),
		'{ }': editor_settings.get('text_editor/theme/highlighting/engine_type_color'),
	}
	#s.keyword_colors = {
	#	'jump': Color('#00abc7')
	#}
	s.symbol_color = editor_settings.get('text_editor/theme/highlighting/text_color')
	s.number_color = editor_settings.get('text_editor/theme/highlighting/text_color')
	s.member_variable_color = editor_settings.get('text_editor/theme/highlighting/text_color')
	
	s.add_color_region('- ', '', editor_settings.get('text_editor/theme/highlighting/engine_type_color'), true)
	set('syntax_highlighter', s)
