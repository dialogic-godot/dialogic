tool
extends HBoxContainer

# customization options for the event 

# This is the default data that is going to be saved to json
export (Dictionary) var event_data: Dictionary = {'event_id':'dialogic_000'}
export(StyleBoxFlat) var event_style : StyleBoxFlat
var selected_style = preload("../styles/selected_styleboxflat_template.tres")

export(Texture) var event_icon : Texture
export(String) var event_name : String
export(PackedScene) var header_scene : PackedScene
export(PackedScene) var body_scene : PackedScene
export (bool) var expand_on_default := false
export (bool) var needs_indentation := false
signal option_action(action_name)


### internal node eferences
onready var panel = $PanelContainer
onready var warning = $PanelContainer/MarginContainer/VBoxContainer/Header/Warning
onready var title_label = $PanelContainer/MarginContainer/VBoxContainer/Header/TitleLabel
onready var icon_texture  = $PanelContainer/MarginContainer/VBoxContainer/Header/IconTexture
onready var expand_control = $PanelContainer/MarginContainer/VBoxContainer/Header/ExpandControl
onready var options_control = $PanelContainer/MarginContainer/VBoxContainer/Header/OptionsControl
onready var header_content_container = $PanelContainer/MarginContainer/VBoxContainer/Header/Content
onready var body_container = $PanelContainer/MarginContainer/VBoxContainer/Body
onready var body_content_container = $PanelContainer/MarginContainer/VBoxContainer/Body/Content
onready var indent_node = $Indent

var header_node
var body_node

### extarnal node references
var editor_reference

### the indent size
const indent_size = 25

# Setting this to true will ignore the event while saving
# Useful for making placeholder events in drag and drop
var ignore_save = false

## *****************************************************************************
##								PUBLIC METHODS
## *****************************************************************************

func visual_select():
	set_event_style(selected_style)


func visual_deselect():
	set_event_style(event_style)


func set_event_style(style: StyleBoxFlat):
	panel.set('custom_styles/panel', style)


func get_event_style():
	return panel.get('custom_styles/panel')
	

# called by the timeline before adding it to the tree
func load_data(data):
	event_data = data


func get_body():
	return body_node


func get_header():
	return header_node


func set_warning(text):
	warning.texture = get_icon("NodeWarning", "EditorIcons")
	warning.hint_tooltip = text


func remove_warning(text = ''):
	if warning.hint_tooltip == text or text == '':
		warning.texture = null


func set_preview(text: String):
	expand_control.set_preview(text)


func set_indent(indent: int):
	indent_node.rect_min_size = Vector2(indent_size * indent, 0)
	indent_node.visible = indent != 0


func set_expanded(expanded: bool):
	expand_control.set_expanded(expanded)


## *****************************************************************************
##								PRIVATE METHODS
## *****************************************************************************

func _set_event_icon(icon: Texture):
	icon_texture.texture = icon


func _set_event_name(text: String):
	title_label.text = text


func _set_header(scene: PackedScene):
	header_node = _set_content(header_content_container, scene)
	header_node.editor_reference = editor_reference


func _set_body(scene: PackedScene):
	body_node = _set_content(body_content_container, scene)
	body_node.editor_reference = editor_reference
	# show the expand toggle
	expand_control.set_enabled(body_node != null)


func _setup_event():
	if event_style != null:
		set_event_style(event_style)
	if event_icon != null:
		_set_event_icon(event_icon)
	if event_name != null:
		_set_event_name(event_name)
	if header_scene != null:
		_set_header(header_scene)
	if body_scene != null:
		_set_body(body_scene)


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
		if body_node:
			body_container.show()
	else:
		if body_node:
			body_container.hide()
			expand_control.set_preview(body_node.get_preview())


func _on_OptionsControl_action(action_name: String):
	# Simply transmit the signal to the timeline editor
	emit_signal("option_action", action_name)


func _on_Indent_visibility_changed():
	if not indent_node:
		return
	if needs_indentation:
		if indent_node.visible:
			remove_warning("This event needs a question event around it!")
		else:
			set_warning("This event needs a question event around it!")


func _on_gui_input(event):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == 1:
		grab_focus() # Grab focus to avoid copy pasting text or events
		if event.doubleclick and expand_control.enabled:
			expand_control.set_expanded(not expand_control.expanded)


# called when the data of the header is changed
func _on_Header_data_changed(new_event_data):
	event_data = new_event_data
	
	# update the body in case it has to
	if get_body():
		get_body().load_data(event_data)


# called when the data of the body is changed
func _on_Body_data_changed(new_event_data):
	event_data = new_event_data
	
	# update the header in case it has to
	if get_header():
		get_header().load_data(event_data)

func _request_set_body_enabled(enabled:bool):
	expand_control.set_enabled(enabled)
	
	if get_body():
		get_body().visible = enabled
	
func _request_selection():
	var timeline_editor = editor_reference.get_node_or_null('MainPanel/TimelineEditor')
	if (timeline_editor != null):
		# @todo select item and clear selection is marked as "private" in TimelineEditor.gd
		# consider to make it "public" or add a public helper function
		timeline_editor.select_item(self)

## *****************************************************************************
##								OVERRIDES
## *****************************************************************************

func _ready():
	_setup_event()
	
	set_focus_mode(1) # Allowing this node to grab focus
	
	# signals
	panel.connect("gui_input", self, '_on_gui_input')
	expand_control.connect("state_changed", self, "_on_ExpandControl_state_changed")
	options_control.connect("action", self, "_on_OptionsControl_action")

	
	# when it enters the tree, load the data into the header/body
	# If there is any external data, it will be set already BEFORE the event is added to tree
	# if you have a header
	if get_header():
		get_header().connect("data_changed", self, "_on_Header_data_changed")
		get_header().connect("request_open_body", expand_control, "set_expanded", [true])
		get_header().connect("request_close_body", expand_control, "set_expanded", [false])
		get_header().connect("request_selection", self, "_request_selection")
		get_header().connect("request_set_body_enabled", self, "_request_set_body_enabled")
		get_header().connect("set_warning", self, "set_warning")
		get_header().connect("remove_warning", self, "remove_warning")
		get_header().load_data(event_data)
	# if you have a body
	if get_body():
		get_body().connect("data_changed", self, "_on_Body_data_changed")
		get_body().connect("request_open_body", expand_control, "set_expanded", [true])
		get_body().connect("request_close_body", expand_control, "set_expanded", [false])
		get_body().connect("request_set_body_enabled", self, "_request_set_body_enabled")
		get_body().connect("request_selection", self, "_request_selection")
		get_body().connect("set_warning", self, "set_warning")
		get_body().connect("remove_warning", self, "remove_warning")
		get_body().load_data(event_data)
	
	if get_body():
		set_expanded(expand_on_default)
	
	_on_Indent_visibility_changed()

