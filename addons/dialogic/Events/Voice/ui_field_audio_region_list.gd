@tool
extends VBoxContainer

var property_name : String
signal value_changed

func on_value_changed(_p, value):
	var data:String = ""
	for i in range ($list.get_child_count()):
		var n:Node = $list.get_child(i)
		data += n.get_value() + " "
	#print(data)
	emit_signal("value_changed", property_name, data)

func _ready():
	$NumRegions/NumberValue.set_min_value(1)
	$NumRegions/NumberValue.value_changed.connect(_on_NumberValue_value_changed)
	if($list.get_child_count() < 1):
		repopulate(1) #Always have at least one audio region


func set_value(value):
	if value == null:
		return
	if not value is String:
		printerr("Invalid data - %s (SerialAudioRegion): data incoming is not string." % property_name)
	var data:PackedStringArray = value.split("region", false)
	$NumRegions/NumberValue.set_value(len(data))
	repopulate(len(data))
	for i in range ($list.get_child_count()):
		var n:Node = $list.get_child(i)
		n.set_value(data[i])

func _on_NumberValue_value_changed(_p, value):
	repopulate(value)

func repopulate(num:int):
	var i = $list.get_child_count()
	#print ("found " + str(i) + " nodes")
	#add new audio regions
	while i < num:
		#print("adding node number " + str(i))
		var node = load("res://addons/dialogic/Events/Voice/ui_field_audio_region.tscn").instantiate()
		$list.add_child(node)
		#node.set_left_text("| " + str(i) + " Start")
		node.value_changed.connect(on_value_changed)
		i = i + 1
	#remove excess audio regions
	#print(str(i) + ">" + str(num) + "=" + str(i > num))
	while i > num:
		$list.get_child(i-1).queue_free()
		#print("removing node number " + str(i))
		i = i - 1

func set_left_text(text):
	$NumRegions/Label.text = text
