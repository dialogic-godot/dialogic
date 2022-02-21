tool
extends VBoxContainer


func _ready():
	_on_EnableHistoryLogging_toggled($GridContainer/HistoryBox/EnableHistoryLogging.pressed)

func _on_EnableHistoryLogging_toggled(button_pressed):
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
	
	$GridContainer/OpenBox.visible = button_pressed
	$GridContainer/CloseBox.visible = button_pressed
	$GridContainer/ChoiceBox.visible = button_pressed
	$GridContainer/ChoiceBox2.visible = button_pressed
	$GridContainer/ChoiceBox3.visible = button_pressed
	$GridContainer/LogBox.visible = button_pressed
	$GridContainer/ChoiceBox4.visible = button_pressed
	$GridContainer/TLabel8.visible = button_pressed
	$GridContainer/PositionSelector.visible = button_pressed
	$GridContainer/LogBox2.visible = button_pressed
	$GridContainer/TLabel9.visible = button_pressed
	$GridContainer/CharacterDelimiter.visible = button_pressed
	$GridContainer/TLabel7.visible = button_pressed
	$GridContainer/BoxMargin.visible = button_pressed
	$GridContainer/TLabel5.visible = button_pressed
	$GridContainer/ContainerMargin.visible = button_pressed
	
	$GridContainer/HSeparator.visible = button_pressed
	$GridContainer/HSeparator2.visible = button_pressed
	$GridContainer/HSeparator3.visible = button_pressed
	$GridContainer/HSeparator4.visible = button_pressed
