@tool
extends HBoxContainer

## Settings tab that holds genreal dialogic settings.

signal colors_changed

var color_palette :Dictionary = {}


func _ready() -> void:
	var s := DCSS.inline({
		'padding': 5,
		'background': Color(0.545098, 0.545098, 0.545098, 0.211765)
	})
	%ExtensionsFolderPicker.resource_icon = get_theme_icon("Folder", "EditorIcons")

	# Signals
	%ExtensionsFolderPicker.value_changed.connect(_on_ExtensionsFolder_value_changed)
	%PhysicsTimerButton.pressed.connect(_on_physics_timer_button_toggled)

	# Colors
	%ResetColorsButton.button_up.connect(_on_reset_colors_button)

	for n in %Colors.get_children():
		n.color_changed.connect(_on_color_change.bind(n))

	# Extension creator
	%ExtensionCreator.hide()


func refresh() -> void:
	%PhysicsTimerButton.button_pressed = DialogicUtil.is_physics_timer()
	%LayoutNodeEndBehaviour.select(ProjectSettings.get_setting('dialogic/layout/end_behaviour', 0))
	%ExtensionsFolderPicker.set_value(ProjectSettings.get_setting('dialogic/extensions_folder', 'res://addons/dialogic_additions'))
	
	# Color Palette
	color_palette = DialogicUtil.get_color_palette()
	var _scale := DialogicUtil.get_editor_scale()
	for n in %Colors.get_children():
		n.custom_minimum_size = Vector2(50 ,50)*scale
		n.color = color_palette[n.name]
	
	%SectionList.clear()
	%SectionList.create_item()
	var cached_events :Array[DialogicEvent] = get_parent().get_parent().editors_manager.resource_helper.event_script_cache
	var sections := []
	var section_order :Array = DialogicUtil.get_editor_setting('event_section_order', ['Main', 'Logic', 'Timeline', 'Audio', 'Godot','Other', 'Helper'])
	for ev in cached_events:
		if !ev.event_category in sections:
			sections.append(ev.event_category)
			var item :TreeItem = %SectionList.create_item(null)
			item.set_text(0, ev.event_category)
			item.add_button(0, get_theme_icon("ArrowUp", "EditorIcons"))
			item.add_button(0, get_theme_icon("ArrowDown", "EditorIcons"))
			if ev.event_category in section_order:
				
				item.move_before(item.get_parent().get_child(min(section_order.find(ev.event_category),item.get_parent().get_child_count()-1)))
	
	%SectionList.get_root().get_child(0).set_button_disabled(0, 0, true)
	%SectionList.get_root().get_child(-1).set_button_disabled(0, 1, true)


func _on_section_list_button_clicked(item:TreeItem, column, id, mouse_button_index):
	if id == 0:
		item.move_before(item.get_parent().get_child(item.get_index()-1))
	else:
		item.move_after(item.get_parent().get_child(item.get_index()+1))
	for child in %SectionList.get_root().get_children():
		child.set_button_disabled(0, 0, false)
		child.set_button_disabled(0, 1, false)
	
	%SectionList.get_root().get_child(0).set_button_disabled(0, 0, true)
	%SectionList.get_root().get_child(-1).set_button_disabled(0, 1, true)
	
	var sections := []
	for child in %SectionList.get_root().get_children():
		sections.append(child.get_text(0))
	
	DialogicUtil.set_editor_setting('event_section_order', sections)
	force_event_button_list_reload()


func force_event_button_list_reload() -> void:
	find_parent('EditorsManager').editors['Timeline Editor'].node.get_node('VisualEditor').load_event_buttons()


func _on_color_change(color: Color, who) -> void:
	ProjectSettings.set_setting('dialogic/editor/' + str(who.name), color)
	ProjectSettings.save()
	emit_signal('colors_changed')


func _on_reset_colors_button() -> void:
	color_palette = DialogicUtil.get_color_palette(true)
	for n in %Colors.get_children():
		n.color = color_palette[n.name]
		# There is a bug when trying to remove existing values, so we have to
		# set/create new entries for all the colors used.
		# If you manage to make it work using the ProjectSettings.clear()
		# feel free to open a PR!
		ProjectSettings.set_setting('dialogic/editor/' + str(n.name), color_palette[n.name])
	ProjectSettings.save()
	emit_signal('colors_changed')


func _on_physics_timer_button_toggled(button_pressed:bool) -> void:
	ProjectSettings.set_setting('dialogic/timer/process_in_physics', button_pressed)
	ProjectSettings.save()


func _on_ExtensionsFolder_value_changed(property:String, value:String) -> void:
	if value == null or value.is_empty():
		value = 'res://addons/dialogic_additions'
	ProjectSettings.set_setting('dialogic/extensions_folder', value)
	ProjectSettings.save()


func _on_layout_node_end_behaviour_item_selected(index:int) -> void:
	ProjectSettings.set_setting('dialogic/layout/end_behaviour', index)
	ProjectSettings.save()


################################################################################
## 					EXTENSION CREATOR
################################################################################

func _on_create_extension_button_pressed() -> void:
	%CreateExtensionButton.hide()
	%ExtensionCreator.show()

	%NameEdit.text = ""
	%NameEdit.grab_focus()


func _on_submit_extension_button_pressed() -> void:
	if %NameEdit.text.is_empty():
		return

	var extensions_folder :String = ProjectSettings.get_setting('dialogic/extensions_folder', 'res://addons/dialogic_additions')

	extensions_folder = extensions_folder.path_join(%NameEdit.text.to_pascal_case())
	DirAccess.make_dir_recursive_absolute(extensions_folder)
	var mode :int= %ExtensionMode.selected

	var file : FileAccess
	var indexer_content := "@tool\nextends DialogicIndexer\n\n"
	if mode != 1: # don't add event in Subsystem Only mode
		indexer_content += """func _get_events() -> Array:
	return [this_folder.path_join('event_"""+%NameEdit.text.to_snake_case()+""".gd')]\n\n"""
		file = FileAccess.open(extensions_folder.path_join('event_'+%NameEdit.text.to_snake_case()+'.gd'), FileAccess.WRITE)
		file.store_string(
"""@tool
extends DialogicEvent
class_name Dialogic"""+%NameEdit.text.to_pascal_case()+"""Event

# Define properties of the event here

func _execute() -> void:
	# This will execute when the event is reached
	finish() # called to continue with the next event


################################################################################
## 						INITIALIZE
################################################################################

# Set fixed settings of this event
func _init() -> void:
	event_name = \""""+%NameEdit.text.capitalize()+"""\"
	event_category = "Other"

\n
################################################################################
## 						SAVING/LOADING
################################################################################
func get_shortcode() -> String:
	return \""""+%NameEdit.text.to_snake_case()+"""\"

func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name 	: property_info
		#"my_parameter"		: {"property": "property", "default": "Default"},
	}

# You can alternatively overwrite these 3 functions: to_text(), from_text(), is_valid_event()

################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor() -> void:
	pass""")

	if mode != 0: # don't add subsystem in event only mode
		indexer_content += """func _get_subsystems() -> Array:
	return [{'name':'"""+%NameEdit.text.to_pascal_case()+"""', 'script':this_folder.path_join('subsystem_"""+%NameEdit.text.to_snake_case()+""".gd')}]"""
		file = FileAccess.open(extensions_folder.path_join('subsystem_'+%NameEdit.text.to_snake_case()+'.gd'), FileAccess.WRITE)
		file.store_string(
"""extends DialogicSubsystem

## Describe the subsystems purpose here.


####################################################################################################
##					STATE
####################################################################################################

func clear_game_state(clear_flag:=Dialogic.ClearFlags.FullClear):
	pass

func load_game_state():
	pass


####################################################################################################
##					MAIN METHODS
####################################################################################################

# Add some useful methods here.

""")
	file = FileAccess.open(extensions_folder.path_join('index.gd'), FileAccess.WRITE)
	file.store_string(indexer_content)

	%ExtensionCreator.hide()
	%CreateExtensionButton.show()

	find_parent('EditorView').plugin_reference.get_editor_interface().get_resource_filesystem().scan_sources()
	force_event_button_list_reload()

