# Saving and Loading

Dialogic can be used in many different ways, but for simplicities sake, there are two main ways of handeling saving and loading:

A) For games that consist of mainly dialog and little else (e.g. `Visual Novels`), there are many functions that do pretty much everything for you. 
B) For games that use Dialogic just for the dialog, functions are provided to save and load the current data so you can handle saving your own way.


## The Visual Novel way
This approach handles saving for you. It also allows for **multiple save slots**. These will be saved in the user directory under `user://dialogic/SAVE_NAME/`.

These are the functions intedended for you:
- `Dialogic.resume_from_save(save_name)`
	-> very similar of the start method but it loads all the data from the save "save_name" 
- `Dialogic.save_current_state(save_name) `
	-> saves all the data of the latest dialog node into the save "save_name"
- `Dialogic.get_saves_names_array()`
	-> returns a list of all save names (useful for menus)
- `Dialogic.erase_save(save_name) `
- `Dialogic.has_current_dialog_node()` 
	-> useful if you need to know if you can save

They should enable you to create a visual novel like menu with all features you would normally expect.


## The manual way
If Dialogic is not the main part of your game, you probably have an own saving/loading system. 
You can easily get the current data out of dialogic and back in again. 

There are three parts of the data:
- the **current definitions** (values and glossary entries)
- the **dialog state** consisting of the current timeline, event index, portraits, background, background music, etc...
- the game **state**. By default the state only contains a timeline that has to be set manually. You can add other info to it too. This one is legacy and not perfect but necessary for people who created their projects before 1.3.

You can get all this data with the `Dialogic.export()` function and load it back in with the `Dialogic.import()` function.

When you have imported, you can use the `Dialogic.start_from_state()` function to load the last timeline.
Or you can use the `Dialogic.start(my_timeline, false)` to start a different timeline but with the imported definitions.

### Notes for people from before 1.3
The DialogicSingleton got removed, because it proved to be an unstable mess. This and the introduction of the new improved built-in saving system mean you will need to change some smaller things.

The Dialogic.start_from_save() was renamed to Dialogic.start_from_state() function. You can 
