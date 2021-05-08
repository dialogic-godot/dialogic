extends CanvasLayer

## Mirror node to Dialogic node that duplicate its signals
## and had a reference to that Dialogic node

# Copied
# Event end/start
signal event_start(type, event)
signal event_end(type)
# Timeline end/start
signal timeline_start(timeline_name)
signal timeline_end(timeline_name)
# Custom user signal
signal dialogic_signal(value)


var _dialog_node_scene = load("res://addons/dialogic/Dialog.tscn")
var dialog_node = null


func set_dialog_node_scene(scene) -> void:
	_dialog_node_scene = scene
	dialog_node = _dialog_node_scene.instance()
  

func _enter_tree() -> void:  
	if dialog_node:
		add_child(dialog_node)
		dialog_node.connect('tree_exited', self, 'dialog_finished')


func dialog_finished():
	queue_free()


func _ready() -> void:
	var _err:int
	if dialog_node:
		_err = dialog_node.connect("event_start", self, "_on_event_start")
		assert(_err == OK)
		_err = dialog_node.connect("event_end", self, "_on_event_end")
		assert(_err == OK)
		_err = dialog_node.connect("timeline_start", self, "_on_timeline_start")
		assert(_err == OK)
		_err = dialog_node.connect("timeline_end", self, "_on_timeline_end")
		assert(_err == OK)
		_err = dialog_node.connect("dialogic_signal", self, "_on_dialogic_signal")
		assert(_err == OK)


func _on_event_start(type, event) -> void:
  emit_signal("event_start", type, event)


func _on_event_end(type) -> void:
  emit_signal("event_end", type)


func _on_timeline_start(timeline_name) -> void:
  emit_signal("timeline_start", timeline_name)


func _on_timeline_end(timeline_name) -> void:
  emit_signal("timeline_end", timeline_name)


func _on_dialogic_signal(value) -> void:
  emit_signal("dialogic_signal", value)
