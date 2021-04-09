tool
class_name DialogicTextEventResource
extends DialogicEventResource

const EventTimer = preload("res://addons/dialogic/Nodes/TextEventTimer.gd")

export(String, MULTILINE) var text:String = ""
export(Resource) var character = DialogicCharacterResource.new()

var _caller = null
var _timer = null

func excecute(caller:Control) -> void:
	.excecute(caller)
	
	_caller = caller
	_timer = EventTimer.new()
	_timer.caller = _caller
	_caller.add_child(_timer)
	if not _timer.is_connected("timeout", self, "_on_TextTimer_timeout"):
		var _err = _timer.connect("timeout", self, "_on_TextTimer_timeout")
		if _err != OK:
			print_debug(_err)

	caller.visible = true
	
	_update_text()
	
	if not character.name:
		# Default speaker should be displayed here
		character = DialogicCharacterResource.new()

	_update_name()


func _update_text() -> void:
	if "TextNode" in _caller:
		_caller.TextNode.bbcode_text = text
		_caller.TextNode.visible_characters = 0
		_timer.start(_caller.text_speed)


func _update_name() -> void:
	if "NameNode" in _caller:
		_caller.NameNode.text = character.display_name
		_caller.NameNode.set('custom_colors/font_color', character.color)


func _on_TextTimer_timeout():
	(_caller.TextNode as RichTextLabel).visible_characters += 1
	if _caller.TextNode.visible_characters < _caller.TextNode.get_total_character_count():
		_timer.start(_caller.text_speed)
	else:
		_timer.stop()
		_timer.queue_free()
		finish()

func get_event_editor_node() -> Control:
	var _instance = load("res://addons/dialogic/Nodes/editor_event_nodes/text_event_node/text_event_node.tscn").instance()
	_instance.base_resource = self
	return _instance
