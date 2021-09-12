# Saving and Loading

Dialogic can be used in many different ways, but for simplicities sake, there are two main ways of handeling saving and loading:

A) For games that consist of mainly dialog and little else (e.g. `Visual Novels`), there are many functions that do pretty much everything for you. 
B) For games that use Dialogic just for the dialog, functions are provided to save and load the current data so you can handle saving your own way.


## The Visual Novel way
This approach handles saving for you. It also allows for **multiple save slots**. These will be saved in the user directory under `user://dialogic/SAVE_NAME/`.

These are the functions intedended for you:
- Dialogic.resume_from_save(save_name)
- Dialogic.save_current_state(save_name)
- Dialogic.get_saves_names_array()
- Dialogic.erase_save(save_name)
- Dialogic.has_current_dialog_node()

They should enable you to create a visual novel like menu with all features you would normally expect.


## The manual way
If Dialogic is not the main part of your game, you probably have an own saving/loading system. 
You can easily get the current data out of dialogic and back in again. 

There are two types of data: 
- the **current definitions** (values and glossary entries)
- the **game state** consisting of the current timeline, event index, portraits, background, background music, etc...

