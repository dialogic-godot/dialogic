tool
extends Control

var event_resource : DialogicEvent = null
var resource_type = null

var property_name : String
signal value_changed

func _ready():
	pass#list_resources_of_type()
	
func set_hint(value):
	$Hint.text = str(value)

func set_value(value):
	if value is DialogicTimeline:
		$Search.text = value._to_string()
	else:
		$Search.text = "Nothing selected"

func _on_Search_text_entered(new_text):
	pass#emit_signal("value_changed", property_name, $Search.text)


func _on_Search_text_changed(new_text):
	if new_text != "":
		$Search/Suggestions.show()

func can_drop_data(position, data):
	#print(position)
	print(data)
	if typeof(data) == TYPE_DICTIONARY and data.has('files') and len(data.files) == 1:
		var file = load(data.files[0])
		print(file)
		if file is DialogicTimeline:
			print("true")
			return true
		
	return false
	
func drop_data(position, data):
	print("DATA DROPPED")
	print(data)
	var file = load(data.files[0])
	$Search.text = file.to_string()
	emit_signal("value_changed", property_name, file)

func list_resources_of_type():
	var dialogic_plugin = get_tree().root.get_node('EditorNode/DialogicPlugin')
	dialogic_plugin.connect('dialogic_save', self, 'save_timeline')
	scan_folder('res://', dialogic_plugin)

func scan_folder(folder_path, d_plugin):
	var dir = Directory.new()
	if dir.open(folder_path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				print("Found directory: ", file_name )
			else:
				print("Found file: " + file_name)
				print("It's of type ", d_plugin._editor_interface.get_resource_filesystem().get_file_type("res://"+file_name))
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")

	
