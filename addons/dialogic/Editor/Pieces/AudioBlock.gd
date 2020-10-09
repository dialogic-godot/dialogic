tool
extends PanelContainer

var editor_reference
var editorPopup

var play_icon = load("res://addons/dialogic/Images/play.svg")
var stop_icon = load("res://addons/dialogic/Images/stop.svg")

# This is the information of this event and it will get parsed and saved to the JSON file.
var event_data = {
	'audio': 'play',
	'file': ''
}

func _ready():	
	$VBoxContainer/Header/VisibleToggle.disabled()


func _on_ButtonAudio_pressed():
	editor_reference.godot_dialog("*.wav, *.ogg")
	editor_reference.godot_dialog_connect(self, "_on_file_selected")

func _on_file_selected(path, target):
	print('[Dialogic] Loading audio block ', path, target)
	target.load_audio(path)

func load_audio(path):
	$VBoxContainer/Header/Name.text = path
	$VBoxContainer/Header/ButtonPreviewPlay.disabled = false
	event_data['file'] = path


func load_data(data):
	event_data = data
	if data['file'] != '':
		load_audio(data['file'])
	
func _on_ButtonPreviewPlay_pressed():
	print('[Dialogic] Playing audio ' + event_data['file'])
	if $AudioPreview.is_playing():
		$AudioPreview.stop()
	else:
		$AudioPreview.stream = load(event_data['file'])
		$AudioPreview.play()
		$VBoxContainer/Header/ButtonPreviewPlay.icon = stop_icon
		


func _on_AudioPreview_finished():
	$VBoxContainer/Header/ButtonPreviewPlay.icon = play_icon
