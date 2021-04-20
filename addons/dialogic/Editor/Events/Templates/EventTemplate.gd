tool
extends HBoxContainer

export(StyleBoxFlat) var event_style : StyleBoxFlat
export(Texture) var event_icon : Texture
export(String) var event_name : String
export(PackedScene) var header_scene : PackedScene
export(PackedScene) var body_scene : PackedScene

signal option_action(action_name)

onready var panel = $PanelContainer
onready var title_container = $PanelContainer/MarginContainer/VBoxContainer/Header/TitleHBoxContainer
onready var title_label = $PanelContainer/MarginContainer/VBoxContainer/Header/TitleHBoxContainer/TitleMarginContainer/TitleLabel
onready var icon_texture  = $PanelContainer/MarginContainer/VBoxContainer/Header/IconMarginContainer/IconTexture
onready var expand_control = $PanelContainer/MarginContainer/VBoxContainer/Header/ExpandControl
onready var options_control = $PanelContainer/MarginContainer/VBoxContainer/Header/OptionsControl
onready var header_content_container = $PanelContainer/MarginContainer/VBoxContainer/Header/Content
onready var body_container = $PanelContainer/MarginContainer/VBoxContainer/Body
onready var body_content_container = $PanelContainer/MarginContainer/VBoxContainer/Body/Content
onready var indent_node = $Indent

var editor_reference

var header_node
var body_node
var indent_size = 25

# Setting this to true will ignore the event while saving
# Useful for making placeholder events in drag and drop
var ignore_save = false

# This is the data that is going to be saved to json
var event_data := {}

## *****************************************************************************
##								PUBLIC METHODS
## *****************************************************************************

# Called when timeline editor loads
func load_data(data):
	event_data = data


func set_event_style(style: StyleBoxFlat):
	panel.set('custom_styles/panel', style)


func get_event_style():
	return panel.get('custom_styles/panel')
	

func set_event_icon(icon: Texture):
	icon_texture.texture = icon


func set_event_name(text: String):
	title_label.text = text
	if text.empty():
		title_container.hide()
	else:
		title_container.show()


func set_header(scene: PackedScene):
	header_node = _set_content(header_content_container, scene)


func set_body(scene: PackedScene):
	body_node = _set_content(body_content_container, scene)
	expand_control.set_enabled(body_node != null)


func get_body():
	return body_node


func get_header():
	return header_node


func set_preview(text: String):
	expand_control.set_preview(text)


func set_indent(indent: int):
	indent_node.rect_min_size = Vector2(indent_size * indent, 0)
	indent_node.visible = indent != 0


# Override in inherited class
func on_timeline_selected(selected: bool):
	pass


func set_expanded(expanded: bool):
	expand_control.set_expanded(expanded)


## *****************************************************************************
##								PRIVATE METHODS
## *****************************************************************************


func _setup_event():
	if event_style != null:
		set_event_style(event_style)
	if event_icon != null:
		set_event_icon(event_icon)
	if event_name != null:
		set_event_name(event_name)
	if header_scene != null:
		set_header(header_scene)
	if body_scene != null:
		set_body(body_scene)


func _set_content(container: Control, scene: PackedScene):
	for c in container.get_children():
		container.remove_child(c)
	if scene != null:
		var node = scene.instance()
		container.add_child(node)
#		node.set_owner(get_tree().get_edited_scene_root())
		return node
	return null


func _on_ExpandControl_state_changed(expanded: bool):
	if expanded:
		body_container.show()
	else:
		body_container.hide()


func _on_OptionsControl_action(action_name: String):
	# Simply transmit the signal to the timeline editor
	emit_signal("option_action", action_name)


func _on_gui_input(event):
	if event is InputEventMouseButton and event.is_pressed() and event.doubleclick and event.button_index == 1 and expand_control.enabled:
		expand_control.set_expanded(not expand_control.expanded)


## *****************************************************************************
##								OVERRIDES
## *****************************************************************************


func _ready():
	_setup_event()
	panel.connect("gui_input", self, '_on_gui_input')
	expand_control.connect("state_changed", self, "_on_ExpandControl_state_changed")
	options_control.connect("action", self, "_on_OptionsControl_action")
	expand_control.set_enabled(body_scene != null)
