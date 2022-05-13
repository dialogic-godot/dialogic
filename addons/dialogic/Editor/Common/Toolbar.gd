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
