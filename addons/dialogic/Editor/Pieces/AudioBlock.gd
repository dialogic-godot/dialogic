tool
extends PanelContainer

var editor_reference
var editorPopup

var play_button_state = 'stopped'

# This is the information of this event and it will get parsed and saved to the JSON file.
var event_data = {
	'audio': 'play',
	'file': ''
}

func _ready():
	$VBoxContainer/Header/VisibleToggle.disabled()


func _on_ButtonAudio_pressed():
	var file_dialog = editor_reference.godot_dialog()
	file_dialog.add_filter("*.wav, *.ogg")
	editor_reference.godot_dialog_connect(self, "_on_file_selected")

func _on_file_selected(path, target):
	print('load_audio', path, target)
	target.load_audio(path)

func load_audio(path):
	$VBoxContainer/Header/Title.text = path
	$VBoxContainer/Header/ButtonPreviewPlay.disabled = false
	event_data['file'] = path
	print(path)


func load_data(data):
	event_data = data
	if data['file'] != '':
		load_audio(data['file'])

func _on_ButtonPreviewPlay_pressed():
	print(editor_reference.get_node("AudioPreview"))
	
	# It seems like you can't play audio on the editor.
	if play_button_state == 'playing':
		editor_reference.get_node("AudioPreview").stop()
		play_button_state == 'stopped'
	else:
		var audio_preview = editor_reference.get_node("AudioPreview")
		var audio_file = load(event_data['file'])
		audio_preview.stream = audio_file
		editor_reference.get_node("AudioPreview").play()
		play_button_state == 'playing'
