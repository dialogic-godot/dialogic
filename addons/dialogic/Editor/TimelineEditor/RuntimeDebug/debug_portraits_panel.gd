extends PanelContainer


func _ready() -> void:
	%InspectPortraits.button_pressed = owner.settings.get("inspect_portraits", false)
	%PortraitsPanel.visible = %InspectPortraits.button_pressed
	build_portraits_tree()

	Dialogic.Portraits.character_portrait_changed.connect(func(_x): build_portraits_tree())
	Dialogic.Portraits.character_joined.connect(func(_x): build_portraits_tree())
	Dialogic.Portraits.character_left.connect(func(_x): build_portraits_tree())
	Dialogic.Portraits.character_moved.connect(func(_x): build_portraits_tree())
	Dialogic.Text.speaker_updated.connect(func(_x): build_portraits_tree.call_deferred())


func _on_inspect_portraits_toggled(toggled_on: bool) -> void:
	%PortraitsPanel.visible = toggled_on
	build_portraits_tree()
	owner.settings["inspect_portraits"] = toggled_on
	owner.save()


func _on_portrait_containers_toggled(toggled_on: bool) -> void:
	Dialogic.PortraitContainers.debug_draw = toggled_on
	owner.settings["portrait_container_debug"] = toggled_on
	owner.save()


func build_portraits_tree() -> void:
	%PortraitsTree.clear()
	if not %PortraitsTree.is_visible_in_tree():
		return
	var root: TreeItem = %PortraitsTree.create_item()
	var columns := ["character", "portrait", "position_id", "mirrored", "z-index", "joined"]
	%PortraitsTree.columns = columns.size()
	for i in range(columns.size()):
		%PortraitsTree.set_column_title(i, columns[i])
	for i in Dialogic.Portraits.portraits:
		var info: Dictionary = Dialogic.Portraits.portraits[i]
		var item: TreeItem = %PortraitsTree.create_item(root)
		item.set_text(0, i)
		for j in range(1, columns.size()):
			item.set_text(j, str(info.get(columns[j], "")))
