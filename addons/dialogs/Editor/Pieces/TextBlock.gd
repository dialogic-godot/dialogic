tool
extends PanelContainer

var text_height = 80
	
func _ready():
	$VBoxContainer/TextEdit.set("rect_min_size", Vector2(0, 80))
	$VBoxContainer/Header/VisibleToggle.connect("toggled", self, "_on_VisibleToggle_toggled")

func _on_VisibleToggle_toggled(button_pressed):
	var current_rect_size = get("rect_size")
	if button_pressed:
		$VBoxContainer/TextEdit.set("rect_min_size", Vector2(0, 80))
		$VBoxContainer/TextEdit.show()
	else:
		$VBoxContainer/TextEdit.hide()
		$VBoxContainer/TextEdit.set("rect_min_size", Vector2(0, 0))
		#$VBoxContainer.set("rect_size", Vector2(0,0))
		self.set("rect_size", Vector2(current_rect_size.x,0))
