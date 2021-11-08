tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!

## node references
onready var input_field = $HBox/ChoiceText

onready var use_condition = $HasCondition/UseCondition
onready var condition_preview = $HasCondition/ConditionPreview
# used to connect the signals
func _ready():
	# e.g. 
	input_field.connect("text_changed", self, "_on_ChoiceText_text_changed")
	use_condition.connect("toggled", self, "_on_UseCondition_toggled")
	condition_preview.add_color_override("font_color", get_color("disabled_font_color", "Editor"))

# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	# Now update the ui nodes to display the data. 
	input_field.text = event_data['choice']
	
	use_condition.pressed = bool(event_data['definition'])
	condition_preview.visible = use_condition.pressed
	
	if event_data['definition']:
		condition_preview.text = "["+DialogicResources.get_default_definition_item(event_data['definition'])['name']+"]"
		condition_preview.text += " "+{
			"" : "is equal to",
			"==" : "is equal to",
			"!=":"is different from",
			">":"is greater then",
			">=":"is greater or equal to",
			"<":"is less then",
			"<=":"is less or equal to"}[event_data['condition']]+" "+event_data['value']
	else:
		condition_preview.hide()
# has to return the wanted preview, only useful for body parts
func get_preview():
	return ''


func _on_UseCondition_toggled(toggle):
	if not toggle:
		event_data['definition'] = ''
		event_data['value'] = ''
		event_data['condition'] = ''
		condition_preview.hide()
		emit_signal("request_close_body")
	else:
		emit_signal("request_open_body")
