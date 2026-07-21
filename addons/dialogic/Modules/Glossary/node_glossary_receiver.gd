@icon("node_glossary_receiver_icon.svg")
class_name DialogicNode_GlossaryReceiver
extends Node


## Assign the node that should get shown and hidden when a glossary is hovered.
@export_node_path("Control") var glossary_holder := NodePath()

@export var move_holder_to_mouse_pos_on_show := true
@export var keep_holder_at_mouse_pos := true

## Assign nodes that have a text property, e.g. Label or RichtTextLabel
@export var text_nodes: Dictionary[String, NodePath] = {
	"title": NodePath(),
	"text": NodePath(),
	"extra": NodePath(),
}

## Assign any node that should be self_modulated by the hovered entries color.
@export var modulate_nodes: Array[NodePath] = []

signal glossary_hovered(entry_info:Dictionary)


func _ready() -> void:
	var text_system: Node = DialogicUtil.autoload().get(&'Text')
	text_system.connect(&'meta_hover_started', _on_meta_hover_started)
	text_system.connect(&'meta_hover_ended', _on_meta_hover_ended)

	if has_node(glossary_holder):
		get_node(glossary_holder).hide()



func _on_meta_hover_started(meta:String) -> void:
	if has_node(glossary_holder):
		get_node(glossary_holder).show()
		if move_holder_to_mouse_pos_on_show:
			get_node(glossary_holder).global_position = get_node(glossary_holder).get_global_mouse_position()


	var entry_info := DialogicUtil.autoload().Glossary.get_entry(meta)

	if entry_info.is_empty():
		return

	for i in entry_info.keys():
		if i in text_nodes:
			get_node(text_nodes[i]).text = entry_info[i]

	for i in modulate_nodes:
		if "self_modulate" in get_node(i):
			get_node(i).self_modulate = entry_info.color

	glossary_hovered.emit(entry_info)


func _on_meta_hover_ended(_meta:String) -> void:
	if has_node(glossary_holder):
		get_node(glossary_holder).hide()



## Method that keeps the holder at mouse position when visible
func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if has_node(glossary_holder) and keep_holder_at_mouse_pos:
		get_node(glossary_holder).global_position = get_node(glossary_holder).get_global_mouse_position()
