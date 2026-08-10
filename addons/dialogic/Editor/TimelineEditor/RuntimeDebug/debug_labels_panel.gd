extends PanelContainer


var last_label := ""

func _ready() -> void:
	%InspectLabels.button_pressed = owner.settings.get("show_labels", false)
	%LabelsPanel.visible = %InspectLabels.button_pressed

	Dialogic.Jump.passed_label.connect(func(x):last_label = x.identifier)
	Dialogic.Jump.passed_label.connect(update_label_list)
	Dialogic.timeline_started.connect(update_label_list)
	Dialogic.timeline_ended.connect(update_label_list)
	Dialogic.Jump.jumped_to_label.connect(update_label_list)
	Dialogic.Jump.switched_timeline.connect(update_label_list)

	update_label_list()


func _on_inspect_labels_toggled(toggled_on: bool) -> void:
	%LabelsPanel.visible = toggled_on
	owner.settings["show_labels"] = toggled_on
	owner.save()


func update_label_list(_ignore="") -> void:
	%LabelList.clear()

	if not Dialogic.current_timeline:
		%LabelInfo.show()
		%LabelInfo.text = "No timeline active."
		%LabelList.hide()

	var idx := 0
	for ev in Dialogic.current_timeline_events:
		if ev is DialogicLabelEvent:
			%LabelList.add_item(ev.name + " ("+str(idx)+")")
			%LabelList.set_item_metadata(%LabelList.item_count-1, ev.name)
			if ev.name == last_label:
				%LabelList.set_item_custom_fg_color(%LabelList.item_count-1, Color.SKY_BLUE)
		idx += 1

	if %LabelList.item_count:
		%LabelList.show()
		%LabelInfo.hide()
	else:
		%LabelList.hide()
		%LabelInfo.show()
		%LabelInfo.text = "No labels in timeline."


func _on_label_list_item_activated(index: int) -> void:
	Dialogic.Jump.jump_to_label(%LabelList.get_item_metadata(index))
	Dialogic.handle_next_event()
