class_name LayeredPortraitCoverageTest
extends GdUnitTestSuite


func test_coverage_uses_local_transforms_before_entering_tree() -> void:
	var portrait := CanvasGroup.new()
	portrait.set_script(preload(
		"res://addons/dialogic/Modules/LayeredPortrait/layered_portrait.gd"
	))
	# Reproduce the invalid preview transform reported after selecting an empty
	# portrait. Coverage must depend only on transforms below the portrait root.
	portrait.position = Vector2(INF, INF)
	var layer := Node2D.new()
	layer.position = Vector2(30, 20)
	portrait.add_child(layer)

	var sprite := Sprite2D.new()
	sprite.texture = ImageTexture.create_from_image(
		Image.create(20, 10, false, Image.FORMAT_RGBA8)
	)
	sprite.position = Vector2(5, 7)
	layer.add_child(sprite)

	var coverage: Rect2 = portrait._find_largest_coverage_rect()
	assert_bool(coverage.position.is_finite()).is_true()
	assert_bool(coverage.size.is_finite()).is_true()
	assert_vector(coverage.size).is_equal(Vector2(20, 10))
	portrait.free()


func test_coverage_includes_scaled_and_rotated_sprite_corners() -> void:
	var portrait := CanvasGroup.new()
	portrait.set_script(preload(
		"res://addons/dialogic/Modules/LayeredPortrait/layered_portrait.gd"
	))
	var sprite := Sprite2D.new()
	sprite.texture = ImageTexture.create_from_image(
		Image.create(20, 10, false, Image.FORMAT_RGBA8)
	)
	sprite.scale = Vector2(2, 1)
	sprite.rotation = PI / 2.0
	portrait.add_child(sprite)

	var coverage: Rect2 = portrait._find_largest_coverage_rect()
	assert_vector(coverage.size).is_equal_approx(Vector2(10, 40), Vector2(0.001, 0.001))
	portrait.free()
