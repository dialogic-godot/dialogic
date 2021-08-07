tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!

export (bool) var allow_dont_change := true
export (bool) var allow_definition := true

## node references
onready var picker_menu = $HBox/MenuButton
onready var preview = $Node2D/PreviewContainer
onready var preview_title = preview.get_node("VBox/Title")
onready var preview_texture = preview.get_node("VBox/TextureRect")

var current_hovered = null

var character_data = null

# used to connect the signals
func _ready():
	picker_menu.get_popup().connect("index_pressed", self, '_on_PickerMenu_selected')
	picker_menu.get_popup().connect("gui_input", self, "popup_gui_input")
	picker_menu.get_popup().connect("mouse_exited", self, "mouse_exited_popup")
	picker_menu.get_popup().connect("popup_hide", self, "mouse_exited_popup")
	
	picker_menu.connect("about_to_show", self, "_on_PickerMenu_about_to_show")
	preview_title.set('custom_fonts/font', get_font("title", "EditorFonts"))
	preview.set('custom_styles/panel', get_stylebox("panel", "PopupMenu"))

# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	# Now update the ui nodes to display the data. 
	picker_menu.text = event_data['portrait']

# has to return the wanted preview, only useful for body parts
func get_preview():
	return ''

func _on_PickerMenu_selected(index):
	if index == 0 and allow_dont_change:
		event_data['portrait'] = "(Don't change)"
	elif allow_definition and ((allow_dont_change and index == 1) or index == 0):
		event_data['portrait'] = "[Definition]"
	else:
		event_data['portrait'] = picker_menu.get_popup().get_item_text(index)
	
	picker_menu.text = event_data['portrait']
	
	# informs the parent about the changes!
	data_changed()

func get_character_data():
	for ch in DialogicUtil.get_character_list():
		if ch['file'] == event_data['character']:
			return ch

func _on_PickerMenu_about_to_show():
	character_data = get_character_data()
	picker_menu.get_popup().clear()
	var index = 0
	if allow_dont_change:
		picker_menu.get_popup().add_item("(Don't change)")
		index += 1
	if allow_definition:
		picker_menu.get_popup().add_item("[Definition]")
		index += 1
	if event_data['character']:
		if character_data.has('portraits'):
			for p in character_data['portraits']:
				picker_menu.get_popup().add_item(p['name'])
				index += 1

func popup_gui_input(event):
	if event is InputEventMouseMotion:
		if current_hovered != picker_menu.get_popup().get_current_index():
			current_hovered = picker_menu.get_popup().get_current_index()
			
			# hide if this is not a previewable portrait
			# this isn't even an item
			if current_hovered == -1:
				preview.hide()
				return
			var idx_add = 0
			if allow_dont_change:
				idx_add -= 1
				if current_hovered == 0:
					preview.hide()
					return
				if allow_definition and current_hovered == 1:
					preview.hide()
					return
			if allow_definition:
				idx_add -= 1
				if not allow_dont_change and current_hovered == 0:
					preview.hide()
					return
			
			## show the preview
			preview.rect_position.x = picker_menu.get_popup().rect_size.x + 20
			var current = character_data['portraits'][current_hovered + idx_add]
			preview_title.text = '  ' + current['name']
			preview_title.icon = null
			if current['path']:
				if current['path'].ends_with('.tscn'):
					preview_texture.expand = false
					var editor_reference = find_parent('EditorView')
					if editor_reference and editor_reference.editor_interface:
						editor_reference.editor_interface.get_resource_previewer().queue_resource_preview(current['path'], self, "show_scene_preview", null)
					preview_title.icon = get_icon("PackedScene", "EditorIcons")
					return
				else:
					preview_title.icon = get_icon("Sprite", "EditorIcons")
					preview_texture.expand = true
					preview_texture.texture = load(current['path'])
			else:
				preview_texture.texture = null
			preview.show()


func mouse_exited_popup():
	preview.hide()
	current_hovered = null


func show_scene_preview(path:String, preview:Texture, user_data):
	if preview:
		preview_texture.texture = preview
