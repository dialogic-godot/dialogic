@tool
extends Node

## Script that checks for new versions and can install them.

signal update_check_completed(result:UpdateCheckResult)
signal downdload_completed(result:DownloadResult)

enum UpdateCheckResult {UPDATE_AVAILABLE, UP_TO_DATE, NO_ACCESS}
enum DownloadResult {SUCCESS, FAILURE}
enum ReleaseState {ALPHA, BETA, STABLE}

const REMOTE_RELEASES_URL := "https://api.github.com/repos/dialogic-godot/dialogic/releases"
const TEMP_FILE_NAME := "user://temp.zip"

var current_version := ""
var update_info: Dictionary
var current_info: Dictionary

var version_indicator: Button

func _ready() -> void:
	request_update_check()

	setup_version_indicator()



func get_current_version() -> String:
	var plugin_cfg := ConfigFile.new()
	plugin_cfg.load("res://addons/dialogic/plugin.cfg")
	return plugin_cfg.get_value('plugin', 'version', 'unknown version')


func request_update_check() -> void:
	if $UpdateCheckRequest.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
		$UpdateCheckRequest.request(REMOTE_RELEASES_URL)


func _on_UpdateCheck_request_completed(result:int, response_code:int, headers:PackedStringArray, body:PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		update_check_completed.emit(UpdateCheckResult.NO_ACCESS)
		return

	# Work out the next version from the releases information on GitHub
	var response: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(response) != TYPE_ARRAY: return


	var current_release_info := get_release_tag_info(get_current_version())

	# GitHub releases are in order of creation, not order of version
	var versions: Array = (response as Array).filter(compare_versions.bind(current_release_info))
	if versions.size() > 0:
		update_info = versions[0]
		update_check_completed.emit(UpdateCheckResult.UPDATE_AVAILABLE)
	else:
		update_info = current_info
		update_check_completed.emit(UpdateCheckResult.UP_TO_DATE)


func compare_versions(release, current_release_info:Dictionary) -> bool:
	var checked_release_info := get_release_tag_info(release.tag_name)

	if checked_release_info.major < current_release_info.major:
		return false

	if checked_release_info.minor < current_release_info.minor:
		return false

	if checked_release_info.state < current_release_info.state:
		return false

	elif checked_release_info.state == current_release_info.state:
		if checked_release_info.state_version < current_release_info.state_version:
			return false

		if checked_release_info.state_version == current_release_info.state_version:
			current_info = release
			return false

		if checked_release_info.state == ReleaseState.STABLE:
			if checked_release_info.minor == current_release_info.minor:
				current_info = release
				return false

	return true


func get_release_tag_info(release_tag:String) -> Dictionary:
	release_tag = release_tag.strip_edges().trim_prefix('v')
	release_tag = release_tag.substr(0, release_tag.find('('))
	release_tag = release_tag.to_lower()

	var regex := RegEx.create_from_string(r"(?<major>\d+\.\d+)(-(?<state>alpha|beta)-)?(?(2)(?<stateversion>\d*)|\.(?<minor>\d*))?")

	var result: RegExMatch = regex.search(release_tag)
	if !result:
		return {}

	var info: Dictionary = {'tag':release_tag}
	info['major'] = float(result.get_string('major'))
	info['minor'] = int(result.get_string('minor'))

	match result.get_string('state'):
		'alpha':
			info['state'] = ReleaseState.ALPHA
		'beta':
			info['state'] = ReleaseState.BETA
		_:
			info['state'] = ReleaseState.STABLE

	info['state_version'] = int(result.get_string('stateversion'))

	return info


func request_update_download() -> void:
	# Safeguard the actual dialogue manager repo from accidentally updating itself
	if DirAccess.dir_exists_absolute("res://test-project/"):
		prints("[Dialogic] Looks like you are working on the addon. You can't update the addon from within itself.")
		downdload_completed.emit(DownloadResult.FAILURE)
		return

	$DownloadRequest.request(update_info.zipball_url)


func _on_DownloadRequest_completed(result:int, response_code:int, headers:PackedStringArray, body:PackedByteArray):
	if result != HTTPRequest.RESULT_SUCCESS:
		downdload_completed.emit(DownloadResult.FAILURE)
		return

	# Save the downloaded zip
	var zip_file: FileAccess = FileAccess.open(TEMP_FILE_NAME, FileAccess.WRITE)
	zip_file.store_buffer(body)
	zip_file.close()

	OS.move_to_trash(ProjectSettings.globalize_path("res://addons/dialogic"))

	var zip_reader: ZIPReader = ZIPReader.new()
	zip_reader.open(TEMP_FILE_NAME)
	var files: PackedStringArray = zip_reader.get_files()

	var base_path: String = files[0].path_join('addons/')
	for path in files:
		if not "dialogic/" in path:
			continue

		var new_file_path: String = path.replace(base_path, "")
		if path.ends_with("/"):
			DirAccess.make_dir_recursive_absolute("res://addons/".path_join(new_file_path))
		else:
			var file: FileAccess = FileAccess.open("res://addons/".path_join(new_file_path), FileAccess.WRITE)
			file.store_buffer(zip_reader.read_file(path))

	zip_reader.close()
	DirAccess.remove_absolute(TEMP_FILE_NAME)

	downdload_completed.emit(DownloadResult.SUCCESS)


######################	SOME UI MANAGEMENT #####################################
################################################################################

func setup_version_indicator() -> void:
	version_indicator = %Sidebar.get_node('%CurrentVersion')
	version_indicator.pressed.connect($Window/UpdateInstallWindow.open)
	version_indicator.text = get_current_version()


func _on_update_check_completed(result:int):
	var result_color: Color
	match result:
		UpdateCheckResult.UPDATE_AVAILABLE:
			result_color = version_indicator.get_theme_color("warning_color", "Editor")
			version_indicator.icon = version_indicator.get_theme_icon("StatusWarning", "EditorIcons")
			$Window/UpdateInstallWindow.load_info(update_info, result)
		UpdateCheckResult.UP_TO_DATE:
			result_color = version_indicator.get_theme_color("success_color", "Editor")
			version_indicator.icon = version_indicator.get_theme_icon("StatusSuccess", "EditorIcons")
			$Window/UpdateInstallWindow.load_info(current_info, result)
		UpdateCheckResult.NO_ACCESS:
			result_color = version_indicator.get_theme_color("success_color", "Editor")
			version_indicator.icon = version_indicator.get_theme_icon("GuiRadioCheckedDisabled", "EditorIcons")
			$Window/UpdateInstallWindow.load_info(update_info, result)

	version_indicator.add_theme_color_override('font_color', result_color)
	version_indicator.add_theme_color_override('font_hover_color', result_color.lightened(0.5))
	version_indicator.add_theme_color_override('font_pressed_color', result_color)
	version_indicator.add_theme_color_override('font_focus_color', result_color)


