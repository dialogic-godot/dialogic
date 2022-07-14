tool
extends Control

const portrait_entry = preload("res://addons/dialogic/Editor/CharacterEditor/PortraitEntry.tscn")

onready var toolbar = find_parent('EditorView').get_node('%Toolbar')
var current_character : DialogicCharacter
var current_portrait = null

signal portrait_selected(previous, current)

##############################################################################
##							RESOURCE LOGIC
##############################################################################

func new_character(path: String) -> void:
	var resource = DialogicCharacter.new()
	resource.resource_path = path
	resource.name = path.get_file().trim_suffix("."+path.get_extension())
	resource.display_name = path.get_file().trim_suffix("."+path.get_extension())
	resource.color = Color.white
	resource.custom_info = {}
	ResourceSaver.save(path, resource)
	find_parent('EditorView').edit_character(resource)

func load_character(resource: DialogicCharacter) -> void:
	if not resource:
		return
	current_character = resource
	toolbar.get_node('CurrentResource').text = resource.resource_path
	toolbar.set_character_mode()
	$'%NameLineEdit'.text = resource.name
	$'%ColorPickerButton'.color = resource.color
	$'%DisplayNameLineEdit'.text = resource.display_name
	$'%NicknameLineEdit'.text = str(resource.nicknames).trim_prefix('[').trim_suffix(']')
	$'%DescriptionTextEdit'.text = resource.description
	$'%MainScale'.value = 100*resource.scale
	$'%MainOffsetX'.value = resource.offset.x
	$'%MainOffsetY'.value = resource.offset.y
	$'%MainMirror'.pressed = resource.mirror
	$'%PortraitSearch'.text = ""
	
	for main_edit in $'%MainEditTabs'.get_children():
		if main_edit.has_method('load_character'):
			main_edit.load_character(current_character)
	
	update_portrait_list()


func save_character() -> void:
	if ! visible or not current_character:
		return
	current_character.display_name = $'%DisplayNameLineEdit'.text
	current_character.color = $'%ColorPickerButton'.color
	var nicknames = []
	for n_name in $'%NicknameLineEdit'.text.split(','):
		nicknames.append(n_name.strip_edges())
	current_character.nicknames = nicknames
	current_character.description = $'%DescriptionTextEdit'.text
	current_character.scale = $'%MainScale'.value/100.0
	current_character.offset = Vector2($'%MainOffsetX'.value, $'%MainOffsetY'.value) 
	current_character.mirror = $'%MainMirror'.pressed
	
	for main_edit in $'%MainEditTabs'.get_children():
		if main_edit.has_method('save_character'):
			main_edit.save_character(current_character)
	
	current_character.portraits = {}
	for node in $'%PortraitList'.get_children():
		current_character.portraits[node.get_portrait_name()] = node.portrait_data
	
	ResourceSaver.save(current_character.resource_path, current_character)
	toolbar.set_resource_saved()
	
	

##############################################################################
##							INTERFACE
##############################################################################

func _ready() -> void:
	var dialogic_plugin = get_tree().root.get_node('EditorNode/DialogicPlugin')
	dialogic_plugin.connect('dialogic_save', self, 'save_character')
	
	# Let's go connecting!
	$'%NameLineEdit'.connect('text_changed', self, 'something_changed')
	$'%ColorPickerButton'.connect('color_changed', self, 'something_changed')
	$'%DisplayNameLineEdit'.connect('text_changed', self, 'something_changed')
	$'%NicknameLineEdit'.connect('text_changed', self, 'something_changed')
	$'%DescriptionTextEdit'.connect('text_changed', self, 'something_changed')
	$'%MainScale'.connect("value_changed", self, 'main_portrait_settings_update')
	$'%MainOffsetX'.connect("value_changed", self, 'main_portrait_settings_update')
	$'%MainOffsetY'.connect("value_changed", self, 'main_portrait_settings_update')
	$'%MainMirror'.connect("toggled", self, 'main_portrait_settings_update')
	$'%PortraitSearch'.connect("text_changed", self, 'update_portrait_list')
	
	$'%NewPortrait'.connect('pressed', self, 'create_portrait_entry_instance', ['', {'path':'', 'scale':1, 'offset':Vector2(), 'mirror':false}])
	$'%ImportFromFolder'.connect('pressed', self, 'open_portrait_folder_select')
	$'%PreviewMode'.connect('item_selected', self, '_on_PreviewMode_item_selected')
	$'%PreviewMode'.select(DialogicUtil.get_project_setting('dialogic/editor/character_preview_mode', 0))
	_on_PreviewMode_item_selected($'%PreviewMode'.selected)
	$'%PreviewPositionIcon'.texture = get_icon("EditorPosition", "EditorIcons")
	
	if find_parent('EditorView'): # This prevents the view to turn black if you are editing this scene in Godot
		var style = $Split/EditorScroll.get('custom_styles/bg')
		style.set('bg_color', get_color("dark_color_1", "Editor"))
	
	$'%NewPortrait'.icon = get_icon("Add", "EditorIcons")
	$'%ImportFromFolder'.icon = get_icon("Folder", "EditorIcons")
	$'%PortraitsTitle'.set('custom_fonts/font', get_font("doc_title", "EditorFonts"))
	$Split/EditorScroll/Editor/VBoxContainer/PortraitPanel.set('custom_styles/panel', get_stylebox("Background", "EditorStyles"))
	
	$'%PortraitScale'.connect("value_changed", self, 'set_portrait_scale')
	$'%PortraitOffsetX'.connect("value_changed", self, 'set_portrait_offset_x')
	$'%PortraitOffsetY'.connect("value_changed", self, 'set_portrait_offset_y')
	$'%PortraitMirror'.connect("toggled", self, 'set_portrait_mirror')
	
	# Subsystems
	for script in DialogicUtil.get_event_scripts():
		for subsystem in load(script).new().get_required_subsystems():
			if subsystem.has('character_main'):
				var edit =  load(subsystem.character_main).instance()
				if edit.has_signal('changed'):
					edit.connect('changed', self, 'something_changed')
				$'%MainEditTabs'.add_child(edit)
	hide()


func something_changed(fake_argument = "") -> void:
	toolbar.set_resource_unsaved()


func open_portrait_folder_select() -> void:
	find_parent("EditorView").godot_file_dialog(self, "_on_dir_selected","*", EditorFileDialog.MODE_OPEN_DIR)


func _on_dir_selected(path:String) -> void:
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				var file_lower = file_name.to_lower()
				if '.svg' in file_lower or '.png' in file_lower:
					if not '.import' in file_lower:
						var final_name = path+ "/" + file_name
						create_portrait_entry_instance(file_name.get_file().trim_suffix("."+file_name.get_extension()), {'path':final_name, 'scale':1, 'offset':Vector2(), 'mirror':false})
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")


func create_portrait_entry_instance(name:String, portait_data:Dictionary) -> Node:
	var instance = portrait_entry.instance()
	instance.load_data(name, portait_data.duplicate(), self)
	get_node("%PortraitList").add_child(instance)
	something_changed()
	return instance


func update_portrait_list(filter_term:String = '') -> void:
	for node in $'%PortraitList'.get_children():
		node.queue_free()
	
	var prev_portrait_name = ''
	if current_portrait and is_instance_valid(current_portrait):
		prev_portrait_name = current_portrait.get_portrait_name()
	
	# load the portraits
	current_portrait = null
	var first_visible_item = null
	for portrait in current_character.portraits.keys():
		var port = create_portrait_entry_instance(portrait, current_character.portraits[portrait])
		if filter_term.empty() or filter_term.to_lower() in portrait.to_lower():
			if not first_visible_item: first_visible_item = port
			if portrait == prev_portrait_name:
				current_portrait = port
		else:
			port.hide()
	
	if current_portrait == null:
		# Show the first portrait, if there is one
		if first_visible_item:
			update_portrait_preview(first_visible_item)
		else:
			update_portrait_preview()
	else:
		update_portrait_preview(current_portrait)


func update_portrait_preview(portrait_inst = "") -> void:
	if current_portrait and is_instance_valid(current_portrait):
		current_portrait.visual_defocus()
	
	emit_signal("portrait_selected", current_portrait, portrait_inst)
	
	if portrait_inst and is_instance_valid(portrait_inst):
		current_portrait = portrait_inst
		current_portrait.visual_focus()
	
		$'%PreviewLabel'.text = DTS.translate('Preview of')+' "'+current_portrait.get_portrait_name()+'"'
		
		var path:String = current_portrait.portrait_data.get('path', '')
		var mirror:bool = current_portrait.portrait_data.get('mirror', false) != $'%MainMirror'.pressed
		var scale:float = current_portrait.portrait_data.get('scale', 1) * $'%MainScale'.value/100.0
		var offset:Vector2 = current_portrait.portrait_data.get('offset', Vector2()) + Vector2($'%MainOffsetX'.value, $'%MainOffsetY'.value)
		var l_path = path.to_lower()
		if '.png' in l_path or '.svg' in l_path:
			$'%PreviewRealRect'.texture = load(path)
			$'%PreviewFullRect'.texture = load(path)
			$"%PreviewLabel".text += ' (' + str($'%PreviewRealRect'.texture.get_width()) + 'x' + str($'%PreviewRealRect'.texture.get_height())+')'
			$'%PreviewRealRect'.rect_scale = Vector2(scale, scale)
			$'%PreviewRealRect'.flip_h = mirror
			$'%PreviewFullRect'.flip_h = mirror
			$'%PreviewRealRect'.rect_position.x = -($'%PreviewRealRect'.texture.get_width()*scale/2.0)+offset.x
			$'%PreviewRealRect'.rect_position.y = -($'%PreviewRealRect'.texture.get_height()*scale)+offset.y
			
			$'%PortraitSettings'.show()
		elif '.tscn' in l_path:
			$'%PreviewRealRect'.texture = null
			$'%PreviewFullRect'.texture = null
			$'%PreviewLabel'.text = DTS.translate('CustomScenePreview')
			$'%PortraitSettings'.hide()
		
		$'%PortraitScale'.value = current_portrait.portrait_data.get('scale', 1)*100
		$'%PortraitOffsetX'.value = current_portrait.portrait_data.get('offset', Vector2()).x
		$'%PortraitOffsetY'.value = current_portrait.portrait_data.get('offset', Vector2()).y
		$'%PortraitMirror'.pressed = current_portrait.portrait_data.get('mirror', false)
		
	else:
		$'%PortraitSettings'.hide()
		$'%PreviewRealRect'.texture = null
		$'%PreviewFullRect'.texture = null
		$'%PreviewLabel'.text = DTS.translate('Nothing to preview')


func _on_PreviewMode_item_selected(index:int) -> void:
	if index == 0:
		$'%PreviewReal'.hide()
		$'%PreviewFullRect'.show()
	if index == 1 or index == null:
		$'%PreviewReal'.show()
		$'%PreviewFullRect'.hide()
	ProjectSettings.set_setting('dialogic/editor/character_preview_mode', index)
	

func set_portrait_mirror(toggle:bool) -> void:
	current_portrait.portrait_data.mirror = toggle
	update_portrait_preview(current_portrait)
	something_changed()

func set_portrait_scale(value:float) -> void:
	current_portrait.portrait_data.scale = value/100.0
	update_portrait_preview(current_portrait)
	something_changed()

func set_portrait_offset_x(value:float) -> void:
	current_portrait.portrait_data.offset.x = value
	update_portrait_preview(current_portrait)
	something_changed()

func set_portrait_offset_y(value:float) -> void:
	current_portrait.portrait_data.offset.y = value
	update_portrait_preview(current_portrait)
	something_changed()

func main_portrait_settings_update(value = null) -> void:
	update_portrait_preview(current_portrait)
	something_changed()
