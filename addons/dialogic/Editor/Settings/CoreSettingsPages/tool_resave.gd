@tool
extends Node

@onready var ToolUtil := get_parent()

var button_text := "Resave all timelines"
var tooltip := "Opens and resaves all timelines. This can be useful if an update introduced a syntax change."
var method := resave_tool


func resave_tool() -> void:
	ToolUtil.tool_progress_mutex.lock()
	ToolUtil.tool_progress = 0
	ToolUtil.tool_progress_mutex.unlock()

	var index := 0
	var timelines := DialogicResourceUtil.get_timeline_directory()
	for timeline_identifier in timelines:
		var timeline := DialogicResourceUtil.get_timeline_resource(timeline_identifier)
		await timeline.process()
		timeline.set_meta("timeline_not_saved", true)
		ResourceSaver.save(timeline)

		ToolUtil.tool_progress_mutex.lock()
		ToolUtil.tool_progress = 1.0/len(timelines)*index
		ToolUtil.tool_progress_mutex.unlock()

		index += 1

	ToolUtil.tool_progress_mutex.lock()
	ToolUtil.tool_progress = 1
	ToolUtil.tool_progress_mutex.unlock()
