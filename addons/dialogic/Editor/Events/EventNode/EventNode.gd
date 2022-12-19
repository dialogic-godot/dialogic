@tool
extends HBoxContainer

signal option_action(action_name)
signal content_changed()

# Resource
var resource : DialogicEvent


### internal node eferences
@onready var selected_style = %SelectedStyle
@onready var warning = %Warning
@onready var title_label = %TitleLabel
@onready var icon_texture  = %IconTexture
@onready var header_content_container = %HeaderContent
@onready var body_container = %Body
@onready var body_content_container = %BodyContent
@onready var indent_node = %Indent

# is the body visible
var expanded = true

# does the body have elements?
var has_body_content = false

# for choice and condition
var end_node:Node = null:
	get:
		return end_node
	set(node):
		end_node = node
		%CollapseButton.visible = true if end_node else false

var collapsed = false

### extarnal node references
var editor_reference

### the indent size
var indent_size = 15
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
	selected_style.hide()


func is_selected() -> bool:
	return selected_style.visible

# called by the timeline before adding it to the tree
func load_data(data):
	resource = data


func set_warning(text):
	warning.show()
	warning.tooltip_text = text


func remove_warning(text = ''):
	if warning.tooltip_text == text or text == '':
		warning.hide()


func set_indent(indent: int):
	indent_node.custom_minimum_size = Vector2(indent_size * indent, 0)
	indent_node.visible = indent != 0
	current_indent_level = indent
	queue_redraw()


## *****************************************************************************
##								PRIVATE METHODS
## *****************************************************************************

func _set_event_icon(icon: Texture):
	icon_texture.texture = icon
	var _scale = DialogicUtil.get_editor_scale()
	var cpanel = %IconPanelCenterC
	var ip = %IconPanel
	var ipc = icon_texture
	
	# Resizing the icon acording to the scale
	var icon_size = 32
	cpanel.custom_minimum_size = Vector2(icon_size, icon_size) * _scale
	ip.custom_minimum_size = cpanel.custom_minimum_size
	ipc.custom_minimum_size = ip.custom_minimum_size
	
	# Updating the theme properties to scale
	var custom_style = ip.get_theme_stylebox('panel')
	custom_style.corner_radius_top_left = 5 * _scale
	custom_style.corner_radius_top_right = 5 * _scale
	custom_style.corner_radius_bottom_left = 5 * _scale
	custom_style.corner_radius_bottom_right = 5 * _scale
	
	# Separation on the header
	%Header.add_theme_constant_override("custom_constants/separation", 5 * _scale)
	%BodySpacing.custom_minimum_size.x = title_label.position.x
	

func _on_OptionsControl_action(index):
	if index == 0:
		if not resource.help_page_path.is_empty():
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
	if resource:
		if resource.needs_indentation:
			if indent_node.visible:
				remove_warning("This event needs a question event around it!")
			else:
				set_warning("This event needs a question event around it!")


func _request_selection():
	# TODO doesn't work. I'm sure - JS
	var timeline_editor = editor_reference.get_node_or_null('MainPanel/TimelineEditor')
	if (timeline_editor != null):
		# @todo select item and clear selection is marked as "private" in TimelineEditor.gd
		# consider to make it "public" or add a public helper function
		timeline_editor.select_item(self)


# called to inform event parts, that a focus is wanted
func focus():
	pass


func toggle_collapse(toggled):
	collapsed = toggled
	$PanelContainer/MarginContainer/VBoxContainer/CollapsedBody.visible = toggled
	var timeline_editor = find_parent('TimelineVisualEditor')
	if (timeline_editor != null):
		# @todo select item and clear selection is marked as "private" in TimelineEditor.gd
		# consider to make it "public" or add a public helper function
		timeline_editor.indent_events()


func build_editor():
	var p_list = resource._get_property_list()
	var edit_conditions_list = []
	var current_body_container = HFlowContainer.new()
	%BodyContent.add_child(current_body_container)
	for p in p_list:
		### --------------------------------------------------------------------
		### 1. CREATE A NODE OF THE CORRECT TYPE FOR THE PROPERTY
		var editor_node
		
		### OTHER
		if p.name == "linebreak":
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
			if p.display_info.has('selector_options'):
				editor_node.options = p.display_info.selector_options
			if p.display_info.has('disabled'):
				editor_node.disabled = p.display_info.disabled
		
		elif p.dialogic_type == resource.ValueType.Vector2:
			editor_node = load("res://addons/dialogic/Editor/Events/Fields/Vector2.tscn").instantiate()
		
		elif p.dialogic_type == resource.ValueType.StringArray:
			editor_node = load("res://addons/dialogic/Editor/Events/Fields/Array.tscn").instantiate()
			
		elif p.dialogic_type == resource.ValueType.Label:
			editor_node = Label.new()
			editor_node.text = p.display_info.text
			editor_node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
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
		var location = %HeaderContent
		if p.location == 1:
			location = current_body_container
		location.add_child(editor_node)
		
		### --------------------------------------------------------------------
		### 3. FILL THE NEW NODE WITH INFORMATION AND LISTEN TO CHANGES
		if "event_resource" in editor_node:
			editor_node.event_resource = resource
		if 'property_name' in editor_node:
			editor_node.property_name = p.name
		if editor_node.has_method('set_value'):
			if resource.get(p.name) != null: # Got an error here saying that "Cannot convert argument 1 from Nil to bool." so I'm adding this check
				editor_node.set_value(resource.get(p.name))
		if editor_node.has_signal('value_changed'):
			editor_node.value_changed.connect(set_property)
		if editor_node.has_method('set_left_text'):
			editor_node.set_left_text(p.get('left_text', ''))
		if editor_node.has_method('set_right_text'):
			editor_node.set_right_text(p.get('right_text', ''))
		if p.has('condition'):
			edit_conditions_list.append([editor_node, p.condition])

	
	has_body_content = true
	if current_body_container.get_child_count() == 0:
		has_body_content = false
		expanded = false
		body_container.visible = false
	
	content_changed.connect(recalculate_edit_visibility.bind(edit_conditions_list))
	recalculate_edit_visibility(edit_conditions_list)

func recalculate_edit_visibility(list):
	for node_con in list:
		if node_con[1].is_empty():
			node_con[0].show()
		else:
			var expr = Expression.new()
			expr.parse(node_con[1])
			if expr.execute([], resource):
				node_con[0].show()
			else:
				node_con[0].hide()
			if expr.has_execute_failed():
				var name = "unnamed" if "property_name" not in node_con[0] else node_con[0].property_name
				printerr("(recalculate_edit_visibility)  condition expression failed with error: " + expr.get_error_text())
	
	%ExpandButton.visible = false
	if body_content_container != null:
		for node in body_content_container.get_children():
			for sub_node in node.get_children():
				if sub_node.visible:
					%ExpandButton.visible = true
					break

func set_property(property_name, value):
	resource.set(property_name, value)
	emit_signal('content_changed')
	if end_node:
		end_node.parent_node_changed()


func _update_color():
	if resource.dialogic_color_name != '':
		%IconPanel.self_modulate = DialogicUtil.get_color(resource.dialogic_color_name)
## *****************************************************************************
##								OVERRIDES
## *****************************************************************************

func _ready():
	
	## DO SOME STYLING
	var _scale = DialogicUtil.get_editor_scale()
	selected_style.modulate = get_theme_color("accent_color", "Editor")
	warning.texture = get_theme_icon("NodeWarning", "EditorIcons")
	warning.size = Vector2(16 * _scale, 16 * _scale)
	title_label.add_theme_color_override("font_color", Color(1,1,1,1))
	if not get_theme_constant("dark_theme", "Editor"):
		title_label.add_theme_color_override("font_color", get_theme_color("font_color", "Editor"))
	
	indent_size = indent_size * DialogicUtil.get_editor_scale()
	
	%ExpandButton.icon = get_theme_icon("Tools", "EditorIcons")
	
	
	if resource:
		if resource.event_name:
			#title_label.text = DTS.translate(resource.event_name)
			title_label.text = resource.event_name
		if resource._get_icon() != null:
			_set_event_icon(resource._get_icon())

		%IconPanel.self_modulate = resource.event_color
		
		_on_ExpandButton_toggled(resource.expand_by_default)
		
		# Only create this if it can collapse children events
		if resource.can_contain_events:
			var cb:HBoxContainer = HBoxContainer.new()
			cb.name = 'CollapsedBody'
			cb.visible = false
			var cb_label:Label = Label.new()
			cb_label.text = 'Contains Events (currently hidden)'
			cb_label.size_flags_horizontal = 3
			cb_label.horizontal_alignment = 1
			cb.add_child(cb_label)
			$PanelContainer/MarginContainer/VBoxContainer.add_child(cb)
	
	set_focus_mode(1) # Allowing this node to grab focus
	
	# signals
	# TODO godot4 react to changes of the colors, the signal was removed
	#ProjectSettings.project_settings_changed.connect(_update_color)
	$PopupMenu.index_pressed.connect(_on_OptionsControl_action)
	
	
	_on_Indent_visibility_changed()
	%CollapseButton.toggled.connect(toggle_collapse)
	%CollapseButton.icon = get_theme_icon("Collapse", "EditorIcons")
	%CollapseButton.hide()


func _on_ExpandButton_toggled(button_pressed):
	%ExpandButton.set_pressed_no_signal(button_pressed)
	expanded = button_pressed
	body_container.visible = button_pressed
	get_parent().get_parent().queue_redraw()


func _on_EventNode_gui_input(event):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == 1:
		grab_focus() # Grab focus to avoid copy pasting text or events
		if event.double_click:
			if has_body_content:
				_on_ExpandButton_toggled(!expanded)
	# For opening the context menu
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			$PopupMenu.popup_on_parent(Rect2(get_global_mouse_position(),Vector2()))
			if resource.help_page_path == "":
				$PopupMenu.set_item_disabled(0, true)
			else:
				$PopupMenu.set_item_disabled(0, false)
