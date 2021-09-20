extends HBoxContainer

onready var audioButton := $Button


func add_history(historyString, newAudio=''):
	$RichTextLabel.append_bbcode(historyString)
	
	if newAudio != '':
		$Button.disabled = false
	else:
		$Button.disabled = true
