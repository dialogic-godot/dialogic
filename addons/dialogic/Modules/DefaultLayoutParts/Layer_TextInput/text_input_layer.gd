@tool
extends DialogicLayoutLayer

## A layer that contains a text-input node.


func _apply_export_overrides() -> void:
	var layer_theme: Theme = get(&'theme')
	if layer_theme == null:
		layer_theme = Theme.new()

	if get_global_setting(&'font', ''):
		layer_theme.default_font = load(get_global_setting(&'font', '') as String)
	layer_theme.default_font_size = get_global_setting(&'font_size', 0)
