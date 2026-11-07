@tool
class_name DialogicEditorUtil

## Script with utility functions used across Dialogic but editor specific, 
## so not available at runtime.



#region INSPECTOR FIELDS
################################################################################

static func setup_script_property_edit_node(property_info: Dictionary, value:Variant, property_changed:Callable, property_path := "") -> Control:
	if property_path.is_empty():
		property_path = property_info.name
	var input: Control = null
	if property_info.type == TYPE_STRING and property_info.hint == PROPERTY_HINT_MULTILINE_TEXT:
		property_info.hint = PROPERTY_HINT_NONE
	match property_info.type:
		#TYPE_BOOL when false:
			#input = CheckBox.new()
			#if value != null:
				#input.button_pressed = value
			#input.toggled.connect(_on_export_simple_submitted.bind(property_path, property_changed))
		#TYPE_COLOR when false:
			#input = ColorPickerButton.new()
			#if value != null:
				#input.color = value
			#input.color_changed.connect(_on_export_simple_submitted.bind(property_path, property_changed))
			#input.custom_minimum_size.x = get_editor_scale() * 50
		#TYPE_INT when false:
			#if property_info["hint"] & PROPERTY_HINT_ENUM == PROPERTY_HINT_ENUM:
				#input = OptionButton.new()
				#var idx := 0
				#for x in property_info["hint_string"].split(","):
					#input.add_item((Array(x.split(":"))[0] if ":" in x else x).capitalize())
					#var id := int(Array(x.split(":"))[1] if ":" in x else idx)
					#input.set_item_metadata(idx, id)
					#if value == id:
						#input.select(idx)
#
					#idx += 1
				#input.item_selected.connect(DialogicUtil._on_export_int_enum_submitted.bind(property_path, property_changed, input))
			#else:
				#input = load("res://addons/dialogic/Editor/Events/Fields/field_number.tscn").instantiate()
				#input.property_name = property_path
				#input.use_int_mode()
#
				#if ',' in property_info.hint_string:
					#input.min_value = int(property_info.hint_string.get_slice(',', 0))
					#input.max_value = int(property_info.hint_string.get_slice(',', 1))
					#if property_info.hint_string.count(',') > 1:
						#input.step = int(property_info.hint_string.get_slice(',', 2))
				#else:
					#input.step = 1
					#input.max_value = INF
					#input.min_value = -INF
#
				#if value != null:
					#input.set_value(value)
				#input.value_changed.connect(_on_export_field_submitted.bind(property_changed))
		#TYPE_FLOAT when false:
			#input = load("res://addons/dialogic/Editor/Events/Fields/field_number.tscn").instantiate()
			#input.property_name = property_path
			#input.use_float_mode()
			#input.step = 0.01
			#if ',' in property_info.hint_string:
				#input.min_value = float(property_info.hint_string.get_slice(',', 0))
				#input.max_value = float(property_info.hint_string.get_slice(',', 1))
				#if property_info.hint_string.count(',') > 1:
					#input.step = float(property_info.hint_string.get_slice(',', 2))
			#if value != null:
				#input.set_value(value)
			#input.value_changed.connect(_on_export_field_submitted.bind(property_changed))
		#TYPE_VECTOR2, TYPE_VECTOR3, TYPE_VECTOR4 when false:
			#var vectorSize: String = type_string(typeof(value))[-1]
			#input = load("res://addons/dialogic/Editor/Events/Fields/field_vector" + vectorSize + ".tscn").instantiate()
			#input.property_name = property_path
			#input.set_value(value)
			#input.value_changed.connect(_on_export_field_submitted.bind(property_changed))
		#TYPE_VECTOR2I, TYPE_VECTOR3I, TYPE_VECTOR4I when false:
			#var vectorSize: String = type_string(typeof(value))[-2]
			#input = load("res://addons/dialogic/Editor/Events/Fields/field_vector" + vectorSize + ".tscn").instantiate()
			#input.step = 1
			#input.property_name = property_path
			#input.set_value(value)
			#input.value_changed.connect(DialogicUtil._on_export_vectori_submitted.bind(property_changed))
		#TYPE_STRING when false:
			#if property_info['hint'] & PROPERTY_HINT_FILE== PROPERTY_HINT_FILE  or property_info['hint'] & PROPERTY_HINT_DIR == PROPERTY_HINT_DIR:
				#input = load("res://addons/dialogic/Editor/Events/Fields/field_file.tscn").instantiate()
				#input.show_editing_button = true
				#input.file_filter = property_info['hint_string']
				#input.file_mode = FileDialog.FILE_MODE_OPEN_FILE
				#if property_info['hint'] == PROPERTY_HINT_DIR:
					#input.file_mode = FileDialog.FILE_MODE_OPEN_DIR
				#input.property_name = property_path
				#input.placeholder = "Default"
				#input.hide_reset = true
				#if value != null:
					#input.set_value(value)
				#input.value_changed.connect(_on_export_field_submitted.bind(property_changed))
			#elif property_info['hint'] & PROPERTY_HINT_ENUM == PROPERTY_HINT_ENUM:
				#input = OptionButton.new()
				#var options: PackedStringArray = []
				#for x in property_info['hint_string'].split(','):
					#options.append(x.split(':')[0].strip_edges())
					#input.add_item(options[-1])
				#if value != null:
					#input.select(options.find(value))
				#input.item_selected.connect(DialogicUtil._on_export_string_enum_submitted.bind(property_path, options, property_changed))
			#else:
				#input = LineEdit.new()
				#if value != null:
					#input.text = value
				#input.text_submitted.connect(_on_export_simple_submitted.bind(property_path, property_changed))
		#TYPE_DICTIONARY when false:
			#input = load("res://addons/dialogic/Editor/Events/Fields/field_dictionary.tscn").instantiate()
			#input.property_name = property_path
			#input.set_value(value)
			#input.value_changed.connect(_on_export_field_submitted.bind(property_changed))
		#TYPE_ARRAY when false:
			#input = load("res://addons/dialogic/Editor/Events/Fields/field_array.tscn").instantiate()
			#input.property_name = property_path
			#input.set_value(value)
			#input.value_changed.connect(_on_export_field_submitted.bind(property_changed))
		#TYPE_OBJECT when false:
			#input = load("res://addons/dialogic/Editor/Common/hint_tooltip_icon.tscn").instantiate()
			#input.hint_text = "Objects/Resources as settings are currently not supported. \nUse @export_file('*.extension') instead and load the resource once needed."

		_:
			var fake := DialogicFakeObject.new()
			fake.property = value

			var pi := property_info
			input = EditorInspector.instantiate_property_editor(fake, pi.type, "property", pi.hint, pi.hint_string, PROPERTY_USAGE_EDITOR, true)
			fake.editor_property = input
			#var hbox := HBoxContainer.new()
			#hbox.add_theme_constant_override("separation", 0)
			input.ready.connect(func():
				input.set_object_and_property(fake, "property")
				input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				input.set_meta("object", fake)
				input.draw_label = false
				input.property_changed.connect(_on_export_inspector_changed.bind(property_path, property_changed, input))
				input.update_property()
				fake.changed.connect(input.emit_changed.bind(pi.name, "//EMPTY", "", false))
			)
			#hbox.add_child(input)
			#input = hbox

	return input


class DialogicFakeObject extends RefCounted:
	signal changed
	@export var property : Variant = null:
		set(p):
			property = p
			if property is Resource and not property.resource_path:
				if not property.is_connected("changed", changed.emit):
					property.changed.connect(changed.emit)
			ensure_button()

	var editor_property: EditorProperty = null:
		set(ep):
			editor_property = ep
			ensure_button()

	var make_unique_button: Button = null

	func ensure_button() -> void:
		if editor_property == null:
			return

		if property is Resource and ".tscn::" in property.resource_path:
			if make_unique_button:
				make_unique_button.show()
				return
			if not editor_property.is_node_ready():
				await editor_property.ready
			make_unique_button = Button.new()
			make_unique_button.tooltip_text = "Make unique"
			make_unique_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			make_unique_button.icon = editor_property.get_theme_icon("Instance", "EditorIcons")
			make_unique_button.add_theme_stylebox_override("normal", editor_property.get_theme_stylebox("normal", "LineEdit"))
			editor_property.add_child(make_unique_button)
			make_unique_button.pressed.connect(make_unique_manual)
		elif make_unique_button:
			make_unique_button.hide()

	func make_unique_manual() -> void:
		if property is Resource:
			var new_property = property.duplicate(true)
			new_property.resource_path = ""
			property = new_property
			new_property.emit_changed()

#
#static func _on_export_simple_submitted(value:Variant, property_name:String, callable:Callable) -> void:
	#callable.call(property_name, value)
#
#static func _on_export_field_submitted(property_name:String, value:Variant, callable: Callable) -> void:
	#callable.call(property_name, value)
#
#static func _on_export_int_enum_submitted(item:int, property_name:String, callable: Callable, option_button:OptionButton) -> void:
	#callable.call(property_name, option_button.get_item_metadata(item))
#
#static func _on_export_string_enum_submitted(value:int, property_name:String, list:PackedStringArray, callable: Callable):
	#callable.call(property_name, list[value])
#
#static func _on_export_vectori_submitted(property_name:String, value:Variant, callable: Callable) -> void:
	#match typeof(value):
		#TYPE_VECTOR2: value = Vector2i(value)
		#TYPE_VECTOR3: value = Vector3i(value)
		#TYPE_VECTOR4: value = Vector4i(value)
	#callable.call(property_name, value)


static func _on_export_inspector_changed(_name:String, value:Variant, _field:String, _changed:bool, path:String, callable:Callable, input_field:EditorProperty) -> void:
	if typeof(value) == TYPE_STRING and  value == "//EMPTY":
		value = input_field.get_meta("object").property
	callable.call(path, value)

	input_field.get_meta("object").property = value
	input_field.update_property()


static func set_property_edit_node_value(node:Control, value:Variant) -> void:
	if node is CheckBox:
		node.button_pressed = value
	elif node is LineEdit:
		node.text = value
	elif node.has_method("set_value"):
		node.set_value(value)
	elif node is ColorPickerButton:
		node.color = value
	elif node is OptionButton:
		for i in range(node.item_count):
			if node.get_item_metadata(i) == value:
				node.select(i)
	elif node is SpinBox:
		node.value = value
	elif node is EditorProperty:
		node.get_meta("object").property = value
		node.update_property()


#endregion
