@tool
extends Node

## Node that holds timeline and character directories for use in editor.


# barebones instance of DGH, with local Editor references to the event cache and charcater directory
var dialogic_handler: Node 

var event_script_cache: Array[DialogicEvent] = []
var character_directory: Dictionary = {}
var timeline_directory: Dictionary = {}


func _ready():
	## DIRECTORIES SETUP
	#initialize DGH, and set the local variables to references of the DGH ones
	#since we're not actually adding it to the event node, we have to manually run the commands to build the cache's
	dialogic_handler = load("res://addons/dialogic/Other/DialogicGameHandler.gd").new()
	rebuild_character_directory()
	rebuild_timeline_directory()
	rebuild_event_script_cache()


func rebuild_event_script_cache():
	event_script_cache = []
	if dialogic_handler != null:
		dialogic_handler.collect_subsystems()
		event_script_cache = dialogic_handler._event_script_cache
	else:
		for indexer in DialogicUtil.get_indexers():
			# build event cache
			for event in indexer._get_events():
				if not 'event_end_branch.gd' in event and not 'event_text.gd' in event:
					event_script_cache.append(load(event).new())
			
		# Events are checked in order while testing them. EndBranch needs to be first, Text needs to be last
		event_script_cache.push_front(DialogicEndBranchEvent.new())
		event_script_cache.push_back(DialogicTextEvent.new())
	
	return event_script_cache


func rebuild_character_directory() -> void:
	character_directory = {}
	if dialogic_handler != null:		
		dialogic_handler.rebuild_character_directory()	
		character_directory = dialogic_handler.character_directory
		Engine.set_meta("dialogic_character_directory", character_directory)


func rebuild_timeline_directory() -> void:
	timeline_directory = {}
	if dialogic_handler != null:		
		dialogic_handler.rebuild_timeline_directory()	
		timeline_directory = dialogic_handler.timeline_directory
		Engine.set_meta("dialogic_timeline_directory", timeline_directory)


func get_event_scripts() -> Array:
	if event_script_cache.size() > 0:
		return event_script_cache
	else:
		return rebuild_event_script_cache()


func process_timeline(timeline: DialogicTimeline) -> DialogicTimeline:
	return dialogic_handler.process_timeline(timeline)

