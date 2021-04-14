tool
class_name DialogicCharacterJoinEvent
extends DialogicEventResource

# DialogicCharacterResource
export(Resource) var character = null
export(int) var selected_portrait = 0
# Refer to DialogicPortraitManager.Position
export(int) var selected_position = 0
export(bool) var skip = true

var _PortraitManager: DialogicPortraitManager

func excecute(caller:DialogicNode) -> void:
	# Parent function must be called at the start
	.excecute(caller)

	if not character:
		finish()
		return
	
	_caller = caller
	_caller.visible = true
	_PortraitManager = (caller.PortraitManager as DialogicPortraitManager)
	
	if not _PortraitManager:
		finish()
		return
	
	_PortraitManager.visible = true
	_PortraitManager.connect("portrait_added", self, "_on_portrait_added", [], CONNECT_ONESHOT)
	
	var _character_portraits:Array = character.portraits.get_resources()
	var _portrait = _character_portraits[selected_portrait]
	
	_PortraitManager.add_portrait(character, _portrait, selected_position)


func _on_portrait_added()->void:
	finish(skip)


# Returns DialogicEditorEventNode to be used inside the editor.
func get_event_editor_node() -> DialogicEditorEventNode:
	var _scene_resource:PackedScene = load("res://addons/dialogic/Nodes/editor_event_nodes/character_event/join_event_node/join_event_node.tscn")
	_scene_resource.resource_local_to_scene = true
	var _instance = _scene_resource.instance(PackedScene.GEN_EDIT_STATE_INSTANCE)
	_instance.base_resource = self
	return _instance
