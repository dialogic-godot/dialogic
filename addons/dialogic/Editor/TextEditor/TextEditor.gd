@tool
extends CodeEdit

var current_timeline: DialogicTimeline

func _ready():
	DialogicUtil.get_dialogic_plugin().dialogic_save.connect(save_timeline)
	add_highlighting()


func clear_timeline():
	text = ''


func load_timeline(object:DialogicTimeline) -> void:
	clear_timeline()
	current_timeline = object
	get_parent().get_node('Toolbar').load_timeline(current_timeline.resource_path)
	
	text = TimelineUtil.events_to_text(object._events)


func save_timeline():
	if !visible:
		return
	
	if current_timeline:
		current_timeline._events = TimelineUtil.text_to_events(text)
		ResourceSaver.save(current_timeline)


func add_highlighting():
	# This is a dumpster fire, so hopefully it will be improved during beta?
	var editor_settings = DialogicUtil.get_dialogic_plugin().editor_interface.get_editor_settings()
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


func new_timeline() -> void:
	save_timeline()
	clear_timeline()
	show_save_dialog()


func show_save_dialog():
	find_parent('EditorView').godot_file_dialog(
		create_and_save_new_timeline,
		'*.dtl; DialogicTimeline',
		EditorFileDialog.FILE_MODE_SAVE_FILE,
		"Save new Timeline",
		"New_Timeline",
		true
	)

func create_and_save_new_timeline(path):
	var new_timeline = DialogicTimeline.new()
	new_timeline.resource_path = path
	current_timeline = new_timeline
	save_timeline()
	DialogicUtil.get_dialogic_plugin().editor_interface.get_resource_filesystem().update_file(path)
	load_timeline(new_timeline)
