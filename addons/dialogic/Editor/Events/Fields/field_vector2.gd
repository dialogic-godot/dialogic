@tool
extends DialogicVisualEditorFieldVector
## Event block field for a Vector2.

@export var step: float = 0.1
@export var enforce_step: bool = true

var current_value := Vector2()


func _ready() -> void:
	if enforce_step:
		$X.step = step
		$Y.step = step


func _set_value(value: Variant) -> void:
	current_value = value
	value_changed.emit(property_name, value)
	super(value)


func get_value() -> Vector2:
	return current_value


func _load_display_info(info: Dictionary) -> void:
	for option in info.keys():
		match option:
			#'min': min = info[option]
			#'max': max = info[option]
			#'prefix': update_prefix(info[option])
			#'suffix': update_suffix(info[option])
			'step':
				enforce_step = true
				step = info[option]
			#'hide_step_button': %Spin.hide()


func _on_sub_value_changed(sub_component: String, value: float) -> void:
	match sub_component:
		'X': current_value.x = value
		'Y': current_value.y = value
	_on_value_changed(current_value)


func _update_sub_component_text(value: Variant) -> void:
	$X._on_value_text_submitted(str(value.x), true)
	$Y._on_value_text_submitted(str(value.y), true)
