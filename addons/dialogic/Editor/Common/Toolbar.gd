tool
extends HBoxContainer

func _ready():
	# Get version number
	$Version.set("custom_colors/font_color", get_color("disabled_font_color", "Editor"))
	var config = ConfigFile.new()
	var err = config.load("res://addons/dialogic/plugin.cfg")
	if err == OK:
		$Version.text = "v" + config.get_value("plugin", "version")


	$AddTimeline.icon = load("res://addons/dialogic/Images/Toolbar/add-timeline.svg")


func _on_AddTimeline_pressed():
	get_node("%TimelineEditor").new_timeline()

func _on_AddCharacter_pressed():
	get_parent().get_parent().get_parent().godot_file_dialog(get_parent().get_node("CharacterEditor"), 'new_character', '*.dch; DialogicCharacter', EditorFileDialog.MODE_SAVE_FILE)

func set_resource_saved():
	if $CurrentResource.text.ends_with(("(*)")):
		$CurrentResource.text = $CurrentResource.text.trim_suffix("(*)")

func set_resource_unsaved():
	if not $CurrentResource.text.ends_with(("(*)")):
		$CurrentResource.text += "(*)"
