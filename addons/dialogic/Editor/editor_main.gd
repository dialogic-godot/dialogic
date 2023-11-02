@tool
extends ColorRect

## Editor root node. Most editor functionality is handled by EditorsManager node!

var plugin_reference: EditorPlugin = null
var editors_manager: Control = null

var editor_file_dialog: EditorFileDialog

## Styling
@export var editor_tab_bg := StyleBoxFlat.new()


func _ready() -> void:
	if get_parent() is SubViewport:
		return

	## REFERENCES
	editors_manager = $Margin/EditorsManager

	## STYLING
	color = get_theme_color("base_color", "Editor")
	editor_tab_bg.border_color = get_theme_color("base_color", "Editor")
	editor_tab_bg.bg_color = get_theme_color("dark_color_2", "Editor")
	$Margin/EditorsManager.editors_holder.add_theme_stylebox_override('panel', editor_tab_bg)

	# File dialog
	editor_file_dialog = EditorFileDialog.new()
	add_child(editor_file_dialog)

	var info_message := Label.new()
	info_message.add_theme_color_override('font_color', get_theme_color("warning_color", "Editor"))
	editor_file_dialog.get_line_edit().get_parent().add_sibling(info_message)
	info_message.get_parent().move_child(info_message, info_message.get_index()-1)
	editor_file_dialog.set_meta('info_message_label', info_message)

	$SaveConfirmationDialog.add_button('No Saving Please!', true, 'nosave')
	$SaveConfirmationDialog.hide()
	update_theme_additions()


func update_theme_additions():
	if theme == null:
		theme = Theme.new()
	theme.clear()

	theme.set_type_variation('DialogicTitle', 'Label')
	theme.set_font('font', 'DialogicTitle', get_theme_font("title", "EditorFonts"))
	theme.set_color('font_color', 'DialogicTitle', get_theme_color('warning_color', 'Editor'))
	theme.set_color('font_uneditable_color', 'DialogicTitle', get_theme_color('warning_color', 'Editor'))
	theme.set_color('font_selected_color', 'DialogicTitle', get_theme_color('warning_color', 'Editor'))
	theme.set_font_size('font_size', 'DialogicTitle', get_theme_font_size("doc_size", "EditorFonts"))

	theme.set_type_variation('DialogicSubTitle', 'Label')
	theme.set_font('font', 'DialogicSubTitle', get_theme_font("title", "EditorFonts"))
	theme.set_font_size('font_size', 'DialogicSubTitle', get_theme_font_size("doc_size", "EditorFonts"))
	theme.set_color('font_color', 'DialogicSubTitle', get_theme_color('accent_color', 'Editor'))

	theme.set_type_variation('DialogicPanelA', 'PanelContainer')
	var panel_style := DCSS.inline({
		'border-radius': 10,
		'border': 0,
		'border_color':get_theme_color("dark_color_3", "Editor"),
		'background': get_theme_color("base_color", "Editor"),
		'padding': [5, 5],
	})
	theme.set_stylebox('panel', 'DialogicPanelA', panel_style)
	theme.set_stylebox('normal', 'DialogicPanelA', panel_style)

	var dark_panel := panel_style.duplicate()
	dark_panel.bg_color = get_theme_color("dark_color_3", "Editor")
	theme.set_stylebox('panel', 'DialogicPanelDarkA', dark_panel)

	var cornerless_panel := panel_style.duplicate()
	cornerless_panel.corner_radius_top_left = 0
	theme.set_stylebox('panel', 'DialogicPanelA_cornerless', cornerless_panel)


	# panel used for example for portrait previews in character editor
	theme.set_type_variation('DialogicPanelB', 'PanelContainer')
	var side_panel :StyleBoxFlat= panel_style.duplicate()
	side_panel.corner_radius_top_left = 0
	side_panel.corner_radius_bottom_left = 0
	side_panel.expand_margin_left = 8
	side_panel.bg_color = get_theme_color("dark_color_2", "Editor")
	side_panel.set_border_width_all(1)
	side_panel.border_width_left = 0
	side_panel.border_color = get_theme_color("contrast_color_2", "Editor")
	theme.set_stylebox('panel', 'DialogicPanelB', side_panel)


	theme.set_type_variation('DialogicEventEdit', 'Control')
	var edit_panel := StyleBoxFlat.new()
	edit_panel.draw_center = true
	edit_panel.bg_color = get_theme_color("accent_color", "Editor")
	edit_panel.bg_color.a = 0.05
	edit_panel.border_width_bottom = 2
	edit_panel.border_color = get_theme_color("accent_color", "Editor").lerp(get_theme_color("dark_color_2", "Editor"), 0.4)
	edit_panel.content_margin_left = 5
	edit_panel.content_margin_right = 5
	edit_panel.set_corner_radius_all(1)
	theme.set_stylebox('panel', 'DialogicEventEdit', edit_panel)
	theme.set_stylebox('normal', 'DialogicEventEdit', edit_panel)

	var focus_edit := edit_panel.duplicate()
	focus_edit.border_color = get_theme_color("property_color_z", "Editor")
	focus_edit.draw_center = false
	theme.set_stylebox('focus', 'DialogicEventEdit', focus_edit)

	var hover_edit := edit_panel.duplicate()
	hover_edit.border_color = get_theme_color("warning_color", "Editor")

	theme.set_stylebox('hover', 'DialogicEventEdit', hover_edit)
	var disabled_edit := edit_panel.duplicate()
	disabled_edit.border_color = get_theme_color("property_color", "Editor")
	theme.set_stylebox('disabled', 'DialogicEventEdit', disabled_edit)

	theme.set_type_variation('DialogicHintText', 'Label')
	theme.set_color('font_color', 'DialogicHintText', get_theme_color("readonly_color", "Editor"))
	theme.set_font('font', 'DialogicHintText', get_theme_font("doc_italic", "EditorFonts"))

	theme.set_type_variation('DialogicHintText2', 'Label')
	theme.set_color('font_color', 'DialogicHintText2', get_theme_color("property_color_w", "Editor"))
	theme.set_font('font', 'DialogicHintText2', get_theme_font("doc_italic", "EditorFonts"))

	theme.set_type_variation('DialogicSection', 'Label')
	theme.set_font('font', 'DialogicSection', get_theme_font("main_msdf", "EditorFonts"))
	theme.set_color('font_color', 'DialogicSection', get_theme_color("property_color_z", "Editor"))
	theme.set_font_size('font_size', 'DialogicSection', get_theme_font_size("doc_size", "EditorFonts"))

	theme.set_type_variation('DialogicSettingsSection', 'DialogicSection')
	theme.set_font('font', 'DialogicSettingsSection', get_theme_font("main_msdf", "EditorFonts"))
	theme.set_color('font_color', 'DialogicSettingsSection', get_theme_color("property_color_z", "Editor"))
	theme.set_font_size('font_size', 'DialogicSettingsSection', get_theme_font_size("doc_size", "EditorFonts"))

	theme.set_type_variation('DialogicSectionBig', 'DialogicSection')
	theme.set_color('font_color', 'DialogicSectionBig', get_theme_color("accent_color", "Editor"))
	theme.set_font_size('font_size', 'DialogicSectionBig', get_theme_font_size("doc_title_size", "EditorFonts"))

	theme.set_type_variation('DialogicLink', 'LinkButton')
	theme.set_color('font_hover_color', 'DialogicLink', get_theme_color("warning_color", "Editor"))

	theme.set_type_variation('DialogicMegaSeparator', 'HSeparator')
	theme.set_stylebox('separator', 'DialogicMegaSeparator', DCSS.inline({
		'border-radius': 10,
		'border': 0,
		'background': get_theme_color("accent_color", "Editor"),
		'padding': [5, 5],
	}))
	theme.set_constant('separation', 'DialogicMegaSeparator', 50)



	theme.set_icon('Plugin', 'Dialogic', load("res://addons/dialogic/Editor/Images/plugin-icon.svg"))


func godot_file_dialog(callable:Callable, filter:String, mode := EditorFileDialog.FILE_MODE_OPEN_FILE, window_title := "Save", current_file_name := 'New_File', saving_something := false, extra_message:String = "") -> EditorFileDialog:
	for connection in editor_file_dialog.file_selected.get_connections():
		editor_file_dialog.file_selected.disconnect(connection.callable)
	for connection in editor_file_dialog.dir_selected.get_connections():
		editor_file_dialog.dir_selected.disconnect(connection.callable)
	editor_file_dialog.file_mode = mode
	editor_file_dialog.clear_filters()
	editor_file_dialog.popup_centered_ratio(0.6)
	editor_file_dialog.add_filter(filter)
	editor_file_dialog.title = window_title
	editor_file_dialog.current_file = current_file_name
	editor_file_dialog.disable_overwrite_warning = !saving_something
	if extra_message:
		editor_file_dialog.get_meta('info_message_label').show()
		editor_file_dialog.get_meta('info_message_label').text = extra_message
	else:
		editor_file_dialog.get_meta('info_message_label').hide()

	if mode == EditorFileDialog.FILE_MODE_OPEN_FILE or mode == EditorFileDialog.FILE_MODE_SAVE_FILE:
		editor_file_dialog.file_selected.connect(callable)
	elif mode == EditorFileDialog.FILE_MODE_OPEN_DIR:
		editor_file_dialog.dir_selected.connect(callable)
	elif mode == EditorFileDialog.FILE_MODE_OPEN_ANY:
		editor_file_dialog.dir_selected.connect(callable)
		editor_file_dialog.file_selected.connect(callable)
	return editor_file_dialog

