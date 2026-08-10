extends PanelContainer

var last_loaded := ""

func _ready() -> void:
	%SaveLoad.button_pressed = owner.settings.get("show_save_load", false)
	%SaveLoadPanel.visible = %SaveLoad.button_pressed

	Dialogic.Save.saved.connect(update_save_list)
	Dialogic.Save.loaded.connect(func(x): last_loaded = x.slot_name)
	Dialogic.Save.loaded.connect(update_save_list)

	update_save_list()


func _on_save_load_toggled(toggled_on: bool) -> void:
	%SaveLoadPanel.visible = toggled_on
	owner.settings["show_save_load"] = toggled_on
	owner.save()


func update_save_list(_ignore="") -> void:
	%SaveList.clear()

	for i in Dialogic.Save.get_slot_names():
		%SaveList.add_item(i)
		if i == last_loaded:
			%SaveList.set_item_custom_fg_color(%SaveList.item_count-1, Color.SKY_BLUE)


func _on_save_list_item_activated(index: int) -> void:
	Dialogic.Save.load(%SaveList.get_item_text(index))


func _on_new_save_pressed() -> void:
	last_loaded = get_new_slot_name()
	Dialogic.Save.save(last_loaded)

	update_save_list()


func get_new_slot_name() -> String:
	var i := 1
	while Dialogic.Save.has_slot("DebugSave"+str(i)):
		i += 1
	return "DebugSave"+str(i)


func _on_save_list_item_clicked(index: int, _at_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_MIDDLE:
		Dialogic.Save.delete_slot(%SaveList.get_item_text(index))
		update_save_list()
