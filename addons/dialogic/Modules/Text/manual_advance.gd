extends RefCounted
class_name DialogicManualAdvance
## This class holds the settings for the Manual-Advance feature.
## Changing the variables will alter the behaviour of manually advancing
## the timeline, e.g. using the input action.

## The key for the enabled state in the current state info.
const ENABLED_STATE_KEY := "enabled"
## The key for the temporary event state in the current state info.
const DISABLED_UNTIL_NEXT_EVENT_STATE_KEY := "temp_disabled"


## If `true`, Manual-Advance will stay enabled until this is set to `false`.
##
## Use this flag to activate or disable Manual-Advance mode.
##
## Can be temporarily overwritten by [variable disabled_until_next_event].
var system_enabled := true :
	set(enabled):
		system_enabled = enabled
		DialogicUtil.autoload().Inputs.manual_advance_info[ENABLED_STATE_KEY] = enabled


## If `true`, Manual-Advance will be deactivated until the next event.
##
## Use this flag to create a temporary Manual-Advance block.
##
## Overrides [variable system_enabled] when true.
var disabled_until_next_event := false :
	set(enabled):
		disabled_until_next_event = enabled
		DialogicUtil.autoload().Inputs.manual_advance_info[DISABLED_UNTIL_NEXT_EVENT_STATE_KEY] = enabled


## Checks if the current state info has the Manual-Advance settings.
## If not, populates the current state info with the default settings.
func _init() -> void:
	var manual_advance: Dictionary = DialogicUtil.autoload().Inputs.manual_advance_info

	disabled_until_next_event = manual_advance.get(DISABLED_UNTIL_NEXT_EVENT_STATE_KEY, disabled_until_next_event)
	system_enabled = manual_advance.get(ENABLED_STATE_KEY, system_enabled)


#region MANUAL ADVANCE HELPERS

## Whether the player can use Manual-Advance to advance the timeline.
func is_enabled() -> bool:
	return system_enabled and not disabled_until_next_event

#endregion
