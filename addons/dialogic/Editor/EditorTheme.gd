tool
extends VBoxContainer

var editor_reference

func _ready():
	var action_option_button = $VBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/ActionOptionButton
	action_option_button.add_item('[Select Action]')
	for a in InputMap.get_actions():
		action_option_button.add_item(a)
	DialogicUtil.test()
	var settings = DialogicUtil.load_settings()
	if settings.has('theme_text_color'):
		$VBoxContainer/HBoxContainer/ColorPickerButton.color = Color('#' + str(settings['theme_text_color']))


func _on_BackgroundTextureButton_pressed():
	editor_reference.godot_dialog("*.png")
	editor_reference.godot_dialog_connect(self, "_on_background_selected")

func _on_background_selected(path, target):
	$VBoxContainer/HBoxContainer4/BackgroundTextureButton.icon = load(path)


func _on_NextIndicatorButton_pressed():
	editor_reference.godot_dialog("*.png")
	editor_reference.godot_dialog_connect(self, "_on_indicator_selected")

func _on_indicator_selected(path, target):
	$VBoxContainer/HBoxContainer3/NextIndicatorButton.icon = load(path)


func _on_ColorPickerButton_color_changed(color):
	var data = DialogicUtil.load_settings()
	data['theme_text_color'] = color.to_html()
	
	var file = File.new()
	file.open(DialogicUtil.get_path('SETTINGS_FILE'), File.WRITE)
	file.store_line(to_json(data))
	file.close()
