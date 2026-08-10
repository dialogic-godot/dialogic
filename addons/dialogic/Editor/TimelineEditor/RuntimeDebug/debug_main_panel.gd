extends PanelContainer


func _ready() -> void:
	%PortraitContainers.button_pressed = owner.settings.get("portrait_container_debug", false)

	Dialogic.event_handled.connect(_update_timeline_info_label)
	Dialogic.state_changed.connect(_update_state_label)



func _update_timeline_info_label(_ignore="") -> void:
	if Dialogic.current_timeline == null:
		%TimelineInfo.text = "Timeline: < No Timeline >"
	else:
		%TimelineInfo.text = "Timeline: "+Dialogic.current_timeline.get_identifier()
		%TimelineInfo.text += "\nEvent "+str(Dialogic.current_event_idx)+": "+Dialogic.current_timeline_events[Dialogic.current_event_idx].event_name


func _update_state_label(new_state:int) -> void:
	%StateInfo.text = "State: "+["Idle", "RevealingText", "Animating", "AwaitingChoice", "Waiting"][new_state]


func _on_portrait_containers_toggled(toggled_on: bool) -> void:
	Dialogic.PortraitContainers.debug_draw = toggled_on
	owner.settings["portrait_container_debug"] = toggled_on
	owner.save()
