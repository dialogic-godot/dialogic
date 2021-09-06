tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!
signal audio_loaded

export (String) var event_name = "Audio Event"

## node references
onready var volume_input := $VBox/adv_settings/AudioVolume/VBox/Volume
onready var region_group := $VBox/adv_settings/AudioRegion
onready var start_at_input := $VBox/adv_settings/AudioRegion/VBox/HBox/StartAt
onready var stop_at_input := $VBox/adv_settings/AudioRegion/VBox/HBox/StopAt
onready var bus_selector := $VBox/adv_settings/AudioBus/VBox/BusSelector
onready var clear_button := $VBox/prime_settings/ButtonClear
onready var audio_button := $VBox/prime_settings/ButtonAudio
onready var audio_preview := $VBox/prime_settings/AudioPreview
onready var preview_play_button := $VBox/prime_settings/ButtonPreviewPlay
onready var show_advanced_button := $VBox/prime_settings/show_adv
onready var advanced_options_group := $VBox/adv_settings

# used to connect the signals
func _ready():
	
	# signals
	audio_button.connect("pressed", self, '_on_ButtonAudio_pressed')
	preview_play_button.connect("pressed", self, '_on_ButtonPreviewPlay_pressed')
	audio_preview.connect("finished", self, '_on_AudioPreview_finished')
	clear_button.connect('pressed', self, "_on_ButtonClear_pressed")
	bus_selector.connect("item_selected", self, "_on_BusSelector_item_selected")
	volume_input.connect("value_changed", self, "_on_Volume_value_changed")
	start_at_input.connect("value_changed", self, "_on_StartAt_value_changed")
	stop_at_input.connect("value_changed", self, "_on_StopAt_value_changed")
	show_advanced_button.connect("toggled", self, "_on_advanced_toggled")
	
	advanced_options_group.hide()
	
	audio_button.text = 'No sound (will stop previous '+event_name+')'
	
	# icons
	clear_button.icon = get_icon("Reload", "EditorIcons")
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
	if data.has('start_time'):
		start_at_input.value = data["start_time"]
	if data.has('stop_time'):
		stop_at_input.value = data["stop_time"]
	if data.has('file'):
		load_audio(data['file'])
	
	if not data.has("event_id"):
		region_group.show()
	

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
	emit_signal("audio_loaded")

### Loading the audio
func load_audio(path: String):
	if not path.empty():
		audio_button.text = path.get_file()
		audio_button.hint_tooltip = path
		clear_button.disabled = false
		preview_play_button.disabled = false
		event_data['file'] = path
		#update the bus and the volume too so it works with voices
		event_data['audio_bus'] = bus_selector.get_item_text(max(0, bus_selector.selected))
		event_data['volume'] = volume_input.value
		
		if event_data.has('audio'): event_data['audio'] = 'play'
		if event_data.has('background-music'): event_data['background-music'] = 'play'
		
		data_changed()
		
		show_options()
	
	else:
		audio_button.text = 'No sound (will stop previous '+event_name+')'
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
		if event_data.has('start_time'):
			audio_preview.play(event_data['start_time'])
		else:
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

func _on_StopAt_value_changed(value):
	event_data['stop_time'] = value
	data_changed()


func _on_StartAt_value_changed(value):
	event_data['start_time'] = value
	data_changed()
	
func _on_advanced_toggled(show:bool):
	if show:
		advanced_options_group.show()
	else:
		advanced_options_group.hide()

func show_options():
	clear_button.show()
	preview_play_button.show()
	
	volume_input.show()

	show_advanced_button.show()
	if show_advanced_button.pressed:
		advanced_options_group.show()

func hide_options():
	clear_button.hide()
	preview_play_button.hide()
	volume_input.hide()
	advanced_options_group.hide()
	show_advanced_button.hide()

func _process(_delta):
	#Will automatically stop playing when reaching stop_time
	if(audio_preview.playing && event_data.has('stop_time') && audio_preview.get_playback_position() >= event_data['stop_time']):
		audio_preview.stop()
