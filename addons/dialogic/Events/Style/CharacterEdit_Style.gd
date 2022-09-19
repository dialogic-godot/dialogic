@tool
extends HBoxContainer

func load_character(character:DialogicCharacter):
	%StyleName.text = character.custom_info.get('style', '')

func save_character(character:DialogicCharacter):
	character.custom_info['style'] = %StyleName.text
