tool
extends PanelContainer

const EventButtonNode = preload("res://addons/dialogic/Editor/event_node/event_node.gd")
const EventClass = preload("res://addons/dialogic/resources/event_class.gd")
const TimelineClass = preload("res://addons/dialogic/resources/timeline_class.gd")

class EventButton extends PanelContainer:
	var event_script:Script
	var icon
	var text
	
	var button:ToolButton
	var border:PanelContainer
	var icon_node:TextureRect
	var spacer:Control
	var text_node:Label
	
	func get_drag_data(position):
		var node = EventButtonNode.new()
		node.event = event_script.new()
		node.call_deferred("update_values")
		set_drag_preview(node)
		return {"event":event_script.new()}
	
	func _ready():
		border.add_stylebox_override("panel", get_stylebox("border", "EventButton"))
		add_stylebox_override("panel", get_stylebox("normal", "EventButton"))
	
	func _init():
		rect_clip_content = true
		size_flags_vertical = SIZE_EXPAND_FILL
		
		button = ToolButton.new()
		button.show_behind_parent = true
		button.mouse_filter = Control.MOUSE_FILTER_PASS
		add_child(button)
		
		icon_node = TextureRect.new()
		icon_node.focus_mode = Control.FOCUS_NONE
		icon_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_node.rect_min_size = Vector2(24,24)
		
		text_node = Label.new()
		text_node.focus_mode = Control.FOCUS_NONE
		text_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		border = PanelContainer.new()
		border.focus_mode = Control.FOCUS_NONE
		border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		border.rect_min_size.x = 4
		
		spacer = Control.new()
		spacer.focus_mode = Control.FOCUS_NONE
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spacer.rect_min_size = Vector2(2, 0)
		
		var hb := HBoxContainer.new()
		hb.size_flags_horizontal = SIZE_EXPAND_FILL
		hb.focus_mode = Control.FOCUS_NONE
		hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_constant_override("separation", 0)
		hb.add_child(border)
		hb.add_child(icon_node)
		hb.add_child(spacer)
		hb.add_child(text_node)
		
		add_child(hb)


class Category extends VBoxContainer:
	const FlowContainer = preload("res://addons/dialogic/Other/flow_container.gd")
	
	signal event_button_added(button)
	
	var name_label:Label
	var event_scripts:Array = []
	var button_container:FlowContainer
	
	func add_event(event) -> void:
		var event_script:Script = event.get_script()
		if event_script in event_scripts:
			return
		
		event_scripts.append(event_script)
		
		var btn := EventButton.new()
		btn.event_script = event_script
		btn.icon_node.texture = event.event_icon
		btn.text_node.text = event.get("event_name")
		var event_hint := "{event_name}\n-----\n{event_hint}"
		btn.hint_tooltip = event_hint.format({"event_name":event.get("event_name"), "event_hint":event.get("event_hint")})
		button_container.add_child(btn)
		btn.add_color_override("font_color", get_color("font_color", "Editor"))
		btn.add_color_override("font_color_hover", get_color("accent_color", "Editor"))
		emit_signal("event_button_added", btn)
	
	
	func _set(property, value) -> bool:
		if property == "name":
			name = value
			name_label.text = value
			return true
		return false
	
	
	func _init():
		event_scripts = []
		name_label = Label.new()
		name_label.align = Label.ALIGN_CENTER
		var separator = HSeparator.new()
		separator.size_flags_horizontal = SIZE_EXPAND_FILL
		var hb = HBoxContainer.new()
		hb.size_flags_horizontal = SIZE_EXPAND_FILL
		hb.add_child(name_label)
		hb.add_child(separator)
		add_child(hb)
		
		button_container = FlowContainer.new()
		add_child(button_container)


signal toolbar_button_pressed(button, event_script)

var know_events:TimelineClass
var categories:Dictionary = {}

var _category_container:VBoxContainer

func reload() -> void:
	categories.clear()
	
	for child in _category_container.get_children():
		child.queue_free()
	
	create_categories()


func create_categories() -> void:
	for event in know_events.get_events():
		event = event as EventClass
		if not event:
			continue
		
		var category:String = event.event_category
		add_category(category)
		
		var category_node:Category = categories.get(category, null)
		category_node.add_event(event)


func add_category(category_name:String) -> void:
	if category_name in categories:
		return
	
	var category:Category = Category.new()
	categories[category_name] = category
	
	category.connect("event_button_added", self, "_on_Category_event_button_added")
	category.name = category_name
	_category_container.add_child(category)


func _enter_tree():
	know_events = TimelineClass.new()
	know_events.add_event(EventClass.new())
	
	if not know_events.is_connected("changed",self,"reload"):
		know_events.connect("changed",self,"reload")


func _on_Category_event_button_added(event_button:EventButton) -> void:
	event_button.button.connect("pressed", self, "_on_Category_event_button_pressed", [event_button])


func _on_Category_event_button_pressed(event_button:EventButton) -> void:
	emit_signal("toolbar_button_pressed", event_button, event_button.event_script)


func _notification(what: int) -> void:
	if what == NOTIFICATION_POST_ENTER_TREE:
		know_events.emit_changed()


func _init():
	categories = {}
	name = "CategoryManager"
	size_flags_vertical = SIZE_EXPAND_FILL
	rect_min_size = Vector2(128, 64)
	
	var _sc = ScrollContainer.new()
	_sc.size_flags_horizontal = SIZE_EXPAND_FILL
	_sc.size_flags_vertical = SIZE_EXPAND_FILL
	add_child(_sc)
	
	_category_container = VBoxContainer.new()
	_category_container.size_flags_horizontal = SIZE_EXPAND_FILL
	_category_container.size_flags_vertical = SIZE_EXPAND_FILL
	_sc.add_child(_category_container)
