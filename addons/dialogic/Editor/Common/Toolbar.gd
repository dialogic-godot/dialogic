tool
extends HBoxContainer

func _ready():
	# Get version number
	$Version.set("custom_colors/font_color", get_color("disabled_font_color", "Editor"))
	var config = ConfigFile.new()
	var err = config.load("res://addons/dialogic/plugin.cfg")
	if err == OK:
		$Version.text = "v" + config.get_value("plugin", "version")
	
	
	$PlayTimeline.icon = get_icon("PlayScene", "EditorIcons")
	$PlayTimeline.connect("pressed", self, "play_timeline")
	
	$AddTimeline.icon = load("res://addons/dialogic/Images/Toolbar/add-timeline.svg")

################################################################################
##							HELPERS
################################################################################

func set_resource_saved():
	if $CurrentResource.text.ends_with(("(*)")):
		$CurrentResource.text = $CurrentResource.text.trim_suffix("(*)")

func set_resource_unsaved():
	if not $CurrentResource.text.ends_with(("(*)")):
		$CurrentResource.text += "(*)"

################################################################################
##							BASICS
################################################################################

func _on_AddTimeline_pressed():
	get_node("%TimelineEditor").new_timeline()

func _on_AddCharacter_pressed():
	find_parent('EditorView').godot_file_dialog(
		get_parent().get_node("CharacterEditor"),
		'new_character',
		'*.dch; DialogicCharacter',
		EditorFileDialog.MODE_SAVE_FILE,
		'Save new Character',
		'New_Character'
	)



################################################################################
##							TIMELINE_MODE
################################################################################

func set_timeline_mode():
	$PlayTimeline.show()

func play_timeline():
	if get_node("%TimelineEditor").current_timeline:
		var dialogic_plugin = DialogicUtil.get_dialogic_plugin()
		# Save the current opened timeline
		ProjectSettings.set_setting('dialogic/current_timeline_path', get_node("%TimelineEditor").current_timeline.resource_path)
		ProjectSettings.save()
		dialogic_plugin._editor_interface.play_custom_scene("res://addons/dialogic/Other/TestTimelineScene.tscn")


################################################################################
##							CHARACTER_MODE
################################################################################

func set_character_mode():
	$PlayTimeline.hide()
