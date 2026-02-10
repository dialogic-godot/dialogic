@tool
extends Control


var current_layer_scene_path := ""
var customization_editor_info := {}

## The id of the currently selected layer.
## "" is the base scene.
var current_layer_id := ""
var current_style : DialogicStyle

var _loading_layer := false

@onready var no_settings_info := %NoSettings

@onready var unre: UndoRedo = owner.unre

func _ready() -> void:
	DialogicUtil.get_dialogic_plugin().scene_saved.connect(_on_scene_saved)
	%ExpandLayerInfo.icon = get_theme_icon("CodeFoldDownArrow", "EditorIcons")

	if not DialogicUtil.get_editor_setting("style_editor_expand_layer_info", true):
		toggle_layer_info()


func open_layer(style:DialogicStyle, layer_id:String) -> void:
	current_style = style
	current_layer_id = layer_id
	DialogicUtil.set_editor_setting("style_editor/"+style.name+"/latest_layer", current_layer_id)

	_loading_layer = true

	var layer_info := current_style.get_layer_inherited_info(current_layer_id)
	show_layer_info()

	var inherited_layer_info := current_style.get_layer_inherited_info(layer_id, true)
	load_layout_scene_customization(
			layer_info.path,
			layer_info.overrides,
			inherited_layer_info.overrides)

	_loading_layer = false


#region LAYER_INFO_SECTION
################################################################################

func show_layer_info() -> void:
	var layer_info := current_style.get_layer_inherited_info(current_layer_id)

	%SmallLayerPreview.hide()
	if %StyleBrowser.is_premade_style_part(layer_info.get("path", "Unkown Layer")):
		var premade_infos = %StyleBrowser.premade_scenes_reference[layer_info.get("path")]
		%LayerName.text = premade_infos.get("name", "Unknown Layer")
		%SmallLayerAuthor.text = "by "+premade_infos.get("author", "")
		%SmallLayerDescription.text = premade_infos.get("description", "")

		if premade_infos.get("preview_image", null) and ResourceLoader.exists(premade_infos.get("preview_image")[0]):
			%SmallLayerPreview.texture = load(premade_infos.get("preview_image")[0])
			%SmallLayerPreview.show()

	else:
		%LayerName.text = %LayerList.clean_scene_name(layer_info.get("path", "Unkown Layer"))
		%SmallLayerAuthor.text = "Custom Layer"
		%SmallLayerDescription.text = layer_info.get("path", "Unkown Layer")

	%SmallLayerScene.text = layer_info.get("path", "Unkown Layer").get_file()
	%SmallLayerScene.tooltip_text = layer_info.get("path", "")


func toggle_layer_info() -> void:
	if %LayerInfoBody.visible:
		%LayerInfoBody.hide()
		%ExpandLayerInfo.icon = get_theme_icon("CodeFoldedRightArrow", "EditorIcons")
	else:
		%LayerInfoBody.show()
		%ExpandLayerInfo.icon = get_theme_icon("CodeFoldDownArrow", "EditorIcons")
	DialogicUtil.set_editor_setting("style_editor_expand_layer_info", %LayerInfoBody.visible)

#endregion


#region LAYER SETTINGS
################################################################################

func load_layout_scene_customization(custom_scene_path:String, overrides:Dictionary = {}, inherited_overrides:Dictionary = {}) -> void:
	for child in %LayerSettingsTabs.get_children():
		child.get_parent().remove_child(child)
		if child == no_settings_info:
			add_child(no_settings_info)
			no_settings_info.hide()
		else:
			child.queue_free()

	var scene: Node = null
	if not custom_scene_path.is_empty() and ResourceLoader.exists(custom_scene_path):
		var pck_scn := load(custom_scene_path)
		if pck_scn:
			scene = pck_scn.instantiate()

	var settings := []
	if scene:
		current_layer_scene_path = scene.scene_file_path
		settings = scene.get_meta("style_customization", []).duplicate(true) + scene.get_meta("base_style_customization", []).duplicate(true)

	if settings.is_empty():
		no_settings_info.show()
		no_settings_info.get_parent().remove_child(no_settings_info)
		%LayerSettingsTabs.add_child(no_settings_info)
		return

	var warning_label_base := Label.new()
	#warning_label_base.text =
	warning_label_base.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning_label_base.clip_text = true
	warning_label_base.size_flags_vertical = Control.SIZE_EXPAND_FILL
	warning_label_base.theme_type_variation = "DialogicHintText"
	warning_label_base.add_theme_color_override("font_color", get_theme_color("warning_color", "Editor"))
	var stylebox : StyleBox = get_theme_stylebox("normal", "Label").duplicate()
	stylebox.content_margin_bottom = 0
	stylebox.content_margin_top = 0
	warning_label_base.add_theme_stylebox_override("normal", stylebox)

	var current_vbox: VBoxContainer = null
	var current_grid: GridContainer = null
	var label_bg_style := get_theme_stylebox("CanvasItemInfoOverlay", "EditorStyles").duplicate()
	label_bg_style.content_margin_left = 5
	label_bg_style.content_margin_right = 5
	label_bg_style.content_margin_top = 5

	#var current_group_name := ""
	var current_subgroup_name := ""
	customization_editor_info = {}
	var current_node_path : String = ""
	for i in settings:
		match i["type"]:
			"Category":
				var main_scroll := ScrollContainer.new()
				main_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
				main_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				main_scroll.name = i["name"]
				%LayerSettingsTabs.add_child(main_scroll, true)

				current_vbox = VBoxContainer.new()
				current_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
				current_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

				main_scroll.add_child(current_vbox)
				#current_group_name = i["name"].to_snake_case(
				current_subgroup_name = ""

			"Node":
				current_node_path = i["name"]

				if (i.display_name.is_empty() or i.display_name == "-") and current_subgroup_name:
					continue

				# add separator
				if current_subgroup_name:
					current_vbox.add_child(HSeparator.new())
					#current_grid.get_child(-1).add_theme_constant_override("separation", 20)
					#current_grid.add_child(current_grid.get_child(-1).duplicate())
					#current_grid.add_child(current_grid.get_child(-1).duplicate())
					#current_grid.add_child(current_grid.get_child(-1).duplicate())

				var title_label := Label.new()
				title_label.text = i.display_name if i.display_name else i.name
				title_label.theme_type_variation = "DialogicSection"
				title_label.size_flags_horizontal = SIZE_EXPAND_FILL
				current_vbox.add_child(title_label, true)

				current_grid = GridContainer.new()
				current_grid.columns = 4
				current_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				current_vbox.add_child(current_grid)
				#current_node.set_meta("style_identifier", i["name"])

				## add spaced to the grid
				#current_grid.add_child(Control.new())
				#current_grid.add_child(Control.new())
				#current_grid.add_child(Control.new())

				current_subgroup_name = i["name"].to_snake_case()

			"Property":
				var property_name: String = i["name"]
				var property_path: String = current_node_path+":"+property_name
				var node := get_scene_node(scene, current_node_path)
				if not property_name in node:
					printerr("[Dialogic] Invalid node property exposed to style editor: "+property_path)
					continue
				var property_display_name: String = i["display_name"]
				var vbox := VBoxContainer.new()
				vbox.add_theme_constant_override("separation", 0)
				var label := Label.new()
				label.text = property_display_name
				vbox.add_child(label, true)
				vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
				vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				current_grid.add_child(vbox)
				label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

				var warning_label := warning_label_base.duplicate()
				vbox.add_child(warning_label)

				var scene_value: Variant = get_value_on_node(node, property_name)
				customization_editor_info[property_path] = {}
				customization_editor_info[property_path]["warning_label"] = warning_label

				if property_path in inherited_overrides:
					customization_editor_info[property_path]["orig"] = inherited_overrides.get(property_path)
				else:
					customization_editor_info[property_path]["orig"] = scene_value

				var current_value: Variant
				if property_path in overrides:
					current_value = overrides.get(property_path)
				else:
					current_value = customization_editor_info[property_path]["orig"]

				var input: Node = DialogicUtil.setup_script_property_edit_node(get_node_property_info(node, property_name), current_value, set_export_override, property_path)
				input.size_flags_horizontal = SIZE_EXPAND_FILL
				customization_editor_info[property_path]["node"] = input

				if i["tooltip"]:
					var tooltip: Node = load("res://addons/dialogic/Editor/Common/hint_tooltip_icon.tscn").instantiate()
					tooltip.hint_text = i["tooltip"]
					current_grid.add_child(tooltip)
				else:
					current_grid.add_child(Control.new())

				var reset := Button.new()
				reset.flat = true
				reset.icon = get_theme_icon("Reload", "EditorIcons")
				reset.tooltip_text = "Remove customization"
				reset.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
				customization_editor_info[property_path]["reset"] = reset
				reset.disabled = current_value == customization_editor_info[property_path]["orig"]
				current_grid.add_child(reset)
				reset.pressed.connect(_on_export_override_reset.bind(property_path))

				current_grid.add_child(input)

				update_setting_warning(property_path)

	var latest_tab: int = DialogicUtil.get_editor_setting("style_editor/"+current_style.name+"/layer_"+current_layer_id+"/selected_tab", 0)

	%LayerSettingsTabs.current_tab = min(latest_tab, %LayerSettingsTabs.get_tab_count()-1)
	if scene:
		scene.queue_free()


func get_value_on_node(node:Node, property:String) -> Variant:
	if property.begins_with("theme_override_"):
		var value: Variant
		if property.begins_with("theme_override_colors"):
			value =  node.get_theme_color(property.get_slice("/", 1))
		elif property.begins_with("theme_override_constants"):
			value = node.get_theme_constant(property.get_slice("/", 1))
		elif property.begins_with("theme_override_fonts"):
			value = node.get_theme_font(property.get_slice("/", 1))
		elif property.begins_with("theme_override_font_sizes"):
			value = node.get_theme_font_size(property.get_slice("/", 1))
		elif property.begins_with("theme_override_icons"):
			value = node.get_theme_icon(property.get_slice("/", 1))
		elif property.begins_with("theme_override_styles"):
			value = node.get_theme_stylebox(property.get_slice("/", 1))
		if value is Resource:
			if value.resource_path.is_empty():
				return null
		return value
	return node.get(property)


func get_scene_node(scene:Node, node_path:String) -> Node:
	if node_path.ends_with("/@all_children"):
		return scene.get_node(node_path.trim_suffix("/@all_children")).get_child(0)
	return scene.get_node(node_path)


func get_node_property_info(node:Node, property_name:String) -> Dictionary:
	for i in node.get_property_list():
		if i.name == property_name:
			return i

	return {}


func set_export_override(property_name:String, value:Variant) -> void:
	var overrides: Dictionary = current_style.get_layer_info(current_layer_id).overrides
	if overrides.has(property_name) and value == overrides[property_name]:
		current_style.emit_changed()
		if overrides[property_name] is Resource:
			unre.create_action("Set Layer Property Subresource Value", unre.MERGE_ENDS)
			unre.add_undo_method(func(): push_warning("[Dialogic] Cannot undo edit done in sub-resources. Sorry."))
			unre.commit_action()
		return
	unre.create_action("Set Style Override '{0}'".format([property_name.capitalize()]), unre.MERGE_ALL)
	unre.add_do_method(set_override_value.bind(property_name, value))
	if overrides.has(property_name):
		unre.add_undo_method(set_override_value.bind(property_name, overrides.get(property_name)))
	else:
		unre.add_undo_method(set_override_value.bind(property_name, customization_editor_info[property_name].orig))
	unre.commit_action()


func set_override_value(property_name:String, value:Variant) -> void:
	if value != customization_editor_info[property_name].orig:
		current_style.set_layer_setting(current_layer_id, property_name, value)
		customization_editor_info[property_name].reset.disabled = false
	else:
		current_style.remove_layer_setting(current_layer_id, property_name)
		customization_editor_info[property_name].reset.disabled = true
	var node: Node = customization_editor_info[property_name].node
	DialogicUtil.set_property_edit_node_value(node, value)
	update_setting_warning(property_name)
	current_style.emit_changed()


func _on_export_override_reset(property_name:String) -> void:
	var overrides: Dictionary = current_style.get_layer_info(current_layer_id).overrides
	unre.create_action("Reset Layer Property '{0}'".format([property_name.capitalize()]))
	unre.add_do_method(set_override_value.bind(property_name, customization_editor_info[property_name].orig))
	if overrides.has(property_name):
		unre.add_undo_method(set_override_value.bind(property_name, overrides.get(property_name)))
	else:
		unre.add_undo_method(set_override_value.bind(property_name, customization_editor_info[property_name].orig))
	unre.commit_action()


func update_setting_warning(property_name:String) -> void:
	if not property_name in customization_editor_info:
		return
	var warning_label: Label = customization_editor_info[property_name].warning_label
	var overrides: Dictionary = current_style.get_layer_info(current_layer_id).overrides
	var override_value: Variant =  overrides.get(property_name, null)
	var orig_value: Variant =  customization_editor_info[property_name].orig
	if override_value is Resource:
		if override_value.resource_path:
			warning_label.text = "This resource is shared. \nMake it unique if you do not want it to change in other places."
			warning_label.add_theme_color_override("font_color", get_theme_color("disabled_font_color", "Editor"))
		else:
			warning_label.text = ""
	elif orig_value is Resource:
		if orig_value.resource_path and not ".tscn::" in orig_value.resource_path:
			warning_label.text = "This resource is shared. \nMake it unique if you do not want it to change in other places or the base scene."
			warning_label.add_theme_color_override("font_color", get_theme_color("warning_color", "Editor"))
		else:
			warning_label.text = "This resource is local to the scene. Make it unique or assign a different resource to start editing it."
			warning_label.add_theme_color_override("font_color", get_theme_color("error_color", "Editor"))
	else:
		warning_label.text = ""
	warning_label.text = "\n"+warning_label.text


func _on_scene_saved(path:String) -> void:
	if path and path == current_layer_scene_path:
		open_layer(current_style, current_layer_id)


func _on_layer_settings_tabs_tab_changed(tab: int) -> void:
	if _loading_layer:
		return

	DialogicUtil.set_editor_setting("style_editor/"+current_style.name+"/layer_"+current_layer_id+"/selected_tab", tab)

#endregion


func _on_edit_layer_button_pressed() -> void:
	var layer_info := current_style.get_layer_inherited_info(current_layer_id)
	get_parent().edit_layer_scene(layer_info.path)
