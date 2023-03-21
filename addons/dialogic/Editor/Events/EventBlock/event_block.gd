@tool
extends MarginContainer

## Scene that represents an event in the visual timeline editor.

signal option_action(action_name)
signal content_changed()

# Resource
var resource : DialogicEvent

var selected : bool = false

### internal node eferences
@onready var warning := %Warning
@onready var title_label := %TitleLabel
@onready var icon_texture  := %IconTexture
@onready var header_content_container := %HeaderContent
@onready var body_container := %Body
@onready var body_content_container := %BodyContent

# is the body visible
var expanded := true

# was the body content loaded
var body_was_build := false

# does the body have elements?
var has_body_content := false

# list that stores visibility conditions 
var field_list := []

# for choice and condition
var end_node:Node = null:
	get:
		return end_node
	set(node):
		end_node = node
		%CollapseButton.visible = true if end_node else false

var collapsed := false

### extarnal node references
var editor_reference

### the indent size
var indent_size := 22
var current_indent_level := 1

# Setting this to true will ignore the event while saving
# Useful for making placeholder events in drag and drop
var ignore_save := false


## *****************************************************************************
##								PUBLIC METHODS
## *****************************************************************************

func visual_select() -> void:
	$PanelContainer.add_theme_stylebox_override('panel', load("res://addons/dialogic/Editor/Events/styles/selected_styleboxflat.tres"))
	selected = true
	%IconPanel.self_modulate = resource.event_color

func visual_deselect() -> void:
	$PanelContainer.add_theme_stylebox_override('panel', load("res://addons/dialogic/Editor/Events/styles/unselected_stylebox.tres"))
	selected = false
	%IconPanel.self_modulate = resource.event_color.lerp(Color.DARK_SLATE_GRAY, 0.3)

func is_selected() -> bool:
	return selected

# called by the timeline before adding it to the tree
func load_data(data:DialogicEvent) -> void:
	resource = data


func set_warning(text:String= "") -> void:
	if !text.is_empty():
		warning.show()
		warning.tooltip_text = text
	else:
		warning.hide()


func set_indent(indent: int) -> void:
	add_theme_constant_override("margin_left", indent_size*indent)
	current_indent_level = indent


## *****************************************************************************
##								PRIVATE METHODS
## *****************************************************************************

func _set_event_icon(icon: Texture) -> void:
	icon_texture.texture = icon
	var _scale = DialogicUtil.get_editor_scale()
	var ip = %IconPanel
	var ipc = icon_texture
	
	# Resizing the icon acording to the scale
	var icon_size = 32
	ip.custom_minimum_size = Vector2(icon_size, icon_size) * _scale
	ipc.custom_minimum_size = ip.custom_minimum_size
	
	# Updating the theme properties to scale
	var custom_style = ip.get_theme_stylebox('panel')
	custom_style.corner_radius_top_left = 5 * _scale
	custom_style.corner_radius_top_right = 5 * _scale
	custom_style.corner_radius_bottom_left = 5 * _scale
	custom_style.corner_radius_bottom_right = 5 * _scale


# called to inform event parts, that a focus is wanted
func focus():
	pass


func toggle_collapse(toggled:bool) -> void:
	collapsed = toggled
	var timeline_editor = find_parent('VisualEditor')
	if (timeline_editor != null):
		# @todo select item and clear selection is marked as "private" in TimelineEditor.gd
		# consider to make it "public" or add a public helper function
		timeline_editor.indent_events()


func build_editor(build_header:bool = true, build_body:bool = false) ->  void:
	var current_body_container :HFlowContainer = null
	
	if build_body and body_was_build: build_body = false
	if build_body:
		if body_was_build:
			return
		current_body_container = HFlowContainer.new()
		%BodyContent.add_child(current_body_container)
		body_was_build = true
	
	for p in resource.get_event_editor_info():
		if !build_body and p.location == 1:
			has_body_content = true
			continue
		elif !build_header and p.location == 0:
			continue
		
		### --------------------------------------------------------------------
		### 1. CREATE A NODE OF THE CORRECT TYPE FOR THE PROPERTY
		var editor_node : Control
		
		### LINEBREAK
		if p.name == "linebreak":
			if !current_body_container.get_child_count():
				current_body_container.queue_free()
			current_body_container = HFlowContainer.new()
			%BodyContent.add_child(current_body_container)
			continue
		
		### STRINGS
		elif p.dialogic_type == resource.ValueType.MultilineText:
			editor_node = load("res://addons/dialogic/Editor/Events/Fields/MultilineText.tscn").instantiate()
		elif p.dialogic_type == resource.ValueType.SinglelineText:
			editor_node = load("res://addons/dialogic/Editor/Events/Fields/SinglelineText.tscn").instantiate()
			editor_node.placeholder = p.display_info.get('placeholder', '')
		elif p.dialogic_type == resource.ValueType.Bool:
			editor_node = load("res://addons/dialogic/Editor/Events/Fields/Bool.tscn").instantiate()
		
		elif p.dialogic_type == resource.ValueType.File:
			editor_node = load("res://addons/dialogic/Editor/Events/Fields/FilePicker.tscn").instantiate()
			editor_node.file_filter = p.display_info.get('file_filter', '')
			editor_node.placeholder = p.display_info.get('placeholder', '')
			editor_node.resource_icon = p.display_info.get('icon', null)
			if editor_node.resource_icon == null and p.display_info.has('editor_icon'):
				editor_node.resource_icon = callv('get_theme_icon', p.display_info.editor_icon)
		
		elif p.dialogic_type == resource.ValueType.Condition:
			editor_node = load("res://addons/dialogic/Editor/Events/Fields/ConditionPicker.tscn").instantiate()
		
		## Complex Picker
		elif p.dialogic_type == resource.ValueType.ComplexPicker:
			editor_node = load("res://addons/dialogic/Editor/Events/Fields/ComplexPicker.tscn").instantiate()
			
			editor_node.file_extension = p.display_info.get('file_extension', '')
			editor_node.get_suggestions_func = p.display_info.get('suggestions_func', editor_node.get_suggestions_func)
			editor_node.empty_text = p.display_info.get('empty_text', '')
			editor_node.placeholder_text = p.display_info.get('placeholder', 'Select Resource')
			editor_node.resource_icon = p.display_info.get('icon', null)
			editor_node.enable_pretty_name = p.display_info.get('enable_pretty_name', false)
			if editor_node.resource_icon == null and p.display_info.has('editor_icon'):
				editor_node.resource_icon = callv('get_theme_icon', p.display_info.editor_icon)
			
		## INTEGERS
		elif p.dialogic_type == resource.ValueType.Integer:
			editor_node = load("res://addons/dialogic/Editor/Events/Fields/Number.tscn").instantiate()
			editor_node.use_int_mode()
			editor_node.max = p.display_info.get('max', 9999)
			editor_node.min = p.display_info.get('min', -9999)
		elif p.dialogic_type == resource.ValueType.Float:
			editor_node = load("res://addons/dialogic/Editor/Events/Fields/Number.tscn").instantiate()
			editor_node.use_float_mode()
			editor_node.max = p.display_info.get('max', 9999)
			editor_node.min = p.display_info.get('min', 0)
		elif p.dialogic_type == resource.ValueType.Decibel:
			editor_node = load("res://addons/dialogic/Editor/Events/Fields/Number.tscn").instantiate()
			editor_node.use_decibel_mode()
		elif p.dialogic_type == resource.ValueType.FixedOptionSelector:
			editor_node = load("res://addons/dialogic/Editor/Events/Fields/OptionSelector.tscn").instantiate()
			editor_node.options = p.display_info.get('selector_options', [])
			editor_node.disabled = p.display_info.get('disabled', false)
			editor_node.symbol_only = p.display_info.get('symbol_only', false)
		
		elif p.dialogic_type == resource.ValueType.Vector2:
			editor_node = load("res://addons/dialogic/Editor/Events/Fields/Vector2.tscn").instantiate()
		
		elif p.dialogic_type == resource.ValueType.StringArray:
			editor_node = load("res://addons/dialogic/Editor/Events/Fields/Array.tscn").instantiate()
			
		elif p.dialogic_type == resource.ValueType.Label:
			editor_node = Label.new()
			editor_node.text = p.display_info.text
			editor_node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			editor_node.set('custom_colors/font_color', Color("#7b7b7b"))
		elif p.dialogic_type == resource.ValueType.Button:
			editor_node = Button.new()
			editor_node.text = p.display_info.text
			if typeof(p.display_info.icon) == TYPE_ARRAY:
				editor_node.icon = callv('get_theme_icon', p.display_info.icon)
			else:
				editor_node.icon = p.display_info.icon
			editor_node.flat = true
			editor_node.custom_minimum_size.x = 30*DialogicUtil.get_editor_scale()
			editor_node.tooltip_text = p.display_info.tooltip
			editor_node.pressed.connect(p.display_info.callable)
		## CUSTOM
		elif p.dialogic_type == resource.ValueType.Custom:
			if p.display_info.has('path'):
				editor_node = load(p.display_info.path).instantiate()
		
		## ELSE
		else:
			editor_node = Label.new()
			editor_node.text = p.name
		
		### --------------------------------------------------------------------
		### 2. ADD IT TO THE RIGHT PLACE (HEADER/BODY)
		var location :Control = %HeaderContent
		if p.location == 1:
			location = current_body_container
		location.add_child(editor_node)
		
		### --------------------------------------------------------------------
		### 3. FILL THE NEW NODE WITH INFORMATION AND LISTEN TO CHANGES
		field_list.append({'node':editor_node})
		if "event_resource" in editor_node:
			editor_node.event_resource = resource
		if 'property_name' in editor_node:
			editor_node.property_name = p.name
			field_list[-1]['property'] = p.name
		if editor_node.has_method('set_value'):
			editor_node.set_value(resource.get(p.name))
		if editor_node.has_signal('value_changed'):
			editor_node.value_changed.connect(set_property)
		var left_label :Label = null 
		var right_label :Label = null
		if !p.get('left_text', '').is_empty():
			left_label = Label.new()
			left_label.text = p.get('left_text')
			location.add_child(left_label)
			location.move_child(left_label, editor_node.get_index())
		if !p.get('right_text', '').is_empty():
			right_label = Label.new()
			right_label.text = p.get('right_text')
			location.add_child(right_label)
			location.move_child(right_label, editor_node.get_index()+1)
		
		if p.has('condition'):
			field_list[-1]['condition'] = p.condition
			if left_label: 
				field_list.append({'node': left_label, 'condition':p.condition})
			if right_label: 
				field_list.append({'node': right_label, 'condition':p.condition})
	
	if build_body:
		has_body_content = true
		if current_body_container.get_child_count() == 0:
			has_body_content = false
			expanded = false
			body_container.visible = false
		
	recalculate_field_visibility()


func recalculate_field_visibility() -> void:
	for p in field_list:
		if !p.has('condition') or p.condition.is_empty():
			p.node.show()
		else:
			var expr := Expression.new()
			expr.parse(p.condition)
			if expr.execute([], resource):
				p.node.show()
			else:
				p.node.hide()
			if expr.has_execute_failed():
				printerr("[Dialogic] Failed executing visibility condition for '",p.get('property', 'unnamed'),"': " + expr.get_error_text())
	%ExpandButton.visible = false
	if body_content_container != null:
		for node in body_content_container.get_children():
			for sub_node in node.get_children():
				if sub_node.visible:
					%ExpandButton.visible = true
					break


func set_property(property_name:String, value:Variant) -> void:
	resource.set(property_name, value)
	content_changed.emit()
	if end_node:
		end_node.parent_node_changed()


func _on_resource_ui_update_needed() -> void:
	for node_info in field_list:
		if node_info.node.has_method('set_value'):
			node_info.node.set_value(resource.get(node_info.property))
		

func _update_color() -> void:
	if resource.dialogic_color_name != '':
		%IconPanel.self_modulate = DialogicUtil.get_color(resource.dialogic_color_name)
	
## *****************************************************************************
##								OVERRIDES
## *****************************************************************************

func _ready():
	
	## DO SOME STYLING
	var _scale := DialogicUtil.get_editor_scale()
	$PanelContainer.self_modulate = get_theme_color("accent_color", "Editor")
	warning.texture = get_theme_icon("NodeWarning", "EditorIcons")
	warning.size = Vector2(16 * _scale, 16 * _scale)
	warning.position = Vector2(-5 * _scale, -10 * _scale)
	title_label.add_theme_color_override("font_color", Color(1,1,1,1))
	if not get_theme_constant("dark_theme", "Editor"):
		title_label.add_theme_color_override("font_color", get_theme_color("font_color", "Editor"))
	
	indent_size = indent_size * DialogicUtil.get_editor_scale()
	
	%ExpandButton.icon = get_theme_icon("Tools", "EditorIcons")
	
	
	if resource:
		if resource.event_name:
			title_label.text = resource.event_name
		if resource._get_icon() != null:
			_set_event_icon(resource._get_icon())
		resource.ui_update_needed.connect(_on_resource_ui_update_needed)
		resource.ui_update_warning.connect(set_warning)

		%IconPanel.self_modulate = resource.event_color
		
		_on_ExpandButton_toggled(resource.expand_by_default)
	
	set_focus_mode(1) # Allowing this node to grab focus
	
	# signals
	# TODO godot4 react to changes of the colors, the signal was removed
	#ProjectSettings.project_settings_changed.connect(_update_color)
	
	# Separation on the header
	%Header.add_theme_constant_override("custom_constants/separation", 5 * _scale)
	
	content_changed.connect(recalculate_field_visibility)
	
#	_on_Indent_visibility_changed()
	%CollapseButton.toggled.connect(toggle_collapse)
	%CollapseButton.icon = get_theme_icon("Collapse", "EditorIcons")
	%CollapseButton.hide()
	await get_tree().process_frame
	body_container.add_theme_constant_override("margin_left", title_label.position.x)

func _on_ExpandButton_toggled(button_pressed:bool) -> void:
	if button_pressed and !body_was_build:
		build_editor(false, true)
	%ExpandButton.set_pressed_no_signal(button_pressed)
	expanded = button_pressed
	body_container.visible = button_pressed
	get_parent().get_parent().queue_redraw()


func _on_EventNode_gui_input(event:InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == 1:
		grab_focus() # Grab focus to avoid copy pasting text or events
		if event.double_click:
			if has_body_content:
				_on_ExpandButton_toggled(!expanded)
	# For opening the context menu
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var popup :PopupMenu = get_parent().get_parent().get_node('EventPopupMenu')
			popup.current_event = self
			popup.popup_on_parent(Rect2(get_global_mouse_position(),Vector2()))
			if resource.help_page_path == "":
				popup.set_item_disabled(0, true)
			else:
				popup.set_item_disabled(0, false)
