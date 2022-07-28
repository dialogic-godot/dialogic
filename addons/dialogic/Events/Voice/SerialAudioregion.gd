tool
extends VBoxContainer

var property_name : String
signal value_changed

func value_changed(_p, value):
	var data:String = ""
	for i in range ($list.get_child_count()):
		var n:Node = $list.get_child(i)
		data += n.get_value() + " "
	print(data)
	emit_signal("value_changed", property_name, data)

func _ready():
	$NumRegions/NumberValue.set_min_value(1)
	$NumRegions/NumberValue.connect("value_changed", self, "_on_NumberValue_value_changed")
	repopulate(1) #Always have at least one audio region


func set_value(value):
	if not value is String:
		printerr("Invalid data - %s (SerialAudioRegion): data incoming is not string." % property_name)
	var data:PoolStringArray = value.split("region", false)
	$NumRegions/NumberValue.set_value(len(data))
	repopulate(len(data))
	for i in range ($list.get_child_count()):
		var n:Node = $list.get_child(i)
		n.set_value(data[i])
#	if not value or not value is Array:
#		return
#	if not value is Array:
#		printerr("Invalid data format")
#		return
#	$NumRegions/NumberValue.set_value(len(value))
#	repopulate(len(value))
#	for i in range ($list.get_child_count()):
#		var n:Node = $list.get_child(i)
#		n.set_value(value[i])

func _on_NumberValue_value_changed(_p, value):
	repopulate(value)

func repopulate(num:int):
	var i = $list.get_child_count()
	#add new audio regions
	while i < num:
		var node:Node = load("res://addons/dialogic/Events/Voice/AudioRegion.tscn").instance()
		$list.add_child(node)
		node.connect("value_changed", self, "value_changed")
		i = i + 1
	#remove excess audio regions
	while i > num:
		$list.get_child(i-1).queue_free()
		i = i - 1
func set_left_text(text):
	$NumRegions/Label.text = text
