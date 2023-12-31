@tool
extends DialogicLayoutLayer

## Example scene for viewing the History
## Implements most of the visual options from 1.x History mode

@export_group('Look')
@export_subgroup('Font')
@export var font_use_global_size := true
@export var font_custom_size : int = 15
@export var font_use_global_fonts := true
@export_file('*.ttf') var font_custom_normal := ""
@export_file('*.ttf') var font_custom_bold := ""
@export_file('*.ttf') var font_custom_italics := ""

@export_subgroup('Buttons')
@export var show_open_button: bool = true
@export var show_close_button: bool = true

@export_group('Settings')
@export_subgroup('Events')
@export var show_all_choices: bool = true
@export var show_join_and_leave: bool = true

@export_subgroup('Behaviour')
@export var scroll_to_bottom: bool = true
@export var show_name_colors: bool = true
@export var name_delimeter: String = ": "

var scroll_to_bottom_flag: bool = false

@export_group('Private')
@export var HistoryItem: PackedScene = null

var history_item_theme : Theme = null


func _ready() -> void:
	if Engine.is_editor_hint():
		return


func _apply_export_overrides() -> void:
	if DialogicUtil.autoload().has_subsystem('History'):
		$ShowHistory.visible = show_open_button and DialogicUtil.autoload().History.simple_history_enabled
	else:
		self.visible = false

	history_item_theme = Theme.new()

	if font_use_global_size:
		history_item_theme.default_font_size = get_global_setting('font_size', font_custom_size)
	else:
		history_item_theme.default_font_size = font_custom_size

	if font_use_global_fonts and ResourceLoader.exists(get_global_setting('font', '')):
		history_item_theme.default_font = load(get_global_setting('font', ''))
	elif ResourceLoader.exists(font_custom_normal):
		history_item_theme.default_font = load(font_custom_normal)

	if ResourceLoader.exists(font_custom_bold):
		history_item_theme.set_font('RichtTextLabel', 'bold_font', load(font_custom_bold))
	if ResourceLoader.exists(font_custom_italics):
		history_item_theme.set_font('RichtTextLabel', 'italics_font', load(font_custom_italics))



func _process(delta):
	if Engine.is_editor_hint():
		return
	if scroll_to_bottom_flag and $HistoryBox.visible and %HistoryLog.get_child_count():
		await get_tree().process_frame
		%HistoryBox.ensure_control_visible(%HistoryLog.get_children()[-1])
		scroll_to_bottom_flag = false


func _on_show_history_pressed():
	DialogicUtil.autoload().paused = true
	show_history()


func show_history() -> void:
	for child in %HistoryLog.get_children():
		child.queue_free()

	for info in DialogicUtil.autoload().History.get_simple_history():
		var history_item = HistoryItem.instantiate()
		history_item.theme = history_item_theme
		match info.event_type:
			"Text":
				if info.has('character') and info['character']:
					if show_name_colors:
						history_item.load_info(info['text'], info['character']+name_delimeter, info['character_color'])
					else:
						history_item.load_info(info['text'], info['character']+name_delimeter)
				else:
					history_item.load_info(info['text'])
			"Character":
				if !show_join_and_leave:
					history_item.queue_free()
					continue
				history_item.load_info('[i]'+info['text'])
			"Choice":
				var choices_text := ""
				if show_all_choices:
					for i in info['all_choices']:
						if i.ends_with('#disabled'):
							choices_text += "-  [i]("+i.trim_suffix('#disabled')+")[/i]\n"
						elif i == info['text']:
							choices_text += "-> [b]"+i+"[/b]\n"
						else:
							choices_text += "-> "+i+"\n"
				else:
					choices_text += "- [b]"+info['text']+"[/b]\n"
				history_item.load_info(choices_text)

		%HistoryLog.add_child(history_item)

	if scroll_to_bottom:
		scroll_to_bottom_flag = true

	$ShowHistory.hide()
	$HideHistory.visible = show_close_button
	%HistoryBox.show()


func _on_hide_history_pressed():
	DialogicUtil.autoload().paused = false
	%HistoryBox.hide()
	$HideHistory.hide()
	$ShowHistory.visible = show_open_button and DialogicUtil.autoload().History.simple_history_enabled
