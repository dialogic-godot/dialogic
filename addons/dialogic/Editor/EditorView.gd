tool
extends Control

var plugin_reference
var debug_mode: bool = true # For printing info
var editor_file_dialog # EditorFileDialog
var file_picker_data: Dictionary = {'method': '', 'node': self}
var current_editor_view: String = 'Master'
var version_string: String 
onready var timeline_editor = $MainPanel/TimelineEditor
onready var character_editor = $MainPanel/CharacterEditor
onready var definition_editor = $MainPanel/DefinitionEditor
onready var theme_editor = $MainPanel/ThemeEditor
onready var settings_editor = $MainPanel/SettingsEditor


func _ready():
	# Adding file dialog to get used by pieces
	editor_file_dialog = EditorFileDialog.new()
	add_child(editor_file_dialog)

	# Setting references to this node
	timeline_editor.editor_reference = self
	character_editor.editor_reference = self
	definition_editor.editor_reference = self
	theme_editor.editor_reference = self

	# Toolbar
	$ToolBar/NewTimelineButton.connect('pressed', $MainPanel/TimelineEditor, 'new_timeline')
	$ToolBar/NewCharactersButton.connect('pressed', $MainPanel/CharacterEditor, 'new_character')
	$ToolBar/NewThemeButton.connect('pressed', $MainPanel/ThemeEditor, 'new_theme')
	$ToolBar/NewDefinitionButton.connect('pressed', $MainPanel/DefinitionEditor, 'new_definition')
	$ToolBar/Docs.icon = get_icon("Instance", "EditorIcons")
	$ToolBar/Docs.connect('pressed', OS, "shell_open", ["https://dialogic.coppolaemilio.com"])
	#$ToolBar/FoldTools/ButtonFold.connect('pressed', $EditorTimeline, 'fold_all_nodes')
	#$ToolBar/FoldTools/ButtonUnfold.connect('pressed', $EditorTimeline, 'unfold_all_nodes')
	
	
	# Connecting context menus
	$TimelinePopupMenu.connect('id_pressed', self, '_on_TimelinePopupMenu_id_pressed')
	$CharacterPopupMenu.connect('id_pressed', self, '_on_CharacterPopupMenu_id_pressed')
	$ThemePopupMenu.connect('id_pressed', self, '_on_ThemePopupMenu_id_pressed')
	$DefinitionPopupMenu.connect('id_pressed', self, '_on_DefinitionPopupMenu_id_pressed')
	
	#Connecting confirmation menus
	$RemoveTimelineConfirmation.connect('confirmed', self, '_on_RemoveTimelineConfirmation_confirmed')
	$RemoveCharacterConfirmation.connect('confirmed', self, '_on_RemoveCharacterConfirmation_confirmed')
	$RemoveThemeConfirmation.connect('confirmed', self, '_on_RemoveThemeConfirmation_confirmed')
	$RemoveDefinitionConfirmation.connect('confirmed', self, '_on_RemoveDefinitionConfirmation_confirmed')
	
	# Loading the version number
	var config = ConfigFile.new()
	var err = config.load("res://addons/dialogic/plugin.cfg")
	if err == OK:
		version_string = config.get_value("plugin", "version", "?")
		$ToolBar/Version.text = 'v' + version_string


# Timeline context menu
func _on_TimelinePopupMenu_id_pressed(id):
	if id == 0: # View files
		OS.shell_open(ProjectSettings.globalize_path(DialogicUtil.get_path('TIMELINE_DIR')))
	if id == 1: # Copy to clipboard
		OS.set_clipboard($MainPanel/TimelineEditor.timeline_name)
	if id == 2: # Remove
		$RemoveTimelineConfirmation.popup_centered()


func _on_RemoveTimelineConfirmation_confirmed():
	var dir = Directory.new()
	var target = $MainPanel/TimelineEditor.working_timeline_file
	print('target: ', target)
	dir.remove(target)
	$MainPanel/MasterTree.remove_selected()
	$MainPanel/MasterTree.hide_all_editors(true)


# Character context menu
func _on_CharacterPopupMenu_id_pressed(id):
	if id == 0:
		OS.shell_open(ProjectSettings.globalize_path(DialogicUtil.get_path('CHAR_DIR')))
	if id == 1:
		$RemoveCharacterConfirmation.popup_centered()


# Theme context menu
func _on_ThemePopupMenu_id_pressed(id):
	if id == 0:
		OS.shell_open(ProjectSettings.globalize_path(DialogicUtil.get_path('THEME_DIR')))
	if id == 1:
		$RemoveThemeConfirmation.popup_centered()


# Definition context menu
func _on_DefinitionPopupMenu_id_pressed(id):
	if id == 0:
		OS.shell_open(ProjectSettings.globalize_path(DialogicUtil.get_path('DEFINITIONS_FILE')))
	if id == 1:
		$RemoveDefinitionConfirmation.popup_centered()


func _on_RemoveDefinitionConfirmation_confirmed():
	var target = $MainPanel/DefinitionEditor.current_section
	var config = ConfigFile.new()
	var err = config.load(DialogicUtil.get_path('DEFINITIONS_FILE'))
	if err == OK:
		config.erase_section(target)
		config.save(DialogicUtil.get_path('DEFINITIONS_FILE'))
		$MainPanel/MasterTree.remove_selected()
		$MainPanel/MasterTree.hide_all_editors(true)
	else:
		print('Error loading definitions')


func _on_RemoveCharacterConfirmation_confirmed():
	var dir = Directory.new()
	print($MainPanel/CharacterEditor.opened_character_data)
	var target = DialogicUtil.get_path('CHAR_DIR', $MainPanel/CharacterEditor.opened_character_data['id']) 
	dir.remove(target)
	$MainPanel/MasterTree.remove_selected()
	$MainPanel/MasterTree.hide_all_editors(true)


func _on_RemoveThemeConfirmation_confirmed():
	var dir = Directory.new()
	var filepath = $MainPanel/MasterTree.get_selected().get_metadata(0)['file']
	var target = DialogicUtil.get_path('THEME_DIR', filepath) 
	dir.remove(target)
	$MainPanel/MasterTree.remove_selected()
	$MainPanel/MasterTree.hide_all_editors(true)


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
