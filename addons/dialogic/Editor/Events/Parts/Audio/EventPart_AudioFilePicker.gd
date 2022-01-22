tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!

## node references
onready var file_picker = $FilePicker
onready var preview_button = $ButtonPreviewPlay
onready var audio_preview = $AudioPreview

# used to connect the signals
func _ready():
	file_picker.connect("data_changed", self, "_on_FilePicker_data_changed")
	preview_button.connect("pressed", self, "_on_PreviewButton_pressed")
	audio_preview.connect("finished", self, '_on_AudioPreview_finished')
	preview_button.icon = get_icon("Play", "EditorIcons")
	
# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	# Now update the ui nodes to display the data. 
	file_picker.load_data(event_data)
	preview_button.visible = !event_data['file'].empty()

# has to return the wanted preview, only useful for body parts
func get_preview():
	return ''


func _on_FilePicker_data_changed(data):
	event_data = data
	
	preview_button.visible = !event_data['file'].empty()
	# informs the parent about the changes!
	data_changed()

func _on_PreviewButton_pressed():
	if audio_preview.is_playing():
		audio_preview.stop()
	else:
		audio_preview.stream = load(event_data['file'])
		audio_preview.bus = event_data['audio_bus']
		audio_preview.volume_db =  event_data.get('volume', 0)
		if event_data.has('start_time'):
			audio_preview.play(event_data['start_time'])
		else:
			audio_preview.play()
		preview_button.icon = get_icon("Stop", "EditorIcons")

func _on_AudioPreview_finished():
	preview_button.icon = get_icon("Play", "EditorIcons")


func _process(_delta):
	#Will automatically stop playing when reaching stop_time
	if(audio_preview.playing && event_data.has('stop_time') && audio_preview.get_playback_position() >= event_data['stop_time']):
		audio_preview.stop()
