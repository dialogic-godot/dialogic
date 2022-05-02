tool
extends Button

signal value_saved(value)
signal key_saved(value)

export(bool) var handle_translation = false

export(NodePath) var key_text
export(NodePath) var translated_text


func _on_EditTranslationButton_pressed() -> void:
	var popup = load("res://addons/dialogic/Editor/Events/Parts/Text/TranslationTextEditPopup.tscn").instance()
	add_child(popup)
	popup.show_translation(get_node(key_text).text, get_node(translated_text).text)
	popup.connect("saving_value", self, "_on_TranslationTextEditPopupValueSaved")
	popup.connect("key_changed", self, "_on_TranslationTextEditPopup_NewKeySelected")


func _on_TranslationTextEditPopupValueSaved(var new_value : String):
	get_node(translated_text).text = new_value
	emit_signal("value_saved", new_value)


func _ready() -> void:
	if not handle_translation:
		return
	
	var key_text_input = get_node(key_text)
	if key_text_input == null:
		return
	
	if not key_text_input.has_signal("text_changed"):
		return
	
	# We do this to get around the fact the TextEdit's text_changed signal takes 
	# no parameters, while the LineEdit's text_changed signal takes one.
	if key_text_input is TextEdit: 
		key_text_input.connect("text_changed", self, "_on_key_input_text_changed", [""])
	else:
		key_text_input.connect("text_changed", self, "_on_key_input_text_changed")
	
	_update_translation()


func _update_translation():
	var new_text = DTS.translate(get_node(key_text).text)
	if new_text == get_node(key_text).text:
		get_node(translated_text).text = ""
		return
	
	get_node(translated_text).text = new_text


func _on_key_input_text_changed(var __):
	_update_translation()


func _on_TranslationTextEditPopup_NewKeySelected(var new_key : String):
	get_node(key_text).text = new_key
	_update_translation()
	emit_signal("key_saved", new_key)
