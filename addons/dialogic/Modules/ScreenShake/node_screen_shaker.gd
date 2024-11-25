class_name DialogicNode_ScreenShaker
extends ColorRect


const ROLLOVER_TIME = 3600.0

@onready var time_x: float = material.get_shader_parameter('time_x')
@onready var phase_x: float = material.get_shader_parameter('phase_x')
@onready var last_frequency_x: float = material.get_shader_parameter('frequency_x')

@onready var time_y: float = material.get_shader_parameter('time_y')
@onready var phase_y: float = material.get_shader_parameter('phase_y')
@onready var last_frequency_y: float = material.get_shader_parameter('frequency_y')


func _ready() -> void:
	add_to_group('dialogic_screen_shaker')

	material.set_shader_parameter(
		'clear_color',
		ProjectSettings.get_setting('rendering/environment/defaults/default_clear_color', Color.BLACK))


func _process(delta: float) -> void:
	if not DialogicUtil.autoload().paused:
		time_x += delta
		time_x = fposmod(time_x, ROLLOVER_TIME)
		material.set_shader_parameter('time_x', time_x)

		time_y += delta
		time_y = fposmod(time_y, ROLLOVER_TIME)
		material.set_shader_parameter('time_y', time_y)


func reset_x() -> void:
	time_x = 0.0
	phase_x = 0.0
	last_frequency_x = 0.0

	material.set_shader_parameter('time_x', 0.0)
	material.set_shader_parameter('phase_x', 0.0)


func reset_y() -> void:
	time_y = 0.0
	phase_y = 0.0
	last_frequency_y = 0.0

	material.set_shader_parameter('time_y', 0.0)
	material.set_shader_parameter('phase_y', 0.0)


func update_frequency_x(new_frequency: float) -> void:
	if new_frequency != 0.0:
		phase_x = (last_frequency_x * (time_x + phase_x) / new_frequency) - time_x
	last_frequency_x = new_frequency

	material.set_shader_parameter('frequency_x', new_frequency)
	material.set_shader_parameter('phase_x', phase_x)


func update_frequency_y(new_frequency: float) -> void:
	if new_frequency != 0.0:
		phase_y = (last_frequency_y * (time_y + phase_y) / new_frequency) - time_y
	last_frequency_y = new_frequency

	material.set_shader_parameter('frequency_y', new_frequency)
	material.set_shader_parameter('phase_y', phase_y)
