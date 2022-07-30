@tool
extends HBoxContainer

signal option_action(action_name)
signal content_changed()

# Resource
var resource : DialogicEvent


### internal node eferences
@onready var selected_style = $%SelectedStyle
@onready var warning = $%Warning
@onready var title_label = $%TitleLabel
@onready var icon_texture  = $%IconTexture
@onready var header_content_container = $%HeaderContent
@onready var body_container = $%Body
@onready var body_content_container = $%BodyContent
@onready var indent_node = $%Indent

# is the body visible
var expanded = true

# for choice and condition
var end_node:Node = null:
	get:
		return end_node
	set(node):
		end_node = node
		$%CollapseButton.visible = true if end_node else false

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


func set_indent(indent: int):
	indent_node.custom_minimum_size = Vector2(indent_size * indent, 0)
	indent_node.visible = indent != 0
	current_indent_level = indent
	update()


## *****************************************************************************
##								PRIVATE METHODS
## *****************************************************************************

func _set_event_icon(icon: Texture):
	icon_texture.texture = icon
	var _scale = DialogicUtil.get_editor_scale()
	var cpanel = $%IconPanelCenterC
	var ip = $%IconPanel
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
	$%Header.add_theme_constant_override("custom_constants/separation", 5 * _scale)
	$%BodySpacing.custom_minimum_size.x = title_label.position.x
	

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
	if resource.needs_indentation:
		if indent_node.visible:
			remove_warning(DTS.translate("This event needs a question event around it!"))
		else:
			set_warning(DTS.translate("This event needs a question event around it!"))


func _on_gui_input(event):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == 1:
		grab_focus() # Grab focus to avoid copy pasting text or events
		if event.double_click:
			expanded = !expanded
	# For opening the context menu
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			$PopupMenu.global_position = get_global_mouse_position()
			var popup = $PopupMenu.popup()
			if resource.help_page_path == "":
				$PopupMenu.set_item_disabled(0, true)
			else:
				$PopupMenu.set_item_disabled(0, false)

	
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
	var timeline_editor = find_parent('TimelineEditor')
	if (timeline_editor != null):
		# @todo select item and clear selection is marked as "private" in TimelineEditor.gd
		# consider to make it "public" or add a public helper function
		timeline_editor.indent_events()


func build_editor():
	var p_list = resource._get_property_list()
	var edit_conditions_list = []
	for p in p_list:
		### --------------------------------------------------------------------
		### 1. CREATE A NODE OF THE CORRECT TYPE FOR THE PROPERTY
		var editor_node
		
		### OTHER
		if p.name == "linebreak":
			editor_node = Control.new()
			editor_node.theme_type_variation = "LineBreak"
		### STRINGS
		elif p.dialogic_type == resource.ValueType.MultilineText:
			editor_node = load("res://addons/dialogic/Editor/Events/Fields/MultilineText.tscn").instantiate()
		elif p.dialogic_type == resource.ValueType.SinglelineText:
			editor_node = load("res://addons/dialogic/Editor/Events/Fields/SinglelineText.tscn").instantiate()
		
		elif p.dialogic_type == resource.ValueType.Bool:
			editor_node = load("res://addons/dialogic/Editor/Events/Fields/Bool.tscn").instantiate()
		
		## Complex Picker
		elif p.dialogic_type == resource.ValueType.ComplexPicker:
			editor_node = load("res://addons/dialogic/Editor/Events/Fields/ComplexPicker.tscn").instantiate()
			
			editor_node.file_extension = p.display_info.get('file_extension', '')
			editor_node.get_suggestions_func = p.display_info.get('suggestions_func', editor_node.get_suggestions_func)
			editor_node.empty_text = p.display_info.get('empty_text', '')
			editor_node.placeholder_text = p.display_info.get('placeholder', 'Select Resource')
			editor_node.resource_icon = p.display_info.get('icon', null)
			editor_node.disable_pretty_name = p.display_info.get('disable_pretty_name', false)
			if editor_node.resource_icon == null and p.display_info.has('editor_icon'):
				editor_node.resource_icon = callv('get_theme_icon', p.display_info.editor_icon)
			
		## INTEGERS
		elif p.dialogic_type == resource.ValueType.Integer:
			editor_node = load("res://addons/dialogic/Editor/Events/Fields/Number.tscn").instantiate()
			editor_node.use_int_mode()
		elif p.dialogic_type == resource.ValueType.Float:
			editor_node = load("res://addons/dialogic/Editor/Events/Fields/Number.tscn").instantiate()
			editor_node.use_float_mode()
		elif p.dialogic_type == resource.ValueType.Decibel:
			editor_node = load("res://addons/dialogic/Editor/Events/Fields/Number.tscn").instantiate()
			editor_node.use_decibel_mode()
		elif p.dialogic_type == resource.ValueType.FixedOptionSelector:
			editor_node = load("res://addons/dialogic/Editor/Events/Fields/OptionSelector.tscn").instantiate()
			if p.display_info.has('selector_options'):
				editor_node.options = p.display_info.selector_options
			if p.display_info.has('disabled'):
				editor_node.disabled = p.display_info.disabled
		
		elif p.dialogic_type == resource.ValueType.StringArray:
			editor_node = load("res://addons/dialogic/Editor/Events/Fields/Array.tscn").instantiate()
			
		elif p.dialogic_type == resource.ValueType.Label:
			editor_node = Label.new()
			editor_node.text = p.display_info.text
		
		## CUSTOM
		elif p.dialogic_type == resource.ValueType.Custom:
			if p.display_info.has('path'):
				editor_node = load(p.display_info.path).instantiate()
		
		## ELSE
		else:
			editor_node = Label.new()
			editor_node.text = p.name
		
		### --------------------------------------------------------------------
		### 2. FILL THE NEW NODE WITH INFORMATION AND LISTEN TO CHANGES
		if "event_resource" in editor_node:
			editor_node.event_resource = resource
		if 'property_name' in editor_node:
			editor_node.property_name = p.name
		if editor_node.has_method('set_value'):
			editor_node.set_value(resource.get(p.name))
		if editor_node.has_signal('value_changed'):
			editor_node.value_changed.connect(set_property)
		if editor_node.has_method('set_left_text') and p.has('left_text'):
			editor_node.set_left_text(p.left_text)
		if editor_node.has_method('set_right_text') and p.has('right_text'):
			editor_node.set_right_text(p.right_text)
		if p.has('condition'):
			edit_conditions_list.append([editor_node, p.condition])
		
		
		### --------------------------------------------------------------------
		### 3. ADD IT TO THE RIGHT PLACE (HEADER/BODY)
		var location = get_node("%HeaderContent")
		if p.location == 1:
			location = get_node("%BodyContent")
		location.add_child(editor_node)
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
	
	$'%ExpandButton'.visible = false
	for node in body_content_container.get_children():
		if node.visible:
			$'%ExpandButton'.visible = true
			break

func set_property(property_name, value):
	resource.set(property_name, value)
	emit_signal('content_changed')
	if end_node:
		end_node.parent_node_changed()


func _update_color():
	if resource.dialogic_color_name != '':
		$%IconPanel.self_modulate = DialogicUtil.get_color(resource.dialogic_color_name)
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
	
	$'%ExpandButton'.icon = get_theme_icon("Tools", "EditorIcons")
	
	
	if resource:
		if resource.event_name:
			title_label.text = DTS.translate(resource.event_name)
		if resource.get_icon() != null:
			_set_event_icon(resource.get_icon())

		$%IconPanel.self_modulate = resource.event_color
		$%ExpandButton.button_pressed = resource.expand_by_default
		_on_ExpandButton_toggled(resource.expand_by_default)
	set_focus_mode(1) # Allowing this node to grab focus
	
	# signals
	# TODO godot4 react to changes of the colors, the signal was removed
	#ProjectSettings.project_settings_changed.connect(_update_color)
	$PanelContainer.gui_input.connect(_on_gui_input)
	$PopupMenu.index_pressed.connect(_on_OptionsControl_action)
	
	_on_Indent_visibility_changed()
	$%CollapseButton.toggled.connect(toggle_collapse)
	$%CollapseButton.icon = get_theme_icon("Collapse", "EditorIcons")
	$%CollapseButton.hide()


func _on_ExpandButton_toggled(button_pressed):
	expanded = button_pressed
	body_container.visible = button_pressed


func _on_EventNode_gui_input(event):
	if event is InputEventMouseButton and event.double_click:
		$'%ExpandButton'.button_pressed = !$'%ExpandButton'.button_pressed
