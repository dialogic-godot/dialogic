@tool
class_name DialogicRichTextTransitionEffect
extends RichTextEffect

var visible_characters := -1

@export var bbcode := "animate_in"
var cache := []

@export_range(0.0, 5.0, 0.01) var time := 0.2
@export_group("Color", "color")
@export var color_modulate: Gradient = null
@export var color_replace: Gradient = null
@export_group("Scale", "scale")
@export var scale_enabled := false
@export var scale_curve := Curve.new()
@export var scale_pivot := Vector2()
@export_group("Position", "position")
@export var position_enabled := false
@export var position_x_curve := Curve.new()
@export var position_y_curve := Curve.new()

@export_group("Test", "test")
@export_range(-0.1, 1.0, 0.1) var test_value := -0.1

var was_skipped := false
var was_reset := false


func reset() -> void:
	was_reset = true
	was_skipped = false
	cache.clear()


func skip() -> void:
	was_skipped = true


func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var char_age :float = 0.0
	if test_value >= 0:
		char_age = test_value

	else:
		if visible_characters == 0:
			cache.clear()
			return false
		if was_reset:
			if visible_characters != -1:
				was_reset = false
			else:
				return false

		if len(cache) < visible_characters or visible_characters == -1 or was_skipped:
			if char_fx.range.x >= len(cache):
				cache.append(char_fx.elapsed_time)

		if was_skipped:
			for i in range(len(cache)):
				cache[i] = char_fx.elapsed_time-time

		if len(cache) > char_fx.range.x:
			char_age = char_fx.elapsed_time - cache[char_fx.range.x]

	var text_server := TextServerManager.get_primary_interface()
	var trans: float = clamp(char_age, 0.0, time)/time

	if color_replace:
		var c := color_replace.sample(trans)
		c.a = 1
		char_fx.color = char_fx.color.lerp(c, color_replace.sample(trans).a)
	if color_modulate:
		char_fx.color *= color_modulate.sample(trans)
	if char_fx.font.is_valid():
		var glyph_size := text_server.font_get_glyph_size(char_fx.font, Vector2i(16,1), char_fx.glyph_index)
		if scale_enabled:
			char_fx.transform = char_fx.transform.translated_local(scale_pivot*glyph_size*Vector2(1, -1)*(1-scale_curve.sample(trans)))
			char_fx.transform = char_fx.transform.scaled_local(Vector2.ONE*scale_curve.sample(trans))

		if position_enabled:
			char_fx.transform = char_fx.transform.translated_local(Vector2(position_x_curve.sample(trans), position_y_curve.sample(trans))*glyph_size)

	return true
