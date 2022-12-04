@tool
extends Button

@export var visible_name:String = ""
@export var event_id:String = ''
@export var event_icon:Texture :
	get:
		return event_icon
	set(texture):
		event_icon = texture
		%Icon.texture = texture
@export var event_category:int = 0
@export var event_sorting_index:int = 0
@export var resource:Resource
@export var dialogic_color_name:String = ''

func _ready():
	self_modulate = Color(1,1,1)
	if visible_name != '':
		text = '  ' + visible_name
	#tooltip_text = DTS.translate(tooltip_text)
	
	var _scale = DialogicUtil.get_editor_scale()
	custom_minimum_size = Vector2(30,30)* _scale
	icon = null

	%ColorBorder.custom_minimum_size.x = 5 * _scale
	%IconContainer.custom_minimum_size = custom_minimum_size
	
	add_theme_color_override("font_color", get_theme_color("font_color", "Editor"))
	add_theme_color_override("font_color_hover", get_theme_color("accent_color", "Editor"))
	%Icon.modulate = get_theme_color("font_color", "Button")
	
	# TODO godot4 signal was removed. find a way to react to color changes
	# ProjectSettings.project_settings_changed.connect(_update_color)

func set_color(color):
	%ColorBorder.self_modulate = color

#func _update_color():
#	if dialogic_color_name != '':
#		var new_color = DialogicUtil.get_color(dialogic_color_name)
#		resource.event_color = new_color
#		%ColorBorder.self_modulate = DialogicUtil.get_color(dialogic_color_name)

func _get_drag_data(position):
	var preview_label = Label.new()
	
	preview_label.text = 'Add Event %s' % [ tooltip_text ]
	if self.text != '':
		preview_label.text = text
		
	set_drag_preview(preview_label)
	
	return { "source": "EventButton", "resource": resource }
