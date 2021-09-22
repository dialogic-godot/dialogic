tool
extends PopupPanel


export(PackedScene) var HistoryRow = load("res://addons/dialogic/Example Assets/HistoryRows/HistoryRow.tscn")
export(int) var Vertical_Separation = 16

onready var HistoryTimeline = $ScrollContainer/MarginContainer/HistoryTimeline
onready var scrollbar = $ScrollContainer.get_v_scrollbar()

var lastQuestionNode = null
var curTheme = null

func _ready():
	var testHistoryRow = HistoryRow.instance()
	assert(testHistoryRow.has_method('add_history'), 'HistoryRow Scene must implement add_history(string, string) method.')
	testHistoryRow.queue_free()


# Add history based on the passed event, using some logic to get it right
func add_history_row_event(eventData):
	var newHistoryRow = HistoryRow.instance()
	HistoryTimeline.add_child(newHistoryRow)
	newHistoryRow.load_theme(curTheme)
	
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
			newHistoryRow.AudioButton.connect('pressed', self, '_on_audio_trigger', [audioData])
	
	if eventData.event_id == 'dialogic_001':
		newHistoryRow.add_history(str(characterPrefix, eventData.text), audioData)
	elif eventData.event_id == 'dialogic_010':
		newHistoryRow.add_history(str(characterPrefix, eventData.question), audioData)
		if eventData.has('options'):
			var choiceString = "\n\t"
			for choice in eventData['options']:
				choiceString = str(choiceString, '[', choice.label, ']\t')
			newHistoryRow.add_history(choiceString, audioData)
		lastQuestionNode = newHistoryRow


func add_answer_to_question(stringData):
	if lastQuestionNode != null:
		lastQuestionNode.add_history(str('\n\t\t', stringData), lastQuestionNode.audioPath)
		lastQuestionNode = null


# Add a history row blindly based on passed strings
func add_history_row_string(stringData, audioData=''):
	var newHistoryRow = HistoryRow.instance()
	HistoryTimeline.add_child(newHistoryRow)
	newHistoryRow.load_theme(curTheme)
	
	newHistoryRow.add_history(str(stringData), audioData)
	if audioData != '':
		newHistoryRow.AudioButton.connect('pressed', self, '_on_audio_trigger', [audioData])


func load_theme(theme: ConfigFile):
	curTheme = theme


func _on_audio_trigger(audioFilepath):
	$HistoryAudio.stream = load(audioFilepath)
	$HistoryAudio.play()


func _on_HistoryPopup_popup_hide():
	$HistoryAudio.stop()


func _on_HistoryPopup_about_to_show():
	$ScrollContainer.scroll_vertical = scrollbar.max_value

