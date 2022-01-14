tool
extends VBoxContainer



func _on_EnableHistoryLogging_toggled(button_pressed):
	$GridContainer/ThemeBox/EnableDynamicTheme.disabled = !button_pressed
	$GridContainer/OpenBox/EnableDefaultOpenButton.disabled = !button_pressed
	$GridContainer/CloseBox/EnableDefaultCloseButton.disabled = !button_pressed
	$GridContainer/ChoiceBox/LogChoices.disabled = !button_pressed
	$GridContainer/ChoiceBox2/LogAnswers.disabled = !button_pressed
	$GridContainer/ChoiceBox3/LogArrivals.disabled = !button_pressed
	$GridContainer/LogBox/LineEdit.editable = button_pressed
	$GridContainer/ChoiceBox4/LogExits.disabled = !button_pressed
	$GridContainer/LogBox2/LineEdit.editable = button_pressed
	$GridContainer/PositionSelector.disabled = !button_pressed
	$GridContainer/CharacterDelimiter.editable = button_pressed
	$GridContainer/BoxMargin/MarginX.editable = button_pressed
	$GridContainer/BoxMargin/MarginY.editable = button_pressed
	$GridContainer/ContainerMargin/MarginX.editable = button_pressed
	$GridContainer/ContainerMargin/MarginY.editable = button_pressed
