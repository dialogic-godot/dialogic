tool
extends Control

var plugin_reference
var debug_mode: bool = true # For printing info
var editor_file_dialog # EditorFileDialog
var file_picker_data: Dictionary = {'method': '', 'node': self}
var current_editor_view: String = 'Master'
var working_timeline_file: String = ''
var version_string: String 
onready var timeline_editor = $MainPanel/TimelineEditor
onready var character_editor = $MainPanel/CharacterEditor
onready var glossary_editor = $MainPanel/GlossaryEditor
onready var theme_editor = $MainPanel/ThemeEditor


func _ready():
	# Adding file dialog to get used by pieces
	editor_file_dialog = EditorFileDialog.new()
	add_child(editor_file_dialog)

	# Setting references to this node
	$MainPanel/MasterTree.editor_reference = self
	timeline_editor.editor_reference = self
	character_editor.editor_reference = self
	glossary_editor.editor_reference = self
	theme_editor.editor_reference = self

	# Toolbar
	$ToolBar/NewTimelineButton.connect('pressed', $MainPanel/TimelineEditor, 'new_timeline')
	$ToolBar/NewCharactersButton.connect('pressed', $MainPanel/CharacterEditor, 'new_character')
	$ToolBar/Docs.icon = get_icon("Instance", "EditorIcons")
	$ToolBar/Docs.connect('pressed', OS, "shell_open", ["https://dialogic.coppolaemilio.com"])
	#$ToolBar/FoldTools/ButtonFold.connect('pressed', $EditorTimeline, 'fold_all_nodes')
	#$ToolBar/FoldTools/ButtonUnfold.connect('pressed', $EditorTimeline, 'unfold_all_nodes')
	
	# Loading the version number
	var config = ConfigFile.new()
	var err = config.load("res://addons/dialogic/plugin.cfg")
	if err == OK:
		version_string = config.get_value("plugin", "version", "?")


func _on_TimelinePopupMenu_id_pressed(id):
	if id == 0: # Rename
		pass
	if id == 1: # View files
		OS.shell_open(ProjectSettings.globalize_path(DialogicUtil.get_path('TIMELINE_DIR')))
	if id == 2: # Copy to clipboard
		OS.set_clipboard($MainPanel/TimelineEditor.timeline_name)
	if id == 3: # Remove
		$RemoveTimelineConfirmation.popup_centered()


func _on_CharacterPopupMenu_id_pressed(id):
	if id == 0:
		OS.shell_open(ProjectSettings.globalize_path(DialogicUtil.get_path('CHAR_DIR')))
	if id == 1:
		get_node("RemoveCharacterConfirmation").popup_centered()



func _on_RemoveTimelineConfirmation_confirmed():
	var dir = Directory.new()
	var target = $MainPanel/TimelineEditor.working_timeline_file
	dir.remove(target)
	$MainPanel/MasterTree.remove_selected()


# Godot dialog
func godot_dialog(filter):
	editor_file_dialog.mode = EditorFileDialog.MODE_OPEN_FILE
	editor_file_dialog.clear_filters()
	editor_file_dialog.popup_centered_ratio(0.75)
	editor_file_dialog.add_filter(filter)
	return editor_file_dialog


func godot_dialog_connect(who, method_name):
	var signal_name = "file_selected"
	# Checking if previous connection exists, if it does, disconnect it.
	if editor_file_dialog.is_connected(
		signal_name,
		file_picker_data['node'],
		file_picker_data['method']):
			editor_file_dialog.disconnect(
				signal_name,
				file_picker_data['node'],
				file_picker_data['method']
			)
	# Connect new signal
	editor_file_dialog.connect(signal_name, who, method_name, [who])
	file_picker_data['method'] = method_name
	file_picker_data['node'] = who


func _on_file_selected(path):
	dprint(path)


func _on_Logo_gui_input(event) -> void:
	# I should probably replace this with an "About Dialogic" dialog
	if event is InputEventMouseButton and event.button_index == 1:
		OS.shell_open("https://github.com/coppolaemilio/dialogic")


func dprint(what) -> void:
	if debug_mode:
		print(what)
