tool

const DB_PATH = "res://addons/dialogic/Database/"
const TIMELINEDB_PATH = DB_PATH+"SavedTimelines.tres"
const CHARACTERDB_PATH = DB_PATH+"SavedCharacters.tres"

const CONFIGURATION_PATH = DB_PATH+"EditorConfiguration.tres"

const RESOURCES_DIR = "res://dialogic_files/"
const TIMELINES_DIR = RESOURCES_DIR+"timelines/"
const CHARACTERS_DIR = RESOURCES_DIR+"characters/"

const ICON_PATH_DARK = "res://addons/dialogic/assets/Images/Plugin/plugin-editor-icon-dark-theme.svg"
const ICON_PATH_LIGHT = "res://addons/dialogic/assets/Images/Plugin/plugin-editor-icon-light-theme.svg"

# This method should call a recursive one.
# But not for now
static func verify_resource_directories() -> void:
	var _info = "[Dialogic Resources]"
	var _d = Directory.new()
	
	if not _d.dir_exists(RESOURCES_DIR):
		print("{i} {m}".format({"i":_info,"m":"Dialogic folder doesn't exist."}))
		var _err = _d.make_dir_recursive(RESOURCES_DIR)
		if _err != OK:
			print("{i} {m} -> ".format({"i":_info,"m":"Failed, skipping"}), _err)
			return
		print("{i} {m}".format({"i":_info,"m":"Dialogic folder created."}))
	
	if not _d.dir_exists(TIMELINES_DIR):
		print("{i} {m}".format({"i":_info,"m":"Timelines folder doesn't exist."}))
		var _err = _d.make_dir_recursive(TIMELINES_DIR)
		if _err != OK:
			print("{i} {m} -> ".format({"i":_info,"m":"Failed, skipping"}), _err)
			return
		print("{i} {m}".format({"i":_info,"m":"Timelines folder created."}))

	
	if not _d.dir_exists(CHARACTERS_DIR):
		print("{i} {m}".format({"i":_info,"m":"Characters folder doesn't exist."}))
		var _err = _d.make_dir_recursive(CHARACTERS_DIR)
		if _err != OK:
			print("{i} {m} -> ".format({"i":_info,"m":"Failed, skipping"}), _err)
			return
		print("{i} {m}".format({"i":_info,"m":"Characters folder created."}))
	
	print("{i} {m}".format({"i":_info,"m":"All folders verified. There's no problems"}))
