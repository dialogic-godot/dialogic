@tool
extends HBoxContainer

var parent_resource = null

func _ready():
	$AddElif.button_up.connect(add_elif)
	$AddElse.button_up.connect(add_else)

func refresh():
	if parent_resource is DialogicConditionEvent:
		show()
		$Label.text = "End of IF ("+parent_resource.Condition+")"
	else:
		hide()

func add_elif():
	var timeline = find_parent('TimelineEditor')
	if timeline:
		var resource = DialogicConditionEvent.new()
		resource.ConditionType = DialogicConditionEvent.ConditionTypes.ELIF
		timeline.add_event_with_end_branch(resource, get_parent().get_index()+1)
		timeline.indent_events()

func add_else():
	var timeline = find_parent('TimelineEditor')
	if timeline:
		var resource = DialogicConditionEvent.new()
		resource.ConditionType = DialogicConditionEvent.ConditionTypes.ELSE
		timeline.add_event_with_end_branch(resource, get_parent().get_index()+1)
		timeline.indent_events()
