@tool
extends DialogicVisualEditorField

## Event block field for boolean values.

#region MAIN METHODS
################################################################################
func _ready() -> void:
	self.toggled.connect(_on_value_changed)


func _load_display_info(info:Dictionary) -> void:
	pass


func _set_value(value:Variant) -> void:
	match DialogicUtil.get_variable_value_type(value):
		DialogicUtil.VarTypes.STRING:
			self.button_pressed = value and not value.strip_edges() == "false"
		_:
			self.button_pressed = value and true
#endregion


#region SIGNAL METHODS
################################################################################
func _on_value_changed(value:bool) -> void:
	value_changed.emit(property_name, value)

#endregion
