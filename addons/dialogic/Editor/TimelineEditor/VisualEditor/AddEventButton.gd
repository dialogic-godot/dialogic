@tool
extends Button

@export var visible_name:String = ""
@export var event_id:String = ''
@export var event_icon:Texture :
	get:
		return event_icon
	set(texture):
		event_icon = texture
		icon = event_icon
@export var event_sorting_index:int = 0
@export var resource:DialogicEvent
@export var dialogic_color_name:String = ''


func _ready() -> void:
	tooltip_text = visible_name
	
	custom_minimum_size = Vector2(get_theme_font("font", 'Label').get_string_size(text).x+35,30) * DialogicUtil.get_editor_scale()
	
	add_theme_color_override("font_color", get_theme_color("font_color", "Editor"))
	add_theme_color_override("font_color_hover", get_theme_color("accent_color", "Editor"))
	apply_base_button_style()


func apply_base_button_style() -> void:
	var nstyle :StyleBoxFlat= get_parent().get_theme_stylebox('normal', 'Button').duplicate()
	nstyle.border_width_left = 5 * DialogicUtil.get_editor_scale()
	add_theme_stylebox_override('normal', nstyle)
	var hstyle :StyleBoxFlat= get_parent().get_theme_stylebox('hover', 'Button').duplicate()
	hstyle.border_width_left = 5 * DialogicUtil.get_editor_scale()
	add_theme_stylebox_override('hover', hstyle)
	set_color(resource.event_color)


func set_color(color:Color) -> void:
	var style := get_theme_stylebox('normal', 'Button')
	style.border_color = color
	add_theme_stylebox_override('normal', style)
	style = get_theme_stylebox('hover', 'Button')
	style.border_color = color
	add_theme_stylebox_override('hover', style)


func toggle_name(on:= false) -> void:
	if !on:
		text = ""
		custom_minimum_size = Vector2(40, 40) * DialogicUtil.get_editor_scale()
		var style := get_theme_stylebox('normal', 'Button')
		style.bg_color = style.border_color.darkened(0.2)
		add_theme_stylebox_override('normal', style)
		style = get_theme_stylebox('hover', 'Button')
		style.bg_color = style.border_color
		add_theme_stylebox_override('hover', style)
	else:
		text = visible_name
		custom_minimum_size = Vector2(get_theme_font("font", 'Label').get_string_size(text).x+35,30) * DialogicUtil.get_editor_scale()
		apply_base_button_style()


func _on_button_down():
	find_parent('VisualEditor').get_node('%TimelineArea').start_dragging(1, resource)
