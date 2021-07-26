# Using signals?

## The Emit Signal event
First of all: The **Emit Signal** event does NOT create a signal. 
It emits the dialogic_signal of the current Dialog node with the given string as an argument.

If you instance your dialog via script, use a code similar to this:
`func start_dialog():
	var dialog = Dialogic.start("my_timeline")
	dialog.connect("dialogic_signal", self, "dialog_listener")
	add_node(dialog)

func dialog_listener(string):
	match string:
		"TomEntered":
			# do something
			pass
`

If you instanced the scene using the editor you can connect the signal like you would always do in godot from the NODE tab > Signals.

## The other signals
You can also listen to dialogic using the four other signals:

- **event_end** and **event_start** are emited for each event in your timeline
- **timeline_end** and **timeline_start** are emited when a timeline starts and ends.

You can connect these signals using the editor or via code:
`func start_dialog():
	var dialog = Dialogic.start("my_timeline")
	dialog.connect("timeline_end", self, "dialog_ended")
	add_node(dialog)
`