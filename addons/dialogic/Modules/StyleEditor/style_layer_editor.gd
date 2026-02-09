@tool
extends HSplitContainer

## Script that handles the style editor.


var current_style: DialogicStyle = null
## The id of the currently selected layer.
## "" is the base scene.
var current_layer_id := ""


func load_style(style:DialogicStyle) -> void:
	current_style = style
	current_layer_id = DialogicUtil.get_editor_setting("style_editor/"+current_style.name+"/latest_layer", "")

	%LayerList.load_style_layer_list(current_style)


func load_layer(layer_id:=""):
	current_layer_id = layer_id
	#print(current_style.get_layer_info(layer_id))
	%LayerView.open_layer(current_style, layer_id)
	%DeleteLayerButton.disabled = layer_id == "" or current_style.inherits_anything()


func _on_layer_list_layer_selected(layer_id: String) -> void:
	load_layer(layer_id)


func edit_layer_scene(scene_path:String) -> void:
	if ResourceLoader.exists(scene_path):
		EditorInterface.open_scene_from_path(scene_path)
		await get_tree().process_frame
		EditorInterface.set_main_screen_editor("2D")
