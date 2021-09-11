# Using signals?

## Emit Signal event
You can learn more about how to use this event in it's own documentation page (in the Events folder).

## Other signals
You can also listen to Dialogic using the four other signals:

- **event_end** and **event_start** are emitted for each event in your timeline
- **timeline_end** and **timeline_start** are emitted when a timeline starts and ends.

You can connect signals using the editor or via code:
`func start_dialog():
	var dialog = Dialogic.start("my_timeline")
	dialog.connect("timeline_end", self, "dialog_ended")
	add_node(dialog)
`