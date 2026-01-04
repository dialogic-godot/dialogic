@tool
class_name DialogicClearEvent
extends DialogicEvent

## Event that clears audio & visuals (not variables).
## Useful to make sure the scene is clear for a completely new thing.

var time := 1.0
var step_by_step := true

var clear_textbox := true
var clear_portraits := true
var clear_style := true
var clear_music := true
var clear_portrait_positions := true
var clear_background := true

#region EXECUTE
################################################################################

func _execute() -> void:
	var final_time := time

	if dialogic.Inputs.auto_skip.enabled:
		var time_per_event: float = dialogic.Inputs.auto_skip.time_per_event
		final_time = min(time, time_per_event)

	if clear_textbox and dialogic.has_subsystem("Text") and dialogic.Text.is_textbox_visible():
		dialogic.Text.update_dialog_text('')
		if step_by_step:
			await dialogic.Text.hide_textbox(final_time == 0)
		else:
			dialogic.Text.hide_textbox(final_time == 0)
		dialogic.current_state = dialogic.States.IDLE

	if clear_portraits and dialogic.has_subsystem('Portraits') and len(dialogic.Portraits.get_joined_characters()) != 0:
		if final_time == 0:
			dialogic.Portraits.leave_all_characters("Instant", final_time, step_by_step)
		else:
			dialogic.Portraits.leave_all_characters("", final_time, step_by_step)
		if step_by_step: await dialogic.get_tree().create_timer(final_time).timeout

	if clear_background and dialogic.has_subsystem('Backgrounds') and dialogic.Backgrounds.has_background():
		dialogic.Backgrounds.update_background('', '', final_time)
		if step_by_step: await dialogic.get_tree().create_timer(final_time).timeout

	if clear_music and dialogic.has_subsystem('Audio'):
		dialogic.Audio.stop_all_one_shot_sounds()
		if dialogic.Audio.is_any_channel_playing():
			dialogic.Audio.stop_all_channels(final_time)
			if step_by_step: await dialogic.get_tree().create_timer(final_time).timeout

	if clear_style and dialogic.has_subsystem('Styles'):
		dialogic.Styles.change_style()

	if clear_portrait_positions and dialogic.has_subsystem('Portraits'):
		dialogic.PortraitContainers.reset_all_containers()

	if not step_by_step:
		await dialogic.get_tree().create_timer(final_time).timeout

	finish()

#endregion


#region INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Clear"
	event_description = "Clears current state like text, background, portraits, style or audio."
	set_default_color('Color9')
	event_category = "Other"
	event_sorting_index = 2

#endregion


#region SAVING/LOADING
################################################################################

func get_shortcode() -> String:
	return "clear"


func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name : property_info
		"time"		: {"property": "time",	 			"default": ""},
		"step"		: {"property": "step_by_step", 		"default": true},
		"text"		: {"property": "clear_textbox",		"default": true},
		"portraits"	: {"property": "clear_portraits", 	"default": true},
		"music"		: {"property": "clear_music", 		"default": true},
		"background": {"property": "clear_background", 	"default": true},
		"positions"	: {"property": "clear_portrait_positions", 	"default": true},
		"style"		: {"property": "clear_style", 		"default": true},
	}

#endregion


#region EDITOR REPRESENTATION
################################################################################

func build_event_editor() -> void:
	add_header_label('Clear')

	add_body_edit('time', ValueType.NUMBER, {'left_text':'Time:'})

	add_body_edit('step_by_step', ValueType.BOOL, {'left_text':'Step by Step:'}, 'time > 0')
	add_body_line_break()

	add_body_edit('clear_textbox', ValueType.BOOL_BUTTON, {'left_text':'Clear:', 'icon':load("res://addons/dialogic/Modules/Clear/clear_textbox.svg"), 'tooltip':'Clear Textbox'})
	add_body_edit('clear_portraits', ValueType.BOOL_BUTTON, {'icon':load("res://addons/dialogic/Modules/Clear/clear_characters.svg"), 'tooltip':'Clear Portraits'})
	add_body_edit('clear_background', ValueType.BOOL_BUTTON, {'icon':load("res://addons/dialogic/Modules/Clear/clear_background.svg"), 'tooltip':'Clear Background'})
	add_body_edit('clear_music', ValueType.BOOL_BUTTON, {'icon':load("res://addons/dialogic/Modules/Clear/clear_music.svg"), 'tooltip':'Clear Audio'})
	add_body_edit('clear_style', ValueType.BOOL_BUTTON, {'icon':load("res://addons/dialogic/Modules/Clear/clear_style.svg"), 'tooltip':'Clear Style'})
	add_body_edit('clear_portrait_positions', ValueType.BOOL_BUTTON, {'icon':load("res://addons/dialogic/Modules/Clear/clear_positions.svg"), 'tooltip':'Clear Portrait Positions'})

#endregion
