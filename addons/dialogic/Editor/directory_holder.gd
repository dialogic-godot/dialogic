@tool
extends Node

## Node that holds timeline and character directories for use in editor.

# barebones instance of DGH, with local Editor references to the event cache and charcater directory
#var dialogic_handler: Node
#
#var event_script_cache: Array[DialogicEvent] = []
#var label_directory :Dictionary = {}:
	#set(value):
		#label_directory = value
		#Engine.get_main_loop().set_meta("dialogic_label_directory", value)
#

#
#func _ready() -> void:
	#if owner.get_parent() is SubViewport:
		#return
#
	### DIRECTORIES SETUP
	##initialize DGH, and set the local variables to references of the DGH ones
	##since we're not actually adding it to the event node, we have to manually run the commands to build the cache's
	#dialogic_handler = load("res://addons/dialogic/Other/DialogicGameHandler.gd").new()
	##rebuild_character_directory()
	##rebuild_timeline_directory()
	#rebuild_event_script_cache()
	#label_directory = DialogicUtil.get_editor_setting('label_ref', {})
	#for i in label_directory:
		#if !i in DialogicResourceUtil.get_timeline_directory():
			#label_directory.erase(i)
#
	#find_parent('EditorView').plugin_reference.get_editor_interface().get_file_system_dock().files_moved.connect(_on_file_moved)


func _on_file_moved(old_name:String, new_name:String) -> void:
	if old_name.ends_with('.dch'):
		DialogicResourceUtil.update_directory('dch')
	elif old_name.ends_with('.dtl'):
		DialogicResourceUtil.update_directory('dtl')


#
#func rebuild_character_directory() -> void:
	#character_directory = {}
	#if dialogic_handler != null:
		#dialogic_handler.rebuild_character_directory()
		#character_directory = dialogic_handler.character_directory
#
#
#func get_character_short_path(resource:DialogicCharacter) -> String:
	#for chr in character_directory.values():
		#if chr.resource == resource:
			#return chr.unique_short_path
	#return resource.resource_path.get_file().trim_suffix(resource.resource_path.get_extension())
#
#
#func rebuild_timeline_directory() -> void:
	#timeline_directory = {}
	#if dialogic_handler != null:
		#dialogic_handler.rebuild_timeline_directory()
		#timeline_directory = dialogic_handler.timeline_directory
##
#
#func get_event_scripts() -> Array:
	#if event_script_cache.size() > 0:
		#return event_script_cache
	#else:
		#return rebuild_event_script_cache()
