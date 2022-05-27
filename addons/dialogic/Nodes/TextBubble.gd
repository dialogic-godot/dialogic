tool
extends Control

var text_speed := 0.02 # Higher = lower speed
var theme_text_speed = text_speed
var theme_text_max_height = 0

#experimental database of current commands
var commands = []
#the regex matching object
var regex = RegEx.new()
var bbcoderemoverregex = RegEx.new()

onready var text_container = $TextContainer
onready var text_label = $TextContainer/RichTextLabel
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
	var name_is_hidden = _theme.get_value('name', 'is_hidden', false)
	if name_is_hidden:
		name_label.visible = false
		return
	
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

func clear():
	text_label.bbcode_text = ""
	name_label.text = ""
	$WritingTimer.stop()

func update_text(text:String):
	
	var orig_text = text
	text_label.bbcode_text = text
	var text_bbcodefree = text_label.text
	
	#regex moved from func scope to class scope
	#regex compilation moved to _ready
	#  - KvaGram
	#var regex = RegEx.new()
	var result:RegExMatch = null
	text_speed = theme_text_speed # Resetting the speed to the default
	commands = []
	
	### remove commands from text, and store where and what they are
	#current regex: \[\s*(nw|(nw|speed|signal|play|pause)\s*=\s*(.+?)\s*)\](.*?)
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
			commands.append([result.get_start()-1, result.get_string(2).strip_edges(), result.get_string(3).strip_edges()])
		text_bbcodefree = text_bbcodefree.substr(0, result.get_start()) + text_bbcodefree.substr(result.get_end())
		text = text.replace(result.get_string(), "")
		
		result = regex.search(text_bbcodefree)

	text_label.bbcode_text = text
	text_label.visible_characters = 0

	## SIZING THE RICHTEXTLABEL
	# The sizing is done in a very terrible way because the RichtTextLabel has 
	# a hard time knowing what size it will be and how to display this.
	# for this reason the RichTextLabel ist first set to just go for the size it needs,
	# even if this might be more than available.
	text_label.size_flags_vertical = 0
	text_label.rect_clip_content = 0
	text_label.fit_content_height = true
	# a frame later, when the sizes have been updated, it will check if there 
	# is enough space or the scrollbar should be activated.
	call_deferred("update_sizing")
	
	
	# updating the size alignment stuff
	text_label.grab_focus()
	start_text_timer()
	return true

func update_sizing():
	# this will enable/disable the scrollbar based on the size of the text
	theme_text_max_height = text_container.rect_size.y

	if text_label.rect_size.y >= theme_text_max_height:
		text_label.fit_content_height = false
		text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	else:
		text_label.fit_content_height = true
		text_label.size_flags_vertical = 0


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
	elif(command[1] == "pause"):
		$WritingTimer.stop()
		var x = text_label.visible_characters
		get_parent().get_node("DialogicTimer").start(float(command[2]))
		yield(get_parent().get_node("DialogicTimer"), "timeout")
		# only continue, if no skip was performed
		if text_label.visible_characters == x: 
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
	
	# setting the vertical alignment
	var alignment = theme.get_value('text', 'alignment',0)
	if alignment <= 2: # top
		text_container.alignment = BoxContainer.ALIGN_BEGIN
	elif alignment <= 5: # center
		text_container.alignment = BoxContainer.ALIGN_CENTER
	elif alignment <= 8: # bottom
		text_container.alignment = BoxContainer.ALIGN_END
	
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
	text_container.set('margin_left', theme.get_value('text', 'text_margin_left', 20))
	text_container.set('margin_right', theme.get_value('text', 'text_margin_right', -20))
	text_container.set('margin_top', theme.get_value('text', 'text_margin_top', 10))
	text_container.set('margin_bottom', theme.get_value('text', 'text_margin_bottom', -10))

	# Backgrounds
	$TextureRect.texture = DialogicUtil.path_fixer_load(theme.get_value('background','image', "res://addons/dialogic/Example Assets/backgrounds/background-2.png"))
	$ColorRect.color = Color(theme.get_value('background','color', "#ff000000"))

	if theme.get_value('background', 'modulation', false):
		$TextureRect.modulate = Color(theme.get_value('background', 'modulation_color', '#ffffffff'))
	else:
		$TextureRect.modulate = Color('#ffffffff')

	$ColorRect.visible = theme.get_value('background', 'use_color', false)
	$TextureRect.visible = theme.get_value('background', 'use_image', true)
	$TextureRect.visible = theme.get_value('background', 'use_image', true)
	$TextureRect.patch_margin_left = theme.get_value('ninepatch', 'ninepatch_margin_left', 0)
	$TextureRect.patch_margin_right = theme.get_value('ninepatch', 'ninepatch_margin_right', 0)
	$TextureRect.patch_margin_top = theme.get_value('ninepatch', 'ninepatch_margin_top', 0)
	$TextureRect.patch_margin_bottom = theme.get_value('ninepatch', 'ninepatch_margin_bottom', 0)

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
	name_style.set('content_margin_top', name_padding.y)
	
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
	if _finished == false:
		text_label.visible_characters += 1
		if(commands.size()>0 && commands[0][0] <= text_label.visible_characters):
			handle_command(commands.pop_front()) #handles the command, and removes it from the queue
		if text_label.visible_characters > text_label.get_total_character_count():
			_handle_text_completed()
		elif (
			text_label.visible_characters > 0 and 
			#text_label.text.length() > text_label.visible_characters-1 and 
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
	regex.compile("\\[\\s*(nw|(nw|speed|signal|play|pause)\\s*=\\s*(.+?)\\s*)\\](.*?)")
	
