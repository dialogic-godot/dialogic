tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

onready var text_editor = $VBoxContainer/TextEditor
onready var voice_editor = $VBoxContainer/VoiceEditor


func _ready() -> void:
	text_editor.connect("data_changed", self, "_on_text_editor_data_changed")
	voice_editor.connect("data_changed", self, "_on_voice_editor_data_changed")
	voice_editor.visible = use_voices()
	voice_editor.editor_reference = editor_reference
	voice_editor.repopulate()


func load_data(data):
	.load_data(data)
	
	text_editor.load_data(data)
	voice_editor.visible = use_voices()
	voice_editor.load_data(data)
	update_voices_lines()


func get_preview():
	return text_editor.get_preview()


func use_voices():
	var config = DialogicResources.get_settings_config()
	return config.get_value('dialog', 'text_event_audio_enable', false)


func _on_text_editor_data_changed(data) -> void:
	event_data = data 
	
	#udpate the voice picker to check if we repopulate it 
	update_voices_lines()
	# informs the parent 
	data_changed()


func update_voices_lines():
	var text = text_editor.get_child(0).text
	voice_editor._on_text_changed(text)


func _on_voice_editor_data_changed(data) -> void:
	event_data['voice_data'] = data['voice_data']
	voice_editor.visible = use_voices()
	# informs the parent 
	data_changed()

func focus():
	text_editor.focus()
