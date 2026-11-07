extends GdUnitTestSuite

const SOURCE_SCENE := "res://addons/dialogic/Modules/LayeredPortrait/layered_portrait.tscn"
const SOURCE_SCRIPT := "res://addons/dialogic/Modules/LayeredPortrait/custom_layered_portrait.gd"
const TARGET_DIR := "user://dialogic_customize_file_test"
const TARGET_SCENE := TARGET_DIR + "/custom_portrait.tscn"
const TARGET_SCRIPT := TARGET_DIR + "/custom_layered_portrait.gd"


func before_test() -> void:
	_remove_test_files()
	DirAccess.make_dir_recursive_absolute(TARGET_DIR)


func after_test() -> void:
	_remove_test_files()


func test_customized_scene_uses_copied_script() -> void:
	DialogicUtil.customize_file(SOURCE_SCENE, TARGET_SCENE)

	assert_file(TARGET_SCENE).exists()
	assert_file(TARGET_SCRIPT).exists()

	var scene_text := FileAccess.get_file_as_string(TARGET_SCENE)
	assert_str(scene_text).not_contains(SOURCE_SCRIPT)
	assert_str(scene_text).contains('path="'+TARGET_SCRIPT+'"')

	var packed := ResourceLoader.load(TARGET_SCENE, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	assert_object(packed).is_not_null()
	var instance: Node = auto_free(packed.instantiate())
	assert_str(instance.get_script().resource_path).is_equal(TARGET_SCRIPT)


func _remove_test_files() -> void:
	if not DirAccess.dir_exists_absolute(TARGET_DIR):
		return
	var dir := DirAccess.open(TARGET_DIR)
	for file in dir.get_files():
		dir.remove(file)
	DirAccess.remove_absolute(TARGET_DIR)
