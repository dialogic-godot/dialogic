extends DialogicEditorEventNode

export(NodePath) var TextEdit_path:NodePath

func _on_resource_change() -> void:
	pass


func _on_TextEdit_text_changed() -> void:
	pass # Replace with function body.


func _on_TextEdit_focus_exited() -> void:
	DialogicUtil.Logger.print(self,"Focus lost, saving things")
	var _err = ResourceSaver.save(base_resource.resource_path, base_resource)
	if _err != OK:
		print_debug(DialogicUtil.Error.DIALOGIC_ERROR, " There was an error while saving: ", base_resource.resource_path)
