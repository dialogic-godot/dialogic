tool
extends ScrollContainer

var editor_reference

func _ready():
	pass # Replace with function body.


func load_definition(path):
	pass


func new_definition():
	var section_name = DialogicUtil.generate_random_id()
	var config = ConfigFile.new()
	var file = DialogicUtil.get_path('DEFINITIONS_FILE')
	var err = config.load(file)
	if err == OK:
		config.set_value(section_name, 'name', 'definition')
		config.save(file)
