@tool
extends HBoxContainer

func load_character(character:DialogicCharacter):
	%ThemeName.text = character.custom_info.get('theme', '')

func save_character(character:DialogicCharacter):
	character.custom_info['theme'] = %ThemeName.text
