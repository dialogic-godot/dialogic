tool
extends HBoxContainer

var editor_reference
var editorPopup

var file : String
var audio : String
var audio_bus : String = "Master"
var volume: float = 0

signal audio_changed(file, audio, audio_bus, volume)

func _ready():
	load_audio('')
	$ButtonClear.icon = get_icon("Remove", "EditorIcons")
	$ButtonPreviewPlay.icon = get_icon("Play", "EditorIcons")

func _on_ButtonAudio_pressed():
	editor_reference.godot_dialog("*.wav, *.ogg, *.mp3")
	editor_reference.godot_dialog_connect(self, "_on_file_selected")

func _on_file_selected(path, target):
	target.load_audio(path) # why is the targer needed? Couldn't it just call itself?

func load_audio(path: String):
	if not path.empty():
		$Name.text = path
		$ButtonClear.disabled = false
		$ButtonPreviewPlay.disabled = false
		file = path
		audio = 'play'
		emit_signal("audio_changed", file, audio, audio_bus, volume)
	else:
		$Name.text = 'No sound (will stop previous audio event)'
		$ButtonClear.disabled = true
		$ButtonPreviewPlay.disabled = true
		file = ''
		audio = 'stop'
		emit_signal("audio_changed", file, audio, audio_bus, volume)

func load_data(data):
	file = data['file']
	audio = data['audio']
	if data.has('audio_bus'): audio_bus = data['audio_bus']
	if data.has('volume'): audio_bus = data['volume']
	load_audio(file)

func _on_ButtonPreviewPlay_pressed():
	if $AudioPreview.is_playing():
		$AudioPreview.stop()
	else:
		$AudioPreview.stream = load(file)
		$AudioPreview.play()
		$ButtonPreviewPlay.icon = get_icon("Stop", "EditorIcons")

func _on_AudioPreview_finished():
	$ButtonPreviewPlay.icon = get_icon("Play", "EditorIcons")

func _on_ButtonClear_pressed():
	load_audio('')
