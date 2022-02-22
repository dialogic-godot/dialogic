# Saving and loading

Dialogic can handle saving and loading the game for you.

## Simple saving
By default, Dialogic's autosave settings are turned on. They will save whenever you start a new timeline.
To trigger a save you can also use the `Save` event, or call `Dialogic.save()`.

## Simple loading
All the saving in the world will have little visible effece if you don't load your dialogue.

To do so, you can call `Dialogic.load()`.

Then you can use `Dialogic.start('')` to play from the last saved point. As a fallback (for the first game, or if the player finished the game last time), you can give a default timeline as the second argument: `Dialogic.start('', 'Chapter1')`.

In case you want to restart, you can do `Dialogic.reset_saves()` before calling `Dialogic.start()`.



## Implementing save slots
Many games allow you to have more then one save at the same time. 

To make this easily possible, you can do `Dialogic.save('slot_name')` and `Dialogic.load('slot_name')`.

There are some more functions for slots:

- `Dialogic.get_slot_list()` returns a list of slots.
- `Dialogic.erase_slot('slot_name')` deletes the given slot.
- `Dialogic.get_current_slot()` returns the name of the last loaded slot.
- `Dialogic.reset_saves('slot_name')` will reset the given slot.

For making menus with this, the function `Dialogic.has_current_dialog_node()` is useful, as it will tell you whether a dialogue node is instanced right now.

For **visual novels** there is a [template with a full menu](https://github.com/Dialogic-Godot/visual-novel-template). You can look at the implementation there if you are want to know how to do a menu.


## Custom saving/loading (export+import)
Some games might not want to use dialogic's built in saving system, but still want to save and load dialogic data.

The `Dialogic.export()` function will give you all the important information in a dictionary that you can save or do whatever you want with. 

You can then use `Dialogic.import(data)` to import a dictionary. After you have done so, you can use `Dialogic.start('')` like before.


## Saving custom information
Dialogic has a dictionary of custom information that you can use to store things unrelated to dialogic too. You could store your players location in there or other variables.

There are two functions for this:
- `Dialogic.get_saved_state_general_key('key')`
- `Dialogic.set_saved_state_general_key('key', value)`

This dictionary is saved and loaded (or exported/imported) alongside the other information.