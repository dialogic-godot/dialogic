tool
extends HBoxContainer

var event_name

signal option_action(action_name)
signal content_changed()

# Resource
var resource : DialogicEvent


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

var end_node = null setget set_end_node
var collapsed = false

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
	if resource.event_name:
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
		if not resource.help_page_path.empty():
			OS.shell_open(resource.help_page_path)
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

func toggle_collapse(toggled):
	collapsed = toggled
	print("TOGGLED ", toggled)
	var timeline_editor = find_parent('TimelineEditor')
	if (timeline_editor != null):
		# @todo select item and clear selection is marked as "private" in TimelineEditor.gd
		# consider to make it "public" or add a public helper function
		timeline_editor.indent_events()


func set_end_node(node):
	end_node = node
	$PanelContainer/MarginContainer/VBoxContainer/Header/CollapseButton.visible = true if end_node else false


func build_editor():
	#print('Building event node')
	var p_list = resource._get_property_list()
	#print(p_list)
	for p in p_list:
		### --------------------------------------------------------------------
		### 1. CREATE A NODE OF THE CORRECT TYPE FOR THE PROPERTY
		var editor_node
		if p.type == TYPE_STRING:
			if p.get("dialogic_type") == resource.DialogicValueType.MultilineText:
				editor_node = load("res://addons/dialogic/Editor/Events/Fields/MultilineText.tscn").instance()
			else:
				editor_node = load("res://addons/dialogic/Editor/Events/Fields/SinglelineText.tscn").instance()
		
		elif p.type == TYPE_OBJECT and p.has('dialogic_type'):
			editor_node = load("res://addons/dialogic/Editor/Events/Fields/DialogicResourcePicker.tscn").instance()
			if p.dialogic_type == resource.DialogicValueType.Character:
				editor_node.resource_type = editor_node.resource_types.Characters
			elif p.dialogic_type == resource.DialogicValueType.Portrait:
				editor_node.resource_type = editor_node.resource_types.Portraits
			elif p.dialogic_type == resource.DialogicValueType.Timeline:
				editor_node.resource_type = editor_node.resource_types.Timelines
		elif p.type == TYPE_INT:
			if not p.has('dialogic_type') or p.dialogic_type == resource.DialogicValueType.Integer:
				editor_node = load("res://addons/dialogic/Editor/Events/Fields/Number.tscn").instance()
				editor_node.use_int_mode()
			elif p.dialogic_type == resource.DialogicValueType.FixedOptionSelector:
				editor_node = load("res://addons/dialogic/Editor/Events/Fields/OptionSelector.tscn").instance()
				if p.has('selector_options'):
					editor_node.options = p.selector_options
				if p.has('disabled'):
					editor_node.disabled = p.disabled
		elif p.type == TYPE_REAL:
			if not p.has('dialogic_type') or p.dialogic_type == resource.DialogicValueType.Float:
				editor_node = load("res://addons/dialogic/Editor/Events/Fields/Number.tscn").instance()
				editor_node.use_float_mode()
		else:
			editor_node = Label.new()
			editor_node.text = p.name
		
		### --------------------------------------------------------------------
		### 2. FILL THE NEW NODE WITH INFORMATION AND LISTEN TO CHANGES
		if 'property_name' in editor_node:
			editor_node.property_name = p.name
		if editor_node.has_method('set_value'):
			editor_node.set_value(resource.get(p.name))
		if editor_node.has_signal('value_changed'):
			editor_node.connect('value_changed', self, "set_property")
		if editor_node.has_method('set_hint') and p.has('hint_string'):
			editor_node.set_hint(p.hint_string)
		if "event_resource" in editor_node:
			editor_node.event_resource = resource
		if editor_node.has_method("react_to_change"):
			connect('content_changed', editor_node, 'react_to_change')
			editor_node.react_to_change()
		
		### --------------------------------------------------------------------
		### 3. ADD IT TO THE RIGHT PLACE (HEADER/BODY)
		var location = get_node("%Header/Content")
		if p.location == 1:
			location = get_node("%Body/Content")
		location.add_child(editor_node)
		
	
	#resource.connect('changed', self, 'update_from_resource')

#
#
#func update_from_resource():
#	for node in get_node("%Header/Content").get_children():
#		node.set_value(resource.get(node.property_name))
#	for node in get_node("%Body/Content").get_children():
#		node.set_value(resource.get(node.property_name))

func set_property(property_name, value):
	resource.set(property_name, value)
	emit_signal('content_changed')
	if end_node:
		end_node.parent_node_changed()

## *****************************************************************************
##								OVERRIDES
## *****************************************************************************

func _ready():
	#if resource.event_name:
	#	event_name = DTS.translate(resource.event_name)
	
	## DO SOME STYLING
	$PanelContainer/SelectedStyle.modulate = get_color("accent_color", "Editor")
	warning.texture = get_icon("NodeWarning", "EditorIcons")
	title_label.add_color_override("font_color", Color.white)
	if not get_constant("dark_theme", "Editor"):
		title_label.add_color_override("font_color", get_color("font_color", "Editor"))
	
	indent_size = indent_size * DialogicUtil.get_editor_scale(self)
	
	if resource.get_icon() != null:
		_set_event_icon(resource.get_icon())
	if event_name != null:
		_set_event_name(event_name)

	
	$PanelContainer/MarginContainer/VBoxContainer/Header/CenterContainer/IconPanel.set("self_modulate", resource.event_color)
	
	set_focus_mode(1) # Allowing this node to grab focus
	
	# signals
	$PanelContainer.connect("gui_input", self, '_on_gui_input')
	expand_control.connect("state_changed", self, "_on_ExpandControl_state_changed")
	$PopupMenu.connect("index_pressed", self, "_on_OptionsControl_action")
	
	_on_Indent_visibility_changed()
	$PanelContainer/MarginContainer/VBoxContainer/Header/CollapseButton.connect('toggled', self, 'toggle_collapse')
	$PanelContainer/MarginContainer/VBoxContainer/Header/CollapseButton.icon = get_icon("Collapse", "EditorIcons")
	$PanelContainer/MarginContainer/VBoxContainer/Header/CollapseButton.hide()
