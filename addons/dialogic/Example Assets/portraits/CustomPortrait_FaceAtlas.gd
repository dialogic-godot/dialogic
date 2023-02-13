@tool
extends Node2D

enum Faces {BasedOnPortraitName, Neutral, Happy, Sad, Joy, Shock, Angry}

var portrait

@export var emotion : Faces = Faces.BasedOnPortraitName
@export var portrait_width: int
@export var portrait_height: int
@export var alien = true

var does_custom_portrait_change = true

func _ready():
	$Alien.hide()

# Function to accept and use the extra data, if the custom portrait wants to accept it
func _set_extra_data(data: String) -> void:
	if data == "alien":
		$Alien.show()
	elif data == "no_alien":
		$Alien.hide()

# This function can be overridden. Defaults to true, if not overridden!
func _should_do_portrait_update(character:DialogicCharacter, portrait:String) -> bool:
	return true

# If the custom portrait accepts a change, then accept it here
func _update_portrait(passed_character:DialogicCharacter, passed_portrait:String) -> void:
	for face in $Faces.get_children():
		face.hide()
	if emotion == Faces.BasedOnPortraitName:
		if 'happy' in passed_portrait.to_lower(): $Faces/Smile.show()
		elif 'sad' in passed_portrait.to_lower(): $Faces/Frown.show()
		elif 'joy' in passed_portrait.to_lower(): $Faces/Joy.show()
		elif 'shock' in passed_portrait.to_lower(): $Faces/Shock.show()
		elif 'angry' in passed_portrait.to_lower(): $Faces/Anger.show()
		else: $Faces/Neutral.show()
	else:
		if emotion == Faces.Happy: $Faces/Smile.show()
		elif emotion == Faces.Sad: $Faces/Frown.show()
		elif emotion == Faces.Joy: $Faces/Joy.show()
		elif emotion == Faces.Shock: $Faces/Shock.show()
		elif emotion == Faces.Angry: $Faces/Anger.show()
		else: $Faces/Neutral.show()
	
	$Alien.visible = alien

func _set_mirror(mirror:bool) -> void:
	if mirror: scale.x *= -1

# if implemented, this is used by the editor for the "full view" mode
func _get_covered_rect() -> Rect2:
	#return Rect2($Faces/Anger.position+$Faces.position, $Faces/Anger.get_rect().size*$Faces/Anger.scale*$Faces.scale) #  will fcus on the face
	return Rect2($Body.position, $Body.get_rect().size*$Body.scale)
