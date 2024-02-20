extends GdUnitTestSuite

const VALID_SPEAKER_PATH := "res://Tests/Resources/unit_test_character.dch"

## We ensure that missing a speaker will return null.
func test_missing_current_speaker() -> void:
	var null_speaker := DialogicUtil.autoload().Text.get_current_speaker()

	assert(null_speaker == null, "Current speaker is not null.")


## We ensure invalid speaker paths return the correct value.
func test_set_invalid_current_speaker() -> void:
	DialogicUtil.autoload().current_state_info["speaker"] = "Invalid Speaker Path"
	var current_speaker := DialogicUtil.autoload().Text.get_current_speaker()

	assert(current_speaker == null, "Invalid speaker must be invalid, but is valid.")


## We ensure valid speaker paths return a valid [class DialogicCharacter] and
## the path is set correctly.
func test_set_valid_current_speaker() -> void:
	DialogicUtil.autoload().current_state_info["speaker"] = VALID_SPEAKER_PATH
	var current_speaker := DialogicUtil.autoload().Text.get_current_speaker()

	assert(not current_speaker == null, "Valid speaker must be valid, but is invalid.")
	assert(current_speaker.get_path() == VALID_SPEAKER_PATH, "Valid speaker path is not set correctly.")
