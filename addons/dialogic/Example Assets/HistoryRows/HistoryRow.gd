extends Panel

onready var audioButton := $HBoxContainer/Button
onready var textLabel := $HBoxContainer/RichTextLabel
var audioPath = ''

# This class can be edited or replaced as long as add_history is implemented
# TODO Make this an interface or otherwise a replaceable part
func add_history(historyString, newAudio=''):
	textLabel.append_bbcode(historyString)
	audioPath = newAudio
	if newAudio != '':
		audioButton.disabled = false
	else:
		audioButton.disabled = true
		audioButton.icon = load("res://addons/dialogic/Images/Event Icons/character.svg")


func _on_RichTextLabel_minimum_size_changed():
	rect_min_size.y = textLabel.rect_size.y
