tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"


export(PackedScene) var audio_picker

onready var voices_container = $VoicesList
var audio_lines = 1 # how many lines does the text event has


func load_data(data):
	.load_data(data)
	

func repopulate() -> void:
	for child in voices_container.get_children():
		child.queue_free()
	
	#recraete audio pickers
	for i in range(audio_lines):
		var a_picker = audio_picker.instance()
		a_picker.editor_reference = editor_reference
		a_picker.connect("audio_loaded", self, "_on_audio_picker_audio_loaded", [i])
		voices_container.add_child(a_picker)
		
		#loaded daata 
		if event_data.has('voice_data'):
			var voice_data = event_data['voice_data']
			if voice_data.has(str(i)):
				var _d = voice_data[str(i)]
				if _d.has('file'):
					a_picker.load_data(_d)
	


func _on_text_changed(text:String) -> void:
	# This is called when the text has changed
	# Are we adding new text events per new line ?
	var settings_file =  DialogicResources.get_settings_config()
	
	if not (settings_file.get_value("dialog", "new_lines", true)):
		$Label.text = "Voice Picker :"
		return 
	
	var prev_lines = audio_lines
	$Label.text = "Voice Picker [Multiline mode] :"
	audio_lines = max(1, len(text.split('\n')))
	
	if prev_lines != audio_lines:
		repopulate()
	
	
	

func _on_audio_picker_audio_loaded(index:int) -> void:
	# update the data 
	var data_loaded = voices_container.get_child(index).event_data
	if not event_data.has('voice_data'):
		event_data['voice_data'] = {}
		
	event_data['voice_data'][str(index)] = data_loaded
	#load the data
	load_data(event_data)
	
	# informs the parent about the data change 
	data_changed()


func update_data():
	if not event_data.has('voice_data'):
		return 
	var keys = event_data['voice_data'].keys()
	for i in range(voices_container.get_child_count()):
		if keys.has(str(i)):
			var data = event_data['voice_data'][str(i)]
			voices_container.get_child(i).load_data(data)
