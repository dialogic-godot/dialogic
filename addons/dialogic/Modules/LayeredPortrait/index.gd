@tool
extends DialogicIndexer


func _get_portrait_scene_presets() -> Array[Dictionary]:
	return [
		{
			"path": this_folder.path_join("layered_portrait.tscn"),
			"name": "Layered Portrait",
			"description": "Base for a charcter made up of multiple sprites. Allows showing/switching/hiding the layers with the character event extra data.",
			"author":"Cake for Dialogic",
			"type": "Preset",
			"icon":"",
			"preview_image":[this_folder.path_join("layered_portrait_thumbnail.png")],
			"documentation":"https://docs.dialogic.pro/layered-portraits.html",
		},
	]
