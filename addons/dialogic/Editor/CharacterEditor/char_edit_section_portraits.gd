@tool
extends DialogicCharacterEditorMainSection

## The general portrait settings section
var loading := false

func _ready() -> void:
	# Connecting all necessary signals
	%DefaultPortraitPicker.value_changed.connect(default_portrait_changed)
	%MainScale.value_changed.connect(main_portrait_settings_update)
	%MainOffset.value_changed.connect(main_portrait_settings_update)
	%MainMirror.toggled.connect(main_portrait_settings_update)
	
	# Setting up Default Portrait Picker
	%DefaultPortraitPicker.resource_icon = load("res://addons/dialogic/Editor/Images/Resources/portrait.svg")
	%DefaultPortraitPicker.get_suggestions_func = suggest_portraits



# Make sure preview get's updated when portrait settings change
func main_portrait_settings_update(_something=null, _value=null) -> void:
	if loading: 
		return
	character_editor.current_resource.scale = %MainScale.value/100.0
	character_editor.current_resource.offset = %MainOffset.current_value
	character_editor.current_resource.mirror = %MainMirror.button_pressed
	character_editor.update_preview()
	character_editor.something_changed()


func default_portrait_changed(property:String, value:String) -> void:
	character_editor.current_resource.default_portrait = value
	character_editor.update_default_portrait_star(value)


func _load_character(resource:DialogicCharacter) -> void:
	loading = true
	%DefaultPortraitPicker.set_value(resource.default_portrait)
	
	%MainScale.value = 100*resource.scale
	%MainOffset.set_value(resource.offset)
	%MainMirror.button_pressed = resource.mirror
	loading = false

func _save_changes(resource:DialogicCharacter) -> DialogicCharacter:
	# Portrait settings
	if %DefaultPortraitPicker.current_value in resource.portraits.keys():
		resource.default_portrait = %DefaultPortraitPicker.current_value
	elif !resource.portraits.is_empty():
		resource.default_portrait = resource.portraits.keys()[0]
	else:
		resource.default_portrait = ""
	
	resource.scale = %MainScale.value/100.0
	resource.offset = %MainOffset.current_value
	resource.mirror = %MainMirror.button_pressed
	return resource


# Get suggestions for DefaultPortraitPicker
func suggest_portraits(search:String) -> Dictionary:
	var suggestions := {}
	for portrait in character_editor.get_updated_portrait_dict().keys():
		suggestions[portrait] = {'value':portrait}
	return suggestions

