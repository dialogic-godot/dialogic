tool
extends HBoxContainer

const EventButtonNode = preload("res://addons/dialogic/Editor/event_node/event_node.gd")
const EventClass = preload("res://addons/dialogic/resources/event_class.gd")
const TimelineClass = preload("res://addons/dialogic/resources/timeline_class.gd")

class EventButton extends Button:
	var event_script:Script
	
	func get_drag_data(position):
		var node = EventButtonNode.new()
		node.event = event_script.new()
		node.call_deferred("update_values")
		set_drag_preview(node)
		return {"event":event_script.new()}
	
	
	func _init():
		clip_text = true
		expand_icon = true
		size_flags_vertical = SIZE_EXPAND_FILL
		rect_min_size = Vector2(24,24)


class Category extends VBoxContainer:
	signal event_button_added(button)
	
	var name_label:Label
	var event_scripts:Array = []
	var button_container:HBoxContainer
	
	func add_event(event) -> void:
		var event_script:Script = event.get_script()
		if event_script in event_scripts:
			return
		
		event_scripts.append(event_script)
		
		var btn := EventButton.new()
		btn.icon = event.event_icon
		btn.event_script = event_script
		var event_hint := "{event_name}\n-----\n{event_hint}"
		btn.hint_tooltip = event_hint.format({"event_name":event.get("event_name"), "event_hint":event.get("event_hint")})
		button_container.add_child(btn)
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
		add_child(name_label)
		
		button_container = HBoxContainer.new()
		button_container.alignment = BoxContainer.ALIGN_CENTER
		add_child(button_container)


signal toolbar_button_pressed(button, event_script)

var know_events:TimelineClass
var categories:Dictionary = {}

func reload() -> void:
	for child in get_children():
		child.queue_free()
		categories.clear()
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
	if get_child_count() > 0:
		add_child(VSeparator.new())
	add_child(category)


func _enter_tree():
	know_events = TimelineClass.new()
	if not know_events.is_connected("changed",self,"reload"):
		know_events.connect("changed",self,"reload")
	theme = Theme.new()
	var button_stylebox:StyleBox = get_stylebox("normal", "Button").duplicate()
	button_stylebox.content_margin_bottom = 1
	button_stylebox.content_margin_left = 1
	button_stylebox.content_margin_right = 1
	button_stylebox.content_margin_top = 1
	theme.set_stylebox("normal", "Button", button_stylebox)
	var hover_stylebox:StyleBox = get_stylebox("hover", "Button").duplicate()
	hover_stylebox.content_margin_bottom = 3
	hover_stylebox.content_margin_left = 3
	hover_stylebox.content_margin_right = 3
	hover_stylebox.content_margin_top = 3
	theme.set_stylebox("hover", "Button", hover_stylebox)


func _on_Category_event_button_added(event_button:EventButton) -> void:
	event_button.connect("pressed", self, "_on_Category_event_button_pressed", [event_button])


func _on_Category_event_button_pressed(event_button:EventButton) -> void:
	emit_signal("toolbar_button_pressed", event_button, event_button.event_script)


func _notification(what: int) -> void:
	if what == NOTIFICATION_POST_ENTER_TREE:
		know_events.emit_changed()


func _init():
	alignment = BoxContainer.ALIGN_CENTER
	categories = {}
	name = "CategoryManager"
