tool
extends HBoxContainer

export (bool) var optional := false

var default_definition_text = 'Select Definition'
var default_condition_text = 'equal to'
onready var Definition = $Values/Definition
onready var Condition = $Values/Condition
onready var Value = $Values/Value
var options = [{
		"text": "equal to",
		"condition": "=="
	},{
		"text": "different from",
		"condition": "!="
	},{
		"text": "greater than",
		"condition": ">"
	},{
		"text": "greater or equal to",
		"condition": ">="
	},{
		"text": "less than",
		"condition": "<"
	},{
		"text": "less or equal to",
		"condition": "<="
	}
]


func _ready():
	Definition.get_popup().connect("index_pressed", self, '_on_definition_selected')
	Definition.connect("about_to_show", self, "_on_definition_about_to_show")
	
	Condition.get_popup().connect("index_pressed", self, '_on_condition_selected')
	Condition.connect("about_to_show", self, "_on_condition_about_to_show")
	
	Value.connect("text_changed", self, "_on_value_changed")

	$HasCondition.visible = false
	$Values.visible = true

	if optional:
		$HasCondition.visible = true
		$HasCondition/CheckBox.connect('toggled', self, '_on_toggle_visibility')
		$Values.visible = false


func _on_toggle_visibility(checkbox_value):
	$Values.visible = checkbox_value
	if checkbox_value == false:
		Definition.text = default_definition_text
		Condition.text = default_condition_text
		Value.text = ''
		get_parent().event_data['definition'] = ''
		get_parent().event_data['condition'] = ''
		get_parent().event_data['value'] = ''


# Definition picker ------------------------------------------------------------
func set_definition(definition):
	if definition != '':
		for d in DialogicResources.get_default_definitions()['variables']:
			if d['id'] == definition:
				Definition.text = d['name']
	else:
		Definition.text = default_definition_text


func _on_definition_selected(index):
	var definition = Definition.get_popup().get_item_metadata(index).get('id', '')
	set_definition(definition)
	# Set values on the parent
	get_parent().event_data['definition'] = definition


func _on_definition_about_to_show():
	Definition.get_popup().clear()
	var index = 0
	for d in DialogicUtil.get_default_definitions_list():
		if d['type'] == 0:
			Definition.get_popup().add_item(d['name'])
			Definition.get_popup().set_item_metadata(index, d)
			index += 1


# Condition picker -------------------------------------------------------------
func set_condition(condition):
	for o in options:
		if o['condition'] == condition:
			Condition.text = o['text']


func _on_condition_selected(index):
	var condition = Condition.get_popup().get_item_metadata(index).get('condition')
	set_condition(condition)
	# Set values on the parent
	get_parent().event_data['condition'] = condition


func _on_condition_about_to_show():
	Condition.get_popup().clear()
	var index = 0
	for o in options:
		Condition.get_popup().add_item(o['text'])
		Condition.get_popup().set_item_metadata(index, o)
		index += 1

# Value ------------------------------------------------------------------------
func _on_value_changed(new_text):
	# Set values on the parent
	get_parent().event_data['value'] = new_text
