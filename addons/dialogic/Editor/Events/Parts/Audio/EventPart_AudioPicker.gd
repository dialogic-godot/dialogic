tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!

export (String) var event_name = "Audio Event"

## node references
onready var name_label := $HBox/Name
onready var volume_input := $HBox/Volume
onready var bus_selector := $HBox/BusSelector
onready var clear_button := $HBox/ButtonClear
onready var audio_button := $HBox/ButtonAudio
onready var audio_preview := $HBox/AudioPreview
onready var preview_play_button := $HBox/ButtonPreviewPlay

# used to connect the signals
func _ready():
	
	# signals
	audio_button.connect("pressed", self, '_on_ButtonAudio_pressed')
	preview_play_button.connect("pressed", self, '_on_ButtonPreviewPlay_pressed')
	audio_preview.connect("finished", self, '_on_AudioPreview_finished')
	clear_button.connect('pressed', self, "_on_ButtonClear_pressed")
	bus_selector.connect("item_selected", self, "_on_BusSelector_item_selected")
	volume_input.connect("value_changed", self, "_on_Volume_value_changed")
	
	# icons
	clear_button.icon = get_icon("Remove", "EditorIcons")
	preview_play_button.icon = get_icon("Play", "EditorIcons")
	
	# AudioBusPicker update
	AudioServer.connect("bus_layout_changed", self, "update_bus_selector")
	update_bus_selector()

# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	# Now update the ui nodes to display the data. 
	if data.has('audio_bus'): 
		for idx in range(bus_selector.get_item_count()):
			if bus_selector.get_item_text(idx) == data['audio_bus']:
				bus_selector.select(idx)
		
	if data.has('volume'):
		volume_input.value = data['volume']
	load_audio(data['file'])

# has to return the wanted preview, only useful for body parts
func get_preview():
	if event_data['file']:
		return 'Plays '+event_data['file'].get_file()
	else:
		if event_data['event_id'] == 'dialogic_030':
			return 'Stops previous audio event'
		if event_data['event_id'] == 'dialogic_031':
			return 'Stops previous background music'

### The AudioFile selection
func _on_ButtonAudio_pressed():
	editor_reference.godot_dialog("*.wav, *.ogg, *.mp3")
	editor_reference.godot_dialog_connect(self, "_on_file_selected")

func _on_file_selected(path, target):
	target.load_audio(path) # why is the targer needed? Couldn't it just call itself?


### Loading the audio
func load_audio(path: String):
	if not path.empty():
		name_label.text = path.get_file()
		name_label.hint_tooltip = path
		audio_button.hint_tooltip = path
		clear_button.disabled = false
		preview_play_button.disabled = false
		event_data['file'] = path
		
		
		if event_data.has('audio'): event_data['audio'] = 'play'
		if event_data.has('background-music'): event_data['background-music'] = 'play'
		
		data_changed()
		
		show_options()
	
	else:
		name_label.text = 'No sound (will stop previous '+event_name+')'
		event_data['file'] = ''
		
		if event_data.has('audio'): event_data['audio'] = 'stop'
		if event_data.has('background-music'): event_data['background-music'] = 'stop'
		
		data_changed()

		hide_options()


func _on_ButtonPreviewPlay_pressed():
	if audio_preview.is_playing():
		audio_preview.stop()
	else:
		audio_preview.stream = load(event_data['file'])
		audio_preview.bus = event_data['audio_bus']
		audio_preview.volume_db =  event_data['volume']
		audio_preview.play()
		preview_play_button.icon = get_icon("Stop", "EditorIcons")

func _on_AudioPreview_finished():
	preview_play_button.icon = get_icon("Play", "EditorIcons")

func _on_ButtonClear_pressed():
	load_audio('')

func update_bus_selector():
	if bus_selector != null:
		var previous_selected_bus_name = bus_selector.get_item_text(max(0, bus_selector.selected))
		
		bus_selector.clear()
		for i in range(AudioServer.bus_count):
			var bus_name = AudioServer.get_bus_name(i)
			bus_selector.add_item(bus_name)
			
			if previous_selected_bus_name == bus_name:
				bus_selector.select(i)

func _on_BusSelector_item_selected(index):
	event_data['audio_bus'] = bus_selector.get_item_text(index)
	data_changed()

func _on_Volume_value_changed(value):
	event_data['volume'] = value
	data_changed()

func show_options():
	clear_button.show()
	preview_play_button.show()
	bus_selector.show()
	$HBox/AudioBusLabel.show()
	$HBox/VolumeLabel.show()
	volume_input.show()

func hide_options():
	clear_button.hide()
	preview_play_button.hide()
	bus_selector.hide()
	$HBox/AudioBusLabel.hide()
	$HBox/VolumeLabel.hide()
	volume_input.hide()
