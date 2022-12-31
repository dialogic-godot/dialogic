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
	$NumRegions/Fromfile.connect("pressed", on_request_clipboard)

func on_request_clipboard():
	#getting clipboard
	var clip:String = DisplayServer.clipboard_get()
	#testing for native value
	var result:String = _test_value(clip)
	if !result.is_empty():
		set_value(result)
		return
	#testing for audacity label format
	result = _test_value(audacity_label_translater(clip))
	if !result.is_empty():
		set_value(result)
		return
	
	#no other known formats to test. Function failed. No value set from clipboard.
	return

func audacity_label_translater(input:String):
	var result:String = ""
	#audacity label standard format is line-seperated per label
	var lines:PackedStringArray = input.split("\n", false)
	for l in lines:
		#then tab seperated per value
		var v = l.split("\t", false)
		#A valid label has two float values, nothing before, then an optional name field (that we ignore)
		#if number of values are less than 2, or if values 0 and 1 are not floats
		#Then the line invalid. This will be expected for a label using extended format.
		#In that case, ignore the line. Do not cancel.
		if len(v) < 2 || !v[0].is_valid_float() || !v[1].is_valid_float():
			continue
		result += "region start at %s, stop at %s "%[v[0], v[1]]
		
	if !result.is_empty():
		result = '"'+result+'"' #this may be silly, but it's so the regex will recognize it.
	return result
	
func _test_value(input)->String:
	var regex:RegEx = RegEx.create_from_string("\"region start at .*\"")
	var result = regex.search(input)
	if result:
		return result.get_string().replace('"','')
	return ""
	
func set_value(value):
	if value == null:
		return
	if not value is String:
		printerr("Invalid data - %s (SerialAudioRegion): data incoming is not string." % property_name)
	if value.is_empty():
		return
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
		$list.get_child(i-1).free() #queue free caused issues.
		#print("removing node number " + str(i))
		i = i - 1

func set_left_text(text):
	$NumRegions/Label.text = text
