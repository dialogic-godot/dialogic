extends MarginContainer


# Called when the node enters the scene tree for the first time.
func _ready():
			
	var history_root = find_parent("ExampleHistoryScene")
	%TextBox.add_theme_font_override("normal_font", history_root.history_font_normal)
	%TextBox.add_theme_font_override("bold_font", history_root.history_font_normal)
	%TextBox.add_theme_font_override("italics_font", history_root.history_font_normal)
	%TextBox.add_theme_font_size_override("normal_font_size", history_root.history_font_size)
	%TextBox.add_theme_font_size_override("bold_font_size", history_root.history_font_size)
	%TextBox.add_theme_font_size_override("italics_font_size", history_root.history_font_size)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
	
func set_text(text: String) -> void:
	%TextBox.text = text
