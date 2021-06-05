#	Random Audio Stream PLayer Godot Engine Add-on
#	Copyright (c) Tim Krief.
#
#	Permission is hereby granted, free of charge, to any person obtaining a copy
#	of this software and associated documentation files (the "Software"), to deal
#	in the Software without restriction, including without limitation the rights
#	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#	copies of the Software, and to permit persons to whom the Software is
#	furnished to do so, subject to the following conditions:
#
#	The above copyright notice and this permission notice shall be included in all
#	copies or substantial portions of the Software.
#
#	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#	SOFTWARE.

tool
extends AudioStreamPlayer

export(Array, AudioStream) var samples = []
export(String, DIR) var select_samples_from_folder setget load_samples_from_folder
export(int, "Pure", "No consecutive repetition", "Use all samples before repeat") var random_strategy = 0
onready var base_volume = volume_db
export(float, 0, 80) var random_volume_range = 0
onready var base_pitch = pitch_scale
export(float, 0, 4) var random_pitch_range = 0

var playing_sample_nb : int = -1
var last_played_sample_nb : int = -1 # only used if random_strategy = 1
var to_play = [] # only used if random_strategy = 2

# You can use playing_sample_nb to choose what sample to use
func play(from_position=0.0, playing_sample_nb=-1):
	var number_of_samples = len(samples)
	if number_of_samples > 0:
		if playing_sample_nb < 0:
			if number_of_samples == 1:
				playing_sample_nb = 0
			else:
				match random_strategy:
					1:
						playing_sample_nb = randi() % (number_of_samples - 1)
						if last_played_sample_nb == playing_sample_nb:
							playing_sample_nb += 1
						last_played_sample_nb = playing_sample_nb
					2:
						if len(to_play) == 0:
							for i in range(number_of_samples):
								if i != last_played_sample_nb:
									to_play.append(i)
							to_play.shuffle()
						playing_sample_nb = to_play.pop_back()
						last_played_sample_nb = playing_sample_nb
					_:
						playing_sample_nb = randi() % number_of_samples
			if random_volume_range != 0:
				.set_volume_db(base_volume + (randf() - .5) * random_volume_range)
			if random_pitch_range != 0:
				.set_pitch_scale(base_pitch + (randf() - .5) * random_pitch_range)
		set_stream(samples[playing_sample_nb])
		.play(from_position)

func set_volume_db(new_volume_db):
	base_volume = new_volume_db

func set_pitch_scale(new_pitch):
	base_pitch = new_pitch

func load_samples_from_folder(path):
	if path != "":
		samples.clear()
		var dir = Directory.new()
		if dir.open(path) == OK:
			dir.list_dir_begin(true)
			var file_name = dir.get_next()
			while file_name != "":
				if not dir.current_is_dir():
					if file_name.to_lower().ends_with(".wav") or file_name.to_lower().ends_with(".ogg"):
						#print(dir.get_current_dir() + "/" + file_name)
						var resource = ResourceLoader.load(dir.get_current_dir() + "/" + file_name)
						#print(resource)
						samples.append(resource)
				file_name = dir.get_next()
		select_samples_from_folder = ""
