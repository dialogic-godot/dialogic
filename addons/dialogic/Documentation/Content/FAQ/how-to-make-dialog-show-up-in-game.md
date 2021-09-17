# How can I make a dialog show up in game?

There are two ways of doing this; using gdscript or the scene editor.

Using the `Dialogic` class you can add dialogs from code easily:

```
var new_dialog = Dialogic.start('Your Timeline Name Here')
add_child(new_dialog)
```

And using the editor, you can drag and drop the scene located at `/addons/dialogic/Dialog.tscn` and set the current timeline via the inspector.