extends VBoxContainer

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

var _current_view:Dictionary = {
	"state":EditorView.DEFAULT,
	"reference":null
	} setget _set_current_view

onready var settings_view_node:Control = get_node_or_null(SettingsView_path)
onready var default_view_node:Control = get_node_or_null(DefaultView_path)
onready var blank_view_node:Control = get_node_or_null(BlankView_path)
onready var timeline_view_node:Control = get_node_or_null(TimelineView_path)
onready var character_view_node:Control = get_node_or_null(CharacterView_path)
onready var definition_view_node:Control = get_node_or_null(DefinitionView_path)
onready var theme_view_node:Control = get_node_or_null(ThemeView_path)

func _ready() -> void:
	self._current_view = {"state":EditorView.DEFAULT, "reference":default_view_node}


func _hide_all_views_except(who):
	var view_nodes = [
		blank_view_node, 
		default_view_node, 
		settings_view_node, 
		timeline_view_node,
		character_view_node,
		]
	
	for view_node in view_nodes:
		if view_node == who:
			view_node.visible = true
			continue
		view_node.visible = false
	

func _set_current_view(view:Dictionary):
	_current_view["state"] = view.get("state", EditorView.BLANK)
	_current_view["reference"] = view.get("reference", blank_view_node)
	
	
	match _current_view["state"]:
		
		EditorView.SETTINGS:
			blank_view_node.visible = false
			default_view_node.visible = false
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
