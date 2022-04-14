tool
extends HBoxContainer

var event_name

signal option_action(action_name)

# Resource
export (Resource) var resource


### internal node eferences
onready var selected_style = $PanelContainer/SelectedStyle
onready var warning = $PanelContainer/MarginContainer/VBoxContainer/Header/CenterContainer/IconPanel/Warning
onready var title_label = $PanelContainer/MarginContainer/VBoxContainer/Header/TitleLabel
onready var icon_texture  = $PanelContainer/MarginContainer/VBoxContainer/Header/CenterContainer/IconPanel/IconTexture
onready var expand_control = $PanelContainer/MarginContainer/VBoxContainer/Header/ExpandControl
onready var header_content_container = $PanelContainer/MarginContainer/VBoxContainer/Header/Content
onready var body_container = $PanelContainer/MarginContainer/VBoxContainer/Body
onready var body_content_container = $PanelContainer/MarginContainer/VBoxContainer/Body/Content
onready var indent_node = $Indent

### extarnal node references
var editor_reference

### the indent size
var indent_size = 45
var current_indent_level = 1

# Setting this to true will ignore the event while saving
# Useful for making placeholder events in drag and drop
var ignore_save = false

## *****************************************************************************
##								PUBLIC METHODS
## *****************************************************************************

func visual_select():
	selected_style.show()


func visual_deselect():
	if selected_style:
		selected_style.hide()


# called by the timeline before adding it to the tree
func load_data(data):
	resource = data


func set_warning(text):
	warning.show()
	warning.hint_tooltip = text


func remove_warning(text = ''):
	if warning.hint_tooltip == text or text == '':
		warning.hide()


func set_preview(text: String):
	expand_control.set_preview(text)


func set_indent(indent: int):
	var indent_node = $Indent
	indent_node.rect_min_size = Vector2(indent_size * indent, 0)
	indent_node.visible = indent != 0
	current_indent_level = indent
	update()


func set_expanded(expanded: bool):
	expand_control.set_expanded(expanded)


## *****************************************************************************
##								PRIVATE METHODS
## *****************************************************************************

func _set_event_icon(icon: Texture):
	icon_texture.texture = icon
	var _scale = DialogicUtil.get_editor_scale(self)
	var cpanel = $PanelContainer/MarginContainer/VBoxContainer/Header/CenterContainer
	var ip = $PanelContainer/MarginContainer/VBoxContainer/Header/CenterContainer/IconPanel
	var ipc = $PanelContainer/MarginContainer/VBoxContainer/Header/CenterContainer/IconPanel/IconTexture
	# Change color if light theme
	ipc.self_modulate = Color(1,1,1,1)
	if not get_constant("dark_theme", "Editor"):
		icon_texture.self_modulate = get_color("font_color", "Editor")
	# Resizing the icon acording to the scale
	var icon_size = 38
	cpanel.rect_min_size = Vector2(icon_size, icon_size) * _scale
	ip.rect_min_size = cpanel.rect_min_size
	ipc.rect_min_size = ip.rect_min_size


func _set_event_name(text: String):
	if resource.name:
		title_label.text = text
	else:
		var t_label = get_node_or_null("PanelContainer/MarginContainer/VBoxContainer/Header/TitleLabel")
		if t_label:
			t_label.queue_free()


func _on_ExpandControl_state_changed(expanded: bool):
	if expanded:
		if resource.body_scene:
			body_container.show()
	else:
		if resource.body_scene:
			body_container.hide()
			expand_control.set_preview(resource.body_scene.get_preview())


func _on_OptionsControl_action(index):
	if index == 0:
		if resource.help_page_path:
			var master_tree = editor_reference.get_node_or_null('MainPanel/MasterTreeContainer/MasterTree')
			master_tree.select_documentation_item(resource.help_page_path)
	elif index == 2:
		emit_signal("option_action", "up")
	elif index == 3:
		emit_signal("option_action", "down")
	elif index == 5:
		emit_signal("option_action", "remove")


func _on_Indent_visibility_changed():
	if not indent_node:
		return
	if resource.needs_indentation:
		if indent_node.visible:
			remove_warning(DTS.translate("This event needs a question event around it!"))
		else:
			set_warning(DTS.translate("This event needs a question event around it!"))


func _on_gui_input(event):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == 1:
		grab_focus() # Grab focus to avoid copy pasting text or events
		if event.doubleclick and expand_control.enabled:
			expand_control.set_expanded(not expand_control.expanded)
	# For opening the context menu
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_RIGHT and event.pressed:
			$PopupMenu.rect_global_position = get_global_mouse_position()
			var popup = $PopupMenu.popup()

	
func _request_selection():
	var timeline_editor = editor_reference.get_node_or_null('MainPanel/TimelineEditor')
	if (timeline_editor != null):
		# @todo select item and clear selection is marked as "private" in TimelineEditor.gd
		# consider to make it "public" or add a public helper function
		timeline_editor.select_item(self)


# called to inform event parts, that a focus is wanted
func focus():
	pass
	#if resource.header_scene:
	#	resource.header_scene.focus()
	#if resource.body_scene:
	#	resource.body_scene.focus()

## *****************************************************************************
##								OVERRIDES
## *****************************************************************************

func _ready():
	if resource.name:
		event_name = DTS.translate(resource.name)
	
	## DO SOME STYLING
	$PanelContainer/SelectedStyle.modulate = get_color("accent_color", "Editor")
	warning.texture = get_icon("NodeWarning", "EditorIcons")
	title_label.add_color_override("font_color", Color.white)
	if not get_constant("dark_theme", "Editor"):
		title_label.add_color_override("font_color", get_color("font_color", "Editor"))
	
	indent_size = indent_size * DialogicUtil.get_editor_scale(self)
	
	if resource.icon != null:
		_set_event_icon(resource.icon)
	if event_name != null:
		_set_event_name(event_name)
	
	var label_editor = load("res://addons/dialogic/Editor/Events/Fields/Label.tscn")
	var text_area = load("res://addons/dialogic/Editor/Events/Fields/TextArea.tscn")
	if resource.header != null:
		print('resource.header: ', resource.header)
		for r in resource.header:
			var new_node = label_editor.instance()
			
			if r.type == 0: # Label
				new_node = label_editor.instance()
				new_node.text = r.key
			if r.type == 1: # Text
				new_node = text_area.instance()
				
			header_content_container.add_child(new_node)
			new_node.owner = self
			
	if resource.body != null:
		print('resource.body: ', resource.body)
		for r in resource.body:
			var new_node = label_editor.instance()
			if r.type == 0: # Label
				new_node = label_editor.instance()
				new_node.text = r.key
			if r.type == 1: # Text
				new_node = text_area.instance()
				
			body_content_container.add_child(new_node)
			new_node.owner = self
		body_content_container.add_constant_override('margin_left', 40*DialogicUtil.get_editor_scale(self))
	$PanelContainer/MarginContainer/VBoxContainer/Header/CenterContainer/IconPanel.set("self_modulate", resource.color)
	
	set_focus_mode(1) # Allowing this node to grab focus
	
	# signals
	$PanelContainer.connect("gui_input", self, '_on_gui_input')
	expand_control.connect("state_changed", self, "_on_ExpandControl_state_changed")
	$PopupMenu.connect("index_pressed", self, "_on_OptionsControl_action")
	
	_on_Indent_visibility_changed()
