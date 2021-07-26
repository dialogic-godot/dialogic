# Full Documentation (old)
I hope you find what you are looking for here. If not you can try asking on [emilios discord server](https://discord.gg/v4zhZNh)!

## Contents

[Getting Started](#getting-started)
* [Installation](#-installation-downloading-the-plugin)

[Tutorials](#tutorials)
* [Your first dialogic project](#your-first-dialogic-project)

[Reference](#reference)

[Plugin Development](#plugin-development)

# Getting started
## ⚙ Installation: Downloading the plugin

To use Dialogic in your game you first have to insatll the plugin. You can do this using the **AssetLib** that is built into godot. Or you can download it from the github page. Because it takes some time to get approved, sometimes the version in the AssetLib is a bit outdated.

### Installation using the AssetLib
You can find the AssetLib tab at the top of the editor. Search for Dialogic. Then click "Download". When the download is finnished, click "Install". You can deselect the **.github** folder. You only need the addons folder and all it's children.
![grafik](https://user-images.githubusercontent.com/42868150/114314756-48dfe180-9afc-11eb-86d6-bd522ac1cbd4.png)

Now go to the project settings then into the plugins tab and activate dialogic. You should see an Dialogic tab in the top now.

### Installation from GitHub
You can find all stable releases here: https://github.com/coppolaemilio/dialogic/releases. Download the newewst release. Then extract the ZIP archive and move the `addons/` folder it contains into your project folder. Then, enable the plugin in the project settings in the plugins tab.

If you want to know more about installing plugins you can read the [official documentation page](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html).


# Tutorials
Dialogic is very simple to use, try it a bit and you will quickly understand how to master it.

## Your first dialogic project
Let's begin creating your first dialog with dialogic!

- [Meeting the dialogic tab](#meeting-the-dialogic-tab)
- [Creating your first character](#creating-your-first-character)
- [Creating your first timeline](#creating-your-first-timeline)
- [Adding your first DialogNode to a scene](#adding-your-first-dialognode-to-a-scene)
- [Making your first definition](#making-your-first-definition)
- [Create your first dialog theme](#create-your-first-dialog-theme)
- [How to export your game](#how-to-export-the-game)
- [How to export your game](#how-to-export-the-game)

- - -
### Meeting the dialogic tab
All the things related to your dialog will be done in the dialogic tab. You can access it like the 2D and 3D tab on the very top of the editor. You can access all the things you create with dialogic here.  
![Dialogic Tab](https://user-images.githubusercontent.com/42868150/114405867-5dc57f00-9ba7-11eb-835e-f685945af72e.PNG)

Let's have a look into the toolbar at the top.

![Toolbar](https://user-images.githubusercontent.com/42868150/114406011-79308a00-9ba7-11eb-9fa5-ba221eb8da96.PNG)

Here you can create dialogics four "ressources": 
* **Timelines** that represent a list of events. Control characters, make them talk, change the background, ask questions, emit signals and more!
* **Characters** that represent your characters. You can set a name, a description, a color, and set different images for expressions.
* **Definitions** that can be used as variables (to branch your story or be used inside the texts) or as information for the player (a name and description are shwon when the player hovers over the word).
* **Themes** that specify how your dialog is looking. There are many settings you can tweak to suit your need.

You will hear more on each of them later.

All your ressources are shown in the big master tree on the left. You can select on which you want to work there.

Let's continue! What is the most important thing for a dialog? Someone to talk to. So we will create our first character.
- - -
### Creating your first character
Click the little character icon in the toolbar to create a new character. You will see the character editor now.
![Empty Character Editor](https://user-images.githubusercontent.com/42868150/114406042-80f02e80-9ba7-11eb-9c52-798d4a67f8d8.PNG)


We will go over it step by step.
Go on and give your character a name and a color. You can ignore the rest of these settings for now.
![YFD Character NameColor](https://user-images.githubusercontent.com/42868150/114406074-88173c80-9ba7-11eb-9b33-92bac8c7890b.PNG)
Next let's add a default look for them. You can select a file by clicking the tree dots.
![grafik](https://user-images.githubusercontent.com/42868150/114315214-32d32080-9afe-11eb-8b80-660f68b8623e.png)

If you do not have a image to use right now, you can use the default dwarf from the Example Assets folder inside the dialogic folder.

> ⚠️ THERE SHOULD BE AN EXPLENATION FOR OFFSET AND SCALE. I HOPE THE PORTRAITS WORK OUT OF THE BOX IN THE NEXT STABLE RELEASE.

This is all for now. You can create a second character just like this.

When you are ready let's create our first ever dialog!
- - -
### Creating your first timeline
Timelines specify what events happen in which order. Create a new timline with the icon in the toolbar.
You can now see the timeline editor. You can find all possible events on the right.
![grafik](https://user-images.githubusercontent.com/42868150/114315458-6498b700-9aff-11eb-830d-9472b16f82a1.png)


#### | Give it a name
Let's first give our timeline a proper name. To do so doubleclick the ressource on the right. Give it a name of your liking.
![grafik](https://user-images.githubusercontent.com/42868150/114315551-be00e600-9aff-11eb-9aac-5ecd78cebe0d.png)


#### | Now let's talk about the EVENTS!

You can click each of the buttons on the rigth to add the event to the timeline. Or you can drag and drop it to the position you want. 

You can select events by left clicking them. When you click one of the event buttons on the right, new events will be added below the selected one.

You can select events and delte them with CRTL + DEL.

In the timeline you can reorder the events by dragging and dropping them. You can also move the selected event up/down with ALT+UP/ALT+DOWN.

#### | Let's do it!
The events are sorted on the right so you can more easily find them. Let's look at the first three. We will use them to built our first timeline. 

Click on the `Character Join` button and drag it onto the timeline. Drop it there (by releasing the mouse button).

All of the events have settings to customize them. For the `Character Join` event, we can set a character that should join, it's portrait (only if the character has more then one) and the position at which the character should be standing by selecting one of the five positions.

When you have done that, add a `Text` event the same way.

For this event we can specify which character talks, the portrait they have while saying it (if they have more then one) and what they say. On default, linebreaks split the message and empty lines are just ignored.

Let your character say something!

If you are ready let the character leave with the `Character Leave` event.
You can find explenations for all events and their settings further down in the [refrence](#refrence).

#### | On we go
Now your dialog is ready to be played! But how? Let's find out!

- - -
### Adding your first DialogNode to a scene

There are two ways of doing this, using gdscript or the scene editor.

#### | Instancing the scene using gdscript
Using the `Dialogic` class you can add dialogs from code easily:

```
var new_dialog = Dialogic.start('Your Timeline Name Here')
add_child(new_dialog)
```
#### | Instancing the scene using the editor
Using the editor, you can drag and drop the scene located at `/addons/dialogic/Dialog.tscn` and set the current timeline via the inspector.

#### | Run, game, run!
If you have done one of the previous steps, run your game (F5). I hope you will see your dialog appear. If not check if you missed something. You can also always ask for help on the discord.

Before you start to make your own dialog, let us introduce some more cool things!
- - -
### Making your first definition
This is already pretty cool, but let's make things more complex. We mentioned them earlier but here they are: Definitons.

#### | Make one?
Create a new definition by clicking the X-icon in the toolbar. You will now see the definition editor.

Here you can give your definition a name and a default value, but behold. Do you see that `Type` button? It's very important because it differentiates to types of definitions that are very diffrent:

A `Variable` just has a name and a value. These definitions can be used to store information (that can be inserted into text events) and to use that information in condition events.

An `Extra Information` is used for extra information. WOW. Sorry. If the name of such a definition is inside a text, the player can hover over it and see a box with information appear.

#### | Make one!
Let's first create a `variable`, so make sure that type is selected. We will call it weapon and give it a default value of "knife". 

#### | And... another one!
Now let's create another defintion, this time of type `Extra Information`. Select the type.

I will call mine "Hogwarts" and use the same as the title. I will enter some usefull information and some lore to be displayed at the bottom.

#### | Now use them. Do it!
These definitions are nice and everything. But let's put them to actual use.

Go back into your timeline. Add a new `Text` event.
Now we want to mention the characters weapon. We will write the name of the definition in brackets:
> ⚠️ ADD IMAGE HERE

Test the game. The definitions name is replaced by it's value.
Let's get even more crazy. Add a `Set Value` event and drag it above the `Text` event from earlier. In the event select the variable and set it's value to "Axe".

Now play the game again. Can you spot the difference?

#### | What about the Extra information

To use the extra information definitions you don't have to put them in brackets. Just use the word somewhere in your text. Let's try it out. Add a text event that contains the name of your extra information definition.

Run the game and hover over the word. Cool, right?

- - -
### Create your first dialog theme
- - -
### How to export the game
When you export a project using Dialogic, you need to add `*.json, *.cfg` on the Resources tab (see the image below). This allows Godot to pack the files from the `/dialogic` folder.

![Screenshot](https://coppolaemilio.com/images/dialogic/exporting-2.png?v2)

### Behind the scenes
If you wonder how all of this works, here is some (very) short explantaion.

All the ressources are saved as jsons in a dialogic folder in your games root directory.

Boom. There you go :). I'm to lazy to explain more.
- - -
- - -

📖 
# Reference
Here you should find explanations for all the settings and public functions.

## Editors
### Timeline Editor
![grafik](https://user-images.githubusercontent.com/42868150/114318500-89942680-9b0d-11eb-9922-57469f486669.png)

You can click each of the buttons on the rigth to add the event to the timeline. Or you can drag and drop it to the position you want. 

You can select events by left clicking them. When you click one of the event buttons on the right, new events will be added below the selected one.

You can select events and delte them with CRTL + BACKSPACE.

In the timeline you can reorder the events by dragging and dropping them. You can also move the selected event up/down with ALT+UP/ALT+DOWN.

### Character Editor
### Definitions Editor
### Theme Editor
### Settings Page

## Events
### Text

![Event Text](https://user-images.githubusercontent.com/42868150/114401157-f3aadb00-9ba2-11eb-9077-7e419e46d036.PNG)

The text event can be used to let a character (or noone) say text. If a character is selected, additionaly a portrait can be selected.

### Character Join

![Event Character Join](https://user-images.githubusercontent.com/42868150/114401200-fb6a7f80-9ba2-11eb-9762-47a795c3b0a4.PNG)

### Character Leave
![Event Character Leave](https://user-images.githubusercontent.com/42868150/114401237-045b5100-9ba3-11eb-854c-e9a248c3d7c2.PNG)

### Question

![Event Question](https://user-images.githubusercontent.com/42868150/114401272-0d4c2280-9ba3-11eb-9b7f-d6e4650ec472.PNG)

![Event Question in use](https://user-images.githubusercontent.com/42868150/114406417-d0365f00-9ba7-11eb-861a-2859a865d572.PNG)

### Choice
![Event Choice](https://user-images.githubusercontent.com/42868150/114406300-b72dae00-9ba7-11eb-889b-c3bbf97c1635.PNG)

### Condition
![Event Condition](https://user-images.githubusercontent.com/42868150/114406364-c6146080-9ba7-11eb-81d6-7d5d6e4a88a4.PNG)

![Event Condition in use](https://user-images.githubusercontent.com/42868150/114406392-cc0a4180-9ba7-11eb-9f4b-fcb7f4307f25.PNG)

### End Branch

![Event End Branch](https://user-images.githubusercontent.com/42868150/114406469-dc222100-9ba7-11eb-8a85-96a6b2dfe5b8.PNG)

### Set Value
![Event Set Value](https://user-images.githubusercontent.com/42868150/114406511-e2b09880-9ba7-11eb-8954-76c185aa8992.PNG)
![Event Set Value Options](https://user-images.githubusercontent.com/42868150/114406523-e6dcb600-9ba7-11eb-9679-435b47a120aa.PNG)

### Change Timeline
![Event Change Timeline](https://user-images.githubusercontent.com/42868150/114406548-ec3a0080-9ba7-11eb-8795-593d7004f7a6.PNG)

## The Dialoic Class

> ⚠️ IT IS VERY LIKELY THAT THIS CLASS GETS SOME MAJOR UPDATES BEFORE THE NEW STABLE VERSION

#### Description
The `Dialogic` class exposes methods allowing you to control the plugin:

#### Functions
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
mments but this will remain a plugin :)

- - -
- - -

# Plugin Development

## 🌳 Source structure

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
