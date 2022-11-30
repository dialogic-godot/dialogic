@tool
extends DialogicEditor

## Editor that contains all settings 

func _register():
	editors_manager.register_simple_editor(self)


func _ready():
	for script in DialogicUtil.get_event_scripts():
		for subsystem in load(script).new().get_required_subsystems():
			if subsystem.has('settings'):
				$Tabs.add_child(load(subsystem.settings).instantiate())



func _open(extra_information:Variant = null) -> void:
	refresh()


func _close():
	for child in $Tabs.get_children():
		if child.has_method('_about_to_close'):
			child._about_to_close()


func refresh():
	for child in $Tabs.get_children():
		if child.has_method('refresh'):
			child.refresh()

