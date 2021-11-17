tool
extends Control

var text_speed := 0.02 # Higher = lower speed
var theme_text_speed = text_speed

#experimental database of current commands
var commands = []
#the regex matching object
var regex = RegEx.new()
var bbcoderemoverregex = RegEx.new()

onready var text_label = $RichTextLabel
onready var name_label = $NameLabel
onready var next_indicator = $NextIndicatorContainer/NextIndicator

var _finished := false
var _theme

signal text_completed()
signal letter_written()
signal signal_request(arg)

## *****************************************************************************
##								PUBLIC METHODS
## *****************************************************************************


func update_name(name: String, color: Color = Color.white, autocolor: bool=false) -> void:
	if not name.empty():
		name_label.visible = true
		# Hack to reset the size
		name_label.rect_min_size = Vector2(0, 0)
		name_label.rect_size = Vector2(-1, 40)
		# Setting the color and text
		name_label.text = name
		# Alignment
		call_deferred('align_name_label')
		if autocolor:
			name_label.set('custom_colors/font_color', color)
	else:
		name_label.visible = false


func update_text(text:String):
	
	var orig_text = text
	var text_bbcodefree = text
	
	for result in bbcoderemoverregex.search_all(text_bbcodefree):
		text_bbcodefree = text_bbcodefree.replace(result.get_string(), "")
	
	#regex moved from func scope to class scope
	#regex compilation moved to _ready
	#  - KvaGram
	#var regex = RegEx.new()
	var result:RegExMatch = null
	text_speed = theme_text_speed # Resetting the speed to the default
	commands = []
	
	### remove commands from text, and store where and what they are
	#current regex: \[(nw|(nw|speed|signal|play|pause)=(.+?))\](.*?)
	#Note: The version defined in _ready will have aditional escape characers.
	#      DO NOT JUST COPY/PASTE
	#remeber regex101.com is your friend. Do not shoot it. You may ask it to verify the code.
	#The capture groups, and what they do:
	# 0 everything ex [speed=5]
	# 1 the "nw" single command or one of the variable commands ex "nw" or "speed=5"
	# 2 the command, assuming it is an variable command ex "speed"
	# 3 the argument, again assuming a variable command ex "5"
	# 4 nothing (ignore it)
	#keep this up to date whenever the regex string is updated! - KvaGram
	
	result = regex.search(text_bbcodefree)
	#loops until all commands are cleared from the text
	while result:
		if result.get_string(1) == "nw" || result.get_string(2) == "nw":
			#The no wait command is handled elsewhere. Ignore it.
			pass
		else:
			#Store an assigned varible command as an array by 0 index in text, 1 command-name, 2 argument
			commands.append([result.get_start()-1, result.get_string(2), result.get_string(3)])
		text_bbcodefree = text_bbcodefree.substr(0, result.get_start()) + text_bbcodefree.substr(result.get_end())
		text = text.replace(result.get_string(), "")
		
		result = regex.search(text_bbcodefree)
	

	# Updating the text and starting the animation from 0
	text_label.bbcode_text = text
	text_label.visible_characters = 0
	
	text_label.grab_focus()
	start_text_timer()
	return true

#handle an activated command.
func handle_command(command:Array):
	if(command[1] == "speed"):
		text_speed = float(command[2]) * 0.01
		$WritingTimer.stop()
		start_text_timer()
	elif(command[1] == "signal"):
		emit_signal("signal_request", command[2])
	elif(command[1] == "play"):
		var path = "res://dialogic/sounds/" + command[2]
		if ResourceLoader.exists(path, "AudioStream"):
			var audio:AudioStream = ResourceLoader.load(path, "AudioStream")
			$sounds.stream = audio
			$sounds.play()
			#yield(get_tree().create_timer(audio.get_length()), "timeout")
			#$sounds.stop()
	elif(command[1] == "pause"):
		$WritingTimer.stop()
		yield(get_tree().create_timer(float(command[2])), "timeout")
		start_text_timer()
		

func skip():
	text_label.visible_characters = -1
	_handle_text_completed()


func reset():
	name_label.text = ''
	name_label.visible = false


func load_theme(theme: ConfigFile):
	# Text
	var theme_font = DialogicUtil.path_fixer_load(theme.get_value('text', 'font', 'res://addons/dialogic/Example Assets/Fonts/DefaultFont.tres'))
	text_label.set('custom_fonts/normal_font', theme_font)
	text_label.set('custom_fonts/bold_font', DialogicUtil.path_fixer_load(theme.get_value('text', 'bold_font', 'res://addons/dialogic/Example Assets/Fonts/DefaultBoldFont.tres')))
	text_label.set('custom_fonts/italics_font', DialogicUtil.path_fixer_load(theme.get_value('text', 'italic_font', 'res://addons/dialogic/Example Assets/Fonts/DefaultItalicFont.tres')))
	name_label.set('custom_fonts/font', DialogicUtil.path_fixer_load(theme.get_value('name', 'font', 'res://addons/dialogic/Example Assets/Fonts/NameFont.tres')))
	
	
	var text_color = Color(theme.get_value('text', 'color', '#ffffffff'))
	text_label.set('custom_colors/default_color', text_color)
	name_label.set('custom_colors/font_color', text_color)

	text_label.set('custom_colors/font_color_shadow', Color('#00ffffff'))
	name_label.set('custom_colors/font_color_shadow', Color('#00ffffff'))

	if theme.get_value('text', 'shadow', false):
		var text_shadow_color = Color(theme.get_value('text', 'shadow_color', '#9e000000'))
		text_label.set('custom_colors/font_color_shadow', text_shadow_color)

	var shadow_offset = theme.get_value('text', 'shadow_offset', Vector2(2,2))
	text_label.set('custom_constants/shadow_offset_x', shadow_offset.x)
	text_label.set('custom_constants/shadow_offset_y', shadow_offset.y)
	

	# Text speed
	text_speed = theme.get_value('text','speed', 2) * 0.01
	theme_text_speed = text_speed

	# Margin
	var text_margin = theme.get_value('text', 'margin', Vector2(20, 10))
	text_label.set('margin_left', text_margin.x)
	text_label.set('margin_right', text_margin.x * -1)
	text_label.set('margin_top', text_margin.y)
	text_label.set('margin_bottom', text_margin.y * -1)

	# Backgrounds
	$TextureRect.texture = DialogicUtil.path_fixer_load(theme.get_value('background','image', "res://addons/dialogic/Example Assets/backgrounds/background-2.png"))
	$ColorRect.color = Color(theme.get_value('background','color', "#ff000000"))

	if theme.get_value('background', 'modulation', false):
		$TextureRect.modulate = Color(theme.get_value('background', 'modulation_color', '#ffffffff'))
	else:
		$TextureRect.modulate = Color('#ffffffff')

	$ColorRect.visible = theme.get_value('background', 'use_color', false)
	$TextureRect.visible = theme.get_value('background', 'use_image', true)

	# Next image
	$NextIndicatorContainer.rect_position = Vector2(0,0)
	next_indicator.texture = DialogicUtil.path_fixer_load(theme.get_value('next_indicator', 'image', 'res://addons/dialogic/Example Assets/next-indicator/next-indicator.png'))
	# Reset for up and down animation
	next_indicator.margin_top = 0 
	next_indicator.margin_bottom = 0 
	next_indicator.margin_left = 0 
	next_indicator.margin_right = 0 
	# Scale
	var indicator_scale = theme.get_value('next_indicator', 'scale', 0.4)
	next_indicator.rect_scale = Vector2(indicator_scale, indicator_scale)
	# Offset
	var offset = theme.get_value('next_indicator', 'offset', Vector2(13, 10))
	next_indicator.rect_position = theme.get_value('box', 'size', Vector2(910, 167)) - (next_indicator.texture.get_size() * indicator_scale)
	next_indicator.rect_position -= offset
	
	# Character Name
	$NameLabel/ColorRect.visible = theme.get_value('name', 'background_visible', false)
	$NameLabel/ColorRect.color = Color(theme.get_value('name', 'background', '#282828'))
	$NameLabel/TextureRect.visible = theme.get_value('name', 'image_visible', false)
	$NameLabel/TextureRect.texture = DialogicUtil.path_fixer_load(theme.get_value('name','image', "res://addons/dialogic/Example Assets/backgrounds/background-2.png"))
	
	var name_padding = theme.get_value('name', 'name_padding', Vector2( 10, 0 ))
	var name_style = name_label.get('custom_styles/normal')
	name_style.set('content_margin_left', name_padding.x)
	name_style.set('content_margin_right', name_padding.x)
	name_style.set('content_margin_bottom', name_padding.y)
	
	var name_shadow_offset = theme.get_value('name', 'shadow_offset', Vector2(2,2))
	if theme.get_value('name', 'shadow_visible', true):
		name_label.set('custom_colors/font_color_shadow', Color(theme.get_value('name', 'shadow', '#9e000000')))
		name_label.set('custom_constants/shadow_offset_x', name_shadow_offset.x)
		name_label.set('custom_constants/shadow_offset_y', name_shadow_offset.y)
	name_label.rect_position.y = theme.get_value('name', 'bottom_gap', 48) * -1 - (name_padding.y)
	if theme.get_value('name', 'modulation', false) == true:
		$NameLabel/TextureRect.modulate = Color(theme.get_value('name', 'modulation_color', '#ffffffff'))
	else:
		$NameLabel/TextureRect.modulate = Color('#ffffffff')
	
	
	# Setting next indicator animation
	next_indicator.self_modulate = Color('#ffffff')
	var animation = theme.get_value('next_indicator', 'animation', 'Up and down')
	next_indicator.get_node('AnimationPlayer').play(animation)
	
	
	# Saving reference to the current theme
	_theme = theme

## *****************************************************************************
##								PRIVATE METHODS
## *****************************************************************************


func _on_writing_timer_timeout():
	# Checks for the 'fade_in_tween_show_time' which only exists during the fade in animation
	# if that node doesn't exists, it won't start the letter by letter animation.
	if get_parent().has_node('fade_in_tween_show_time') == false:
		if _finished == false:
			text_label.visible_characters += 1
			if(commands.size()>0 && commands[0][0] <= text_label.visible_characters):
				handle_command(commands.pop_front()) #handles the command, and removes it from the queue
			if text_label.visible_characters > text_label.get_total_character_count():
				_handle_text_completed()
			elif (
				text_label.visible_characters > 0 and
				text_label.text[text_label.visible_characters-1] != " "
			):
				emit_signal('letter_written')
		else:
			$WritingTimer.stop()


func start_text_timer():
	if text_speed == 0:
		text_label.visible_characters = -1
		_handle_text_completed()
	else:
		$WritingTimer.start(text_speed)
		_finished = false


func _handle_text_completed():
	$WritingTimer.stop()
	_finished = true
	emit_signal("text_completed")


func align_name_label():
	var name_padding = _theme.get_value('name', 'name_padding', Vector2( 10, 0 ))
	var horizontal_offset = _theme.get_value('name', 'horizontal_offset', 0)
	var name_label_position = _theme.get_value('name', 'position', 0)
	var label_size = name_label.rect_size.x
	if name_label_position == 0:
		name_label.rect_global_position.x = rect_global_position.x + horizontal_offset
	elif name_label_position == 1: # Center
		name_label.rect_global_position.x = rect_global_position.x + (rect_size.x / 2) - (label_size / 2) + horizontal_offset
	elif name_label_position == 2: # Right
		name_label.rect_global_position.x = rect_global_position.x + rect_size.x - label_size + horizontal_offset

## *****************************************************************************
##								OVERRIDES
## *****************************************************************************


func _ready():
	reset()
	$WritingTimer.connect("timeout", self, "_on_writing_timer_timeout")
	text_label.meta_underlined = false
	regex.compile("\\[(nw|(nw|speed|signal|play|pause)=(.+?))\\](.*?)")
	
	bbcoderemoverregex.compile("\\[\\/*(b|i|u|s|code|center|right|fill|indent|url|img|font|color|table|cell|wave|tornado|shake|fade|rainbow)[^]]*\\]")

