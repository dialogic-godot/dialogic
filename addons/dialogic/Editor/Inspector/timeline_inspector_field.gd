@tool
extends EditorProperty

var field: Control = null
var button: Button = null
# An internal value of the property.
var current_value: DialogicTimeline = null
# A guard against internal changes when the property is updated.
var updating = false


func _init() -> void:
	var hbox := HBoxContainer.new()
	add_child(hbox)

	field = load("res://addons/dialogic/Editor/Events/Fields/field_options_dynamic.tscn").instantiate()
	hbox.add_child(field)
	field.placeholder_text = "No Timeline"
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	field.mode = field.Modes.IDENTIFIER
	field.fit_text_length = false
	field.valid_file_drop_extension = ".dtl"
	field.value_changed.connect(_on_field_value_changed)
	field.suggestions_func = get_timeline_suggestions

	button = Button.new()
	hbox.add_child(button)
	button.hide()
	button.pressed.connect(_on_button_pressed, CONNECT_DEFERRED)


func _on_field_value_changed(property:String, value:Variant) -> void:
	# Ignore the signal if the property is currently being updated.
	if updating:
		return

	var new_value: DialogicTimeline = null
	if value:
		new_value = DialogicResourceUtil.get_timeline_resource(value)

	if current_value != new_value:
		current_value = new_value
		if current_value:
			button.show()
		else:
			button.hide()
		emit_changed(get_edited_property(), current_value)


func _update_property() -> void:
	field.resource_icon = get_theme_icon("TripleBar", "EditorIcons")
	button.icon = get_theme_icon("ExternalLink", "EditorIcons")

	# Read the current value from the property.
	var new_value = get_edited_object()[get_edited_property()]
	if (new_value == current_value):
		return

	# Update the control with the new value.
	updating = true
	current_value = new_value
	if current_value:
		field.set_value(current_value.get_identifier())
		button.show()
	else:
		button.hide()
		field.set_value("")
	updating = false


func get_timeline_suggestions(filter:String) -> Dictionary:
	var suggestions := {}
	var timeline_directory := DialogicResourceUtil.get_timeline_directory()
	for identifier in  timeline_directory.keys():
		suggestions[identifier] = {'value': identifier, 'tooltip':timeline_directory[identifier], 'editor_icon': ["TripleBar", "EditorIcons"]}
	return suggestions


func _on_button_pressed() -> void:
	if current_value:
		EditorInterface.edit_resource(current_value)
