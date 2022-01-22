tool
extends PanelContainer

export(NodePath) var Audio_Button_Path = @"HBoxContainer/PlayAudioButton"
export(NodePath) var Text_Label_Path = @"HBoxContainer/RichTextLabel"

var audioPath = ''
var AudioButton
var TextLabel

"""
	Example of a HistoryRow. Every time dialog is logged, a new row is created.
	You can extend this class to customize the logging experience as you see fit.
	
	This class can be edited or replaced as long as add_history is implemented
"""

class_name HistoryRow

func _ready():
	TextLabel = get_node(Text_Label_Path)
	AudioButton = get_node(Audio_Button_Path)
	
	assert(TextLabel is RichTextLabel, 'Text_Label must be a rich text label.')
	assert(AudioButton is Button, 'Audio_Button must be a button.')


func add_history(historyString, newAudio=''):
	TextLabel.append_bbcode(historyString)
	audioPath = newAudio
	if newAudio != '':
		AudioButton.disabled = false
		AudioButton.icon = load("res://addons/dialogic/Images/Event Icons/Main Icons/audio-event.svg")
		AudioButton.flat = false
	else:
		AudioButton.disabled = true
		#AudioButton.icon = load("res://addons/dialogic/Images/Event Icons/Main Icons/text-event.svg")
	AudioButton.focus_mode = FOCUS_NONE


# Uses the default theme to make the font and boxes looks a bit nicer
func load_theme(theme: ConfigFile):
	# Text
	var theme_font = DialogicUtil.path_fixer_load(theme.get_value('text', 'font', 'res://addons/dialogic/Example Assets/Fonts/DefaultFont.tres'))
	TextLabel.set('custom_fonts/normal_font', theme_font)
	TextLabel.set('custom_fonts/bold_font', DialogicUtil.path_fixer_load(theme.get_value('text', 'bold_font', 'res://addons/dialogic/Example Assets/Fonts/DefaultBoldFont.tres')))
	TextLabel.set('custom_fonts/italics_font', DialogicUtil.path_fixer_load(theme.get_value('text', 'italic_font', 'res://addons/dialogic/Example Assets/Fonts/DefaultItalicFont.tres')))
	
	var text_color = Color(theme.get_value('text', 'color', '#ffffffff'))
	TextLabel.set('custom_colors/default_color', text_color)
	
	TextLabel.set('custom_colors/font_color_shadow', Color('#00ffffff'))
	
	if theme.get_value('text', 'shadow', false):
		var text_shadow_color = Color(theme.get_value('text', 'shadow_color', '#9e000000'))
		TextLabel.set('custom_colors/font_color_shadow', text_shadow_color)
	
	var shadow_offset = theme.get_value('text', 'shadow_offset', Vector2(2,2))
	TextLabel.set('custom_constants/shadow_offset_x', shadow_offset.x)
	TextLabel.set('custom_constants/shadow_offset_y', shadow_offset.y)
	
	# Margin
	var text_margin = theme.get_value('text', 'margin', Vector2(20, 10))
	TextLabel.set('margin_left', text_margin.x)
	TextLabel.set('margin_right', text_margin.x * -1)
	TextLabel.set('margin_top', text_margin.y)
	TextLabel.set('margin_bottom', text_margin.y * -1)
	
	# Backgrounds
	$TextureRect.texture = DialogicUtil.path_fixer_load(theme.get_value('background','image', "res://addons/dialogic/Example Assets/backgrounds/background-2.png"))
	$TextureRect.expand = true
	$ColorRect.color = Color(theme.get_value('background','color', "#ff000000"))
	
	if theme.get_value('background', 'modulation', false):
		$TextureRect.modulate = Color(theme.get_value('background', 'modulation_color', '#ffffffff'))
	else:
		$TextureRect.modulate = Color('#ffffffff')
	
	$ColorRect.visible = theme.get_value('background', 'use_color', false)
	$TextureRect.visible = theme.get_value('background', 'use_image', true)

