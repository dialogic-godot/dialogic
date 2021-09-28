tool
extends GridContainer

signal style_modified(section)
signal picking_background(section)

var real_file_path = 'res://addons/dialogic/Example Assets/backgrounds/background-2.png'


func load_style(data):
	$TextColor/CheckBox.pressed = data[0]
	$TextColor/ColorPickerButton.color = data[1]
	
	$FlatBackground/CheckBox.pressed = data[2]
	$FlatBackground/ColorPickerButton.color = data[3]
	
	$BackgroundTexture/CheckBox.pressed = data[4]
	set_path(data[5])
	
	$TextureModulation/CheckBox.pressed = data[6]
	$TextureModulation/ColorPickerButton.color = data[7]
	
	check_visible_buttons()


func get_style_array():
	var results = []
	results.append($TextColor/CheckBox.pressed)
	results.append($TextColor/ColorPickerButton.color)
	
	results.append($FlatBackground/CheckBox.pressed)
	results.append($FlatBackground/ColorPickerButton.color)
	
	results.append($BackgroundTexture/CheckBox.pressed)
	results.append(real_file_path)
	
	results.append($TextureModulation/CheckBox.pressed)
	results.append($TextureModulation/ColorPickerButton.color)
	
	return results


func set_path(path):
	$BackgroundTexture/Button.text = DialogicResources.get_filename_from_path(path)


func check_visible_buttons():
	$FlatBackground/ColorPickerButton.visible = $FlatBackground/CheckBox.pressed
	
	if $FlatBackground/CheckBox.pressed:
		$BackgroundTexture.visible = false
		$BackgroundTextureLabel.visible = false
		$TextureModulation.visible = false
		$TextureModulationLabel.visible = false
	else:
		$BackgroundTexture.visible = true
		$BackgroundTextureLabel.visible = true
		$TextureModulation.visible = true
		$TextureModulationLabel.visible = true


func _on_CheckBox_toggled(button_pressed):
	emit_signal("style_modified", name.to_lower())
	check_visible_buttons()


func _on_ColorPickerButton_color_changed(color):
	emit_signal("style_modified", name.to_lower())


func _on_Button_pressed():
	emit_signal("picking_background", name.to_lower())


func _on_button_texture_selected(path, target) -> void:
	emit_signal("style_modified", name.to_lower())


func _on_TextColor_ColorPickerButton_color_changed(color):
	$TextColor/CheckBox.pressed = true
	emit_signal("style_modified", name.to_lower())
