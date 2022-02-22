tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!

export (bool) var allow_dont_change := true
export (bool) var allow_definition := true

## node references
onready var picker_menu = $HBox/MenuButton
onready var preview = $Preview/PreviewContainer
onready var preview_title = preview.get_node("VBox/Title")
onready var preview_texture = preview.get_node("VBox/TextureRect")
var current_hovered = null

var character_data = null

# theme
var no_change_icon
var definition_icon
var portrait_icon


# used to connect the signals
func _ready():
	picker_menu.get_popup().connect("index_pressed", self, '_on_PickerMenu_selected')
	picker_menu.get_popup().connect("gui_input", self, "popup_gui_input")
	picker_menu.get_popup().connect("mouse_exited", self, "mouse_exited_popup")
	picker_menu.get_popup().connect("popup_hide", self, "mouse_exited_popup")
	
	picker_menu.connect("about_to_show", self, "_on_PickerMenu_about_to_show")
	preview_title.set('custom_fonts/font', get_font("title", "EditorFonts"))
	preview.set('custom_styles/panel', get_stylebox("panel", "PopupMenu"))

	# Themeing
	no_change_icon = get_icon("GuiRadioUnchecked", "EditorIcons")
	definition_icon = load("res://addons/dialogic/Images/Resources/definition.svg")
	portrait_icon = load("res://addons/dialogic/Images/Event Icons/Portrait.svg")

# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	allow_dont_change = event_data['event_id'] != 'dialogic_002' or (event_data['event_id'] == 'dialogic_002' and int(event_data.get('type', 0)) == 2)
	
	if event_data['event_id'] == 'dialogic_002' and event_data['type'] == 2:
		$HBox/Label.text = "to portrait"
	else:
		$HBox/Label.text = "with portrait"
	
	# Now update the ui nodes to display the data. 
	if event_data.get('portrait', '').empty():
		# if this is a text/question event or character event in update mode 
		if allow_dont_change:
			picker_menu.text = "(Don't change)"
			picker_menu.custom_icon = no_change_icon
		else:
			picker_menu.text = "Default"
			picker_menu.custom_icon = portrait_icon
	else:
		if event_data['portrait'] == "[Definition]":
			picker_menu.text = "[Value]"
			picker_menu.custom_icon = definition_icon
		else:
			picker_menu.text = event_data['portrait']
			picker_menu.custom_icon = portrait_icon

# has to return the wanted preview, only useful for body parts
func get_preview():
	return ''

func _on_PickerMenu_selected(index):
	if index == 0 and allow_dont_change:
		event_data['portrait'] = "(Don't change)"
		picker_menu.custom_icon = no_change_icon
	elif allow_definition and ((allow_dont_change and index == 1) or index == 0):
		event_data['portrait'] = "[Definition]"
		picker_menu.custom_icon = definition_icon
	else:
		event_data['portrait'] = picker_menu.get_popup().get_item_text(index)
		picker_menu.custom_icon = portrait_icon
	# TODO in 2.0
	if event_data['portrait'] == "[Definition]":
		picker_menu.text = "[Value]"
	else:
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
		picker_menu.get_popup().set_item_icon(index, no_change_icon)
		index += 1
	if allow_definition:
		picker_menu.get_popup().add_item("[Value]")
		picker_menu.get_popup().set_item_icon(index, definition_icon)
		index += 1
	if event_data['character']:
		if character_data.has('portraits'):
			for p in character_data['portraits']:
				picker_menu.get_popup().add_item(p['name'])
				picker_menu.get_popup().set_item_icon(index, portrait_icon)
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
			preview.rect_position.x = picker_menu.get_popup().rect_size.x + 130
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
