@tool
extends DialogicLayoutLayer

## A layer that contains a text-input node.


func _apply_export_overrides():
	if self.theme == null:
		self.theme = Theme.new()

	if get_global_setting('font', ''):
		self.theme.default_font = load(get_global_setting('font', ''))
	self.theme.default_font_size = get_global_setting('font_size', 0)
