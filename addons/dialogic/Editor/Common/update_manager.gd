@tool
extends Node

## Script that checks for new versions and can install them.

signal update_check_completed(UpdateCheckResult)

enum UpdateCheckResult {UPDATE_AVAILABLE, UP_TO_DATE, NO_ACCESS}
enum UpdateResult {SUCCESS, FAILURE, NO_ACCESS}

const REMOTE_RELEASES_URL := "https://api.github.com/repos/coppolaemilio/dialogic/releases"

var current_version : String = ""

var update_info :Dictionary

func get_current_version() -> String:
	var plugin_cfg := ConfigFile.new()
	plugin_cfg.load("res://addons/dialogic/plugin.cfg")
	return plugin_cfg.get_value('plugin', 'version', 'unknown version')


func get_version_cleaned(version:String) -> String:
	version = version.to_lower()
	version = version.trim_prefix('v')
	if '(' in version:
		version = version.substr(0, version.find('('))
	return version.strip_edges()


func request_update_check() -> void:
	if $UpdateCheckRequest.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
		$UpdateCheckRequest.request(REMOTE_RELEASES_URL)


func _on_UpdateCheck_request_completed(result:int, response_code:int, headers:PackedStringArray, body:PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		update_check_completed.emit(UpdateCheckResult.NO_ACCESS)
		return
	
	var current_version: String = get_version_cleaned(get_current_version())
	
	# Work out the next version from the releases information on GitHub
	var response :Variant= JSON.parse_string(body.get_string_from_utf8())
	if typeof(response) != TYPE_ARRAY: return
	
	# GitHub releases are in order of creation, not order of version
	var versions :Array = (response as Array).filter(func(release):
		var version: String = get_version_cleaned(release.tag_name)
		return version_to_number(version) > version_to_number(current_version)
	)
	if versions.size() > 0:
		update_info = versions[0]
		update_check_completed.emit(UpdateCheckResult.UPDATE_AVAILABLE)
	else:
		update_info = {}
		update_check_completed.emit(UpdateCheckResult.UP_TO_DATE)


# Convert a version number to an actually comparable number
func version_to_number(version: String) -> int:
	version = version.to_lower()
	var bits := version.substr(0,version.find('-')).split(".")
	var number := 0
	if version.count('.') == 1:
		number = int(bits[0]) * 1_000_000 + int(bits[1]) * 1000
	elif version.count('.') == 2:
		number = int(bits[0]) * 1_000_000 + int(bits[1]) * 1000 + bits[2].to_int()
	
	if 'alpha' in version:
		number -= 100_000
		print(version.substr(version.find('-alpha-')+7))
		if version.substr(version.find('-alpha-')+7).is_valid_int():
			number += int(version.substr(version.find('-alpha-')+7).strip_edges())
			
	
	printt(version, number)
	return number


func install_update() -> UpdateResult:
	return UpdateResult.NO_ACCESS


