tool
extends WindowDialog

signal colors_changed

onready var color_palette = DialogicUtil.get_color_palette()

func _ready():
	connect("about_to_show", self, 'refresh')
	
	if not Engine.editor_hint:
		popup()
	
	# Colors
	$Panel/Tabs/General/VBox/VBoxContainer/ResetColorsButton.connect('pressed', self, '_on_reset_colors_button')
	var _scale = DialogicUtil.get_editor_scale(self)
	for n in $"%Colors".get_children():
		n.color = color_palette[n.name]
		n.rect_min_size = Vector2(50 * _scale,0)
		n.connect('color_changed', self, '_on_color_change', [n])
	
	
	# Subsystems
	for script in DialogicUtil.get_event_scripts():
		for subsystem in load(script).new().get_required_subsystems():
			if len(subsystem) > 2:
				$Panel/Tabs.add_child(load(subsystem[2]).instance())
	refresh()


func refresh():
	for child in $Panel/Tabs.get_children():
		if child.has_method('refresh'):
			child.refresh()

func _on_color_change(color: Color, who):
	ProjectSettings.set_setting('dialogic/' + who.name, color)
	emit_signal('colors_changed')

func _on_reset_colors_button():
	color_palette = DialogicUtil.get_color_palette(true)
	for n in $"%Colors".get_children():
		n.color = color_palette[n.name]
		# There is a bug when trying to remove existing values, so we have to
		# set/create new entries for all the colors used. 
		# If you manage to make it work using the ProjectSettings.clear() 
		# feel free to open a PR!
		ProjectSettings.set_setting('dialogic/' + n.name, color_palette[n.name])
	emit_signal('colors_changed')
