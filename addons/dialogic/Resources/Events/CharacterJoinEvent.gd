tool
extends DialogicEventResource
class_name DialogicCharacterJoinEvent

#const PortraitScene = preload("res://addons/dialogic/Nodes/Portrait.tscn")

export(Resource) var character = null
export(int) var selected_portrait = 0

func excecute(caller) -> void:
	.excecute(caller)
	
	if not character or not character.name:
		finish()
		return
	
	# TODO: Haz esto de nuevo, con efectos.
	# Tambien cambia el lugar donde se guardan los
	# recuadros
	var p := TextureRect.new()
	p.texture = character.portraits[0].image
	p.name = (character as DialogicCharacterResource).name
	caller.PortraitsNode.add_child(p)
	finish()
