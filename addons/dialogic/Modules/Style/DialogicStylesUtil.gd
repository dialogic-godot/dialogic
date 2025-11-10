@tool
class_name DialogicStylesUtil
extends Node

static var style_directory := {}

#region STYLES
################################################################################

static func update_style_directory() -> void:
	style_directory = ProjectSettings.get_setting('dialogic/layout/style_directory', {})


static func build_style_directory() -> void:
	style_directory.clear()

	var default := get_default_style_path()
	if ResourceLoader.exists(default):
		style_directory[""] = default

	var styles: Array = ProjectSettings.get_setting('dialogic/layout/style_list', [])
	for style_path in styles:
		if not ResourceLoader.exists(style_path):
			continue
		# TODO this is bad
		var resource: DialogicStyle = load(style_path)
		style_directory[resource.name] = style_path

	if Engine.is_editor_hint():
		ProjectSettings.set_setting('dialogic/layout/style_directory', style_directory)
		ProjectSettings.save()


static func get_default_style_path() -> String:
	return ProjectSettings.get_setting('dialogic/layout/default_style', '')


static func get_default_layout_base() -> PackedScene:
	return load(DialogicUtil.get_module_path('DefaultLayoutParts').path_join("Base_Default/default_layout_base.tscn"))


static func get_fallback_style_path() -> String:
	return DialogicUtil.get_module_path('DefaultLayoutParts').path_join("Style_VN_Default/default_vn_style.tres")


static func get_fallback_style() -> DialogicStyle:
	return load(get_fallback_style_path())


static func get_style_path(name_or_path:String) -> String:
	if name_or_path.begins_with("res://"):
		if not ResourceLoader.exists(name_or_path):
			name_or_path = ""

	if name_or_path in style_directory:
		name_or_path = style_directory[name_or_path]

	if not name_or_path:
		name_or_path = get_default_style_path()

	if not name_or_path or not ResourceLoader.exists(name_or_path):
		return get_fallback_style_path()

	return name_or_path


static func start_style_preload(name_or_path:String) -> void:
	ResourceLoader.load_threaded_request(get_style_path(name_or_path))


static func get_style(style_name:String) -> DialogicStyle:
	var path := get_style_path(style_name)
	if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_LOADED:
		return ResourceLoader.load_threaded_get(path)

	return load(path)


#endregion
