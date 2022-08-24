@tool
extends HBoxContainer

var parent_resource = null

func refresh():
	if parent_resource is DialogicChoiceEvent:
		show()
		$Label.text = "End of choice ("+parent_resource.Text+")"
	else:
		hide()
