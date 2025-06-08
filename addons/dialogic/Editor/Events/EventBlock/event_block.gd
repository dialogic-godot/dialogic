@tool
extends MarginContainer

## Scene that represents an event in the visual timeline editor.

signal content_changed()

## REFERENCES
var resource: DialogicEvent
var editor_reference
# for choice and condition
var end_node: Node = null:
	get:
		return end_node
	set(node):
		end_node = node
		%ToggleChildrenVisibilityButton.visible = true if end_node else false


## FLAGS
var selected := false
# Whether the body is visible
var expanded := true
var body_was_build := false
var has_any_enabled_body_content := false
# Whether contained events (e.g. in choices) are visible
var collapsed := false


## CONSTANTS
const icon_size := 28
const indent_size := 22

## STATE
# List that stores visibility conditions
var field_list := []
var current_indent_level := 1


#region UI AND LOGIC INITIALIZATION
################################################################################

func _ready() -> void:
	if get_parent() is SubViewport:
		return

	if not resource:
		printerr("[Dialogic] Event block was added without a resource specified.")
		return

	initialize_ui()
	initialize_logic()


func initialize_ui() -> void:
	var _scale := DialogicUtil.get_editor_scale()

	add_theme_constant_override("margin_bottom", DialogicUtil.get_editor_setting("event_block_margin", 0) * _scale)

	$PanelContainer.self_modulate = get_theme_color("accent_color", "Editor")

	# Warning Icon
	%Warning.texture = get_theme_icon("NodeWarning", "EditorIcons")
	%Warning.size = Vector2(16 * _scale, 16 * _scale)
	%Warning.position = Vector2(-5 * _scale, -10 * _scale)

	# Expand Button
	%ToggleBodyVisibilityButton.icon = get_theme_icon("CodeFoldedRightArrow", "EditorIcons")
	%ToggleBodyVisibilityButton.set("theme_override_colors/icon_normal_color", get_theme_color("contrast_color_2", "Editor"))
	%ToggleBodyVisibilityButton.set("theme_override_colors/icon_hover_color", get_theme_color("accent_color", "Editor"))
	%ToggleBodyVisibilityButton.set("theme_override_colors/icon_pressed_color", get_theme_color("contrast_color_2", "Editor"))
	%ToggleBodyVisibilityButton.set("theme_override_colors/icon_hover_pressed_color", get_theme_color("accent_color", "Editor"))
	%ToggleBodyVisibilityButton.add_theme_stylebox_override('hover_pressed', StyleBoxEmpty.new())

	# Icon Panel
	%IconPanel.tooltip_text = resource.event_name
	%IconPanel.self_modulate = resource.event_color

	# Event Icon
	%IconTexture.texture = resource._get_icon()

	%IconPanel.custom_minimum_size = Vector2(icon_size, icon_size) * _scale
	%IconTexture.custom_minimum_size = %IconPanel.custom_minimum_size

	var custom_style: StyleBoxFlat = %IconPanel.get_theme_stylebox('panel')
	custom_style.set_corner_radius_all(5 * _scale)

	# Focus Mode
	set_focus_mode(1) # Allowing this node to grab focus

	# Separation on the header
	%Header.add_theme_constant_override("custom_constants/separation", 5 * _scale)

	# Collapse Button
	%ToggleChildrenVisibilityButton.toggled.connect(_on_collapse_toggled)
	%ToggleChildrenVisibilityButton.icon = get_theme_icon("Collapse", "EditorIcons")
	%ToggleChildrenVisibilityButton.hide()

	%Body.add_theme_constant_override("margin_left", icon_size * _scale)

	visual_deselect()


func initialize_logic() -> void:
	resized.connect(get_parent().get_parent().queue_redraw)

	resource.ui_update_needed.connect(_on_resource_ui_update_needed)
	resource.ui_update_warning.connect(set_warning)

	content_changed.connect(recalculate_field_visibility)

	_on_ToggleBodyVisibility_toggled(resource.expand_by_default or resource.created_by_button)

#endregion


#region VISUAL METHODS
################################################################################

func visual_select() -> void:
	$PanelContainer.add_theme_stylebox_override('panel', load("res://addons/dialogic/Editor/Events/styles/selected_styleboxflat.tres"))
	selected = true
	%IconPanel.self_modulate = resource.event_color
	%IconTexture.modulate = get_theme_color("icon_saturation", "Editor")


func visual_deselect() -> void:
	$PanelContainer.add_theme_stylebox_override('panel', load("res://addons/dialogic/Editor/Events/styles/unselected_stylebox.tres"))
	selected = false
	%IconPanel.self_modulate = resource.event_color.lerp(Color.DARK_SLATE_GRAY, 0.1)
	%IconTexture.modulate = get_theme_color('font_color', 'Label')


func is_selected() -> bool:
	return selected


func set_warning(text:String= "") -> void:
	if !text.is_empty():
		%Warning.show()
		%Warning.tooltip_text = text
	else:
		%Warning.hide()


func set_indent(indent: int) -> void:
	add_theme_constant_override("margin_left", indent_size * indent * DialogicUtil.get_editor_scale())
	current_indent_level = indent

#endregion


#region EVENT FIELDS
################################################################################

var FIELD_SCENES := {
	DialogicEvent.ValueType.MULTILINE_TEXT: 	"res://addons/dialogic/Editor/Events/Fields/field_text_multiline.tscn",
	DialogicEvent.ValueType.SINGLELINE_TEXT: 	"res://addons/dialogic/Editor/Events/Fields/field_text_singleline.tscn",
	DialogicEvent.ValueType.FILE: 				"res://addons/dialogic/Editor/Events/Fields/field_file.tscn",
	DialogicEvent.ValueType.BOOL: 				"res://addons/dialogic/Editor/Events/Fields/field_bool_check.tscn",
	DialogicEvent.ValueType.BOOL_BUTTON: 		"res://addons/dialogic/Editor/Events/Fields/field_bool_button.tscn",
	DialogicEvent.ValueType.CONDITION: 			"res://addons/dialogic/Editor/Events/Fields/field_condition.tscn",
	DialogicEvent.ValueType.ARRAY: 				"res://addons/dialogic/Editor/Events/Fields/field_array.tscn",
	DialogicEvent.ValueType.DICTIONARY: 		"res://addons/dialogic/Editor/Events/Fields/field_dictionary.tscn",
	DialogicEvent.ValueType.DYNAMIC_OPTIONS: 	"res://addons/dialogic/Editor/Events/Fields/field_options_dynamic.tscn",
	DialogicEvent.ValueType.FIXED_OPTIONS	: 	"res://addons/dialogic/Editor/Events/Fields/field_options_fixed.tscn",
	DialogicEvent.ValueType.NUMBER: 			"res://addons/dialogic/Editor/Events/Fields/field_number.tscn",
	DialogicEvent.ValueType.VECTOR2: 			"res://addons/dialogic/Editor/Events/Fields/field_vector2.tscn",
	DialogicEvent.ValueType.VECTOR3: 			"res://addons/dialogic/Editor/Events/Fields/field_vector3.tscn",
	DialogicEvent.ValueType.VECTOR4: 			"res://addons/dialogic/Editor/Events/Fields/field_vector4.tscn",
	DialogicEvent.ValueType.COLOR: 				"res://addons/dialogic/Editor/Events/Fields/field_color.tscn",
	DialogicEvent.ValueType.AUDIO_PREVIEW: 		"res://addons/dialogic/Editor/Events/Fields/field_audio_preview.tscn",
	DialogicEvent.ValueType.IMAGE_PREVIEW:		"res://addons/dialogic/Editor/Events/Fields/field_image_preview.tscn",
	}

func build_editor(build_header:bool = true, build_body:bool = false) ->  void:
	var current_body_container: HFlowContainer = null

	if build_body and body_was_build:
		build_body = false

	if build_body:
		if body_was_build:
			return
		current_body_container = HFlowContainer.new()
		%BodyContent.add_child(current_body_container)
		body_was_build = true

	for p in resource.get_event_editor_info():
		field_list.append({'node':null, 'location':p.location})
		if p.has('condition'):
			field_list[-1]['condition'] = p.condition

		if !build_body and p.location == 1:
			continue
		elif !build_header and p.location == 0:
			continue

		### --------------------------------------------------------------------
		### 1. CREATE A NODE OF THE CORRECT TYPE FOR THE PROPERTY
		var editor_node: Control

		### LINEBREAK
		if p.name == "linebreak":
			field_list.remove_at(field_list.size()-1)
			if !current_body_container.get_child_count():
				current_body_container.queue_free()
			current_body_container = HFlowContainer.new()
			%BodyContent.add_child(current_body_container)
			continue

		elif p.field_type in FIELD_SCENES:
			editor_node = load(FIELD_SCENES[p.field_type]).instantiate()

		elif p.field_type == resource.ValueType.LABEL:
			editor_node = Label.new()
			editor_node.text = p.display_info.text
			editor_node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			editor_node.set('custom_colors/font_color', Color("#7b7b7b"))
			editor_node.add_theme_color_override('font_color', resource.event_color.lerp(get_theme_color("font_color", "Editor"), 0.8))

		elif p.field_type == resource.ValueType.BUTTON:
			editor_node = Button.new()
			editor_node.text = p.display_info.text
			editor_node.tooltip_text = p.display_info.get('tooltip', '')
			if typeof(p.display_info.icon) == TYPE_ARRAY:
				editor_node.icon = callv('get_theme_icon', p.display_info.icon)
			else:
				editor_node.icon = p.display_info.icon
			editor_node.flat = true
			editor_node.custom_minimum_size.x = 30 * DialogicUtil.get_editor_scale()
			editor_node.pressed.connect(p.display_info.callable)

		## CUSTOM
		elif p.field_type == resource.ValueType.CUSTOM:
			if p.display_info.has('path'):
				editor_node = load(p.display_info.path).instantiate()

		## ELSE
		else:
			editor_node = Label.new()
			editor_node.text = p.name
			editor_node.add_theme_color_override('font_color', resource.event_color.lerp(get_theme_color("font_color", "Editor"), 0.8))


		field_list[-1]['node'] = editor_node
		### --------------------------------------------------------------------
		# Some things need to be called BEFORE the field is added to the tree
		if editor_node is DialogicVisualEditorField:
			editor_node.event_resource = resource

			editor_node.property_name = p.name
			field_list[-1]['property'] = p.name

			editor_node._load_display_info(p.display_info)

		var location: Control = %HeaderContent
		if p.location == 1:
			location = current_body_container
		location.add_child(editor_node)

		# Some things need to be called AFTER the field is added to the tree
		if editor_node is DialogicVisualEditorField:
			# Only set the value if the field is visible
			#
			# This prevents events with varied value types (event_setting, event_variable)
			# from injecting incorrect types into hidden fields, which then throw errors
			# in the console.
			if p.has('condition') and not p.condition.is_empty():
				if _evaluate_visibility_condition(p):
					editor_node._set_value(resource.get(p.name))
			else:
				editor_node._set_value(resource.get(p.name))

			editor_node.value_changed.connect(set_property)

			editor_node.tooltip_text = p.display_info.get('tooltip', '')

			# Apply autofocus
			if resource.created_by_button and p.display_info.get('autofocus', false):
				editor_node.call_deferred('take_autofocus')

		### --------------------------------------------------------------------
		### 4. ADD LEFT AND RIGHT TEXT
		var left_label: Label = null
		var right_label: Label = null
		if !p.get('left_text', '').is_empty():
			left_label = Label.new()
			left_label.text = p.get('left_text')
			left_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			left_label.add_theme_color_override('font_color', resource.event_color.lerp(get_theme_color("font_color", "Editor"), 0.8))
			location.add_child(left_label)
			location.move_child(left_label, editor_node.get_index())
		if !p.get('right_text', '').is_empty():
			right_label = Label.new()
			right_label.text = p.get('right_text')
			right_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			right_label.add_theme_color_override('font_color', resource.event_color.lerp(get_theme_color("font_color", "Editor"), 0.8))
			location.add_child(right_label)
			location.move_child(right_label, editor_node.get_index()+1)

		### --------------------------------------------------------------------
		### 5. REGISTER CONDITION
		if p.has('condition'):
			field_list[-1]['condition'] = p.condition
			if left_label:
				field_list.append({'node': left_label, 'condition':p.condition, 'location':p.location})
			if right_label:
				field_list.append({'node': right_label, 'condition':p.condition, 'location':p.location})


	if build_body:
		if current_body_container.get_child_count() == 0:
			expanded = false
			%Body.visible = false

	recalculate_field_visibility()


func recalculate_field_visibility() -> void:
	has_any_enabled_body_content = false
	for p in field_list:
		if !p.has('condition') or p.condition.is_empty():
			if p.node != null:
				p.node.show()
			if p.location == 1:
				has_any_enabled_body_content = true
		else:
			if _evaluate_visibility_condition(p):
				if p.node != null:
					if p.node.visible == false and p.has("property"):
						p.node._set_value(resource.get(p.property))
					p.node.show()
				if p.location == 1:
					has_any_enabled_body_content = true
			else:
				if p.node != null:
					p.node.hide()
	%ToggleBodyVisibilityButton.visible = has_any_enabled_body_content


func set_property(property_name:String, value:Variant) -> void:
	resource.set(property_name, value)
	content_changed.emit()
	if end_node:
		end_node.parent_node_changed()


func _evaluate_visibility_condition(p: Dictionary) -> bool:
	var expr := Expression.new()
	expr.parse(p.condition)
	var result: bool
	if expr.execute([], resource):
		result = true
	else:
		result = false
	if expr.has_execute_failed():
		printerr("[Dialogic] Failed executing visibility condition for '",p.get('property', 'unnamed'),"': " + expr.get_error_text())
	return result


func get_field_node(property_name:String) -> Node:
	for i in field_list:
		if i.get("property", "") == property_name:
			return i.node
	return null


func _on_resource_ui_update_needed() -> void:
	for node_info in field_list:
		if node_info.node and node_info.node.has_method('set_value'):
			# Only set the value if the field is visible
			#
			# This prevents events with varied value types (event_setting, event_variable)
			# from injecting incorrect types into hidden fields, which then throw errors
			# in the console.
			if node_info.has('condition') and not node_info.condition.is_empty():
				if _evaluate_visibility_condition(node_info):
					node_info.node.set_value(resource.get(node_info.property))
			else:
				node_info.node.set_value(resource.get(node_info.property))
	recalculate_field_visibility()


#region SIGNALS
################################################################################

func _on_collapse_toggled(toggled:bool) -> void:
	collapsed = toggled
	var timeline_editor: Node = find_parent('VisualEditor')
	if (timeline_editor != null):
		# @todo select item and clear selection is marked as "private" in TimelineEditor.gd
		# consider to make it "public" or add a public helper function
		timeline_editor.indent_events()



func _on_ToggleBodyVisibility_toggled(button_pressed:bool) -> void:
	if button_pressed and !body_was_build:
		build_editor(false, true)
	%ToggleBodyVisibilityButton.set_pressed_no_signal(button_pressed)

	if button_pressed:
		%ToggleBodyVisibilityButton.icon = get_theme_icon("CodeFoldDownArrow", "EditorIcons")
	else:
		%ToggleBodyVisibilityButton.icon = get_theme_icon("CodeFoldedRightArrow", "EditorIcons")

	expanded = button_pressed
	%Body.visible = button_pressed

	if find_parent('VisualEditor') != null:
		find_parent('VisualEditor').indent_events()


func _on_EventNode_gui_input(event:InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == 1:
		grab_focus() # Grab focus to avoid copy pasting text or events
		if event.double_click:
			if has_any_enabled_body_content:
				_on_ToggleBodyVisibility_toggled(!expanded)
	# For opening the context menu
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var popup: PopupMenu = get_parent().get_parent().get_node('EventPopupMenu')
			popup.current_event = self
			popup.popup_on_parent(Rect2(get_global_mouse_position(),Vector2()))
			if resource.help_page_path == "":
				popup.set_item_disabled(4, true)
			else:
				popup.set_item_disabled(4, false)
