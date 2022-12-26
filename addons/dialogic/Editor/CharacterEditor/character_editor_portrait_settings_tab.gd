@tool
class_name DialogicCharacterEditorPortraitSettingsTab
extends ScrollContainer

## Base class for all portrait settings tabs. Methods should be overriden.

# Emit this, if something changed
signal changed
signal update_preview

var character_editor:Control 

var selected_item :TreeItem = null

func _load_portrait_data(data:Dictionary) -> void:
	pass
