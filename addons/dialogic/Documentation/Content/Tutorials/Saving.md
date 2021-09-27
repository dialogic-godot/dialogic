# Saving and Loading

Dialogic can be used in many different ways, but for simplicities sake, there are three main ways of handeling saving and loading:

The **default way** will save to the default_slot on timeline start and end. 
The **visual novel way** is an expansion of the default. If you set it up, it allows for multiple save slots.
The **manual way** allows you to import and export data so you can handle saving yourself.

## The loading
In either way, the most important function is the one that starts a dialog from loaded data: 
`Dialogic.start_from_save(save_name = '', default_timeline = '', ...)`

If you ** provide a save_name**, it will load from that save slot.
If you do **not provide a save_name** , it will first try to use the currently loaded info (e.g. imported info).
If that fails, it will try to get the data from the default save_slot. 
If everything fails, it will load the given default_timeline instead.

## The default autosave way
By default dialogic saves the current state and definitions each time a timeline starts or ends. You can disable this in the settings menu.
If you want to load from this default save, you can just use `Dialogic.start_from_save()`. Make sure to leave the first argument empty.
Here is a short example script:
`
func _ready():
	var dialog = Dialogic.start_from_save('', 'Introduction')
	add_child(dialog)
`
If you want to start the game from the begining, use `Dialogic.reset_saves()` before this.


## The visual novel way
Like the previous one, this approach handles saving for you. It also allows for **multiple save slots**. These will be saved in the user directory under `user://dialogic/SAVE_NAME/`.
These are the functions intedended for you:
- `Dialogic.save_current_info(save_name) `
	-> saves all the data of the latest dialog node into the save "save_name"
- `Dialogic.get_saves_names_array()`
	-> returns a list of all save names (useful for menus)
- `Dialogic.erase_save(save_name) `
- `Dialogic.has_current_dialog_node()` 
	-> useful if you need to know if you can save

They should enable you to create a visual novel menu with all features you would normally expect.

*[A full visual novel template using this method can be found here.](https://github.com/Dialogic-Godot/visual-novel-template)*

## The manual way
If Dialogic is not the main part of your game, you probably have an own saving/loading system. 
You can easily get the current data out of dialogic and back in again. 

There are three parts of the data:
- the **current definitions** (values and glossary entries)
- the **dialog state** consisting of the current timeline, event index, portraits, background, background music, etc...
- the **game state**. By default the state only contains a timeline that has to be set manually. You can add other info to it too. This one is legacy and not perfect but necessary for people who created their projects before 1.3.

You can get all this data with the `Dialogic.export()` function and load it back in with the `Dialogic.import()` function.

When you have imported, you can use the `Dialogic.start_from_save()` function to load the last timeline.
Or you can use the `Dialogic.start(my_timeline, false)` to start a different timeline but with the imported definitions.

Here is an example:
`
func my_saving_function():
	...
	var file = File.new()
	file.open('user://my_save.txt', File.WRITE)
	file.store_var(Dialogic.export())
	file.close()
	...

func my_loading_function():
	...
	var file = File.new()
	file.open('user://my_save.txt', File.READ)
	Dialogic.import(file.get_var())
	file.close()
	
	var dialog = Dialogic.start_from_save()
	add_child(dialog)
`

### Notes for people from before 1.3
The DialogicSingleton got removed, because it proved to be an unstable mess. This and the introduction of the new improved built-in saving system mean you will need to change some smaller things.

The `Dialogic.start_from_save()` works a bit differently now. If you want to provide a default timeline, it's the second argument now. Also it wont use the "current_timeline" anymore. Instead it uses the 'last_dialog_state' that is imported with `Dialogic.import()`.