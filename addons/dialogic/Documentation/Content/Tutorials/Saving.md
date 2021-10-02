# Saving and Loading

Dialogic save system can be used in two ways:

With **save slots** on timeline start and end. 
Or the **manual** way. This lets you handle the import and export of data manually.


## Examples

### Very simple

`     # when starting your game
     Dialogic.load()

     # when you want to start your dialog
     var dialog = Dialogic.start('', 'my_first_timeline')
     add_child(dialog)

     # to save the dialog
     Dialogic.save()
     
     # if you want to restart
     Dialogic.reset_saves()`

### Save slots
`     # when deciding on a save slot
     Dialogic.load('my_slot')

     # when you want to start your dialog
     var dialog = Dialogic.start('', 'my_first_timeline')
     add_child(dialog)

     # to save the dialog
     Dialogic.save() # you can specify what slot, but you don't need to
     
     # if you want to clear that slot
     Dialogic.reset_saves('my_slot')

     # if you want to remove that slot
     Dialogic.erase_slot('my_slot')

     # to know what slots exist
     Dialogic.get_slot_names()

     # if you need to know if you can save
     Dialogic.has_current_dialog_node()

     # if you need to know, what slot is currently used
     Dialogic.get_current_slot()
`

### Manual saving (export/import)

`
    # when you loaded the data
    Dialogic.import(data)

    # when you want to start your dialog
    Dialogic.start('', 'my_first_timeline')

    # when you want to save the data
    var data = Dialogic.export()

    # if you need to know if you can save
    Dialogic.has_current_dialog_node()
`

## Loading
To load the data you can use Dialogic.load() or Dialogic.import()


## Saving
By default Dialogic saves the current state and definitions each time a timeline starts or ends (you can disable this in the settings menu).
If you want to load from this default save, you can just use `Dialogic.start_from_save()`. Make sure to leave the first argument empty.
Here is a short example script:
`
func _ready():
	var dialog = Dialogic.start_from_save('', 'Introduction')
	add_child(dialog)
`
If you want to start the game from the beginning, use `Dialogic.reset_saves()` before this.


## Save slots
Like the previous one, this approach handles saving for you. It also allows for **multiple save slots**. These will be saved in the user directory under `user://dialogic/SAVE_NAME/`.
These are the functions intended for you:
- `Dialogic.save_current_info(save_name) `
	-> saves all the data of the latest dialog node into the save "save_name"
- `Dialogic.get_save_names_array()`
	-> returns a list of all save names (useful for menus)
- `Dialogic.erase_save(save_name) `
- `Dialogic.has_current_dialog_node()` 
	-> useful if you need to know if you can save

They should enable you to create a visual novel menu with all features you would normally expect.

*[A full visual novel template using this method can be found here.](https://github.com/Dialogic-Godot/visual-novel-template)*

## The manual way
If Dialogic is not the main part of your game, you probably have an own saving/loading system. 
You can easily get the current data out of Dialogic and integrate it with your current code. 

There are three parts of the data:
- **current definitions**: values and glossary entries
- **dialog state**: The current timeline, event index, portraits, background, background music, etc...
- **game state**: By default the state only contains a timeline that has to be set manually. You can add other info to it too. This one is legacy and not perfect but necessary for people who created their projects before 1.3.

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
The `DialogicSingleton` got removed because it proved to be an unstable mess. This, and the introduction of the new and improved built-in saving system, mean that you will need to change some smaller things in your existing code.

The `Dialogic.start_from_save()` works a bit differently now. If you want to provide a default timeline, it's the second argument now. Also it wont use the `current_timeline` anymore. Instead it uses the `last_dialog_state` that is imported with `Dialogic.import()`.