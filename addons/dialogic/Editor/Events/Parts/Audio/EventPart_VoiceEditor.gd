tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"


export(PackedScene) var audio_picker

#onready var voices_container = $List/VoicesList
#onready var label_container = $List/Label
var audio_lines = 1 # how many lines does the text event has

#multilang support variables
onready var c_lang := "INTERNAL" #current language
#end of multilang support variables

func load_data(data):
	.load_data(data)
	
	update_data()

func repopulate() -> void:
	for child in $List.get_children():
		child.queue_free()
	
	var settings = DialogicResources.get_settings_config()
	#recraete audio pickers
	for i in range(audio_lines):
		var label = Label.new()
		label.text = "Line "+str(i+1)+":"
		label.size_flags_vertical = 0
		$List.add_child(label)
		
		var a_picker = audio_picker.instance()
		a_picker.editor_reference = editor_reference
		a_picker.event_name = "voice line"
		a_picker.connect("data_changed", self, "_on_audio_picker_audio_loaded", [i])
		$List.add_child(a_picker)
		
		#loaded data 
		if event_data.has('voice_data'):
			var voice_data = event_data['voice_data']
			if voice_data.has(str(i)):
				var _d = voice_data[str(i)]
				if _d.has('file'):
					a_picker.load_data(_d)
					continue
		
		a_picker.load_data({'file':'', 'audio_bus':settings.get_value("dialog", "text_event_audio_default_bus", "Master")})


func _on_text_changed(text:String) -> void:
	# This is called when the text has changed
	# Are we adding new text events per new line ?
	var settings_file =  DialogicResources.get_settings_config()
	
	if not (settings_file.get_value("dialog", "new_lines", true)):
		$Label.text = "Audio Picker:"
		return 
	
	var prev_lines = audio_lines
	$Label.text = "Audio Pickers:"
	audio_lines = max(1, len(text.split('\n')))
	
	if prev_lines != audio_lines:
		repopulate()

#Since the nodes are now in a grid sharing indicies with lables, index must
#be multiplied by 2, then added an offset of 1 to get the requested node
func _get_audio_picker(index:int):
	var data = $List.get_child(index * 2 + 1)
	return data

func _on_audio_picker_audio_loaded(data,index:int) -> void:
	# update the data 
	if not event_data.has('voice_data'):
		event_data['voice_data'] = {}
	
	var key = str(index) #key made into a variable...
	if(c_lang != "INTERNAL"):
		key += "_"+c_lang #to allow appending the language
	event_data['voice_data'][key] = data
	
	#load the data
	load_data(event_data)
	
	# informs the parent about the data change 
	data_changed()


func update_data():
	if not event_data.has('voice_data'):
		return
	var keys = event_data['voice_data'].keys()
	# This subroutine was already a hack before I got to it, so don't blame me.
	# divide by two, again becouse the two merged nodes.
	# reused _get_audio_picker wherein we multiply by two again :D
	# - KvaGram
	# uh, it's me again. This time I am to blame for the new hack.
	# Alternate languages are stored as intex_name.
	# Where the default/internal keys are 0, 1, 2, etc, tranlations would be 0_NB, 1_NB, 2_NB, etc
	# - KvaGram
	for i in range($List.get_child_count() / 2):
		var key = str(i) #key made into a variable...
		if(c_lang != "INTERNAL"):
			key += "_"+c_lang #to allow appending the language
		var data = event_data['voice_data'].get(key, {})
		#voices_container.get_child(i).load_data(data)
		_get_audio_picker(i).load_data(data)
			

#part of the multilang support.
#Called from the editorview's toolbar via timeline editor, eventblock and TextAndVoicepicker
func on_language_changed(language):
	c_lang = language
	update_data()
