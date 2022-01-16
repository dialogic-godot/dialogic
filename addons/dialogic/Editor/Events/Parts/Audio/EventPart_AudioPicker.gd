tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!
signal audio_loaded

export (String) var event_name = "Audio Event"

## node references
onready var file_picker := $VBox/AudioFilePicker

onready var volume_input := $VBox/adv_settings/AudioVolume/VBox/Volume
onready var region_group := $VBox/adv_settings/AudioRegion
onready var start_at_input := $VBox/adv_settings/AudioRegion/VBox/HBox/StartAt
onready var stop_at_input := $VBox/adv_settings/AudioRegion/VBox/HBox/StopAt
onready var bus_selector := $VBox/adv_settings/AudioBus/VBox/BusSelector

# used to connect the signals
func _ready():
	
	# signals
	file_picker.connect("data_changed", self, '_on_FilePicker_data_changed')
	bus_selector.connect("item_selected", self, "_on_BusSelector_item_selected")
	volume_input.connect("value_changed", self, "_on_Volume_value_changed")
	start_at_input.connect("value_changed", self, "_on_StartAt_value_changed")
	stop_at_input.connect("value_changed", self, "_on_StopAt_value_changed")
	
	# AudioBusPicker update
	AudioServer.connect("bus_layout_changed", self, "update_bus_selector")
	update_bus_selector()
	
	# file picker is here only used for text voice 
	file_picker.hide()

# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	file_picker.load_data(data)
	
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

	if not data.has("event_id"):
		file_picker.show()
		region_group.show()
	
	# TODO 2.0 delete this mess
	if event_data.has('audio'): event_data['audio'] = 'play'
	if event_data.has('background-music'): event_data['background-music'] = 'play'

func get_preview():
	return ''

func update_bus_selector():
	if bus_selector != null:
		var previous_selected_bus_name = bus_selector.get_item_text(max(0, bus_selector.selected))
		
		bus_selector.clear()
		for i in range(AudioServer.bus_count):
			var bus_name = AudioServer.get_bus_name(i)
			bus_selector.add_item(bus_name)
			
			if previous_selected_bus_name == bus_name:
				bus_selector.select(i)

func _on_FilePicker_data_changed(data):
	event_data['file'] = data['file']
	data_changed()

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
