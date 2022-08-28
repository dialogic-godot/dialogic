@tool
extends CodeEdit

var current_timeline: DialogicTimeline

var editor_reference = null

func _ready():
	DialogicUtil.get_dialogic_plugin().dialogic_save.connect(save_timeline)
	if find_parent('EditorView'): # This prevents the view to turn black if you are editing this scene in Godot
		editor_reference = find_parent('EditorView')
	add_highlighting()


func clear_timeline():
	text = ''


func load_timeline(object:DialogicTimeline) -> void:
	clear_timeline()
	current_timeline = object
	if current_timeline._events_processed == false:
		current_timeline = editor_reference.process_timeline(current_timeline)
	get_parent().get_node('Toolbar').load_timeline(current_timeline.resource_path)
	
	#text = TimelineUtil.events_to_text(object._events)
	var result:String = ""	
	var indent := 0
	for idx in range(0, len(object._events)):
		var event = object._events[idx]
		
		if event['event_name'] == 'End Branch':
			indent -= 1
			continue
		
		if event != null:
			result += "\t".repeat(indent)+event['event_node_as_text'].replace('\n', "\n"+"\t".repeat(indent)) + "\n"
		if event.can_contain_events:
			indent += 1
		if indent < 0: indent = 0
		result += "\t".repeat(indent)+"\n"
		
	text = result


func save_timeline():
	if !visible:
		return
	
	if current_timeline:
		# The translations need this to be actual Events, so we do a few steps of conversion here
		current_timeline._events = text_timeline_to_array(text)
		
		#set as false the first time, so the processor can parse it
		current_timeline._events_processed = false
		editor_reference.process_timeline(current_timeline)
		
		#set back as false again so the saver knows it's ready to use
		current_timeline._events_processed = false
		
		ResourceSaver.save(current_timeline, current_timeline.resource_path)


func add_highlighting():
	# This is a dumpster fire, so hopefully it will be improved during beta?
	var editor_settings = DialogicUtil.get_dialogic_plugin().editor_interface.get_editor_settings()
	var s := CodeHighlighter.new()
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
	s.function_color = editor_settings.get('text_editor/theme/highlighting/text_color')
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

func text_timeline_to_array(text:String) -> Array:
	# Parse the lines down into an array
	var prev_indent := ""
	var events := []
	
	# this is needed to add a end branch event even to empty conditions/choices
	var prev_was_opener := false
	
	var lines := text.split('\n', true)
	var idx := -1
	
	while idx < len(lines)-1:
		idx += 1
		var line :String = lines[idx]
		var line_stripped :String = line.strip_edges(true, true)
		if !line_stripped.is_empty():
			events.append(line)
		
	return events
