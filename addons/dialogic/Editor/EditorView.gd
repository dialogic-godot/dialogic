tool
extends VBoxContainer

const DialogicUtil = preload("res://addons/dialogic/Core/DialogicUtil.gd")
const DialogicDB = preload("res://addons/dialogic/Core/DialogicDatabase.gd")

enum EditorView {
	BLANK=-1, 
	DEFAULT, 
	SETTINGS, 
	TIMELINE, 
	CHARACTER, 
	DEFINITION,
	THEME,
	}

export(NodePath) var SettingsView_path:NodePath
export(NodePath) var DefaultView_path:NodePath
export(NodePath) var BlankView_path:NodePath
export(NodePath) var TimelineView_path:NodePath
export(NodePath) var CharacterView_path:NodePath
export(NodePath) var DefinitionView_path:NodePath
export(NodePath) var ThemeView_path:NodePath

export(NodePath) var TimelineContainer_path:NodePath
export(NodePath) var CharacterContainer_path:NodePath
export(NodePath) var DefinitionContainer_path:NodePath
export(NodePath) var ThemeContainer_path:NodePath

export(NodePath) var NewTimelinePopup_path:NodePath
export(NodePath) var NewCharacterPopup_path:NodePath

var _current_view:Dictionary = {
	"state":EditorView.DEFAULT,
	"reference":null
	} setget _set_current_view

onready var settings_view_node := get_node_or_null(SettingsView_path)
onready var default_view_node := get_node_or_null(DefaultView_path)
onready var blank_view_node := get_node_or_null(BlankView_path)
onready var timeline_view_node := get_node_or_null(TimelineView_path)
onready var character_view_node := get_node_or_null(CharacterView_path)
onready var definition_view_node := get_node_or_null(DefinitionView_path)
onready var theme_view_node := get_node_or_null(ThemeView_path)

onready var timeline_container_node := get_node_or_null(TimelineContainer_path)
onready var character_container_node := get_node_or_null(CharacterContainer_path)
onready var definition_container_node := get_node_or_null(DefinitionContainer_path)
onready var theme_container_node := get_node_or_null(ThemeContainer_path)

onready var timeline_popup_node := get_node_or_null(NewTimelinePopup_path)
onready var character_popup_node := get_node_or_null(NewCharacterPopup_path)

func _ready() -> void:
	self._current_view = {"state":EditorView.DEFAULT, "reference":default_view_node}
	timeline_container_node.tree_resource = DialogicDB.Timelines.get_database()
	character_container_node.tree_resource = DialogicDB.Characters.get_database()

func _hide_all_views_except(who) -> void:
	var view_nodes = [
		blank_view_node, 
		default_view_node, 
		settings_view_node, 
		timeline_view_node,
		character_view_node,
		theme_view_node,
		]
	
	for view_node in view_nodes:
		if view_node == who:
			view_node.visible = true
			continue
		view_node.visible = false
	

func _set_current_view(view:Dictionary):
	_current_view["state"] = view.get("state", EditorView.BLANK)
	_current_view["reference"] = view.get("reference", blank_view_node)
	DialogicUtil.Logger.print(self,["Changing view to:", _current_view["reference"].name])
	
	
	match _current_view["state"]:
		
		EditorView.SETTINGS:
			blank_view_node.visible = false
			default_view_node.visible = false
			timeline_view_node.visible = false
			character_view_node.visible = false
			theme_view_node.visible = false
			if settings_view_node.visible:
				_current_view["state"] = EditorView.DEFAULT
				_current_view["reference"] = default_view_node
				_set_current_view(_current_view)
			else:
				settings_view_node.visible = true
		
		var _anything_else:
			_hide_all_views_except(_current_view["reference"])


func _on_SettingsButton_pressed() -> void:
	self._current_view = {"state":EditorView.SETTINGS, "reference":settings_view_node}


func _on_NewTimelineButton_pressed() -> void:
	self._current_view = {}
	(timeline_popup_node as ConfirmationDialog).popup_centered_minsize()
	timeline_container_node.tree_resource = DialogicDB.Timelines.get_database()
	timeline_container_node.force_update()


func _on_NewTimelinePopup_confirmed() -> void:
	var _name = timeline_popup_node.text_node.text
	DialogicDB.Timelines.add(_name)


func _on_NewCharacterButton_pressed() -> void:
	self._current_view = {}
	(character_popup_node as ConfirmationDialog).popup_centered_minsize()


func _on_NewCharacterPopup_confirmed() -> void:
	DialogicUtil.Logger.print(self,["NewCharacter: ", character_popup_node.text_node.text])


func _on_TimelinesContainer_tree_item_selected(tree_item:TreeItem) -> void:
	var _res_path = tree_item.get_metadata(0)
	DialogicUtil.Logger.print(self,["Using resource:", _res_path])
	timeline_view_node.base_resource_path = _res_path
	self._current_view = {"state":EditorView.TIMELINE, "reference":timeline_view_node}
