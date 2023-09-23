@tool
class_name DialogiClearEvent
extends DialogicEvent

## Event that clears audio & visuals (not variables).
## Useful to make sure the scene is clear for a completely new thing.

var time := 1.0
var step_by_step := true

var clear_portraits := true
var clear_style := true
var clear_music := true
var clear_portrait_positions := true
var clear_background := true

################################################################################
## 						EXECUTE
################################################################################

func _execute() -> void:
	if clear_portraits and dialogic.has_subsystem('Portraits') and len(dialogic.Portraits.get_joined_characters()) != 0:
		if time == 0:
			dialogic.Portraits.leave_all_characters(DialogicUtil.guess_animation_file('Instant In Or Out'), time, step_by_step)
		else:
			dialogic.Portraits.leave_all_characters("", time, step_by_step)
		if step_by_step: await dialogic.get_tree().create_timer(time).timeout
		
	if clear_background and dialogic.has_subsystem('Backgrounds') and dialogic.Backgrounds.has_background():
		dialogic.Backgrounds.update_background('', '', time)
		if step_by_step: await dialogic.get_tree().create_timer(time).timeout
	
	if clear_music and dialogic.has_subsystem('Audio') and dialogic.Audio.has_music():
		dialogic.Audio.update_music('', 0.0, "", time)
		if step_by_step: await dialogic.get_tree().create_timer(time).timeout
	
	if clear_style and dialogic.has_subsystem('Styles'):
		dialogic.Styles.add_layout_style()
	
	if clear_portrait_positions and dialogic.has_subsystem('Portraits'):
		dialogic.Portraits.reset_all_portrait_positions()
	
	finish()


################################################################################
## 						INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Clear"
	set_default_color('Color9')
	event_category = "Other"
	event_sorting_index = 2


################################################################################
## 						SAVING/LOADING
################################################################################

func get_shortcode() -> String:
	return "clear"


func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name : property_info
		"time"		: {"property": "time",	 			"default": ""},
		"step"		: {"property": "step_by_step", 		"default": true},
		"portraits"	: {"property": "clear_portraits", 	"default": true},
		"music"		: {"property": "clear_music", 		"default": true}, 
		"background": {"property": "clear_background", 	"default": true},
		"positions"	: {"property": "clear_portrait_positions", 	"default": true},
		"style"		: {"property": "clear_style", 		"default": true},
	}


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_label('Clear')
	
	add_body_edit('time', ValueType.FLOAT, {'left_text':'Time:'})
	
	add_body_edit('step_by_step', ValueType.BOOL, {'left_text':'Step by Step:'}, 'time > 0')
	add_body_line_break()
	
#	add_body_edit('set_z_index', ValueType.BOOL, {'icon':load("res://addons/dialogic/Modules/Character/update_z_index.svg"), 'tooltip':'Change Z-Index'}, "action == Actions.UPDATE")
	add_body_edit('clear_portraits', ValueType.BOOL, {'left_text':'Clear:', 'icon':load("res://addons/dialogic/Modules/Clear/clear_characters.svg"), 'tooltip':'Clear Portraits'})
	add_body_edit('clear_background', ValueType.BOOL, {'icon':load("res://addons/dialogic/Modules/Clear/clear_background.svg"), 'tooltip':'Clear Background'})
	add_body_edit('clear_music', ValueType.BOOL, {'icon':load("res://addons/dialogic/Modules/Clear/clear_music.svg"), 'tooltip':'Clear Music'})
	add_body_edit('clear_style', ValueType.BOOL, {'icon':load("res://addons/dialogic/Modules/Clear/clear_style.svg"), 'tooltip':'Clear Style'})
	add_body_edit('clear_portrait_positions', ValueType.BOOL, {'icon':load("res://addons/dialogic/Modules/Clear/clear_positions.svg"), 'tooltip':'Clear Portrait Positions'})
