@tool
extends DialogicPortrait

enum Faces {BASED_ON_PORTRAIT_NAME, NEUTRAL, HAPPY, SAD, JOY, SHOCK, ANGRY}

@export var emotion : Faces = Faces.BASED_ON_PORTRAIT_NAME
@export var portrait_width: int
@export var portrait_height: int
@export var alien := true

var does_custom_portrait_change := true

func _ready() -> void:
	$Alien.hide()


# Function to accept and use the extra data, if the custom portrait wants to accept it
func _set_extra_data(data: String) -> void:
	if data == "alien":
		$Alien.show()
	elif data == "no_alien":
		$Alien.hide()


# This function can be overridden. Defaults to true, if not overridden!
func _should_do_portrait_update(_character: DialogicCharacter, _portrait:String) -> bool:
	return true


# If the custom portrait accepts a change, then accept it here
func _update_portrait(_passed_character: DialogicCharacter, passed_portrait: String) -> void:
	for face in $Faces.get_children():
		face.hide()

	if emotion == Faces.BASED_ON_PORTRAIT_NAME:
		if 'happy' in passed_portrait.to_lower(): $Faces/Smile.show()
		elif 'sad' in passed_portrait.to_lower(): $Faces/Frown.show()
		elif 'joy' in passed_portrait.to_lower(): $Faces/Joy.show()
		elif 'shock' in passed_portrait.to_lower(): $Faces/Shock.show()
		elif 'angry' in passed_portrait.to_lower(): $Faces/Anger.show()
		else: $Faces/Neutral.show()

	else:
		if emotion == Faces.HAPPY: $Faces/Smile.show()
		elif emotion == Faces.SAD: $Faces/Frown.show()
		elif emotion == Faces.JOY: $Faces/Joy.show()
		elif emotion == Faces.SHOCK: $Faces/Shock.show()
		elif emotion == Faces.ANGRY: $Faces/Anger.show()
		else: $Faces/Neutral.show()

	$Alien.visible = alien


func _set_mirror(is_mirrored: bool) -> void:
	if is_mirrored:
		self.scale.x = -1

	else:
		self.scale.x = 1


## If implemented, this is used by the editor for the "full view" mode
func _get_covered_rect() -> Rect2:
	# This will focus on the face.
	# return Rect2($Faces/Anger.position+$Faces.position, $Faces/Anger.get_rect().size*$Faces/Anger.scale*$Faces.scale)
	var size: Vector2 = $Body.get_rect().size
	var scaled_size: Vector2 = size * $Body.scale
	var position: Vector2 = $Body.position

	return Rect2(position, scaled_size)
