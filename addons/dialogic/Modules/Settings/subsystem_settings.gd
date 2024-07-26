extends DialogicSubsystem
## Subsystem that allows setting and getting settings that are automatically saved slot independent.
##
## All settings that are stored in the project settings dialogic/settings section are supported.
## For example the text_speed setting is stored there.
## How to access this subsystem via code:
##    ```gd
##        Dialogic.Settings.text_speed = 0.05
##    ```
##
## Settings stored there can also be changed with the Settings event.


var settings := {}
var _connections := {}


#region MAIN METHODS
####################################################################################################

## Built-in, called by DialogicGameHandler.
func clear_game_state(_clear_flag:=DialogicGameHandler.ClearFlags.FULL_CLEAR):
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
	if not settings.has(property) or settings[property] != value:
		_setting_changed(property, value)
	settings[property] = value
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
		if not is_instance_valid(i.get_object()):
			var remove := func(): _connections[property].erase(i)
			remove.call_deferred()
			continue
		i.call(value)

#endregion


#region HANDY METHODS
####################################################################################################

## Get a setting named `property`, if it does not exist, falls back to `default`.
func get_setting(property: StringName, default: Variant) -> Variant:
	return _get(property) if _get(property) != null else default

## Whether a setting has been set/stored before.
func has_setting(property: StringName) -> bool:
	return property in settings


func reset_all() -> void:
	for setting in settings:
		reset_setting(setting)


func reset_setting(property: StringName) -> void:
	if ProjectSettings.has_setting('dialogic/settings/'+property):
		settings[property] = ProjectSettings.get_setting('dialogic/settings/'+property)
		_setting_changed(property, settings[property])
	else:
		settings.erase(property)
		_setting_changed(property, null)


## If a setting named `property` changes its value, this will emit `Callable`.
func connect_to_change(property: StringName, callable: Callable) -> void:
	if not property in _connections:
		_connections[property] = []
	_connections[property].append(callable)

#endregion
