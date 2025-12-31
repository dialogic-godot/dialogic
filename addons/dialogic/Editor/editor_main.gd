@tool
extends Control

## Editor root node. Most editor functionality is handled by EditorsManager node!

var plugin_reference: EditorPlugin = null
var editors_manager: Control = null

var editor_file_dialog: EditorFileDialog

@onready var sidebar := %Sidebar as DialogicSidebar

func _ready() -> void:
	if get_parent() is SubViewport:
		return

	## CONNECTIONS
	sidebar.show_sidebar.connect(_on_sidebar_toggled)

	## REFERENCES
	editors_manager = $EditorsManager
	var button: Button = editors_manager.add_button(
		get_theme_icon("MakeFloating", "EditorIcons"), 
		"",
		"Make the dialogic editor floating.",
		null,
		editors_manager.ButtonPlacement.TOOLBAR_MAIN
	)
	button.pressed.connect(toggle_floating_window)

	# File dialog
	editor_file_dialog = EditorFileDialog.new()
	add_child(editor_file_dialog)

	var info_message := Label.new()
	info_message.add_theme_color_override("font_color", get_theme_color("warning_color", "Editor"))
	editor_file_dialog.get_line_edit().get_parent().add_sibling(info_message)
	info_message.get_parent().move_child(info_message, info_message.get_index() - 1)
	editor_file_dialog.set_meta("info_message_label", info_message)

	$SaveConfirmationDialog.add_button("No Saving Please!", true, "nosave")
	$SaveConfirmationDialog.hide()
	update_theme_additions()
	EditorInterface.get_base_control().theme_changed.connect(update_theme_additions)


func _on_sidebar_toggled(sidebar_shown: bool) -> void:
	var h_split := (%HSplit as HSplitContainer)
	if sidebar_shown:
		h_split.dragger_visibility = SplitContainer.DRAGGER_VISIBLE
		h_split.split_offset = 150
		h_split.collapsed = false
	else:
		h_split.dragger_visibility = SplitContainer.DRAGGER_HIDDEN_COLLAPSED
		h_split.split_offset = 0
		h_split.collapsed = true


func update_theme_additions() -> void:
	var scale := DialogicUtil.get_editor_scale()
	add_theme_stylebox_override("panel", DCSS.inline({
		"background": get_theme_color("base_color", "Editor"),
		"padding":
		[5 * scale, 5 * scale],
		}))
	var holder_panel := (DCSS.inline({
		"border-radius": 5,
		"background": get_theme_color("dark_color_2", "Editor"),
		"padding":
		[5 * scale, 5 * scale],
		}))

	holder_panel.border_width_top = 0
	holder_panel.corner_radius_top_left = 0
	editors_manager.editors_holder.add_theme_stylebox_override("panel", holder_panel)

	var new_theme := Theme.new()

	new_theme.set_type_variation("DialogicTitle", "Label")
	new_theme.set_font("font", "DialogicTitle", get_theme_font("title", "EditorFonts"))
	new_theme.set_color("font_color", "DialogicTitle", get_theme_color("warning_color", "Editor"))
	new_theme.set_color(
		"font_uneditable_color", "DialogicTitle", get_theme_color("warning_color", "Editor")
	)
	new_theme.set_color(
		"font_selected_color", "DialogicTitle", get_theme_color("warning_color", "Editor")
	)
	new_theme.set_font_size(
		"font_size", "DialogicTitle", get_theme_font_size("doc_size", "EditorFonts")
	)

	new_theme.set_type_variation("DialogicSubTitle", "Label")
	new_theme.set_font("font", "DialogicSubTitle", get_theme_font("title", "EditorFonts"))
	new_theme.set_font_size(
		"font_size", "DialogicSubTitle", get_theme_font_size("doc_size", "EditorFonts")
	)
	new_theme.set_color("font_color", "DialogicSubTitle", get_theme_color("accent_color", "Editor"))

	new_theme.set_type_variation("DialogicPanelA", "PanelContainer")
	var panel_style := (
		DCSS
		. inline(
			{
				"border-radius": 10,
				"background": get_theme_color("base_color", "Editor"),
				"padding": [5, 5],
			}
		)
	)
	new_theme.set_stylebox("panel", "DialogicPanelA", panel_style)
	new_theme.set_stylebox("normal", "DialogicPanelA", panel_style)

	var dark_panel := panel_style.duplicate()
	dark_panel.bg_color = get_theme_color("dark_color_3", "Editor")
	new_theme.set_stylebox("panel", "DialogicPanelDarkA", dark_panel)

	var cornerless_panel := panel_style.duplicate()
	cornerless_panel.corner_radius_top_left = 0
	new_theme.set_stylebox("panel", "DialogicPanelA_cornerless", cornerless_panel)

	# panel used for example for portrait previews in character editor
	new_theme.set_type_variation("DialogicPanelB", "PanelContainer")
	var side_panel: StyleBoxFlat = panel_style.duplicate()
	side_panel.corner_radius_top_left = 0
	side_panel.corner_radius_bottom_left = 0
	side_panel.expand_margin_left = get_theme_constant("separation", "SplitContainer")
	side_panel.bg_color = get_theme_color("dark_color_2", "Editor")
	side_panel.set_border_width_all(1)
	side_panel.border_width_left = 0
	side_panel.content_margin_left = 0
	side_panel.border_color = get_theme_color("contrast_color_2", "Editor")
	new_theme.set_stylebox("panel", "DialogicPanelB", side_panel)

	new_theme.set_type_variation("DialogicTabs", "TabBar")
	new_theme.set_color("icon_selected_color", "DialogicTabs", get_theme_color("accent_color", "Editor"))
	var selected_tab: StyleBoxFlat = get_theme_stylebox("tab_selected", "TabBar").duplicate()
	selected_tab.bg_color = get_theme_color("background", "Editor")
	new_theme.set_stylebox("tab_selected", "DialogicTabs", selected_tab)
	var unselected_tab: StyleBoxFlat = get_theme_stylebox("tab_unselected", "TabBar").duplicate()
	unselected_tab.bg_color = get_theme_color("disabled_bg_color", "Editor")
	new_theme.set_stylebox("tab_unselected", "DialogicTabs", unselected_tab)

	new_theme.set_type_variation("DialogicSidebarList", "ItemList")
	var stylebox: StyleBoxFlat = get_theme_stylebox("panel", "ItemList").duplicate()
	stylebox.bg_color = get_theme_color("disabled_bg_color", "Editor")
	new_theme.set_stylebox("panel", "DialogicSidebarList", stylebox)

	new_theme.set_type_variation("DialogicSidebarTree", "Tree")
	new_theme.set_stylebox("panel", "DialogicSidebarTree", stylebox)

	new_theme.set_type_variation("DialogicEventEdit", "Control")
	var edit_panel := StyleBoxFlat.new()
	edit_panel.draw_center = true
	edit_panel.bg_color = get_theme_color("accent_color", "Editor")
	edit_panel.bg_color.a = 0.05
	edit_panel.border_width_bottom = 2
	edit_panel.border_color = get_theme_color("accent_color", "Editor").lerp(
		get_theme_color("dark_color_2", "Editor"), 0.4
	)
	edit_panel.content_margin_left = 5
	edit_panel.content_margin_right = 5
	edit_panel.set_corner_radius_all(1)
	new_theme.set_stylebox("panel", "DialogicEventEdit", edit_panel)
	new_theme.set_stylebox("normal", "DialogicEventEdit", edit_panel)

	var focus_edit := edit_panel.duplicate()
	focus_edit.border_color = get_theme_color("property_color_z", "Editor")
	focus_edit.draw_center = false
	new_theme.set_stylebox("focus", "DialogicEventEdit", focus_edit)

	var hover_edit := edit_panel.duplicate()
	hover_edit.border_color = get_theme_color("warning_color", "Editor")

	new_theme.set_stylebox("hover", "DialogicEventEdit", hover_edit)
	var disabled_edit := edit_panel.duplicate()
	disabled_edit.border_color = get_theme_color("property_color", "Editor")
	new_theme.set_stylebox("disabled", "DialogicEventEdit", disabled_edit)

	new_theme.set_type_variation("DialogicHintText", "Label")
	new_theme.set_color("font_color", "DialogicHintText", get_theme_color("readonly_color", "Editor"))
	new_theme.set_font("font", "DialogicHintText", get_theme_font("doc_italic", "EditorFonts"))

	new_theme.set_type_variation("DialogicHintText2", "Label")
	new_theme.set_color(
		"font_color", "DialogicHintText2", get_theme_color("property_color_w", "Editor")
	)
	new_theme.set_font("font", "DialogicHintText2", get_theme_font("doc_italic", "EditorFonts"))

	new_theme.set_type_variation("DialogicSection", "Label")
	new_theme.set_font("font", "DialogicSection", get_theme_font("main_msdf", "EditorFonts"))
	new_theme.set_color("font_color", "DialogicSection", get_theme_color("property_color_z", "Editor"))
	new_theme.set_font_size(
		"font_size", "DialogicSection", get_theme_font_size("doc_size", "EditorFonts")
	)

	new_theme.set_type_variation("DialogicSettingsSection", "DialogicSection")
	new_theme.set_font("font", "DialogicSettingsSection", get_theme_font("main_msdf", "EditorFonts"))
	new_theme.set_color(
		"font_color", "DialogicSettingsSection", get_theme_color("property_color_z", "Editor")
	)
	new_theme.set_font_size(
		"font_size", "DialogicSettingsSection", get_theme_font_size("doc_size", "EditorFonts")
	)

	new_theme.set_type_variation("DialogicSectionBig", "DialogicSection")
	new_theme.set_color("font_color", "DialogicSectionBig", get_theme_color("accent_color", "Editor"))
	new_theme.set_font_size(
		"font_size", "DialogicSectionBig", get_theme_font_size("doc_title_size", "EditorFonts")
	)

	new_theme.set_type_variation("DialogicLink", "LinkButton")
	new_theme.set_color("font_hover_color", "DialogicLink", get_theme_color("warning_color", "Editor"))

	new_theme.set_type_variation("DialogicMegaSeparator", "HSeparator")
	new_theme.set_stylebox("separator", "DialogicMegaSeparator",
				DCSS.inline({
						"border-radius": 10,
						"border": 0,
						"background": get_theme_color("accent_color", "Editor"),
						"padding": [5, 5],
					})
				)
	new_theme.set_constant("separation", "DialogicMegaSeparator", 50)

	new_theme.set_type_variation("DialogicTextEventTextEdit", "CodeEdit")
	var editor_settings := EditorInterface.get_editor_settings()
	var text_panel := DCSS.inline({
				"border-radius": 8,
				"background":
				editor_settings.get_setting("text_editor/theme/highlighting/background_color").lerp(
					editor_settings.get_setting("text_editor/theme/highlighting/text_color"), 0.05
				),
				"padding": [8, 8],
			})
	text_panel.content_margin_bottom = 5
	text_panel.content_margin_left = 13
	new_theme.set_stylebox("normal", "DialogicTextEventTextEdit", text_panel)

	var event_field_group_panel := DCSS.inline({
		'border-radius': 8,
		"border":1,
		"padding":2,
		"boder-color": get_theme_color("property_color", "Editor"),
		"background":"none"})
	new_theme.set_type_variation("DialogicEventEditGroup", "PanelContainer")
	new_theme.set_stylebox("panel", "DialogicEventEditGroup", event_field_group_panel)

	new_theme.set_icon('Plugin', 'Dialogic', load("res://addons/dialogic/Editor/Images/plugin-icon.svg"))

	theme = new_theme


## Switches from floating window mode to embedded mode based on current mode
func toggle_floating_window() -> void:
	if get_parent() is Window:
		swap_to_embedded_editor()
	else:
		swap_to_floating_window()


## Removes the main control from it's parent and adds it to a new Window node
func swap_to_floating_window() -> void:
	if get_parent() is Window:
		return

	var parent := get_parent()
	get_parent().remove_child(self)
	var window := Window.new()
	parent.add_child(window)
	window.add_child(self)
	window.title = "Dialogic"
	window.close_requested.connect(swap_to_embedded_editor)
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	window.size = size
	window.min_size = Vector2(500, 500)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	window.disable_3d = true
	window.wrap_controls = true
	window.popup_centered()
	EditorInterface.set_main_screen_editor("2D")


## Removes the main control from the window node and adds it to it's grandparent
##  which is the original owner.
func swap_to_embedded_editor() -> void:
	if not get_parent() is Window:
		return

	var window := get_parent()
	get_parent().remove_child(self)
	EditorInterface.set_main_screen_editor("Dialogic")
	window.get_parent().add_child(self)
	window.queue_free()


func godot_file_dialog(
		callable: Callable, filter: String, mode := EditorFileDialog.FILE_MODE_OPEN_FILE,
		window_title := "Save",
		current_file_name := "New_File",
		saving_something := false,
		extra_message: String = ""
		) -> EditorFileDialog:

	for connection in editor_file_dialog.file_selected.get_connections():
		editor_file_dialog.file_selected.disconnect(connection.callable)
	for connection in editor_file_dialog.files_selected.get_connections():
		editor_file_dialog.files_selected.disconnect(connection.callable)
	for connection in editor_file_dialog.dir_selected.get_connections():
		editor_file_dialog.dir_selected.disconnect(connection.callable)

	if mode == EditorFileDialog.FILE_MODE_OPEN_FILE or mode == EditorFileDialog.FILE_MODE_SAVE_FILE:
		editor_file_dialog.file_selected.connect(callable)
	elif mode == EditorFileDialog.FILE_MODE_OPEN_FILES:
		editor_file_dialog.files_selected.connect(callable)
	elif mode == EditorFileDialog.FILE_MODE_OPEN_DIR:
		editor_file_dialog.dir_selected.connect(callable)
	elif mode == EditorFileDialog.FILE_MODE_OPEN_ANY:
		editor_file_dialog.dir_selected.connect(callable)
		editor_file_dialog.file_selected.connect(callable)

	editor_file_dialog.file_mode = mode
	editor_file_dialog.clear_filters()
	editor_file_dialog.add_filter(filter)
	editor_file_dialog.title = window_title
	editor_file_dialog.current_file = current_file_name
	editor_file_dialog.disable_overwrite_warning = !saving_something
	if extra_message:
		editor_file_dialog.get_meta("info_message_label").show()
		editor_file_dialog.get_meta("info_message_label").text = extra_message
	else:
		editor_file_dialog.get_meta("info_message_label").hide()
	editor_file_dialog.popup_centered_ratio(0.6)


	return editor_file_dialog
