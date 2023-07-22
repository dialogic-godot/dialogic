@tool
extends HBoxContainer

var parent_resource: DialogicChoiceEvent = null

func refresh():
	if parent_resource is DialogicChoiceEvent:
		show()
		$Label.text = "End of choice ("+parent_resource.text+")"
	else:
		hide()
