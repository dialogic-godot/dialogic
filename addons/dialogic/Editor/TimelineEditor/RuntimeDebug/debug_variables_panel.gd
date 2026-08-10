extends PanelContainer


var recent := []
var building = false


func _ready() -> void:
	%InspectVariables.button_pressed = owner.settings.get("inspect_variables", false)
	%VariablesPanel.visible = %InspectVariables.button_pressed

	Dialogic.VAR.variable_changed.connect(_on_variable_changed)

	build_variable_list()


func _on_inspect_variables_toggled(toggled_on: bool) -> void:
	%VariablesPanel.visible = toggled_on
	owner.settings["inspect_variables"] = toggled_on
	owner.save()


func _on_variable_changed(info:Dictionary) -> void:
	if info.variable in recent:
		recent.erase(info.variable)
	recent.append(info.variable)
	update_branch(%VariablesTree.get_root())


func build_variable_list(_ignore="") -> void:
	building = true
	var folded_items: Array = owner.settings.get("folded_variable_folders", [])
	%VariablesTree.clear()
	%VariablesTree.create_item()

	for i:String in Dialogic.VAR.variables():
		build_variable_item(%VariablesTree.get_root(), i, i)

	for i:Dialogic.VARSubsystem.VariableFolder in Dialogic.VAR.folders():
		build_variable_tree_branch(%VariablesTree.get_root(), i, folded_items)
	building = false


func build_variable_tree_branch(parent_item:TreeItem, variable_folder:Dialogic.VARSubsystem.VariableFolder, folded_items:Array) -> TreeItem:
	var item: TreeItem = %VariablesTree.create_item(parent_item)
	item.set_text(0, variable_folder.path)
	for i:String in variable_folder.variables():
		build_variable_item(item, i, variable_folder.path+"."+i)
	for i:Dialogic.VARSubsystem.VariableFolder in variable_folder.folders():
		build_variable_tree_branch(item, i, folded_items)
	if variable_folder.path in folded_items:
		item.collapsed = true
	item.set_metadata(0, variable_folder)
	return item


func build_variable_item(parent_item:TreeItem, variable_name:String, path:String) -> TreeItem:
	var item: TreeItem = %VariablesTree.create_item(parent_item)
	item.set_text(0, variable_name)
	item.set_text(1, str(Dialogic.VAR.get_variable(path)))
	item.set_metadata(1, path)
	return item


func get_folded_items(item:TreeItem) -> Array:
	var array := []
	for child:TreeItem in item.get_children():
		if child.collapsed:
			array.append(child.get_metadata(0).path)
		array.append_array(get_folded_items(child))
	return array


func update_branch(item:TreeItem) -> void:
	for i in item.get_children():
		if typeof(i.get_metadata(1)) == TYPE_STRING:
			var path: String = i.get_metadata(1)
			i.set_text(1, str(Dialogic.VAR.get_variable(path)))
			if path in recent:
				i.set_custom_bg_color(1, Color.DARK_GREEN.lerp(Color.WEB_PURPLE, (recent.find(path)+1)/float(recent.size())))
				if recent.find(path) == recent.size()-1:
					var tw := create_tween()
					tw.tween_method(func(x): i.set_custom_bg_color(1, x), i.get_custom_bg_color(1), Color.HOT_PINK, 0.1)
					tw.tween_method(func(x): i.set_custom_bg_color(1, x), Color.HOT_PINK, Color.WEB_PURPLE, 0.2)
					%VariablesTree.scroll_to_item(i)
		else:
			update_branch(i)

func _on_variables_tree_item_collapsed(_item: TreeItem) -> void:
	if building:
		return

	owner.settings["folded_variable_folders"] = get_folded_items(%VariablesTree.get_root())
	owner.save()
