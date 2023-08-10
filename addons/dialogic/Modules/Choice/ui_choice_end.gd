@tool
extends HBoxContainer

var parent_resource: DialogicChoiceEvent = null

func refresh():
	if parent_resource is DialogicChoiceEvent:
		show()
		if len(parent_resource.text) > 12:
			$Label.text = "End of choice ("+parent_resource.text.substr(0,12)+"...)"
		else:
			$Label.text = "End of choice ("+parent_resource.text+")"
	else:
		hide()
