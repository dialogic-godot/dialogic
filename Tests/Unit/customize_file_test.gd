class_name CustomizeFileTest
extends GdUnitTestSuite


func test_customized_scene_drops_the_template_resource_uid() -> void:
	var source_dir := "res://Tests/Unit/.tmp_customize_file/source"
	var target_dir := "res://Tests/Unit/.tmp_customize_file/target"
	DirAccess.make_dir_recursive_absolute(source_dir)
	DirAccess.make_dir_recursive_absolute(target_dir)
	var script_path := source_dir.path_join("portrait.gd")
	var scene_path := source_dir.path_join("portrait.tscn")
	var target_scene_path := target_dir.path_join("portrait.tscn")
	var script_file := FileAccess.open(script_path, FileAccess.WRITE)
	script_file.store_string("extends Node2D\n")
	script_file.close()
	var scene_file := FileAccess.open(scene_path, FileAccess.WRITE)
	scene_file.store_string(
		'[gd_scene load_steps=2 format=3]\n\n'
		+ '[ext_resource type="Script" uid="uid://template" path="%s" id="1"]\n\n' % script_path
		+ '[node name="Portrait" type="Node2D"]\nscript = ExtResource("1")\n'
	)
	scene_file.close()

	DialogicUtil.customize_file(scene_path, target_scene_path)
	var customized := FileAccess.get_file_as_string(target_scene_path)
	assert_str(customized).contains('path="%s"' % target_dir.path_join("portrait.gd"))
	assert_str(customized).not_contains('uid="uid://template"')
	DirAccess.remove_absolute(target_scene_path)
	DirAccess.remove_absolute(target_dir.path_join("portrait.gd"))
	DirAccess.remove_absolute(scene_path)
	DirAccess.remove_absolute(script_path)
	DirAccess.remove_absolute(target_dir)
	DirAccess.remove_absolute(source_dir)
	DirAccess.remove_absolute("res://Tests/Unit/.tmp_customize_file")
