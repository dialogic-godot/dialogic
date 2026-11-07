class_name LayeredPortraitCoverageTest
extends GdUnitTestSuite

const LAYERED_PORTRAIT_SCENE := preload(
	"res://addons/dialogic/Modules/LayeredPortrait/layered_portrait.tscn"
)


func test_coverage_refreshes_after_an_empty_portrait_receives_a_texture() -> void:
	var portrait := LAYERED_PORTRAIT_SCENE.instantiate()
	add_child(portrait)

	var empty_rect: Rect2 = portrait._get_covered_rect()
	assert_vector(empty_rect.size).is_equal(Vector2.ZERO)

	portrait.get_node("Layer1").texture = _make_texture(Vector2i(24, 40))
	var populated_rect: Rect2 = portrait._get_covered_rect()
	assert_vector(populated_rect.size).is_equal(Vector2(24, 40))

	portrait.queue_free()


func test_coverage_ignores_invalid_preview_scale_on_portrait_root() -> void:
	var portrait := LAYERED_PORTRAIT_SCENE.instantiate()
	portrait.get_node("Layer1").texture = _make_texture(Vector2i(24, 40))
	portrait.scale = Vector2(INF, INF)
	add_child(portrait)

	var rect: Rect2 = portrait._get_covered_rect()
	assert_bool(rect.position.is_finite()).is_true()
	assert_bool(rect.size.is_finite()).is_true()
	assert_vector(rect.size).is_equal(Vector2(24, 40))

	portrait.queue_free()


func _make_texture(size: Vector2i) -> ImageTexture:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	return ImageTexture.create_from_image(image)
