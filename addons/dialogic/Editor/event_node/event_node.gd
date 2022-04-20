tool
extends HBoxContainer

const EventClass = preload("res://addons/dialogic/resources/event_class.gd")
const TimelineClass = preload("res://addons/dialogic/resources/timeline_class.gd")

class DragData:
	var event
	var related_timeline

var event_button:Button

## Event related to this node
var event:EventClass setget set_event

## Timeline that contains this event. Used as editor hint
var timeline:TimelineClass
var idx:int setget set_idx

# Background
var __bg:PanelContainer
var __indent_node:Control
var __header:HBoxContainer
var __body:MarginContainer
var __icon_container:PanelContainer
var __icon_node:TextureRect
var __event_label:Label
var __expand_button:CheckButton

func update_values() -> void:
	__update_event_icon()
	__update_event_name()
	
	if has_method("_update_values"):
		call("_update_values")


func add_node_at_header(node:Control) -> void:
	__header.get_child(1).add_child(node)


func add_node_at_body(node:Control) -> void:
	__expand_button.visible = true
	__body.get_child(0).add_child(node)


func set_event(_event) -> void:
	if event and event.is_connected("changed",self,"update_values"):
		event.disconnect("changed",self,"update_values")
	
	event = _event
	
	if event != null:
		if not event.is_connected("changed",self,"update_values"):
			event.connect("changed",self,"update_values")
		name = event.event_name


func set_idx(value:int) -> void:
	idx = value


func set_button_group(button_group:ButtonGroup) -> void:
	event_button.set_button_group(button_group)


func _on_event_button_toggled(toggled:bool) -> void:
	var color:Color
	var style:StyleBox
	if toggled:
		style =  get_stylebox("hover", "EventNode")
		color = Color.cyan if not Engine.editor_hint else get_color("accent_color", "Editor")
	else:
		style = StyleBoxEmpty.new()
		color = Color.white
	
	__bg.add_stylebox_override("panel", style)
	event_button.modulate = color


func _on_expand_toggled(toggled:bool) -> void:
	__body.visible = toggled


func __update_event_name() -> void:
		var text := "{Event Name}"
		if event:
			text = event.event_name
		__event_label.text = text


func __update_event_icon() -> void:
	var icon:Texture = get_icon("warning", "EditorIcons")
	if event:
		icon = event.event_icon
	__icon_node.texture = icon


func _notification(what):
	match what:
		NOTIFICATION_THEME_CHANGED:
			var none := StyleBoxEmpty.new()
			event_button.add_stylebox_override("normal", none)
			event_button.add_stylebox_override("hover", get_stylebox("hover", "EventNode"))
			event_button.add_stylebox_override("pressed", get_stylebox("pressed", "EventNode"))
			event_button.add_stylebox_override("focus", get_stylebox("hover", "EventNode"))
			
			__header.get_child(0).set("rect_min_size", Vector2(get_constant("margin_left", "EventNode"),0))
			
			var icon_bg = StyleBoxTexture.new()
			icon_bg.texture = get_icon("bg", "EventNode")
			__icon_container.add_stylebox_override("panel", icon_bg)
			
			__expand_button.add_icon_override("off", get_icon("unchecked", "EventNode"))
			__expand_button.add_icon_override("on", get_icon("checked", "EventNode"))
			
			__body.add_constant_override("margin_left", 50)


func _init():
	name = "EventNode"
	size_flags_horizontal = SIZE_EXPAND_FILL
	rect_clip_content = true
	mouse_filter = Control.MOUSE_FILTER_PASS
	
	__indent_node = Control.new()
	add_child(__indent_node)
	
	__bg = PanelContainer.new()
	__bg.focus_mode = Control.FOCUS_NONE
	__bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	__bg.add_stylebox_override("panel", StyleBoxEmpty.new())
	__bg.size_flags_horizontal = SIZE_EXPAND_FILL
	add_child(__bg)
	
	event_button = Button.new()
	event_button.toggle_mode = true
	event_button.focus_mode = Control.FOCUS_ALL
	event_button.mouse_filter = Control.MOUSE_FILTER_PASS
	event_button.name = "UIBehaviour"
	event_button.set_meta("event_node", self)
	event_button.connect("toggled", self, "_on_event_button_toggled")
	__bg.add_child(event_button)
	
	var vb = VBoxContainer.new()
	vb.focus_mode = Control.FOCUS_NONE
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	__header = HBoxContainer.new()
	__header.name = "Header"
	__header.focus_mode = Control.FOCUS_NONE
	__header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	__header.add_child(Control.new())
	__header.add_child(HBoxContainer.new())
	
	__body = MarginContainer.new()
	__body.name = "Body"
	__body.focus_mode = Control.FOCUS_NONE
	__body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	__body.add_child(VBoxContainer.new())
	
	__expand_button = CheckButton.new()
	__expand_button.visible = false
	__expand_button.connect("toggled", self, "_on_expand_toggled")
	__expand_button.set_pressed_no_signal(true)
	__header.add_child(__expand_button)
	
	vb.add_child(__header)
	vb.add_child(__body)
	__bg.add_child(vb)
	
	__icon_container = PanelContainer.new()
	__icon_node = TextureRect.new()
	__icon_node.name = "Icon"
	__icon_node.expand = true
	__icon_node.rect_min_size = Vector2(32,32)
	__icon_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	__icon_node.show_behind_parent = true
	__icon_container.add_child(__icon_node)
	add_node_at_header(__icon_container)
	
	__event_label = Label.new()
	add_node_at_header(__event_label)
