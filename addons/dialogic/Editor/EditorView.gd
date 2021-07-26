tool
extends Control

var editor_file_dialog # EditorFileDialog
var file_picker_data: Dictionary = {'method': '', 'node': self}
var version_string: String 

# this is set when the plugins main-view is instanced in dialogic.gd
var editor_interface = null

func _ready():
	# Adding file dialog to get used by Events
	editor_file_dialog = EditorFileDialog.new()
	add_child(editor_file_dialog)

	# Setting references to this node
	$MainPanel/TimelineEditor.editor_reference = self
	$MainPanel/CharacterEditor.editor_reference = self
	$MainPanel/ValueEditor.editor_reference = self
	$MainPanel/GlossaryEntryEditor.editor_reference = self
	$MainPanel/ThemeEditor.editor_reference = self
	$MainPanel/DocumentationViewer.editor_reference = self


	$MainPanel/MasterTreeContainer/MasterTree.connect("editor_selected", self, 'on_master_tree_editor_selected')

	# Updating the folder structure
	DialogicUtil.update_resource_folder_structure()
	
	# Sizes
	# This part of the code is a bit terrible. But there is no better way
	# of doing this in Godot at the moment. I'm sorry.
	var separation = get_constant("separation", "BoxContainer")
	$MainPanel.margin_left = separation
	$MainPanel.margin_right = separation * -1
	$MainPanel.margin_bottom = separation * -1
	$MainPanel.margin_top = 38
	var modifier = ''
	var _scale = get_constant("inspector_margin", "Editor")
	_scale = _scale * 0.125
	if _scale == 1:
		$MainPanel.margin_top = 30
	if _scale == 1.25:
		modifier = '-1.25'
		$MainPanel.margin_top = 37
	if _scale == 1.5:
		modifier = '-1.25'
		$MainPanel.margin_top = 46
	if _scale == 1.75:
		modifier = '-1.25'
		$MainPanel.margin_top = 53
	if _scale == 2:
		$MainPanel.margin_top = 59
		modifier = '-2'
	$ToolBar/NewTimelineButton.icon = load("res://addons/dialogic/Images/Toolbar/add-timeline" + modifier + ".svg")
	$ToolBar/NewCharactersButton.icon = load("res://addons/dialogic/Images/Toolbar/add-character" + modifier + ".svg")
	$ToolBar/NewValueButton.icon = load("res://addons/dialogic/Images/Toolbar/add-definition" + modifier + ".svg")
	$ToolBar/NewGlossaryEntryButton.icon = load("res://addons/dialogic/Images/Toolbar/add-glossary" + modifier + ".svg")
	$ToolBar/NewThemeButton.icon = load("res://addons/dialogic/Images/Toolbar/add-theme" + modifier + ".svg")
	
	var modulate_color = Color.white
	if not get_constant("dark_theme", "Editor"):
		modulate_color = get_color("property_color", "Editor")
	$ToolBar/NewTimelineButton.modulate = modulate_color
	$ToolBar/NewCharactersButton.modulate = modulate_color
	$ToolBar/NewValueButton.modulate = modulate_color
	$ToolBar/NewGlossaryEntryButton.modulate = modulate_color
	$ToolBar/NewThemeButton.modulate = modulate_color
	
	$ToolBar/FoldTools/ButtonFold.icon = get_icon("GuiTreeArrowRight", "EditorIcons")
	$ToolBar/FoldTools/ButtonUnfold.icon = get_icon("GuiTreeArrowDown", "EditorIcons")
	# Toolbar
	$ToolBar/NewTimelineButton.connect('pressed', $MainPanel/MasterTreeContainer/MasterTree, 'new_timeline')
	$ToolBar/NewCharactersButton.connect('pressed', $MainPanel/MasterTreeContainer/MasterTree, 'new_character')
	$ToolBar/NewThemeButton.connect('pressed', $MainPanel/MasterTreeContainer/MasterTree, 'new_theme')
	$ToolBar/NewValueButton.connect('pressed', $MainPanel/MasterTreeContainer/MasterTree, 'new_value_definition')
	$ToolBar/NewGlossaryEntryButton.connect('pressed', $MainPanel/MasterTreeContainer/MasterTree, 'new_glossary_entry')
	$ToolBar/Docs.icon = get_icon("Instance", "EditorIcons")
	$ToolBar/Docs.connect('pressed', OS, "shell_open", ["https://dialogic.coppolaemilio.com"])
	$ToolBar/FoldTools/ButtonFold.connect('pressed', $MainPanel/TimelineEditor, 'fold_all_nodes')
	$ToolBar/FoldTools/ButtonUnfold.connect('pressed', $MainPanel/TimelineEditor, 'unfold_all_nodes')
	
	
	#Connecting confirmation
	$RemoveFolderConfirmation.connect('confirmed', self, '_on_RemoveFolderConfirmation_confirmed')

	# Loading the version number
	var config = ConfigFile.new()
	var err = config.load("res://addons/dialogic/plugin.cfg")
	if err == OK:
		version_string = config.get_value("plugin", "version", "?")
		$ToolBar/Version.text = 'Dialogic v' + version_string
		
	$MainPanel/MasterTreeContainer/FilterMasterTreeEdit.right_icon = get_icon("Search", "EditorIcons")


func on_master_tree_editor_selected(editor: String):
	$ToolBar/FoldTools.visible = editor == 'timeline'


func popup_remove_confirmation(what):
	var remove_text = "Are you sure you want to remove this [resource]? \n (Can't be restored)"
	$RemoveConfirmation.dialog_text = remove_text.replace('[resource]', what)
	if $RemoveConfirmation.is_connected( 
		'confirmed', self, '_on_RemoveConfirmation_confirmed'):
				$RemoveConfirmation.disconnect(
					'confirmed', self, '_on_RemoveConfirmation_confirmed')
	$RemoveConfirmation.connect('confirmed', self, '_on_RemoveConfirmation_confirmed', [what])
	$RemoveConfirmation.popup_centered()


func _on_RemoveFolderConfirmation_confirmed():
	var item_path = $MainPanel/MasterTreeContainer/MasterTree.get_item_path($MainPanel/MasterTreeContainer/MasterTree.get_selected())
	DialogicUtil.remove_folder(item_path)
	$MainPanel/MasterTreeContainer/MasterTree.build_full_tree()


func _on_RemoveConfirmation_confirmed(what: String = ''):
	if what == 'Timeline':
		var target = $MainPanel/TimelineEditor.timeline_file
		DialogicResources.delete_timeline(target)
	elif what == 'GlossaryEntry':
		var target = $MainPanel/GlossaryEntryEditor.current_definition['id']
		DialogicResources.delete_default_definition(target)
	elif what == 'Value':
		var target = $MainPanel/ValueEditor.current_definition['id']
		DialogicResources.delete_default_definition(target)
	elif what == 'Theme':
		var filename = $MainPanel/MasterTreeContainer/MasterTree.get_selected().get_metadata(0)['file']
		DialogicResources.delete_theme(filename)
	elif what == 'Character':
		var filename = $MainPanel/CharacterEditor.opened_character_data['id']
		DialogicResources.delete_character(filename)
	DialogicUtil.update_resource_folder_structure()
	$MainPanel/MasterTreeContainer/MasterTree.remove_selected()
	$MainPanel/MasterTreeContainer/MasterTree.hide_all_editors()


# Godot dialog
func godot_dialog(filter, mode = EditorFileDialog.MODE_OPEN_FILE):
	editor_file_dialog.mode = mode
	editor_file_dialog.clear_filters()
	editor_file_dialog.popup_centered_ratio(0.75)
	editor_file_dialog.add_filter(filter)
	return editor_file_dialog


func godot_dialog_connect(who, method_name, signal_name = "file_selected"):
	# You can pass multiple signal_name using an array
	
	# Checking if previous connections exist, if they do, disconnect them.
	for test_signal in editor_file_dialog.get_signal_list():
		if editor_file_dialog.is_connected(
			test_signal.name,
			file_picker_data['node'],
			file_picker_data['method']
		):
				editor_file_dialog.disconnect(
					test_signal.name,
					file_picker_data['node'],
					file_picker_data['method']
				)
	
	# Connect new signals
	for new_signal_name in signal_name if typeof(signal_name) == TYPE_ARRAY else [signal_name]:
		editor_file_dialog.connect(new_signal_name, who, method_name, [who])
	
	file_picker_data['method'] = method_name
	file_picker_data['node'] = who
