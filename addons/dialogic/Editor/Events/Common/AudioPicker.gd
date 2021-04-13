tool
extends HBoxContainer

var editor_reference
var editorPopup

export (String) var event_name = 'Audio Event'

var file : String
var audio : String
var audio_bus : String = "Master"
var volume: float = 0

signal audio_changed(file, audio, audio_bus, volume)

func _ready():
	load_audio('')
	AudioServer.connect("bus_layout_changed", self, "update_bus_selector")
	$ButtonClear.icon = get_icon("Remove", "EditorIcons")
	$ButtonPreviewPlay.icon = get_icon("Play", "EditorIcons")
	update_bus_selector()

func _on_ButtonAudio_pressed():
	editor_reference.godot_dialog("*.wav, *.ogg, *.mp3")
	editor_reference.godot_dialog_connect(self, "_on_file_selected")

func _on_file_selected(path, target):
	target.load_audio(path) # why is the targer needed? Couldn't it just call itself?

func load_audio(path: String):
	if not path.empty():
		$Name.text = path.get_file()
		$Name.hint_tooltip = path
		$ButtonAudio.hint_tooltip = path
		$ButtonClear.disabled = false
		$ButtonPreviewPlay.disabled = false
		file = path
		audio = 'play'
		emit_signal("audio_changed", file, audio, audio_bus, volume)
		
		show_options()
	else:
		$Name.text = 'No sound (will stop previous '+event_name+')'
		file = ''
		audio = 'stop'
		emit_signal("audio_changed", file, audio, audio_bus, volume)

		hide_options()

func load_data(data):
	file = data['file']
	if data.has('audio'): audio = data['audio']
	if data.has('background-music'): audio = data['background-music']
	
	if data.has('audio_bus'): audio_bus = data['audio_bus']
	
	for idx in range($BusSelector.get_item_count()):
		if $BusSelector.get_item_text(idx) == audio_bus:
			$BusSelector.select(idx)
	
	if data.has('volume'): volume = data['volume']
	$Volume.value = volume
	load_audio(file)

func _on_ButtonPreviewPlay_pressed():
	if $AudioPreview.is_playing():
		$AudioPreview.stop()
	else:
		$AudioPreview.stream = load(file)
		$AudioPreview.bus = audio_bus
		$AudioPreview.volume_db = volume
		$AudioPreview.play()
		$ButtonPreviewPlay.icon = get_icon("Stop", "EditorIcons")

func _on_AudioPreview_finished():
	$ButtonPreviewPlay.icon = get_icon("Play", "EditorIcons")

func _on_ButtonClear_pressed():
	load_audio('')

func update_bus_selector():
	$BusSelector.clear()
	for i in range(AudioServer.bus_count):
		$BusSelector.add_item(AudioServer.get_bus_name(i))

func _on_BusSelector_item_selected(index):
	audio_bus = $BusSelector.get_item_text(index)
	emit_signal("audio_changed", file, audio, audio_bus, volume)

func _on_Volume_value_changed(value):
	volume = value
	emit_signal("audio_changed", file, audio, audio_bus, volume)

func show_options():
	$ButtonClear.show()
	$ButtonPreviewPlay.show()
	$BusSelector.show()
	$VolumeLabel.show()
	$Volume.show()

func hide_options():
	$ButtonClear.hide()
	$ButtonPreviewPlay.hide()
	$BusSelector.hide()
	$VolumeLabel.hide()
	$Volume.hide()
