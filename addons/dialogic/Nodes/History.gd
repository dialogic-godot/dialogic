tool
extends Control


export(PackedScene) var HistoryRow = load("res://addons/dialogic/Example Assets/History/HistoryRow.tscn")
export(PackedScene) var HistoryDefaultBackground = load("res://addons/dialogic/Example Assets/History/HistoryBackground.tscn")
export(PackedScene) var HistoryOpenButton = load("res://addons/dialogic/Example Assets/History/HistoryButton.tscn")
export(PackedScene) var HistoryCloseButton = load("res://addons/dialogic/Example Assets/History/HistoryButton.tscn")
export(int) var Vertical_Separation = 16

onready var HistoryTimeline = $HistoryPopup/ScrollHistoryContainer/MarginContainer/HistoryTimeline
onready var scrollbar = $HistoryPopup/ScrollHistoryContainer.get_v_scrollbar()
onready var ScrollHistoryContainer = $HistoryPopup/ScrollHistoryContainer
onready var HistoryPopup = $HistoryPopup
onready var HistoryAudio = $HistoryPopup/HistoryAudio

var HistoryButton 
var CloseButton
var HistoryBackground

var is_history_open = false
var is_mouse_on_button = false
var block_dialog_advance = false setget , history_advance_block

var lastQuestionNode = null
var curTheme = null
var prevState

var eventsToLog = ['dialogic_001', 'dialogic_002', 'dialogic_003', 'dialogic_010'] 


func _ready():
	var testHistoryRow = HistoryRow.instance()
	assert(testHistoryRow.has_method('add_history'), 'HistoryRow Scene must implement add_history(string, string) method.')
	testHistoryRow.queue_free()
	
	HistoryBackground = HistoryDefaultBackground.instance()
	HistoryPopup.add_child(HistoryBackground)
	HistoryPopup.move_child(HistoryBackground, 0)
	
	HistoryButton = HistoryOpenButton.instance()
	add_child(HistoryButton)
	HistoryButton.connect("pressed", self, '_on_toggle_history')
	HistoryButton.connect("mouse_entered", self, '_on_HistoryButton_mouse_entered')
	HistoryButton.connect("mouse_exited", self, '_on_HistoryButton_mouse_exited')
	HistoryButton.disabled = false
	HistoryButton.show()
	
	CloseButton = HistoryCloseButton.instance()
	HistoryPopup.add_child(CloseButton)
	CloseButton.connect("pressed", self, '_on_toggle_history')

	CloseButton.text = 'Test'
	CloseButton.disabled = true
	CloseButton.hide()


func initalize_history():
	
	var button_anchor = get_parent().settings.get_value('history', 'history_button_position', 2)
	
	for button in [HistoryButton, CloseButton]:
		var reference = button.get_parent().rect_size
		
		# Adding audio when focused or hovered
		button.connect('focus_entered', get_parent(), '_on_option_hovered', [button])
		button.connect('mouse_entered', get_parent(), '_on_option_focused')
		
		# Button positioning
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
			position_offset.x = reference.x/2 - button.rect_size.x
			position_offset.y = 0
		# Top Right
		elif button_anchor == 2:
			anchor_values = [1, 0, 1, 0]
			position_offset.x = reference.x - button.rect_size.x
			position_offset.y = 0
		# 3 - Number skip because of the separator
		# Center Left
		elif button_anchor == 4:
			anchor_values = [0, .5, 0, .5]
			position_offset.x = 0
			position_offset.y = reference.y/2 - button.rect_size.y
		# True Center
		elif button_anchor == 5:
			anchor_values = [.5, .5, .5, .5]
			position_offset.x = reference.x/2 - button.rect_size.x
			position_offset.y = reference.y/2 - button.rect_size.y
		# Center Right
		elif button_anchor == 6:
			anchor_values = [1, .5, 1, .5]
			position_offset.x = reference.x - button.rect_size.x
			position_offset.y = reference.y/2 - button.rect_size.y
		# Number skip because of the separator
		elif button_anchor == 8:
			anchor_values = [0, 1, 0, 1]
			position_offset.x = 0
			position_offset.y = reference.y - button.rect_size.y
		elif button_anchor == 9:
			anchor_values = [.5, 1, .5, 1]
			position_offset.x = reference.x/2 - button.rect_size.x
			position_offset.y = reference.y - button.rect_size.y
		elif button_anchor == 10:
			anchor_values = [1, 1, 1, 1]
			position_offset.x = reference.x - button.rect_size.x
			position_offset.y = reference.y - button.rect_size.y
		
		button.anchor_left = anchor_values[0]
		button.anchor_top = anchor_values[1]
		button.anchor_right = anchor_values[2]
		button.anchor_bottom = anchor_values[3]
		
		button.rect_global_position = button.get_parent().rect_global_position + position_offset


# Add history based on the passed event, using some logic to get it right
func add_history_row_event(eventData):
	if !eventsToLog.has(eventData.event_id):
		return
	
	var newHistoryRow = HistoryRow.instance()
	HistoryTimeline.add_child(newHistoryRow)
	newHistoryRow.load_theme(curTheme)
	
	var characterPrefix = ''
	if eventData.has('character') and eventData.character != '':
		var characterData = DialogicUtil.get_character(eventData.character)
		var characterName = characterData.get('name', '')
		
		if characterData.data.get('display_name_bool', false)  == true:
			characterName = characterData.data.get('display_name', '')
		
		if characterName != '':
			var characterColor = characterData.data.get('color', Color.white)
			characterPrefix = str("[color=",characterColor,"]",characterName, "[/color]: ")
	
	var audioData = ''
	if eventData.has('voice_data'):
		if eventData['voice_data'].has('0'):
			audioData = eventData['voice_data']['0'].file
			newHistoryRow.AudioButton.connect('pressed', self, '_on_audio_trigger', [audioData])
	
	# event logging handled here
	if eventData.event_id == 'dialogic_001':
		newHistoryRow.add_history(str(characterPrefix, eventData.text), audioData)
	elif eventData.event_id == 'dialogic_002':
		newHistoryRow.add_history(str(characterPrefix, ' has arrived.'), audioData)
	elif eventData.event_id == 'dialogic_003':
		newHistoryRow.add_history(str(characterPrefix, ' has left.'), audioData)
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


func change_theme(newTheme: ConfigFile):
	if get_parent().settings.get_value('history', 'enable_dynamic_theme', false):
		curTheme = newTheme


func load_theme(theme: ConfigFile):
	curTheme = theme


func _on_audio_trigger(audioFilepath):
	HistoryAudio.stream = load(audioFilepath)
	HistoryAudio.play()


func _on_HistoryPopup_popup_hide():
	HistoryAudio.stop()


func _on_HistoryPopup_about_to_show():
	HistoryButton.show()
	ScrollHistoryContainer.scroll_vertical = scrollbar.max_value


func _on_CloseButton_pressed():
	$HistoryPopup.hide()
	HistoryButton.show()
	HistoryButton.disabled = false
	CloseButton.disabled = true
	CloseButton.hide()
	is_history_open = false


func _on_HistoryButton_pressed():
	if $HistoryPopup.visible == false:
		$HistoryPopup.popup()
		HistoryButton.hide()
		HistoryButton.disabled = true
		CloseButton.disabled = false
		CloseButton.show()
		is_history_open = true


func _on_toggle_history():
	if $HistoryPopup.visible == false:
		$HistoryPopup.popup()
		HistoryButton.hide()
		HistoryButton.disabled = true
		CloseButton.disabled = false
		CloseButton.show()
		is_history_open = true
		is_mouse_on_button = false
	else:
		$HistoryPopup.hide()
		HistoryButton.show()
		HistoryButton.disabled = false
		CloseButton.disabled = true
		CloseButton.hide()
		is_history_open = false
		is_mouse_on_button = false


func _on_History_item_rect_changed():
	if not Engine.is_editor_hint():
		HistoryPopup.rect_size =  get_tree().root.size;
		HistoryPopup.margin_bottom = -20
		HistoryPopup.margin_left = 20
		HistoryPopup.margin_right = -20
		HistoryPopup.margin_top = 20


func _on_HistoryButton_mouse_entered():
	is_mouse_on_button = true


func _on_HistoryButton_mouse_exited():
	is_mouse_on_button = false


func history_advance_block() -> bool:
	return is_mouse_on_button or is_history_open 
