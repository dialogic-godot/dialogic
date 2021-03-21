# Dialogic Release Candidate v1.0 ![Godot v3.2](https://img.shields.io/badge/godot-v3.2.4-%23478cbf)
Create dialogs, characters and scenes to display conversations in your Godot games. 

![Screenshot](https://coppolaemilio.com/images/dialogic/dialogic-hero.png?v2)

⚠️ Under development! ⚠️

The plugin is not production ready, this means that it will not work in your game right now unless you know what you are doing. Make sure to follow the repo for the next update.

---

## Changelog

### 🆕 v1.0 - WIP
  - When upgrading from 0.9 to the current version things might not work as expected:
    - ⚠ **PLEASE MAKE A BACKUP OF YOUR PROJECT BEFORE UPGRADING** ⚠
    - Glossary variables will be lost
    - Glossary related events will not be loaded (`If condition Event` and `Set Value Event`)
    - The theme you made in the 0.9 theme editor will be lost. You will have to remake it.
  - New layout:
    - All editors in the same screen. Say goodbye to tabs!
    - You can now rename resources by double clicking them
    - New Settings panel for advanced properties
  - Character Editor:
    - Set the scale of your character's portrait
    - Add offset to the portrait
  - Timeline Editor:
    - New `Theme event` to change the theme in the middle of a timeline
    - Re-enabled the `Scene Event`
  - Theme Editor:
    - You can now add multiple themes
    - Moved the preview button to the left side so it is never hidden by default in small screens
    - New properties:
      - `Box size` set the width and height of the dialogue box in pixels
      - `Alignment` you can now align the text displayed (Left, Center, Right)
      - `Bottom Gap` The distance between the bottom of the screen and the start of the dialog box.
  - Glossary was renamed to Definitions. I feel like the word `Definitions` cover both "variables" and "lore" a bit better.
  - Definitions:
    - Dynamic types! All variables are just dynamic, so they can be ints, floats or strings.
  - The events now emit signals. Thank you [Jesse Lieberg](https://github.com/GammaGames) for your first contribution!
  - Re-added the auto color for character names in text messages
  - You can display the definition values in a text event by doing: `[definition name here]`.
  - Fixed some resource issues with exported games
  - Special thanks to [Arnaud Vergnet](https://github.com/arnaudvergnet) for all your work in improving Definitions, conditional events and many more! 🙇‍♂️

To view the full changelog [click here](https://github.com/coppolaemilio/dialogic/blob/master/CHANGELOG.md). 

---

## Installation

### Downloading the plugin

To install a Dialogic, download it as a ZIP archive. All releases are listed here: https://github.com/coppolaemilio/dialogic/releases. Then extract the ZIP archive and move the `addons/` folder it contains into your project folder. Then, enable the plugin in project settings.

If you want to know more about installing plugins you can read the [official documentation page](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html).

You can also install Dialogic using the **AssetLib** tab in the editor, but the version here will not be the latest one available since it takes some time for it to be approved.

### Preparing the export

When you export a project using Dialogic, you need to add `*.json, *.cfg` on the Resources tab (see the image below). This allows Godot to pack the files from the `/dialogic` folder.

![Screenshot](https://coppolaemilio.com/images/dialogic/exporting-2.png?v2)

## Basic Usage

After installing the plugin, you will find a new **Dialogic** tab at the top, next to the Assets Lib. Clicking on it will display the Dialogic editor.

Using the buttons on the top left, you can create 4 types of objects:

* **Timelines**: The actual dialog! Control characters, make them talk, change the background, ask questions, emit signals and more!
* **Characters**: Each entry represents a different character. You can set a name, a description, a color, and set different images for expressions. When Dialogic finds the character name in a text, it will color it using the one you specified.
* **Definitions**: These can be either a simple variable, or a glossary entry.
  * Variables: Can have a name and a string value. The plugin tries to convert the value to a number when doing comparisons in `if` branches. TO show a variable content in a dialog box, write `[variable_name]`.
  * Glossary: Can have a name, a title, some text and some extra info. When the given name is found inside a dialog text, it will be colored and hovering the cursor over the name will display an infobox.
* **Themes**: Control how the dialog box appears. There are many settings you can tweak to suit your need.

Dialogic is very simple to use, try it a bit and you will quickly understand how to master it.

## v1.0 Documentation

**Note:** ⚠️ This documentation is valid only for the v1.0 branch. ⚠️

The `Dialogic` class exposes methods allowing you to control the plugin:

* Node `start(timeline: String, dialog_scene_path: String, debug_mode: bool)`

Starts the dialog for the given timeline and returns a Dialog node. You must then add it manually to the scene to display the dialog.

If you made a custom Dialog scene or moved it from its default path, you can specify its new path here. Debug is disabled by default but can be enabled if needed.

Example usage:

```
var new_dialog = Dialogic.start('Your Timeline Name Here')
add_child(new_dialog)
```

This is exactly the same as using the editor: you can drag and drop the scene located at `/addons/dialogic/Dialog.tscn` and set the current timeline via the inspector.

* void `reset_saves()`

Resets saved data (definitions) to the default values you set in the editor. Definitions are saved across runs in `user://dialogic/definitions.cfg`, calling this function will clear this file. Useful for a `New Game` behavior.

* String `get_var(variable: String)`

Gets the value associated to the given variable. Currently, only variable definitions can be queried.

The returned value is a String but can be easily converted into a number using Godot built-in methods: [`is_valid_float`](https://docs.godotengine.org/en/stable/classes/class_string.html#class-string-method-is-valid-float) and [`float()`](https://docs.godotengine.org/en/stable/classes/class_float.html#class-float-method-float).

* String `set_var(variable: String, value)`

Sets the value associated to the given variable. Currently, only variable definitions can be set.

The given value will be converted to string using the [`str()`](https://docs.godotengine.org/en/stable/classes/class_string.html) function. 

## FAQ 

### 🔷 How can I make a dialog show up in game?
There are two ways of doing this; using gdscript or the scene editor.

Using the `Dialogic` class you can add dialogs from code easily:

```
var new_dialog = Dialogic.start('Your Timeline Name Here')
add_child(new_dialog)
```
And using the editor, you can drag and drop the scene located at `/addons/dialogic/Dialog.tscn` and set the current timeline via the inspector.

### 🔷 Can I use Dialogic in one of my projects?
Yes, you can use Dialogic to make any kind of game (even commercial ones). The project is developed under the [MIT License](https://github.com/coppolaemilio/dialogic/blob/master/LICENSE). Please remember to credit!


### 🔷 Why are you not using graph nodes?
When I started developing Dialogic I wanted to do it with graph nodes, but when I tried some of the existing solutions myself I found that they are not very useful for long conversations. Because of how the graph nodes are, the screen gets full of UI elements and it gets harder to follow. I also researched other tools for making Visual Novels (like TyranoBuilder and Visual Novel Maker) and they both work with a series of events flowing from top to bottom. I still haven't developed a complex game using both systems to tell which one is better but I don't want to break the conventions too much. 
If you want to use graph based editors you can try [Levraut's LE Dialogue Editor](https://levrault.itch.io/le-dialogue-editor) or [EXP Godot Dialog System](https://github.com/EXPWorlds/Godot-Dialog-System).


### 🔷 The plugin is cool! Why is it not shipped with Godot?
I see a lot of people saying that the plugin should come with Godot, but I believe this should stay as a plugin since most of the people making games won't be using it. I'm flattered by your comments but this will remain a plugin :)


### 🔷 Can I use C# with Dialogic?
You probably can, but I have no idea how to 😓. If you know your way around C# and Godot please let me know! https://github.com/coppolaemilio/dialogic/issues/55

---

## Source structure

### / (At the root level)
`plugin.cgf` - The required file to be recognized by Godot.

`dialogic.gd` - This is the script that loads the addon. Very minimal and should probably have more stuff? Not sure.

`Dialog.tscn` - Main scene containing the text bubble and all the required sub-nodes to display your timelines in-game. I left this file in the root node because it will be easier to find and drag-drop to an existing scene.


### /Editor

`EditorView.tscn` - When you click on the Dialogic tab, this is the scene you see on the main editor panel. This contains all the sub editors and scripts needed for managing your data.

`editor_view.gd` - This is the code embedded in the `EditorView.tscn`. It handles the right click context menus, resource removing dialogs and file selectors.

`/MasterTree` - This is the [Tree](https://docs.godotengine.org/en/stable/classes/class_tree.html#class-tree) with all the resources. It handles many things like renaming, saving and several other aspects of resource management.

`/TimelineEditor` - Everything related to the timeline editor.

`/ThemeEditor` - Everything related to the theme editor.

`/DefinitionEditor` - Everything related to the definition editor.

`/SettingsEditor` - A very simple editor for changing how Dialogic behaves.

`/Pieces` - Inside this directory you have all the event nodes that populate the timeline editor. Each one has its own name and script. **The name is important** since it has to be instanced from the `editor_view.gd` when clicking on buttons of the same name.

`/Pieces/Common` - This is where some of the common element of the pieces are saved. Things like the Character Picker, the Portrait Picker or the Drag Controller are used in several event nodes, so I'm trying to make them easier to plug in to future events that might need them as well.

`/CharacterEditor` - Everything related to the character editor. This also contains the script `PortraitEntry.gd` and the scene `PortraitEntry.tscn`. When you add a new expression for one of your characters in the Character Editor this node/script will be instanced for handling the settings.

### /Fonts
This directory contains the font files and the resources to load. 

`DefaultFont.tres` - This is the default font used for dialog text such as buttons, names, and the main chat bubble.

`GlossaryFont.tres` - The default font for the small popup on hover. This is basically the same font but smaller because you know... Godot <3 Fonts

### /Images
You shouldn't open this folder expecting it to be organized. Welcome to the world of mixed naming conventions and CaSiNgStYlEs.

All icons are `.svg` files so they can scale nicely. I tried reusing many of the default Godot icons, but instead of using the native ones I copy-pasted the svgs and run with it. I should probably replace them and make the custom one more in line with the rest of the editor.

`/Images/background` - Here you will find the default background images for the dialogs. More will come in the future.

`/Images/portraits` - Some placeholder images for an example project. I might delete these since I'll probably be hosting that somewhere else.

`/Images/tutorials` - Right now it only has one file, but every image created for warnings/tutorials/tips will be placed here. Hopefully.

`/Images/Toolbar` - It contains the icons for the toolbar in the main view.


### /Nodes

`ChoiceButton.tscn` - This is the button created by Dialogic's options events. The node `/Dialog.tscn` will instance these when displaying the options to the user.

`dialog_node.gd` - The script associated with `/Dialog.tscn`. This contains all the logic behind the node and manages everything from timeline parsing, in-game signals and all the visual aspects of the dialog.

`glossary_info.gd` - Handles the logic behind the small popup that shows up when you hover the cursor on one of the highlighted words from the glossary inside a dialog. Part of this logic lives inside the `dialog_node.gd` script and should probably be moved here.

`Portrait.tscn` and `Portrait.gd` - Whenever you make a character join a scene, this is the node used for instancing and displaying an image in the screen. It also contains a few effects for fading in/out of a scene.

---

## Credits
Code made by [Emilio Coppola](https://github.com/coppolaemilio).

Contributors: [Toen](https://twitter.com/ToenAndreMC), Òscar, [and more!](https://github.com/coppolaemilio/dialogic/graphs/contributors)

Documentation page generated using: https://documentation.page/ by [Francisco Presencia](https://francisco.io/)

Placeholder images are from Toen's YouTube DF series:
 - https://toen.world/
 - https://www.youtube.com/watch?v=B1ggwiat7PM

### Thank you to all my [Patreons](https://www.patreon.com/coppolaemilio) for making this possible!
- Mike King
- Allyson Ota
- Buskmann12
- David T. Baptiste
- Francisco Lepe
- Problematic Dave
- Rienk Kroese
- Tyler Dean Osborne
- Gemma M. Rull
- Alex Barton
- Joe Constant
- Kyncho
- JDA
- Chris Shove
- Luke Peters
- Wapiti
- Noah Felt
- Penny
- Lukas Stranzl
- Sl Tu
- Garrett Guillotte
- George Castro
- GammaGames
- Karl Anderson
- A P
- Rokatansky

Support me on [Patreon https://www.patreon.com/coppolaemilio](https://www.patreon.com/coppolaemilio)

[MIT License](https://github.com/coppolaemilio/dialogic/blob/master/LICENSE)
