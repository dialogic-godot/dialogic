@tool
extends DialogicCharacterEditorMainSection

## Character editor tab that allows setting a custom style fot the character. 


func _ready():
	$InfoLabel.add_theme_color_override('font_color', get_theme_color("readonly_color", "Editor"))

func _load_character(character:DialogicCharacter) -> void:
	%StyleName.text = character.custom_info.get('style', '')


func _save_changes(character:DialogicCharacter) -> DialogicCharacter:
	character.custom_info['style'] = %StyleName.text
	return character
