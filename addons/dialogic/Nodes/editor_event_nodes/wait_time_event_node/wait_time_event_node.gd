tool
extends DialogicEditorEventNode

export(NodePath) var TimeLine_path:NodePath

onready var time_line_node := get_node(TimeLine_path)

func _ready() -> void:
	if base_resource:
		_update_node_values()


func _update_node_values() -> void:
	time_line_node.text = str((base_resource as DialogicWaitTimeEvent).wait_time)



func _on_LineEdit_text_changed(new_text: String) -> void:
	var _time = float(new_text)
	if _time <= 0 or _time > 60*60:
		DialogicUtil.Logger.print(self, "Invalid time")
		_time = 0.0
	
	if _time != base_resource.wait_time:
		(base_resource as DialogicWaitTimeEvent).wait_time = _time


func _on_LineEdit_focus_exited() -> void:
	_save_resource()


func _on_LineEdit_text_entered(new_text: String) -> void:
	var _time = float(new_text)
	if _time <= 0 or _time > 60*60:
		DialogicUtil.Logger.print(self, "Invalid time")
		_time = 0.0
	
	if _time != base_resource.wait_time:
		(base_resource as DialogicWaitTimeEvent).wait_time = _time
	_save_resource()
