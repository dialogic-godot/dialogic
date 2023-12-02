@tool
extends HBoxContainer

var parent_resource: DialogicChoiceEvent = null

func refresh():
	$AddChoice.icon = get_theme_icon("Add", "EditorIcons")

	if parent_resource is DialogicChoiceEvent:
		show()
		if len(parent_resource.text) > 12:
			$Label.text = "End of choice ("+parent_resource.text.substr(0,12)+"...)"
		else:
			$Label.text = "End of choice ("+parent_resource.text+")"
	else:
		hide()


func _on_add_choice_pressed() -> void:
	var timeline = find_parent('VisualEditor')
	if timeline:
		var resource = DialogicChoiceEvent.new()
		resource.created_by_button = true
		timeline.add_event_with_end_branch(resource, get_parent().get_index()+1)
		timeline.indent_events()
