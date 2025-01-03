@tool
extends DialogicSettingsPage

## Settings tab that holds dialogic editor accessibility settings.


func _get_title() -> String:
	return "Accessibility"


func _get_priority() -> int:
	return 98


func _refresh() -> void:
	%ImagePreviewHeight.value = ProjectSettings.get_setting('dialogic/accessibility/image_preview_height', 100)
	%EventBlockMargin.value = ProjectSettings.get_setting('dialogic/accessibility/event_block_margin', 0)
	%ShowEventNames.set_pressed_no_signal(ProjectSettings.get_setting('dialogic/accessibility/show_event_names', false))


func _ready() -> void:
	%ImagePreviewHeight.value_changed.connect(_on_ImagePreviewHeight_value_changed)
	%EventBlockMargin.value_changed.connect(_on_EventBlockMargin_value_changed)
	%ShowEventNames.toggled.connect(_on_ShowEventNames_toggled)


func _on_ImagePreviewHeight_value_changed(value:float) -> void:
	ProjectSettings.set_setting('dialogic/accessibility/image_preview_height', value)
	ProjectSettings.save()


func _on_EventBlockMargin_value_changed(value:float) -> void:
	ProjectSettings.set_setting('dialogic/accessibility/event_block_margin', value)
	ProjectSettings.save()


func _on_ShowEventNames_toggled(toggled:bool) -> void:
	ProjectSettings.set_setting('dialogic/accessibility/show_event_names', toggled)
	ProjectSettings.save()
