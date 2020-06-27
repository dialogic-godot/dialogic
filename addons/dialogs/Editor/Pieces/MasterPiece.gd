tool
extends GraphNode

var options = false
var option_item = load("res://addons/dialogs/Editor/Pieces/OptionItem.tscn")
var slot_index = 1
var colors = [Color(1,1,1,1), Color(1, 0.4375, 0.4375), Color(0.4375, 0.828613, 1), Color(0.4375, 1, 0.459473)]

func _ready():
	connect("close_request", self, "_on_close_request")
	connect("resize_request", self, "_on_resize_request")
	set_slot(0, true, 0, Color(1,1,1,1), true, 0, Color(1,1,1,1))
	if $VBoxContainer/OptionsCheckBox:
		$VBoxContainer/OptionsEditor.visible = false
		$VBoxContainer/OptionsCheckBox.connect("toggled", self, '_on_options_toggled')
		$VBoxContainer/OptionsEditor/AddButton.connect("pressed", self, '_on_adding_option')

func _on_close_request():
	print('Closed pressed')
	queue_free()

func _on_resize_request(new_minsize):
	rect_size = new_minsize


# Text Node
func add_character_list(characters):
	for c in characters:
		$VBoxContainer/Character/OptionButton.add_item(c.name)

func random_color():
	return Color(rand_range(0,1),rand_range(0,1),rand_range(0,1))

func _on_options_toggled(button_pressed):
	$VBoxContainer/OptionsEditor.visible = button_pressed

func _on_adding_option():
	if $VBoxContainer/OptionsEditor/LineEdit.text != '':
		set_slot(0, true, 0, Color(1,1,1), false, 0, Color(0,0,0))
		var new_option = option_item.instance()
		new_option.get_node("Container/Label").text = $VBoxContainer/OptionsEditor/LineEdit.text
		new_option.get_node("Container/Button").connect('pressed', self, "_on_remove_option", [new_option])
		set_slot(slot_index, false, 0, Color(0,0,0), true, 0, random_color())
		slot_index += 1
		$VBoxContainer/OptionsEditor/LineEdit.text = ''
		add_child(new_option)

func _on_remove_option(option):
	#TODO: Clear slot connections here!!!!
	option.queue_free()
