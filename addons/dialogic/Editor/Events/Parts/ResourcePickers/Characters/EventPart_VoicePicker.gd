tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

	
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	#update the 
	if "voice_path" in event_data.keys():
		var voice_array = event_data["voice_path"]
		var audio_label = ""
		if voice_array.size() > 1:
			audio_label = "Voice : "+str(voice_array.size())+" Lines"
		elif voice_array.size() == 1:
			audio_label = "Voice : "+event_data["voice_path"][0].split('/')[-1]
		else:
			audio_label = "No Audio"
			
		$HBoxContainer/AudioName.text = audio_label


func _on_Clear_pressed() -> void:
	event_data["voice_path"] = []
	
	load_data(event_data)
	# infroms the parent
	data_changed()


func _on_SelectorButton_pressed() -> void:
	editor_reference.godot_dialog("*.wav, *.ogg",EditorFileDialog.MODE_OPEN_FILES)
	editor_reference.godot_dialog_connect(self, "_on_audio_selected", "files_selected")


func _on_audio_selected(paths, target):
	#update the data here
	event_data["voice_path"] = paths
	load_data(event_data)
	# informs the parent
	data_changed()
