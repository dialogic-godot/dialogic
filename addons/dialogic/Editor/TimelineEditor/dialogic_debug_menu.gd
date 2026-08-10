extends ScrollContainer

var settings := {}


func _init() -> void:
	settings.merge(DialogicUtil.get_editor_setting("debug_settings", {}), true)


func _ready() -> void:
	visible = settings.get("debug_visible", false)
	%PortraitContainers.button_pressed = settings.get("portrait_container_debug", false)

	#%SaveLoad.button_pressed = settings.get("show_save_load", false)
	#%SaveLoadPanel.visible = %SaveLoad.button_pressed

	Dialogic.event_handled.connect(_update_timeline_info_label)
	Dialogic.state_changed.connect(_update_state_label)


func _input(event: InputEvent) -> void:
	if event.is_pressed() and Input.is_key_pressed(KEY_CTRL) and Input.is_key_pressed(KEY_D) and Input.is_key_pressed(KEY_SPACE):
		visible = not visible
		settings["debug_visible"] = visible
		save()


func save() -> void:
	DialogicUtil.set_editor_setting("debug_settings", settings)


func _on_portrait_containers_toggled(toggled_on: bool) -> void:
	Dialogic.PortraitContainers.debug_draw = toggled_on
	settings["portrait_container_debug"] = toggled_on
	save()



func _update_timeline_info_label(_ignore="") -> void:
	if Dialogic.current_timeline == null:
		%TimelineInfo.text = "Timeline: < No Timeline >"
	else:
		%TimelineInfo.text = "Timeline: "+Dialogic.current_timeline.get_identifier()
		%TimelineInfo.text += "\nEvent "+str(Dialogic.current_event_idx)+": "+Dialogic.current_timeline_events[Dialogic.current_event_idx].event_name


func _update_state_label(new_state:int) -> void:
	%StateInfo.text = "State: "+["Idle", "RevealingText", "Animating", "AwaitingChoice", "Waiting"][new_state]
