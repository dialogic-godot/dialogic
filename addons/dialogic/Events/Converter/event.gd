@tool
extends DialogicEvent

## Fake event used to index the converter settings page.

func get_required_subsystems() -> Array:
	return [
				{
				'settings': get_script().resource_path.get_base_dir().path_join('settings_converter.tscn')
				},
			]
