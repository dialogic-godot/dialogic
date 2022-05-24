tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!
export(String, "Audio", "Background", "Scene", "Resource") var Mode = "Background"

## node references
onready var file_button = $FileButton
onready var clear_button = $ClearButton

# until we change the background color of the pickers, the color should ignore the theme
var default_color = Color('ccced3')

# used to connect the signals
func _ready():
	editor_reference = find_parent("EditorView")
	file_button.connect("pressed", self, "_on_FileButton_pressed")
	clear_button.connect('pressed', self, "_on_ClearButton_pressed")
	file_button.add_color_override("font_color", default_color) #get_color("mono_color", "Editor"))
	clear_button.icon = get_icon("Reload", "EditorIcons")
	$FileButton/icon2.texture = get_icon("GuiSliderGrabber", "EditorIcons")
	match Mode:
		"Audio":
			$Label.text = "Play"
			$FileButton/icon.texture = get_icon("AudioStreamPlayer", "EditorIcons")
		"Background":
			$Label.text = "to"
			$FileButton/icon.texture = get_icon("Image", "EditorIcons")
		"Scene":
			$Label.text = "to"
			$FileButton/icon.texture = get_icon("PackedScene", "EditorIcons")
		"Resource":
			$Label.text = "to"
			$FileButton/icon.texture = get_icon("PackedScene", "EditorIcons")


# called by the parent event part
func load_data(event_data:Dictionary):
	
	# first update the event_data
	.load_data(event_data)
	
	# then the ui
	var path
	file_button.text = ""
	match Mode:
		"Audio":
			path = event_data['file']
			if path.empty():
				file_button.text = 'nothing (will stop previous)'
		"Background":
			path = event_data['background']
			if path.empty():
				file_button.text = 'nothing (will hide previous)'
		"Scene":
			path = event_data['change_scene']
			if path.empty():
				file_button.text = 'a yet to be selected scene'
		"Resource":
			path = event_data['resource_file']
			if path.empty():
				file_button.text = 'a yet to be selected resource'
	if file_button.text.empty():
		file_button.text = path.get_file()
		file_button.hint_tooltip = path
	
	clear_button.visible = !path.empty()

func _on_FileButton_pressed():
	match Mode:
		"Audio":
			editor_reference.godot_dialog("*.wav, *.ogg, *.mp3")
		"Background":
			editor_reference.godot_dialog("*.png, *.jpg, *.jpeg, *.tga, *.svg, *.svgz, *.bmp, *.webp, *.tscn")
		"Scene":
			editor_reference.godot_dialog("*.tscn")
		"Resource":
			editor_reference.godot_dialog("*.tres, *.res")
 
	editor_reference.godot_dialog_connect(self, "_on_file_selected")

func _on_file_selected(path, target):
	match Mode:
		"Audio":
			event_data['file'] = path
		"Background":
			event_data['background'] = path
		"Scene":
			event_data['change_scene'] = path
		"Resource":
			event_data['resource_file'] = path
	
	clear_button.visible = true
	file_button.text = path.get_file()
	file_button.hint_tooltip = path
	
	# informs the parent about the changes!
	data_changed()

func _on_ClearButton_pressed():
	match Mode:
		"Audio":
			event_data['file'] = ""
			file_button.text = 'nothing (will stop previous)'
		"Background":
			event_data['background'] = ""
			file_button.text = 'nothing (will hide previous)'
		"Scene":
			event_data['change_scene'] = ""
			file_button.text = 'a yet to be selected scene'
		"Resource":
			event_data['resource_file'] = ""
			file_button.text = 'a yet to be selected resource'
	clear_button.visible = false

	# informs the parent about the changes!
	data_changed()
