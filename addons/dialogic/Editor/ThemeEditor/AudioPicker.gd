tool
extends GridContainer

signal data_updated(section)

var loading = false
var editor_reference
var path = ""

onready var n : Dictionary = {
	'enable': $"FileHBoxContainer/EnableCheckBox",
	'path': $"FileHBoxContainer/PathButton",
	'volume': $"VolumeHBoxContainer/VolumeSpinBox",
	'volume_rand_range': $"VolumeHBoxContainer/VolumeRandRangeSpinBox",
	'pitch': $"PitchHBoxContainer/PitchSpinBox",
	'pitch_rand_range': $"PitchHBoxContainer/PitchRandRangeSpinBox",
	'allow_interrupt': $"AllowInterruptCheckBox",
	'audio_bus': $"AudioBusOptionButton"
}

func _ready():
	editor_reference = find_parent('EditorView')
	
	AudioServer.connect("bus_layout_changed", self, "_on_bus_layout_changed")
	update_audio_bus_option_buttons()

func set_data(data):
	loading = true
	n['enable'].set_pressed(data['enable'])
	
	path = data['path']
	_on_Path_selected(path)
	n['path'].text = DTS.translate('File or folder path')
	n['volume'].set_value(data['volume'])
	n['volume_rand_range'].set_value(data['volume_rand_range'])
	n['pitch'].set_value(data['pitch'])
	n['pitch_rand_range'].set_value(data['pitch_rand_range'])
	n['allow_interrupt'].set_pressed(data['allow_interrupt'])
	
	update_audio_bus_option_buttons(data['audio_bus'])
	
	_set_disabled(!data['enable'])
	loading = false

func get_data():
	return {
		'enable': n['enable'].is_pressed(),
		'path': path,
		'volume': n['volume'].get_value(),
		'volume_rand_range': n['volume_rand_range'].get_value(),
		'pitch': n['pitch'].get_value(),
		'pitch_rand_range': n['pitch_rand_range'].get_value(),
		'allow_interrupt': n['allow_interrupt'].is_pressed(),
		'audio_bus': AudioServer.get_bus_name(n['audio_bus'].get_selected_id())
	}

func _on_EnableCheckBox_toggled(button_pressed):
	if not loading: emit_signal("data_updated", name.to_lower())
	_set_disabled(!button_pressed)

func _set_disabled(disabled):
	n['path'].set_disabled(disabled)
	n['volume'].set_editable(!disabled)
	n['volume_rand_range'].set_editable(!disabled)
	n['pitch'].set_editable(!disabled)
	n['pitch_rand_range'].set_editable(!disabled)
	n['allow_interrupt'].set_disabled(disabled)
	n['audio_bus'].set_disabled(disabled)

func _on_PathButton_pressed():
	editor_reference.godot_dialog("*.ogg, *.wav", EditorFileDialog.MODE_OPEN_ANY)
	editor_reference.godot_dialog_connect(self, "_on_Path_selected", ["dir_selected", "file_selected"])

func _on_Path_selected(selected_path, target = ""):
	if typeof(selected_path) == TYPE_STRING and path != "":
		path = selected_path
		n['path'].text = DialogicResources.get_filename_from_path(path)
	if not loading: emit_signal("data_updated", name.to_lower())

func _on_VolumeSpinBox_value_changed(value):
	if not loading: emit_signal("data_updated", name.to_lower())

func _on_VolumeRandRangeSpinBox_value_changed(value):
	n['volume_rand_range'].set_value(abs(value))
	if not loading: emit_signal("data_updated", name.to_lower())

func _on_PitchSpinBox_value_changed(value):
	n['pitch'].set_value(max(0.01, value))
	if not loading: emit_signal("data_updated", name.to_lower())

func _on_PitchRandRangeSpinBox_value_changed(value):
	n['pitch_rand_range'].set_value(abs(value))
	if not loading: emit_signal("data_updated", name.to_lower())

func _on_AllowInterruptCheckBox_toggled(button_pressed):
	if not loading: emit_signal("data_updated", name.to_lower())

func _on_AudioBusOptionButton_item_selected(index):
	if not loading: emit_signal("data_updated", name.to_lower())

func _on_bus_layout_changed():
	var selected_id = n['audio_bus'].get_selected_id()
	var selected_text = n['audio_bus'].get_item_text(selected_id)
	update_audio_bus_option_buttons(selected_text)

func update_audio_bus_option_buttons(selected_text = ''):
	n['audio_bus'].clear()
	for i in range(AudioServer.bus_count):
		var bus_name = AudioServer.get_bus_name(i)
		n['audio_bus'].add_item(bus_name)
		if bus_name == selected_text:
			n['audio_bus'].select(i)

