extends GdUnitTestSuite

## Ensure Auto-Advance is enabled properly using the user input flag.
func test_enable_auto_advance() -> void:
	Dialogic.Inputs.auto_advance.enabled_until_user_input = true
	var is_enabled: bool = Dialogic.Inputs.auto_advance.is_enabled()

	assert(is_enabled == true, "Auto-Advance is not enabled.")


## This test was created to ensure a bug was fixed:
## When the user enabled the Auto-Advance until user input,
## the Auto-Advance would still run after the user input.
func test_disable_auto_advance() -> void:
	Dialogic.Inputs.auto_advance.enabled_until_user_input = true
	Dialogic.Inputs.handle_input()

	var is_enabled: bool = Dialogic.Inputs.auto_advance.is_enabled()
	assert(is_enabled == false, "Auto-Advance is still running after input")
