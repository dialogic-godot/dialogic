tool
extends VBoxContainer


func _ready():
	
	var action_option_button = $VBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/ActionOptionButton
	action_option_button.add_item('[Select Action]')
	for a in InputMap.get_actions():
		action_option_button.add_item(a)
