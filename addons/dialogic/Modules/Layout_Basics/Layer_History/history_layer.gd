@tool
extends DialogicLayoutLayer

## Example scene for viewing the History
## Implements most of the visual options from 1.x History mode

@export var show_all_choices: bool = true
@export var show_join_and_leave: bool = true

@export var scroll_to_bottom_on_open: bool = true
@export var show_name_colors: bool = true

var scroll_to_bottom_flag: bool = false
#
#@export_group('Private')
#@export var HistoryItem: PackedScene = null
#
#var history_item_theme: Theme = null

@onready var base_history_item := %BaseHistoryItem
#
#func get_show_history_button() -> Button:
	#return $ShowHistory
#
#
#func get_hide_history_button() -> Button:
	#return $HideHistory
#
#
#func get_history_box() -> ScrollContainer:
	#return %HistoryBox
#

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	base_history_item.get_parent().remove_child(base_history_item)

	Dialogic.History.open_requested.connect(_on_show_history_pressed)
	Dialogic.History.close_requested.connect(_on_hide_history_pressed)

	close_history()

	%ShowHistory.visible = Dialogic.has_subsystem("History") and Dialogic.History.simple_history_enabled
#
#
#func _apply_export_overrides() -> void:
	#
	#history_item_theme = Theme.new()
#
	#if font_use_global_size:
		#history_item_theme.default_font_size = get_global_setting(&'font_size', font_custom_size)
	#else:
		#history_item_theme.default_font_size = font_custom_size
#
	#if font_use_global_fonts and ResourceLoader.exists(get_global_setting(&'font', '') as String):
		#history_item_theme.default_font = load(get_global_setting(&'font', '') as String) as Font
	#elif ResourceLoader.exists(font_custom_normal):
		#history_item_theme.default_font = load(font_custom_normal)
#
	#if ResourceLoader.exists(font_custom_bold):
		#history_item_theme.set_font(&'RichtTextLabel', &'bold_font', load(font_custom_bold) as Font)
	#if ResourceLoader.exists(font_custom_italics):
		#history_item_theme.set_font(&'RichtTextLabel', &'italics_font', load(font_custom_italics) as Font)




func _on_show_history_pressed() -> void:
	Dialogic.paused = true
	show_history()


func _on_hide_history_pressed() -> void:
	Dialogic.paused = false
	close_history()


func close_history() -> void:
	%HistoryBox.hide()
	%HideHistory.hide()
	%ShowHistory.show()
	#var history_subsystem: Node = DialogicUtil.autoload().get(&'History')
	##get_show_history_button().visible = show_open_button and history_subsystem.get(&'simple_history_enabled')



func show_history() -> void:
	## Reload history by removing it all and rebuilding it

	## Remove all loaded history logs
	for child: Node in %HistoryLog.get_children():
		child.queue_free()

	for info: Dictionary in Dialogic.History.get_simple_history():
		var log_text := ""
		match info.event_type:
			"Text":
				if info.get("character", ""):
					if show_name_colors:
						log_text = "[color={character_color_html}]{character}[/color]: {text}".format(info)
					else:
						log_text = "{character}: {text}".format(info)
				else:
					log_text = info.text
			"Character":
				if show_join_and_leave:
					log_text = "[i]"+info.text
			"Choice":
				if show_all_choices:
					for i: String in info.all_choices:
						if i.ends_with('#disabled'):
							log_text += "🡒  [i]({0})[/i]\n".format([i.trim_suffix('#disabled')])
						elif i == info['text']:
							log_text += "🡒 [b]{0}[/b]\n".format([i])
						else:
							log_text += "🡒 {0}\n".format([i])
				else:
					log_text = "- [b]{0}[/b]\n".format([info.text])
			_:
				log_text = info.text

		if log_text:
			var log_item: RichTextLabel = base_history_item.duplicate()
			log_item.text = log_text
			%HistoryLog.add_child(log_item)

	if scroll_to_bottom_on_open:
		%Scroll.ensure_control_visible(%HistoryLog.get_children()[-1] as Control)

	%ShowHistory.hide()
	%HistoryBox.show()
	%HideHistory.show()


func _process(_delta : float) -> void:
	if Engine.is_editor_hint():
		return

	### Make sure we are scrolled to the bottom.
	#if scroll_to_bottom_flag and %HistoryBox.visible and %HistoryLog.get_child_count():
		#await get_tree().process_frame
#
		#scroll_to_bottom_flag = false
