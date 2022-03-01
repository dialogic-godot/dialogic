# Adding character animations

Dialogic 1.4 introduced a new animation system ([Anima by Alessandro Senese](https://github.com/ceceppa/anima)).
The files for the animations are stored in the `/dialogic/addons/dialogic/Nodes/Anima/animations` folder.

There are two different kind of animations: Entrances and exits and attention seekers.
You can add your custom animations by creating new `.gd` files in the `animations/entrances_and_exists` or `animations/attention_seeker` folder.

## Entrances and exits
These are used when you have a character showing up or leaving a scene using the character event.
A regular fade in animation looks something like this:

```
func generate_animation(anima_tween: Tween, data: Dictionary) -> void:
	var opacity_frames = [
		{ from = 0, to = 1, easing_points = [0.42, 0, 0.58, 1]},
	]
	anima_tween.add_frames(data, "opacity", opacity_frames)
```

## Attention seekers
These are used when you when using the Character event and the Update setting.
They can be used to make a character shake, bounce or any other one to emphasize the character.

They look something like this:
```
func generate_animation(anima_tween: Tween, data: Dictionary) -> void:
	var frames = [
		{ percentage = 0, from = 1 },
		{ percentage = 25, to = 0 },
		{ percentage = 50, to = 1 },
		{ percentage = 75, to = 0 },
		{ percentage = 100, to = 1 },
	]

	anima_tween.add_frames(data, "opacity", frames)
```