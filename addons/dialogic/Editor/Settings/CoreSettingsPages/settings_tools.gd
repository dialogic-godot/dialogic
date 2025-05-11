@tool
extends Node

var tool_thread : Thread
var tool_progress := 1.0
var tool_progress_mutex : Mutex
signal tool_finished_signal


func _ready() -> void:
	for button in %ToolButtons.get_children():
		button.queue_free()

	for i in get_children():
		var button := Button.new()
		button.text = i.button_text
		button.tooltip_text = i.tooltip
		button.pressed.connect(execute_tool.bind(i.method))
		%ToolButtons.add_child(button)


func execute_tool(method:Callable) -> void:
	for button in %ToolButtons.get_children():
		button.disabled = true

	var prev_timeline := close_active_timeline()
	await get_tree().process_frame
	if tool_thread and tool_thread.is_alive():
		tool_thread.wait_to_finish()

	tool_thread = Thread.new()
	tool_progress_mutex = Mutex.new()
	tool_thread.start(method)

	await tool_finished_signal
	silently_open_timeline(prev_timeline)
	for button in %ToolButtons.get_children():
		button.disabled = false


func _process(_delta: float) -> void:
	if (tool_thread and tool_thread.is_alive()) or %ToolProgress.value < 1:
		if tool_progress_mutex: tool_progress_mutex.lock()
		%ToolProgress.value = tool_progress
		if tool_progress_mutex: tool_progress_mutex.unlock()
		%ToolProgress.show()
		if %ToolProgress.value == 1:
			tool_finished_signal.emit()
			%ToolProgress.hide()


func _exit_tree() -> void:
	if tool_thread:
		tool_thread.wait_to_finish()



#region HELPERS

## Closes the current timeline in the Dialogic Editor and returns the timeline
## as a resource.
## If no timeline has been opened, returns null.
func close_active_timeline() -> Resource:
	var timeline_node: DialogicEditor = get_parent().settings_editor.editors_manager.editors['Timeline']['node']
	# We will close this timeline to ensure it will properly update.
	# By saving this reference, we can open it again.
	var current_timeline := timeline_node.current_resource
	# Clean the current editor, this will also close the timeline.
	get_parent().settings_editor.editors_manager.clear_editor(timeline_node, true)

	return current_timeline


## Opens the timeline resource into the Dialogic Editor.
## If the timeline is null, does nothing.
func silently_open_timeline(timeline_to_open: Resource) -> void:
	if timeline_to_open != null:
		get_parent().settings_editor.editors_manager.edit_resource(timeline_to_open, true, true)

#endregion
