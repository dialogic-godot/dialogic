tool
extends Control

var text_speed := 0.02 # Higher = lower speed

onready var text_label = $RichTextLabel
onready var name_label = $NameLabel
onready var tween = $Tween
onready var next_indicator = $NextIndicatorContainer/NextIndicator

var _finished := false

signal text_completed()


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
		if autocolor:
			name_label.set('custom_colors/font_color', color)
	else:
		name_label.visible = false


func update_text(text):
	# Updating the text and starting the animation from 0
	text_label.bbcode_text = text
	text_label.percent_visible = 0

	# The call to this function needs to be deferred.
	# More info: https://github.com/godotengine/godot/issues/36381
	call_deferred("_start_text_tween")
	return true


func is_finished():
	return _finished


func skip():
	tween.seek(999)
	_on_Tween_tween_completed(null, null)


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

	# Margin
	var text_margin = theme.get_value('text', 'margin', Vector2(20, 10))
	text_label.set('margin_left', text_margin.x)
	text_label.set('margin_right', text_margin.x * -1)
	text_label.set('margin_top', text_margin.y)
	text_label.set('margin_bottom', text_margin.y * -1)

	# Backgrounds
	$TextureRect.texture = DialogicUtil.path_fixer_load(theme.get_value('background','image', "res://addons/dialogic/Example Assets/backgrounds/background-2.png"))
	$ColorRect.color = Color(theme.get_value('background','color', "#ff000000"))

	if theme.get_value('background', 'modulation', false) == true:
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
	var name_shadow_offset = theme.get_value('name', 'shadow_offset', Vector2(2,2))
	if theme.get_value('name', 'shadow_visible', true):
		name_label.set('custom_colors/font_color_shadow', Color(theme.get_value('name', 'shadow', '#9e000000')))
		name_label.set('custom_constants/shadow_offset_x', name_shadow_offset.x)
		name_label.set('custom_constants/shadow_offset_y', name_shadow_offset.y)
	name_label.rect_position.y = theme.get_value('name', 'bottom_gap', 48) * -1
	if theme.get_value('name', 'modulation', false) == true:
		$NameLabel/TextureRect.modulate = Color(theme.get_value('name', 'modulation_color', '#ffffffff'))
	else:
		$NameLabel/TextureRect.modulate = Color('#ffffffff')
	
	# Setting next indicator animation
	next_indicator.self_modulate = Color('#ffffff')
	var animation = theme.get_value('next_indicator', 'animation', 'Up and down')
	next_indicator.get_node('AnimationPlayer').play(animation)


## *****************************************************************************
##								PRIVATE METHODS
## *****************************************************************************


func _on_Tween_tween_completed(object, key):
	_finished = true
	emit_signal("text_completed")


func _start_text_tween():
	# This will start the animation that makes the text appear letter by letter
	var tween_duration = text_speed * text_label.get_total_character_count()
	tween.interpolate_property(
		text_label, "percent_visible", 0, 1, tween_duration,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
	)
	_finished = false
	tween.start()


## *****************************************************************************
##								OVERRIDES
## *****************************************************************************


func _ready():
	reset()
	tween.connect("tween_completed", self, '_on_Tween_tween_completed')
	text_label.meta_underlined = false
