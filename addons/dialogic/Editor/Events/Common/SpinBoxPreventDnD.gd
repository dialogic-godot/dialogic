tool
extends SpinBox

func can_drop_data(position, data):
	# this prevents locking the mouse
	# on some operating systems
	# due to a godot editor bug with SpinBox drag/drop
	return false
