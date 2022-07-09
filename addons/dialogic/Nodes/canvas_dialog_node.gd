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
signal text_complete(text_event)
# Custom user signal
signal dialogic_signal(value)
signal letter_displayed(lastLetter)

var _dialog_node_scene = load("res://addons/dialogic/Nodes/DialogNode.tscn")
var dialog_node = null


func set_dialog_node_scene(scene) -> void:
	_dialog_node_scene = scene
	dialog_node = _dialog_node_scene.instance()
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
		_err = dialog_node.connect("text_complete", self, "_on_text_complete")
		assert(_err == OK)
		_err = dialog_node.connect("dialogic_signal", self, "_on_dialogic_signal")
		assert(_err == OK)
		_err = dialog_node.connect("letter_displayed", self, "_on_letter_displayed")
		assert(_err == OK)

func _enter_tree() -> void:  
	if dialog_node:
		add_child(dialog_node)
		dialog_node.connect('tree_exited', self, 'dialog_finished')

func dialog_finished():
	queue_free()


func _ready() -> void:
	# change the canvas layer
	var config = DialogicResources.get_settings_config()	
	layer = int(config.get_value("theme", "canvas_layer", 1))
	
	


func _on_event_start(type, event) -> void:
	emit_signal("event_start", type, event)


func _on_event_end(type) -> void:
	emit_signal("event_end", type)


func _on_timeline_start(timeline_name) -> void:
	emit_signal("timeline_start", timeline_name)


func _on_timeline_end(timeline_name) -> void:
	emit_signal("timeline_end", timeline_name)


func _on_text_complete(text_event) -> void:
	emit_signal("text_complete", text_event)


func _on_dialogic_signal(value) -> void:
	emit_signal("dialogic_signal", value)


func _on_letter_displayed(last_letter):
	emit_signal("letter_displayed", last_letter)
