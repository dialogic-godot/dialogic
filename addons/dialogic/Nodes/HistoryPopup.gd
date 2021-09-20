extends PopupPanel


onready var HistoryRow = preload("res://addons/dialogic/Nodes/HistoryRow.tscn")
onready var HistoryTimeline = $MarginContainer/HistoryTimeline


# Add history based on the passed event, using some logic to get it right
func add_history_row_event(eventData):
	var newHistoryRow = HistoryRow.instance()
	HistoryTimeline.add_child(newHistoryRow)
	
	var characterPrefix = ''
	if eventData.has('character'):
		var characterData = get_parent().get_character(eventData.character)
		var characterName = get_parent().get_character_name(eventData.character)
		
		if characterName != '':
			var characterColor = characterData.data.get('color', Color.white)
			characterPrefix = str("[color=",characterColor,"]",characterName, "[/color]: ")
	
	var audioData = ''
	if eventData.has('voice_data'):
		if eventData['voice_data'].has('0'):
			audioData = eventData['voice_data']['0'].file
			newHistoryRow.audioButton.connect('pressed', self, '_on_audio_trigger', [audioData])
	
	if eventData.event_id == 'dialogic_001':
		newHistoryRow.add_history(str(characterPrefix, eventData.text), audioData)
	elif eventData.event_id == 'dialogic_010':
		newHistoryRow.add_history(str(characterPrefix, eventData.question))


# Add a history row blindly based on passed strings
func add_history_row_string(stringData, audioData=''):
	var newHistoryRow = HistoryRow.instance()
	HistoryTimeline.add_child(newHistoryRow)
	
	newHistoryRow.add_history(str(stringData), audioData)
	if audioData != '':
		newHistoryRow.audioButton.connect('pressed', self, '_on_audio_trigger', [audioData])


func _on_audio_trigger(audioFilepath):
	$HistoryAudio.stream = load(audioFilepath)
	$HistoryAudio.play()


func _on_HistoryPopup_popup_hide():
	$HistoryAudio.stop()
