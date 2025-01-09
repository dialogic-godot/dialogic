@tool
extends DialogicSettingsPage

## Settings tab that holds dialogic editor settings.

const _SETTING_IMAGE_PREVIEW_HEIGHT = "image_preview_height"
const _SETTING_EVENT_BLOCK_MARGIN = "event_block_margin"
const _SETTING_SHOW_EVENT_NAMES = "show_event_names"

const _SETTING_EVENT_COLOR_PALETTE = "color_palette"
const _SETTING_EVENT_SECTION_ODER = "event_section_order"

var do_timeline_editor_refresh_on_close := false

func _get_title() -> String:
	return "Editor"


func _get_priority() -> int:
	return 98


func _refresh() -> void:
	do_timeline_editor_refresh_on_close = false
	%ImagePreviewHeight.value = DialogicUtil.get_editor_setting(_SETTING_IMAGE_PREVIEW_HEIGHT, 100)
	%EventBlockMargin.value = DialogicUtil.get_editor_setting(_SETTING_EVENT_BLOCK_MARGIN, 0)
	%ShowEventNames.set_pressed_no_signal(DialogicUtil.get_editor_setting(_SETTING_SHOW_EVENT_NAMES, false))

	update_color_palette()
	reload_section_list()


func _ready() -> void:
	%ResetColorsButton.icon = get_theme_icon("Reload", "EditorIcons")
	%ResetColorsButton.pressed.connect(_on_reset_colors_button)

	%ImagePreviewHeight.value_changed.connect(_on_ImagePreviewHeight_value_changed)
	%EventBlockMargin.value_changed.connect(_on_EventBlockMargin_value_changed)
	%ShowEventNames.toggled.connect(_on_ShowEventNames_toggled)


func _about_to_close():
	if do_timeline_editor_refresh_on_close:
		refresh_visual_timeline_editor()


func refresh_visual_timeline_editor() -> void:
	var timeline_node: DialogicEditor = settings_editor.editors_manager.editors["Timeline"]["node"]
	timeline_node.get_node("%VisualEditor").load_event_buttons()

	# If the visual editor is open, close and reopen the timeline to have the colors reloaded.
	if timeline_node.get_node("%VisualEditor").visible:

		var current_timeline := timeline_node.current_resource
		settings_editor.editors_manager.clear_editor(timeline_node)

		settings_editor.editors_manager.edit_resource(current_timeline, true, true)



#region SECTION ORDER
################################################################################

func reload_section_list():
	%SectionList.clear()
	%SectionList.create_item()
	var cached_events := DialogicResourceUtil.get_event_cache()
	var sections := []
	var section_order: Array = DialogicUtil.get_editor_setting(_SETTING_EVENT_SECTION_ODER, ['Main', 'Logic', 'Flow', 'Audio', 'Visuals','Other', 'Helper'])
	for ev in cached_events:
		if !ev.event_category in sections:
			sections.append(ev.event_category)
			var item: TreeItem = %SectionList.create_item(null)
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

	DialogicUtil.set_editor_setting(_SETTING_EVENT_SECTION_ODER, sections)
	do_timeline_editor_refresh_on_close = true

#endregion


#region COLOR PALETTE
################################################################################

## Completely reloads the color palette buttons
func update_color_palette() -> void:
	for child in %Colors.get_children():
		child.queue_free()
	for color in DialogicUtil.get_color_palette():
		var button := ColorPickerButton.new()
		button.custom_minimum_size = Vector2(50 ,50) * DialogicUtil.get_editor_scale()
		%Colors.add_child(button)
		button.color = DialogicUtil.get_color(color)
		button.popup_closed.connect(_on_palette_color_popup_closed)


func _on_palette_color_popup_closed() -> void:
	var new_palette := {}
	for i in %Colors.get_children():
		new_palette["Color"+str(i.get_index()+1)] = i.color
	DialogicUtil.set_editor_setting(_SETTING_EVENT_COLOR_PALETTE, new_palette)

	do_timeline_editor_refresh_on_close = true


func _on_reset_colors_button() -> void:
	DialogicUtil.set_editor_setting(_SETTING_EVENT_COLOR_PALETTE, null)
	update_color_palette()

	do_timeline_editor_refresh_on_close = true

#endregion




func _on_ImagePreviewHeight_value_changed(value:float) -> void:
	DialogicUtil.set_editor_setting(_SETTING_IMAGE_PREVIEW_HEIGHT, value)


func _on_EventBlockMargin_value_changed(value:float) -> void:
	DialogicUtil.set_editor_setting(_SETTING_EVENT_BLOCK_MARGIN, value)
	do_timeline_editor_refresh_on_close = true


func _on_ShowEventNames_toggled(toggled:bool) -> void:
	DialogicUtil.set_editor_setting(_SETTING_SHOW_EVENT_NAMES, toggled)
	do_timeline_editor_refresh_on_close = true
