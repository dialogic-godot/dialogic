tool
extends "res://addons/dialogic/Editor/Events/Templates/EventTemplate.gd"


func _ready():
	event_data = {
		'wait_seconds': 1
	}
	get_header().set_value(float(event_data['wait_seconds']))
	get_header().connect("value_changed", self, "_on_Selector_value_changed")


func load_data(data):
	.load_data(data)
	get_header().set_value(float(event_data['wait_seconds']))


func _on_Selector_value_changed(value):
	event_data['wait_seconds'] = value
