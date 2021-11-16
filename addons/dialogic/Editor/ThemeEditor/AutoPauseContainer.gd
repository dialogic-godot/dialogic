tool
extends HBoxContainer

signal data_changed

func _ready():
	$DeleteButton.icon = get_icon("Remove", "EditorIcons")

func set_data(data):
	$Symbol.text = data[0]
	$Duration.value = float(data[1])

func change(value):
	emit_signal("data_changed")
