class_name DialogicVisualEditorFieldVector extends DialogicVisualEditorField

func _ready() -> void:
	for child in get_children():
		child.value_changed.connect(_on_value_changed)

func _load_display_info(info:Dictionary) -> void:
	for child in get_children():
		if child is DialogicVisualEditorFieldNumber:
			child._load_display_info(info)

func _on_value_changed(property:String, value:float) -> void:
	pass
