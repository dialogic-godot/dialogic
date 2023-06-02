@tool
extends Node

func replace(what: String, forwhat: String, timelines: Array):
    for timeline in timelines:
        _replace(what, forwhat, timeline)

func _replace(what: String, forwhat: String, timeline: DialogicTimeline):
    var file = FileAccess.open(timeline.resource_path, FileAccess.READ)
    var content = file.get_as_text()

    content = content.replace(what, forwhat)

    file = FileAccess.open(timeline.resource_path, FileAccess.WRITE)
    file.store_string(content)