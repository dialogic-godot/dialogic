@tool
extends DialogicVisualEditorField


func _ready() -> void:
	pass


#region OVERWRITES
################################################################################


## To be overwritten
func _set_value(value:Variant) -> void:
	if ResourceLoader.exists(value):
		self.texture = load(value)
		minimum_size_changed.emit()
	else:
		self.texture = null
		minimum_size_changed.emit()

#endregion


#region SIGNAL METHODS
################################################################################

#endregion
