tool
extends PopupPanel

var should_free_on_hide = false

signal saving_value(value)
signal key_changed(new_key)

func show_translation(var key : String, var value : String) -> void:
	$VBoxContainer/HBoxContainer/KeyValueLabel.text = key
	$VBoxContainer/TextEdit.text = value
	
	popup_centered_minsize(Vector2(640, 290))
	
	should_free_on_hide = true
	
	# If we can't find out where to save by default, don't let the user click this
	if CSV_Translation.get_translation_location(key) == "":
		$VBoxContainer/HBoxContainer2/DoneButton.disabled = true
	if key == "":
		$VBoxContainer/HBoxContainer2/SaveAtButton.disabled = true


func _on_DoneButton_pressed() -> void:
	CSV_Translation.save_translation($VBoxContainer/HBoxContainer/KeyValueLabel.text, $VBoxContainer/TextEdit.text)
	_on_done_saving()
	hide()


func _on_DoneButton_hide() -> void:
	if should_free_on_hide: # prevents a crash when opening the scene in-editor
		queue_free()


func _on_SaveAtButton_pressed() -> void:
	var file_picker = FileDialog.new()
	file_picker.filters = ["*.csv"]
	file_picker.current_dir = DialogicResources.get_settings_value("Dialog", "TranslationLocation", "Res://")
	add_child(file_picker)
	file_picker.popup_centered_minsize(Vector2(100, 250))
	var path = yield(file_picker, "file_selected")
	file_picker.queue_free()
	CSV_Translation.save_translation_at($VBoxContainer/HBoxContainer/KeyValueLabel.text, 
			$VBoxContainer/TextEdit.text,
			path)
	_on_done_saving()
	hide()


func _on_BrowseKeys_pressed() -> void:
	$TranslationKeyBrowserPopup.show_keys()


func _on_done_saving():
	emit_signal("saving_value", $VBoxContainer/TextEdit.text)


func _on_TranslationKeyBrowserPopup_key_selected(var new_key : String) -> void:
	emit_signal("key_changed", new_key)
	hide()
