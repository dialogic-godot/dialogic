@tool
extends DialogicCharacterEditorMainTab

## The general character settings tab


func _ready() -> void:
	# Connecting all necessary signals
	%ColorPickerButton.color_changed.connect(character_editor.something_changed)
	%DisplayNameLineEdit.text_changed.connect(character_editor.something_changed)
	%NicknameLineEdit.text_changed.connect(character_editor.something_changed)
	%DescriptionTextEdit.text_changed.connect(character_editor.something_changed)
	%DefaultPortraitPicker.value_changed.connect(default_portrait_changed)
	%MainScale.value_changed.connect(main_portrait_settings_update)
	%MainOffsetX.value_changed.connect(main_portrait_settings_update)
	%MainOffsetY.value_changed.connect(main_portrait_settings_update)
	%MainMirror.toggled.connect(main_portrait_settings_update)
	
	# Setting up Default Portrait Picker
	%DefaultPortraitPicker.resource_icon = load("res://addons/dialogic/Editor/Images/Resources/portrait.svg")
	%DefaultPortraitPicker.get_suggestions_func = suggest_portraits
	%DefaultPortraitPicker.set_left_text("")


func _load_character(resource:DialogicCharacter) -> void:
	%DisplayNameLineEdit.text = resource.display_name
	%ColorPickerButton.color = resource.color
	
	%NicknameLineEdit.text = ""
	for nickname in resource.nicknames: 
		%NicknameLineEdit.text += nickname +", "
	%NicknameLineEdit.text = %NicknameLineEdit.text.trim_suffix(', ')
	
	%DescriptionTextEdit.text = resource.description
	%DefaultPortraitPicker.set_value(resource.default_portrait)
	
	%MainScale.value = 100*resource.scale
	%MainOffsetX.value = resource.offset.x
	%MainOffsetY.value = resource.offset.y
	%MainMirror.button_pressed = resource.mirror


func _save_changes(resource:DialogicCharacter) -> DialogicCharacter:
	resource.display_name = %DisplayNameLineEdit.text
	resource.color = %ColorPickerButton.color
	var nicknames := []
	for n_name in %NicknameLineEdit.text.split(','):
		nicknames.append(n_name.strip_edges())
	resource.nicknames = nicknames
	resource.description = %DescriptionTextEdit.text
	
	if $'%DefaultPortraitPicker'.current_value in resource.portraits.keys():
		resource.default_portrait = $'%DefaultPortraitPicker'.current_value
	elif !resource.portraits.is_empty():
		resource.default_portrait = resource.portraits.keys()[0]
	else:
		resource.default_portrait = ""
	
	resource.scale = %MainScale.value/100.0
	resource.offset = Vector2(%MainOffsetX.value, %MainOffsetY.value) 
	resource.mirror = %MainMirror.button_pressed
	
	return resource


# Get suggestions for DefaultPortraitPicker
func suggest_portraits(search:String) -> Dictionary:
	var suggestions := {}
	for portrait in character_editor.get_updated_portrait_dict().keys():
		suggestions[portrait] = {'value':portrait}
	return suggestions


# Make sure preview get's updated when portrait settings change
func main_portrait_settings_update(value = null) -> void:
	character_editor.current_resource.scale = %MainScale.value/100.0
	character_editor.current_resource.offset = Vector2(%MainOffsetX.value, %MainOffsetY.value) 
	character_editor.current_resource.mirror = %MainMirror.button_pressed
	character_editor.update_preview()
	character_editor.something_changed()

func default_portrait_changed(property:String, value:String) -> void:
	character_editor.current_resource.default_portrait = value
	character_editor.update_default_portrait_star(value)
	
