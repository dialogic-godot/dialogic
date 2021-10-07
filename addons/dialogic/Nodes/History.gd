tool
extends Control


export(PackedScene) var HistoryRow = load("res://addons/dialogic/Example Assets/HistoryRows/HistoryRow.tscn")
export(int) var Vertical_Separation = 16

onready var HistoryTimeline = $HistoryPopup/ScrollHistoryContainer/MarginContainer/HistoryTimeline
onready var scrollbar = $HistoryPopup/ScrollHistoryContainer.get_v_scrollbar()
onready var ScrollHistoryContainer = $HistoryPopup/ScrollHistoryContainer
onready var HistoryButton = $HistoryButton
onready var HistoryPopup = $HistoryPopup
onready var HistoryTextureRect = $HistoryPopup/TextureRect
onready var HistoryColorRect = $HistoryPopup/ColorRect
onready var HistoryAudio = $HistoryPopup/HistoryAudio

var lastQuestionNode = null
var curTheme = null

var styleIndividualBoxes = true


func _ready():
	var testHistoryRow = HistoryRow.instance()
	assert(testHistoryRow.has_method('add_history'), 'HistoryRow Scene must implement add_history(string, string) method.')
	testHistoryRow.queue_free()
		
	HistoryButton.disabled = true
	HistoryButton.hide()


func initalize_history():
	var reference = rect_size
	HistoryButton.disabled = false
	HistoryButton.show()
	
	# Button positioning
	var button_anchor = get_parent().settings.get_value('history', 'history_button_position', 2)
	var anchor_values = [0,0,1,1]
	var position_offset = Vector2(0,0)
	
	# Top Left
	if button_anchor == 0:
		anchor_values = [0, 0, 0, 0]
		position_offset.x = 0
		position_offset.y = 0
	# Top Center
	elif button_anchor == 1:
		anchor_values = [.5, 0, .5, 0]
		position_offset.x = reference.x/2 - HistoryButton.rect_size.x
		position_offset.y = 0
	# Top Right
	elif button_anchor == 2:
		anchor_values = [1, 0, 1, 0]
		position_offset.x = reference.x - HistoryButton.rect_size.x
		position_offset.y = 0
	# 3 - Number skip because of the separator
	# Center Left
	elif button_anchor == 4:
		anchor_values = [0, .5, 0, .5]
		position_offset.x = 0
		position_offset.y = reference.y/2 - HistoryButton.rect_size.y
	# True Center
	elif button_anchor == 5:
		anchor_values = [.5, .5, .5, .5]
		position_offset.x = reference.x/2 - HistoryButton.rect_size.x
		position_offset.y = reference.y/2 - HistoryButton.rect_size.y
	# Center Right
	elif button_anchor == 6:
		anchor_values = [1, .5, 1, .5]
		position_offset.x = reference.x - HistoryButton.rect_size.x
		position_offset.y = reference.y/2 - HistoryButton.rect_size.y
	# Number skip because of the separator
	elif button_anchor == 8:
		anchor_values = [0, 1, 0, 1]
		position_offset.x = 0
		position_offset.y = reference.y - HistoryButton.rect_size.y
	elif button_anchor == 9:
		anchor_values = [.5, 1, .5, 1]
		position_offset.x = reference.x/2 - HistoryButton.rect_size.x
		position_offset.y = reference.y - HistoryButton.rect_size.y
	elif button_anchor == 10:
		anchor_values = [1, 1, 1, 1]
		position_offset.x = reference.x - HistoryButton.rect_size.x
		position_offset.y = reference.y - HistoryButton.rect_size.y
	
	HistoryButton.anchor_left = anchor_values[0]
	HistoryButton.anchor_top = anchor_values[1]
	HistoryButton.anchor_right = anchor_values[2]
	HistoryButton.anchor_bottom = anchor_values[3]
	
	#var theme_choice_offset = theme.get_value('buttons', 'offset', Vector2(0,0))
	HistoryButton.rect_global_position = position_offset

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


func change_theme(newTheme: ConfigFile):
	if get_parent().settings.get_value('history', 'enable_dynamic_theme', false):
		curTheme = newTheme


func load_theme(theme: ConfigFile):
	curTheme = theme
	
	# Backgrounds
	HistoryTextureRect.texture = DialogicUtil.path_fixer_load(theme.get_value('background','image', "res://addons/dialogic/Example Assets/backgrounds/background-2.png"))
	HistoryTextureRect.expand = true
	HistoryColorRect.color = Color(theme.get_value('background','color', "#ff000000"))
	
	if theme.get_value('background', 'modulation', false):
		HistoryTextureRect.modulate = Color(theme.get_value('background', 'modulation_color', '#ffffffff'))
	else:
		HistoryTextureRect.modulate = Color('#ffffffff')
	
	HistoryColorRect.visible = theme.get_value('background', 'use_color', false)
	HistoryTextureRect.visible = theme.get_value('background', 'use_image', true)


func _on_audio_trigger(audioFilepath):
	HistoryAudio.stream = load(audioFilepath)
	HistoryAudio.play()


func _on_HistoryPopup_popup_hide():
	HistoryAudio.stop()


func _on_HistoryPopup_about_to_show():
	$HistoryButton.show()
	ScrollHistoryContainer.scroll_vertical = scrollbar.max_value


func _on_CloseButton_pressed():
	$HistoryPopup.hide()
	$HistoryButton.show()


func _on_HistoryButton_pressed():
	if $HistoryPopup.visible == false:
		$HistoryPopup.popup()
		$HistoryButton.hide()


func _on_History_item_rect_changed():
	if not Engine.is_editor_hint():
		HistoryPopup.rect_size =  get_tree().root.size;
		HistoryPopup.margin_bottom = -20
		HistoryPopup.margin_left = 20
		HistoryPopup.margin_right = -20
		HistoryPopup.margin_top = 20

