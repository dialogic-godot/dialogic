## ✅ Basic Usage

After installing the plugin, you will find a new **Dialogic** tab at the top, next to the Assets Lib. Clicking on it will display the Dialogic editor.

Using the buttons on the top left, you can create 4 types of objects:

* **Timelines**: The actual dialog! Control characters, make them talk, change the background, ask questions, emit signals and more!
* **Characters**: Each entry represents a different character. You can set a name, a description, a color, and set different images for expressions. When Dialogic finds the character name in a text, it will color it using the one you specified.
* **Definitions**: These can be either a simple variable, or a glossary entry.
  * Variables: Can have a name and a string value. The plugin tries to convert the value to a number when doing comparisons in `if` branches. TO show a variable content in a dialog box, write `[variable_name]`.
  * Glossary: Can have a name, a title, some text and some extra info. When the given name is found inside a dialog text, it will be colored and hovering the cursor over the name will display an infobox.
* **Themes**: Control how the dialog box appears. There are many settings you can tweak to suit your need.

Dialogic is very simple to use, try it a bit and you will quickly understand how to master it.

## 📖 v1.0 Documentation

The `Dialogic` class exposes methods allowing you to control the plugin:

### 🔶 start

```gdscript
start(
  timeline: String, 
  reset_saves: bool=true, 
  dialog_scene_path: String="res://addons/dialogic/Dialog.tscn", 
  debug_mode: bool=false
  )
```

Starts the dialog for the given timeline and returns a Dialog node. You must then add it manually to the scene to display the dialog.

Example:
```gdscript
var new_dialog = Dialogic.start('Your Timeline Name Here')
add_child(new_dialog)
```

This is exactly the same as using the editor: you can drag and drop the scene located at /addons/dialogic/Dialog.tscn and set the current timeline via the inspector.

- **@param** `timeline`	The timeline to load. You can provide the timeline name or the filename.
- **@param** `reset_saves` True to reset dialogic saved data such as definitions.
- **@param** `dialog_scene_path` If you made a custom Dialog scene or moved it from its default path, you can specify its new path here.
- **@param** `debug_mode` Debug is disabled by default but can be enabled if needed.
- **@returns** A Dialog node to be added into the scene tree.

### 🔶 start_from_save

```gdscript
start_from_save(
  initial_timeline: String, 
  dialog_scene_path: String="res://addons/dialogic/Dialog.tscn", 
  debug_mode: bool=false
  )
```

Same as the start method above, but using the last timeline saved.

### 🔶 get_default_definitions

```gdscript
get_default_definitions()
```

Gets default values for definitions.

- **@returns** Dictionary in the format `{'variables': [], 'glossary': []}`


### 🔶 get_definitions

```gdscript
get_definitions()
```

Gets currently saved values for definitions.

- **@returns** Dictionary in the format `{'variables': [], 'glossary': []}`


### 🔶 save_definitions

```gdscript
save_definitions()
```

Save current definitions to the filesystem. Definitions are automatically saved on timeline start/end.

- **@returns** Error status, `OK` if all went well


### 🔶 reset_saves

```gdscript
reset_saves()
```

Resets data to default values. This is the same as calling start with reset_saves to true.


### 🔶 get_variable

```gdscript
get_variable(name: String)
```

Gets the value for the variable with the given name.

The returned value is a String but can be easily converted into a number using Godot built-in methods: [`is_valid_float`](https://docs.godotengine.org/en/stable/classes/class_string.html#class-string-method-is-valid-float) and [`float()`](https://docs.godotengine.org/en/stable/classes/class_float.html#class-float-method-float).

- **@param** `name` The name of the variable to find.
- **@returns** The variable's value as string, or an empty string if not found.


### 🔶 set_variable

```gdscript
set_variable(name: String, value)
```

Sets the value for the variable with the given name.

The given value will be converted to string using the [`str()`](https://docs.godotengine.org/en/stable/classes/class_string.html) function.

- **@param** `name` The name of the variable to edit.
- **@param** `value` The value to set the variable to.
- **@returns** The variable's value as string, or an empty string if not found.


### 🔶 get_glossary

```gdscript
get_glossary(name: String)
```

Gets the glossary data for the definition with the given name.

Returned format: `{ title': '', 'text' : '', 'extra': '' }`

- **@param** `name` The name of the glossary to find.
- **@returns** The glossary data as a Dictionary. A structure with empty strings is returned if the glossary was not found. 


### 🔶 set_glossary

```gdscript
set_glossary(name: String, title: String, text: String, extra: String)
```

Sets the data for the glossary of the given name.

Returned format: `{ title': '', 'text' : '', 'extra': '' }`

- **@param** `name` The name of the glossary to edit.
- **@param** `title	` The title to show in the information box.
- **@param** `text` The text to show in the information box.
- **@param** `extra` The extra information at the bottom of the box.


### 🔶 get_current_timeline

```gdscript
get_current_timeline()
```

Gets the currently saved timeline.

Timeline saves are set on timeline start, and cleared on end. This means you can keep track of timeline changes and detect when the dialog ends.

- **@returns** The current timeline filename, or an empty string if none was saved.