@tool
extends PanelContainer

func _ready():
	hide()
	visibility_changed.connect(_on_visibility_changed)
	
	# Subsystems
	for script in DialogicUtil.get_event_scripts():
		for subsystem in load(script).new().get_required_subsystems():
			if subsystem.has('settings'):
				$Tabs.add_child(load(subsystem.settings).instantiate())
	refresh()

func _on_visibility_changed():
	if visible:
		refresh()
	else:
		close()

func refresh():
	for child in $Tabs.get_children():
		if child.has_method('refresh'):
			child.refresh()

func close():
	for child in $Tabs.get_children():
		if child.has_method('_about_to_close'):
			child._about_to_close()
	hide()
