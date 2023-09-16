extends DialogicSubsystem

## Subsystem that allows setting and getting settings that are automatically saved slot independent.
## All settings that are stored in the project settings dialogic/settings section are supported.
## For example the text_speed setting is stored there. 
## Thus it can be acessed like this:
##    Dialogic.Settings.text_speed = 0.05
## Settings stored there can also be changed with the Settings event.

var settings := {}

var _connections := {}

####################################################################################################
##					MAIN METHODS
####################################################################################################

## Built-in, called by DialogicGameHandler.
func clear_game_state(clear_flag:=Dialogic.ClearFlags.FULL_CLEAR):
	_reload_settings()


func _reload_settings() -> void:
	settings = {}
	for prop in ProjectSettings.get_property_list():
		if prop.name.begins_with('dialogic/settings'):
			settings[prop.name.trim_prefix('dialogic/settings/')] = ProjectSettings.get_setting(prop.name)
	
	if dialogic.has_subsystem('Save'):
		for i in settings:
			settings[i] = dialogic.Save.get_global_info(i, settings[i])


func _set(property:StringName, value:Variant) -> bool:
	settings[property] = value
	_setting_changed(property, value)
	if dialogic.has_subsystem('Save'):
		dialogic.Save.set_global_info(property, value)
	return true


func _get(property:StringName) -> Variant:
	if property in settings:
		return settings[property]
	return null


func _setting_changed(property:StringName, value:Variant) -> void:
	if !property in _connections:
		return
	
	for i in _connections[property]:
		i.call(value)

####################################################################################################
##					HANDY METHODS
####################################################################################################

func get_setting(property:StringName, default:Variant) -> Variant:
	return _get(property) if _get(property) != null else default


func has_setting(property:StringName) -> bool:
	return property in settings


func reset_all() -> void:
	for setting in settings:
		reset_setting(setting)


func reset_setting(property:StringName) -> void:
	if ProjectSettings.has_setting('dialogic/settings/'+property):
		settings[property] = ProjectSettings.get_setting('dialogic/settings/'+property)
		_setting_changed(property, settings[property])
	else:
		settings.erase(property)
		_setting_changed(property, null)


func connect_to_change(setting:StringName, callable:Callable) -> void:
	if !setting in _connections:
		_connections[setting] = []
	_connections[setting].append(callable)
