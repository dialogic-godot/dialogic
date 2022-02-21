# Enable/start dialog?

**How can I make my dialogue show up in game?**
There are two ways of doing this: you can use GDScript or the Scene Editor.

Using the `Dialogic` class, you can add dialog nodes from code easily:

```
var new_dialog = Dialogic.start('Your Timeline Name Here')
add_child(new_dialog)
```

Using the editor, you can drag and drop the scene located at `/addons/dialogic/Dialog.tscn` and set the current timeline via the Inspector.