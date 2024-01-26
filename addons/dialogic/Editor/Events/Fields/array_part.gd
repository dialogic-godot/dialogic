@tool
extends PanelContainer

## Event block field part for the Array field.

signal value_changed()

var value_field: Node
var value_type: int = -1

var current_value: Variant

func _ready() -> void:
	%ValueType.options = [{
			'label': 'String',
			'icon': ["String", "EditorIcons"],
			'value': TYPE_STRING
		},{
			'label': 'Number (int)',
			'icon': ["int", "EditorIcons"],
			'value': TYPE_INT
		},{
			'label': 'Number (float)',
			'icon': ["float", "EditorIcons"],
			'value': TYPE_FLOAT
		},{
			'label': 'Boolean',
			'icon': ["bool", "EditorIcons"],
			'value': TYPE_BOOL
		},{
			'label': 'Expression',
			'icon': ["Variant", "EditorIcons"],
			'value': TYPE_MAX
		}
		]
	%ValueType.symbol_only = true
	%ValueType.value_changed.connect(_on_type_changed.bind())
	%ValueType.tooltip_text = "Change type"

	%Delete.icon = get_theme_icon("Remove", "EditorIcons")


func set_value(value:Variant):
	change_field_type(deduce_type(value))
	%ValueType.set_value(deduce_type(value))
	current_value = value
	match value_type:
		TYPE_BOOL:
			value_field.button_pressed = value
		TYPE_STRING:
			value_field.text = value
		TYPE_FLOAT, TYPE_INT:
			value_field.set_value(value)
		TYPE_MAX, _:
			value_field.text = value.trim_prefix('@')


func deduce_type(value:Variant) -> int:
	if value is String and value.begins_with('@'):
		return TYPE_MAX
	else:
		return typeof(value)


func _on_type_changed(prop:String, type:Variant) -> void:
	if type == value_type:
		return

	match type:
		TYPE_BOOL:
			if typeof(current_value) == TYPE_STRING:
				current_value = DialogicUtil.str_to_bool(current_value)
			elif value_type == TYPE_FLOAT or value_type == TYPE_INT:
				current_value = bool(current_value)
			else:
				current_value = true if current_value else false
			set_value(current_value)
		TYPE_STRING:
			current_value = str(current_value).trim_prefix('@')
			set_value(current_value)
		TYPE_FLOAT, TYPE_INT:
			current_value = float(current_value)
			set_value(current_value)
		TYPE_MAX,_:
			current_value = var_to_str(current_value)
			set_value('@'+current_value)


	emit_signal.call_deferred('value_changed')


func get_value() -> Variant:
	return current_value


func _on_delete_pressed() -> void:
	queue_free()
	value_changed.emit()


func change_field_type(type:int) -> void:
	if type == value_type:
		return

	value_type = type

	if value_field:
		value_field.queue_free()
	match type:
		TYPE_BOOL:
			value_field = CheckBox.new()
			value_field.toggled.connect(_on_bool_toggled)
		TYPE_STRING:
			value_field = LineEdit.new()
			value_field.text_changed.connect(_on_str_text_changed)
			value_field.expand_to_text_length = true
		TYPE_FLOAT, TYPE_INT:
			value_field = load("res://addons/dialogic/Editor/Events/Fields/field_number.tscn").instantiate()
			if type == TYPE_FLOAT:
				value_field.use_float_mode()
			else:
				value_field.use_int_mode()
			value_field.value_changed.connect(_on_number_value_changed.bind(type == TYPE_INT))
		TYPE_MAX, _:
			value_field = LineEdit.new()
			value_field.expand_to_text_length = true
			value_field.text_changed.connect(_on_expression_changed)
	$Value.add_child(value_field)
	$Value.move_child(value_field, 1)

func _on_bool_toggled(value:bool) -> void:
	current_value = value
	value_changed.emit()

func _on_str_text_changed(value:String) -> void:
	current_value = value
	value_changed.emit()

func _on_expression_changed(value:String) -> void:
	current_value = '@'+value
	value_changed.emit()

func _on_number_value_changed(prop:String, value:float, int := false) -> void:
	if int:
		current_value = int(value)
	else:
		current_value = value
	value_changed.emit()
