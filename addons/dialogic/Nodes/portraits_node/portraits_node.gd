class_name DialogicPortraitManager
extends Control

signal portrait_added(character)

enum PAnimation {
	NO_ANIMATION,
	APPEAR,
	DISAPPEAR,
	FADE_IN, 
	FADE_OUT,
	}

enum Position {
	CENTER,
	CENTER_LEFT,
	CENTER_RIGHT,
	LEFT,
	RIGHT,
	}

export(NodePath) var LeftNode_path:NodePath
export(NodePath) var CenterLeftNode_path:NodePath
export(NodePath) var CenterNode_path:NodePath
export(NodePath) var CenterRightNode_path:NodePath
export(NodePath) var RightNode_path:NodePath

# {CharacterResource: PortraitNode(TextureRect)}
var portraits:Dictionary = {}

onready var _tween = get_node("Tween")
onready var _left_node = get_node_or_null(LeftNode_path)
onready var _right_node = get_node_or_null(RightNode_path)
onready var _center_node = get_node(CenterNode_path)
onready var _center_left_node = get_node_or_null(CenterLeftNode_path)
onready var _center_right_node = get_node_or_null(CenterRightNode_path)

func add_portrait(
	character_resource:DialogicCharacterResource, 
	portrait:DialogicPortraitResource, 
	position=Position.CENTER,
	animation=PAnimation.NO_ANIMATION,
	get_focus=true
	) -> void:
	
	if not character_resource and not portrait:
		emit_signal("portrait_added")
		return
	
	var _ptrt_node:Control = portraits.get(character_resource, null)
	
	if _ptrt_node:
		remove_portrait(_ptrt_node)
	
	if portrait.image is Texture:
		_ptrt_node = TextureRect.new()
		_ptrt_node.texture = portrait.image
		portraits[character_resource] = _ptrt_node
		add_child(_ptrt_node)
		# Here you can expand to accept scenes
	
	animation = PAnimation.FADE_IN if animation == PAnimation.NO_ANIMATION else animation
	
	match position:
		Position.CENTER:
			_ptrt_node.rect_position = _center_node.rect_position
		
		Position.CENTER_LEFT:
			_ptrt_node.rect_position = _center_left_node.rect_position
		
		Position.CENTER_RIGHT:
			_ptrt_node.rect_position = _center_right_node.rect_position
		
		Position.LEFT:
			_ptrt_node.rect_position = _left_node.rect_position
		
		Position.RIGHT:
			_ptrt_node.rect_position = _right_node.rect_position
		
	
	grab_portrait_focus(_ptrt_node, animation)
	yield(_tween, "tween_all_completed")
	emit_signal("portrait_added")


func remove_portrait(portrait_node) -> void:
	pass


func grab_portrait_focus(char_portrait_node:TextureRect, animation):
	match animation:
		PAnimation.FADE_IN:
			_tween.node_fade_in(char_portrait_node)
			_tween.start()
		_:
			pass
	# wait
	pass
