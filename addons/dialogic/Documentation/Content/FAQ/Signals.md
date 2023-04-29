# How do I use signals with Dialogic?

## Emit Signal event
You can learn more about how to use this event in its own documentation page in the Events folder.

## Other signals
You can also listen to Dialogic using preset signals. All signals can be connected via code.

- **event_start** - emitted at the start of every event. Returns the type of event and the event contents in as a dictionary.
```gdscript
func start_dialog():
	var dialog = Dialogic.start("my_timeline")
	dialog.connect("event_start", self, "_on_event_start")
	add_node(dialog)

func _on_event_start(event_type, event_dict):
	print('Event started! Event is a ', event_type)
	print('Event data ', event_dict)
```

- **event_end** - Emitted when a specific event is completed. Returns the type. This even is currently bugged and does not function as one would expect, only firing off once at timeline end. You can use the **text_complete** signal for most functionality you'd expect here.
```gdscript
func start_dialog():
	var dialog = Dialogic.start("my_timeline")
	dialog.connect("event_end", self, "_on_event_end")
	add_node(dialog)

func _on_event_end(event_type):
	print('Event ended. It was a ', event_type)
```

- **timeline_start** - Emitted when a timeline begins. It returns the human readable name of the timeline that started. This will trigger after a timeline change event.
```gdscript
func start_dialog():
	var dialog = Dialogic.start("my_timeline")
	dialog.connect("timeline_start", self, "_on_timeline_start")
	add_node(dialog)

func _on_timeline_start(timeline_name):
	print('Timeline started! Timeline is called ', timeline_name)
```

- **timeline_end** -  Emitted when a timeline ends. It returns the human readable name of the timeline that ended. Note if a timeline change event occurs, this will reutrn the value of the new timeline. In other words it only returns the last timeline run.
```gdscript
func start_dialog():
	var dialog = Dialogic.start("my_timeline")
	dialog.connect("timeline_end", self, "_on_timeline_end")
	add_node(dialog)

func _on_timeline_end(timeline_name):
	print('Timeline ended! Timeline is called ', timeline_name)
```

- **timeline_changed** Emitted when a timeline changes, usually via a timeline_changed event. It returns the human readable name of the old timeline and new timeline
```gdscript
func start_dialog():
	var dialog = Dialogic.start("my_timeline")
	dialog.connect("timeline_changed", self, "_on_timeline_changed")
	add_node(dialog)

func _on_timeline_end(old_timeline_name, new_timeline_name):
	print('Timeline changed!! Was  in ', old_timeline_name, ' now in ', new_timeline_name)
```

-**letter_displayed** - Emitted after EACH letter appears in a dialog box. It returns the letter that is displayed.
```gdscript
func start_dialog():
	var dialog = Dialogic.start("my_timeline")
	dialog.connect("letter_displayed", self, "_on_letter_displayed")
	add_node(dialog)

func _on_letter_displayed(letter):
	print('New Letter! ', letter)
```

-**text_complete** - Emitted after text has finished displaying. It returns a dictionary of the event data that completed. This event generally does what you'd expect the **event_end** to do.
```gdscript
func start_dialog():
	var dialog = Dialogic.start("my_timeline")
	dialog.connect("letter_displayed", self, "_on_text_complete")
	add_node(dialog)

func _on_text_complete(event_dict):
	print('Text Complete! Here is the data ', event_dict)
```

-**portrait_changed** - Emitted after a new portait has taken focus. This returns a reference to the scene **under the dialog node**. If you are using a custom scene as a portrait, this will give you easier access to the scene to run functions, access properties, or whatever else you might need. Otherwise it will give you the path to the Portrait control node. Access the scene via **portrait_path.custom_instance**
```gdscript
func start_dialog():
	var dialog = Dialogic.start("my_timeline")
	dialog.connect("portrait_changed", self, "_on_portrait_changed")
	add_node(dialog)

func _on_portrait_changed(portraitRef):
	print('Portrait Changed! Portrait Reference scene: ', portraitRef)
	portraitRef.custom_instance.MY_CUSTOM_FUNCTION('My Arg')
```

The Auto advance api adds a utility signal
```gdscript
auto_advance_toggled
```
Which returns the boolean value of the auto advance state. Use this to better control your UIs tied to the auto advance code
```
Dialogic.auto_advance_on(true)
```
