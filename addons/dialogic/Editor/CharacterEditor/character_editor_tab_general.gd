@tool
extends DialogicCharacterEditorMainTab

## The general character settings tab


func _ready() -> void:
	# Connecting all necessary signals
	%ColorPickerButton.color_changed.connect(character_editor.something_changed)
	%DisplayNameLineEdit.text_changed.connect(character_editor.something_changed)
	%NicknameLineEdit.text_changed.connect(character_editor.something_changed)
	%DescriptionTextEdit.text_changed.connect(character_editor.something_changed)


func _load_character(resource:DialogicCharacter) -> void:
	%DisplayNameLineEdit.text = resource.display_name
	%ColorPickerButton.color = resource.color
	
	%NicknameLineEdit.text = ""
	for nickname in resource.nicknames: 
		%NicknameLineEdit.text += nickname +", "
	%NicknameLineEdit.text = %NicknameLineEdit.text.trim_suffix(', ')
	
	%DescriptionTextEdit.text = resource.description


func _save_changes(resource:DialogicCharacter) -> DialogicCharacter:
	resource.display_name = %DisplayNameLineEdit.text
	resource.color = %ColorPickerButton.color
	var nicknames := []
	for n_name in %NicknameLineEdit.text.split(','):
		nicknames.append(n_name.strip_edges())
	resource.nicknames = nicknames
	resource.description = %DescriptionTextEdit.text
	
	return resource
