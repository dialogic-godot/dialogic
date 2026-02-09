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
		settings = collect_settings(scene)

	if settings.is_empty():
		no_settings_info.show()
		no_settings_info.get_parent().remove_child(no_settings_info)
		%LayerSettingsTabs.add_child(no_settings_info)
		#var note := Label.new()
		#note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		#note.text = "This layer has no exposed settings."
		#if not %StyleBrowser.is_premade_style_part(custom_scene_path):
			#note.text += "\n\nIf you want to expose settings, use the scenes sidebar."
		#note.theme_type_variation = "DialogicHintText2"
		#note.name = "General"
		#%LayerSettingsTabs.add_child(note)
		#var button := Button.new()
		#button.text = "Open Scene"
		#%LayerSettingsTabs.add_child(button)
		return

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
		match i["id"]:
			&"GROUP":
				var main_scroll := ScrollContainer.new()
				main_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
				main_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				main_scroll.name = i["name"]
				%LayerSettingsTabs.add_child(main_scroll, true)

				current_grid = GridContainer.new()
				current_grid.columns = 3
				current_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				main_scroll.add_child(current_grid)
				#current_group_name = i["name"].to_snake_case(
				current_subgroup_name = ""

			&"SUBGROUP":
				current_node_path = i["name"]

				if (i.display_name.is_empty() or i.display_name == "-") and current_subgroup_name:
					continue

				# add separator
				if current_subgroup_name:
					current_grid.add_child(HSeparator.new())
					current_grid.get_child(-1).add_theme_constant_override("separation", 20)
					current_grid.add_child(current_grid.get_child(-1).duplicate())
					current_grid.add_child(current_grid.get_child(-1).duplicate())

				var title_label := Label.new()
				title_label.text = i.display_name if i.display_name else i.name
				title_label.theme_type_variation = "DialogicSection"
				title_label.size_flags_horizontal = SIZE_EXPAND_FILL
				current_grid.add_child(title_label, true)


				#current_node.set_meta("style_identifier", i["name"])

				# add spaced to the grid
				current_grid.add_child(Control.new())
				current_grid.add_child(Control.new())

				current_subgroup_name = i["name"].to_snake_case()

			&"SETTING":
				var property_name: String = i["name"]
				var property_path: String = current_node_path+":"+property_name
				var node := get_scene_node(scene, current_node_path)
				if not property_name in node:
					printerr("[Dialogic] Invalid node property exposed to style editor: "+property_path)
					continue
				var property_display_name: String = i["display_name"]

				var label := Label.new()
				#label.text = str(property_display_name.trim_prefix(current_group_name+"_").trim_prefix(current_subgroup_name+"_")).capitalize()
				label.text = property_display_name
				current_grid.add_child(label, true)
				label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

				var scene_value: Variant = get_value_on_node(node, property_name)
				customization_editor_info[property_path] = {}

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

	var latest_tab: int = DialogicUtil.get_editor_setting("style_editor/"+current_style.name+"/layer_"+current_layer_id+"/selected_tab", 0)

	%LayerSettingsTabs.current_tab = min(latest_tab, %LayerSettingsTabs.get_tab_count()-1)
	if scene:
		scene.queue_free()


func get_value_on_node(node:Node, property:String) -> Variant:
	if property.begins_with("theme_override_"):
		if property.begins_with("theme_override_colors"):
			return node.get_theme_color(property.get_slice("/", 1))
		elif property.begins_with("theme_override_constants"):
			return node.get_theme_constant(property.get_slice("/", 1))
		elif property.begins_with("theme_override_fonts"):
			return node.get_theme_font(property.get_slice("/", 1))
		elif property.begins_with("theme_override_font_sizes"):
			return node.get_theme_font_size(property.get_slice("/", 1))
		elif property.begins_with("theme_override_icons"):
			return node.get_theme_icon(property.get_slice("/", 1))
		elif property.begins_with("theme_override_styles"):
			return node.get_theme_stylebox(property.get_slice("/", 1))

	return node.get(property)


func get_scene_node(scene:Node, node_path:String) -> Node:
	if node_path.ends_with("/@all_children"):
		return scene.get_node(node_path.trim_suffix("/@all_children")).get_child(0)
	return scene.get_node(node_path)


func collect_settings(scene:Node) -> Array[Dictionary]:
	var properties: Array = scene.get_meta("style_customization", []) + scene.get_meta("base_style_customization", [])

	var settings: Array[Dictionary] = []

	var current_group := {}
	var current_subgroup := {}

	for i in properties:
		#if i["type"] & PROPERTY_USAGE_CATEGORY == PROPERTY_USAGE_CATEGORY:
			#continue

		if i["type"] == "Category":
			current_group = i
			current_group["added"] = false
			current_group["id"] = &"GROUP"
			current_subgroup = {}

		elif i["type"] == "Node":
			current_subgroup = i
			current_subgroup["added"] = false
			current_subgroup["id"] = &"SUBGROUP"

		elif i["type"] == "Property":
			#if current_group.get("name", "") == "Private":
				#continue

			if current_group.is_empty():
				current_group = {"name":"General", "added":false, "id":&"GROUP"}

			if current_group.get("added", true) == false:
				settings.append(current_group)
				current_group["added"] = true

			if current_subgroup.is_empty():
				current_subgroup = {"name":current_group["name"], "added":false, "id":&"SUBGROUP"}

			if current_subgroup.get("added", true) == false:
				settings.append(current_subgroup)
				current_subgroup["added"] = true

			i["id"] = &"SETTING"
			settings.append(i)
	return settings


func get_node_property_info(node:Node, property_name:String) -> Dictionary:
	for i in node.get_property_list():
		if i.name == property_name:
			return i

	return {}


func set_export_override(property_name:String, value:String = "") -> void:
	#printt(property_name, value)
	if str_to_var(value) != customization_editor_info[property_name]["orig"]:
		current_style.set_layer_setting(current_layer_id, property_name, str_to_var(value))
		customization_editor_info[property_name]["reset"].disabled = false
	else:
		current_style.remove_layer_setting(current_layer_id, property_name)
		customization_editor_info[property_name]["reset"].disabled = true


func _on_export_override_reset(property_name:String) -> void:
	#if customization_editor_info[property_name]["node"].get_meta("object"):
		#print(var_to_str(customization_editor_info[property_name]["node"].get_meta("object").property))
	current_style.remove_layer_setting(current_layer_id, property_name)
	customization_editor_info[property_name]["reset"].disabled = true
	var node: Node = customization_editor_info[property_name]["node"]
	DialogicUtil.set_property_edit_node_value(node, customization_editor_info[property_name]["orig"])



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
