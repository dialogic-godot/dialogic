tool
extends Control

var resource
var parent_node

### the indent size
var indent_size = 45
var current_indent_level = 1

func _ready():
	parent_node_changed()
	$ConditionButtons/Elif.connect('pressed', self, 'add_elif')
	$ConditionButtons/Else.connect('pressed', self, 'add_else')

func visual_select():
	modulate = get_color("accent_color", "Editor")


func visual_deselect():
	modulate = Color.white

func highlight():
	modulate = get_color("warning_color", "Editor")


func unhighlight():
	modulate = Color.white

func set_indent(indent: int):
	var indent_node = $Indent
	indent_node.rect_min_size = Vector2(indent_size * indent, 0)
	indent_node.visible = indent != 0
	current_indent_level = indent
	update()

func parent_node_changed():
	if parent_node:
		if parent_node.resource is DialogicChoiceEvent:
			$Label.text = "End of choice '"+parent_node.resource.Text+"'"
			$ConditionButtons.hide()
		elif parent_node.resource is DialogicConditionEvent:
			if parent_node.resource.ConditionType != DialogicConditionEvent.ConditionTypes.ELSE:
				$ConditionButtons.show()
				$Label.text = "End of condition '"+parent_node.resource.Condition+"'"
			else:
				$ConditionButtons.hide()
				$Label.text = "End of else"
				
			
func add_elif():
	var timeline = find_parent('TimelineEditor')
	if timeline:
		timeline.add_condition_pressed(get_index()+1, DialogicConditionEvent.ConditionTypes.ELIF)
		timeline.indent_events()

func add_else():
	var timeline = find_parent('TimelineEditor')
	if timeline:
		timeline.add_condition_pressed(get_index()+1, DialogicConditionEvent.ConditionTypes.ELSE)
		timeline.indent_events()

