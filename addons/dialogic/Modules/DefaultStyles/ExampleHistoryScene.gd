extends Control

## Example scene for viewing the History
## Implements most of the visual options from 1.x History mode
@export_group('Open &Close Button')
@export var show_open_button: bool = true
@export var show_close_button: bool = true

@export_group('Event visibility')
@export var show_all_choices: bool = true
@export var show_join_and_leave: bool = true

@export_group('Presentation')
@export var scroll_to_bottom: bool = true
@export var show_name_colors: bool = true
@export var name_delimeter: String = ": "

@export_group('Fonts')
@export var history_font_size: int
@export var history_font_normal: Font
@export var history_font_bold: Font
@export var history_font_italics: Font

var scroll_to_bottom_flag: bool = false


func _ready():
	if Dialogic.has_subsystem('History'):
		$ShowHistory.visible = show_open_button and Dialogic.History.simple_history_enabled
	else: 
		self.visible = false


func _process(delta):
	if scroll_to_bottom_flag and $HistoryBox.visible and %HistoryLog.get_child_count():
		await get_tree().process_frame
		%HistoryBox.ensure_control_visible(%HistoryLog.get_children()[-1])
		scroll_to_bottom_flag = false


func _on_show_history_pressed():
	Dialogic.paused = true
	show_history()


func show_history() -> void:
	for child in %HistoryLog.get_children():
		child.queue_free()
	
	for info in Dialogic.History.get_simple_history():
		var history_item :Control= load(DialogicUtil.get_module_path('DefaultStyles').path_join("ExampleHistoryItem.tscn")).instantiate()
		history_item.prepare_textbox(self)
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
	Dialogic.paused = false
	%HistoryBox.hide()
	$HideHistory.hide()
	$ShowHistory.visible = show_open_button and Dialogic.History.simple_history_enabled
