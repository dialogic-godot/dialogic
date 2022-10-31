@tool
extends HBoxContainer

const max_value:float = 9999.0

var property_name
signal value_changed

const stringfluff = ["[", "]", "start at", "stop at", "region"]

func set_value(value):
	if value == null:
		return
	#strip irrelevant parts
	for f in stringfluff:
		value = value.replace(f, "")
	var data:PackedStringArray = value.split(",", false) #value.replace("[", "").replace("]","").replace("region","").split(",", false)
	if len(data) < 2:
		printerr("Invalid data - %s (AudioRegion): no or incomplete set of timecodes found." % property_name)
		return
	$StartValue.set_value(data[0].to_float())
	$StopValue.set_value (data[1].to_float())


func get_value():
	return "region start at %s, stop at %s" % [$StartValue.get_value(),$StopValue.get_value()]

# Called when the node enters the scene tree for the first time.
func _ready():
	$Number.text = str(get_index()+1)+':'
	$StartValue.use_timestamp_mode()
	$StartValue.set_max_value(max_value - 0.1)
	$StartValue.value_changed.connect(on_value_changed)
	$StopValue.use_timestamp_mode()
	$StopValue.set_min_value(0.1)
	$StopValue.set_max_value(max_value)
	$StopValue.value_changed.connect(on_value_changed)
	
func on_value_changed(property_name, value):
	$StopValue.set_min_value($StartValue.get_value() + 0.1)
	emit_signal("value_changed", property_name, get_value())


