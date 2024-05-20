extends RefCounted
class_name DialogicManualAdvance
## This class holds the settings for the Manual-Advance feature.
## Changing the variables will alter the behaviour of manually advancing
## the timeline, e.g. using the input action.

## The key giving access to the state info of Manual-Advance.
const STATE_INFO_KEY := "manual_advance"
## The key for the enabled state in the current state info.
const ENABLED_STATE_KEY := "enabled"
## The key for the temporary event state in the current state info.
const DISABLED_UNTIL_NEXT_EVENT_STATE_KEY := "temp_disabled"


## If `true`, Manual-Advance will be deactivated until the next event.
##
## Use this flag to create a temporary Manual-Advance block.
##
## Overrides [variable system_enabled] when true.
var disabled_until_next_event := false :
	set(enabled):
		disabled_until_next_event = enabled
		DialogicUtil.autoload().current_state_info[STATE_INFO_KEY][DISABLED_UNTIL_NEXT_EVENT_STATE_KEY] = enabled


## If `true`, Manual-Advance will stay enabled until this is set to `false`.
##
## Use this flag to activate or disable Manual-Advance mode.
##
## Can be temporarily overwritten by [variable disabled_until_next_event].
var system_enabled := true :
	set(enabled):
		system_enabled = enabled
		DialogicUtil.autoload().current_state_info[STATE_INFO_KEY][ENABLED_STATE_KEY] = enabled


## Checks if the current state info has the Manual-Advance settings.
## If not, populates the current state info with the default settings.
func _init() -> void:
	if DialogicUtil.autoload().current_state_info.has(STATE_INFO_KEY):
		var state_info := DialogicUtil.autoload().current_state_info
		var manual_advance: Dictionary = state_info[STATE_INFO_KEY]

		disabled_until_next_event = manual_advance.get(DISABLED_UNTIL_NEXT_EVENT_STATE_KEY, disabled_until_next_event)
		system_enabled = manual_advance.get(ENABLED_STATE_KEY, system_enabled)

	else:
		DialogicUtil.autoload().current_state_info[STATE_INFO_KEY] = {
			ENABLED_STATE_KEY: system_enabled,
			DISABLED_UNTIL_NEXT_EVENT_STATE_KEY: disabled_until_next_event,
		}


#region MANUAL ADVANCE HELPERS

## Whether the player can use Manual-Advance to advance the timeline.
func is_enabled() -> bool:
	return system_enabled and not disabled_until_next_event

#endregion
