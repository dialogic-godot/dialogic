@tool
extends Control
var resource
var parent_node

var end_control :Control

### the indent size
var indent_size = 15
var current_indent_level = 1

func _ready():
	$Icon.icon = get_theme_icon("GuiSpinboxUpdown", "EditorIcons")
	parent_node_changed()
	$Spacer.custom_minimum_size.x = 100*DialogicUtil.get_editor_scale()
	

func visual_select():
	modulate = get_theme_color("warning_color", "Editor")


func visual_deselect():
	modulate = Color(1,1,1,1)


func highlight():
	modulate = parent_node.resource.event_color.lightened(0.5)


func unhighlight():
	modulate = Color(1,1,1,1)

func set_indent(indent: int):
	var indent_node = $Indent
	indent_node.custom_minimum_size = Vector2(indent_size * indent, 0)
	indent_node.visible = indent != 0
	current_indent_level = indent
	queue_redraw()

func parent_node_changed():
	if parent_node:
		if end_control and end_control.has_method('refresh'):
			end_control.refresh()

func add_end_control(control:Control):
	add_child(control)
	control.size_flags_vertical = SIZE_SHRINK_BEGIN
	if "parent_resource" in control:
		control.parent_resource = parent_node.resource
	if control.has_method('refresh'):
		control.refresh()
	end_control = control

