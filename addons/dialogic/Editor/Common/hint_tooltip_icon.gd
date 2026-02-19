@tool
extends TextureRect

@export_multiline var hint_text := ""

var hint_popup: Popup = null

var mouse_on_popup := false

func _ready() -> void:
	if owner and owner.get_parent() is SubViewport or get_parent() is SubViewport:
		texture = null
		return

	texture = get_theme_icon("NodeInfo", "EditorIcons")
	modulate = get_theme_color("contrast_color_1", "Editor")

	var tooltip_box := StyleBoxFlat.new()
	tooltip_box.bg_color = get_theme_color("background", "Editor")
	tooltip_box.set_border_width_all(1)
	tooltip_box.border_color = get_theme_color("font_color", "Editor")
	tooltip_box.border_width_left = 5 * int(DialogicUtil.get_editor_scale())
	theme.set_stylebox("panel", "TooltipPanel", tooltip_box)



func _on_mouse_entered() -> void:
	if not hint_popup:
		hint_popup = create_popup()

	#hint_popup.position =
	hint_popup.popup_on_parent(Rect2(get_global_mouse_position(), hint_popup.get_contents_minimum_size()))
	#set_process_input(true)
#
#
#func _input(event:InputEvent) -> void:
	#if not hint_popup:
		#return
#
	#if event is InputEventMouseMotion:
		#check_close()


func check_close() -> void:
	if not (get_global_rect().has_point(get_global_mouse_position()) or mouse_on_popup):
		close()


func close() -> void:
	hint_popup.queue_free()
	hint_popup = null


func create_popup() -> Popup:
	var popup := PopupPanel.new()
	popup.transient
	popup.handle_input_locally = false
	popup.theme_type_variation = "TooltipPanel"

	var rtl := RichTextLabel.new()
	var text := ""
	if hint_text.begins_with("#") and "\n" in hint_text:
		text = "[b]{0}[/b]\n{1}".format(Array(hint_text.trim_prefix("#").split("\n", false, 1)))
		text = text.replace("[code]", "[color={code_color}][code]")
		text = text.replace("[/code]", "[/code][/color]")
		text = text.replace("\\n", "\n")
		text = text.format({"code_color":get_theme_color("accent_color", "Editor").to_html()})
	else:
		text = hint_text
	rtl.text = text
	rtl.fit_content = true
	rtl.bbcode_enabled = true

	rtl.custom_minimum_size.x = 500 * DialogicUtil.get_editor_scale()
	rtl.meta_clicked.connect(_on_meta_clicked)
	popup.add_child(rtl)
	popup.mouse_entered.connect(_on_popup_mouse_entered)
	popup.mouse_exited.connect(_on_popup_mouse_exited)
	var timer := Timer.new()
	timer.autostart = true
	timer.one_shot = false
	timer.timeout.connect(check_close)
	popup.add_child(timer)
	add_child(popup)
	return popup


func _on_popup_mouse_entered() -> void:
	mouse_on_popup = true


func _on_popup_mouse_exited() -> void:
	mouse_on_popup = false
	close()


func _on_meta_clicked(url:=""):
	if url.begins_with("http"):
		OS.shell_open(url)
