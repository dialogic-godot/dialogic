@tool
extends CodeEdit

#var current_timeline: DialogicTimeline

#var editor_reference = null

#@onready var _toolbar = get_parent().get_parent().get_node('Toolbar')

func _ready():
	DialogicUtil.get_dialogic_plugin().dialogic_save.connect(save_timeline)
#	if find_parent('EditorView'): # This prevents the view to turn black if you are editing this scene in Godot
#		editor_reference = find_parent('EditorView')
	add_highlighting()


func _on_text_editor_text_changed():
	get_parent().current_resource_state = DialogicEditor.ResourceStates.Unsaved


func clear_timeline():
	text = ''


func load_timeline(object:DialogicTimeline) -> void:
	clear_timeline()
#	current_timeline = object
	if get_parent().current_resource.events.size() == 0:
		pass
	else: 
		if typeof(get_parent().current_resource.events[0]) == TYPE_STRING:
			get_parent().current_resource.events_processed = false
			get_parent().current_resource = get_parent().editors_manager.resource_helper.process_timeline(get_parent().current_resource)
	
#	get_parent().get_parent().get_node('Toolbar').load_timeline(get_parent().current_resource.resource_path)
	
	#text = TimelineUtil.events_to_text(object.events)
	var result:String = ""	
	var indent := 0
	for idx in range(0, len(object.events)):
		var event = object.events[idx]
		
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
	get_parent().current_resource.set_meta("timeline_not_saved", false)


func save_timeline():
	if get_parent().current_resource:
			# The translations need this to be actual Events, so we do a few steps of conversion here
			
			var text_array:Array = text_timeline_to_array(text)
			get_parent().current_resource.events = text_array
			
			# Build new processed timeline for the ResourceSaver to use
			# ResourceSaver needs a DialogicEvents timeline so the translation builder can run
			get_parent().current_resource.events_processed = false
			get_parent().editors_manager.resource_helper.process_timeline(get_parent().current_resource)
			get_parent().current_resource.events_processed = false		
			ResourceSaver.save(get_parent().current_resource, get_parent().current_resource.resource_path)
			
			#Switch back to the text event array, in case we're switching editor modes
			get_parent().current_resource.events = text_array
			get_parent().current_resource.set_meta("timeline_not_saved", false)
			get_parent().current_resource_state = DialogicEditor.ResourceStates.Saved
			get_parent().editors_manager.resource_helper.rebuild_timeline_directory()
		


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

#
#func new_timeline() -> void:
#	save_timeline()
#	clear_timeline()
#	show_save_dialog()

#
#func show_save_dialog():
#	find_parent('EditorView').godot_file_dialog(
#		create_and_save_new_timeline,
#		'*.dtl; DialogicTimeline',
#		EditorFileDialog.FILE_MODE_SAVE_FILE,
#		"Save new Timeline",
#		"New_Timeline",
#		true
#	)
#
#func create_and_save_new_timeline(path):
#	var new_timeline = DialogicTimeline.new()
#	new_timeline.resource_path = path
#	current_timeline = new_timeline
#	save_timeline()
#	DialogicUtil.get_dialogic_plugin().editor_interface.get_resource_filesystem().update_file(path)
#	load_timeline(new_timeline)

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



