@tool
extends DialogicPortrait

@export_group('Main')
@export_file var image := ""


var unhighlighted_color := Color.DARK_GRAY

## Variables prefixed with `state_` will get copied to the next portrait if it uses the same scene.
var state_highlighted := false
var state_prev_z_index := 0


## Load anything related to the given character and portrait
func _update_portrait(passed_character:DialogicCharacter, passed_portrait:String) -> void:
	apply_character_and_portrait(passed_character, passed_portrait)

	apply_texture($Portrait, image)


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if state_highlighted:
		self.modulate = Color.WHITE
	else:
		self.modulate = unhighlighted_color



func _should_do_portrait_update(_character: DialogicCharacter, _portrait: String) -> bool:
	return false


func _highlight() -> void:
	create_tween().tween_property(self, 'modulate', Color.WHITE, 0.15)
	state_prev_z_index = DialogicUtil.autoload().Portraits.get_character_info(character).get('z_index', 0)
	DialogicUtil.autoload().Portraits.change_character_z_index(character, 99)
	state_highlighted = true


func _unhighlight() -> void:
	create_tween().tween_property(self, 'modulate', unhighlighted_color, 0.15)
	DialogicUtil.autoload().Portraits.change_character_z_index(character, state_prev_z_index)
	state_highlighted = false
