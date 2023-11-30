@tool
extends DialogicCharacterEditorMainSection

## Character editor tab that allows setting a custom style fot the character.

func _get_title() -> String:
	return "Style"


func _ready() -> void:
	%StyleName.resource_icon = get_theme_icon("PopupMenu", "EditorIcons")
	%StyleName.get_suggestions_func = get_style_suggestions
	%StyleName.force_string = true


func _load_character(character:DialogicCharacter) -> void:
	%StyleName.set_value(character.custom_info.get('style', ''))


func _save_changes(character:DialogicCharacter) -> DialogicCharacter:
	character.custom_info['style'] = %StyleName.current_value
	return character


func get_style_suggestions(filter:String="") -> Dictionary:
	var styles := ProjectSettings.get_setting('dialogic/layout/style_list', [])
	var suggestions := {}
	suggestions["No Style"] = {'value': "", 'editor_icon': ["EditorHandleDisabled", "EditorIcons"]}
	for i in styles:
		var style: DialogicStyle = load(i)
		suggestions[style.name] = {'value': style.name, 'editor_icon': ["PopupMenu", "EditorIcons"]}
	return suggestions
