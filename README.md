# Dialogic v0.4 ![Godot v3.2](https://img.shields.io/badge/godot-v3.2-%23478cbf)
Create dialogs, characters and scenes to display conversations in your Godot games. 

![Screenshot](https://coppolaemilio.com/godot/github-portrait.png)

## How to use:

### 1) Creating Characters:
_If you don't plan on using character portraits you can skip this step._

You first need to create a `DialogCharacterResource` for each character you wish to have in your dialog.
To do this, right click in your FileSystem and choose `New Resource`, search for `DialogCharacterResource` and create it.
It's good practice to put these inside a `Resources/Characters` folder.
You can assign each character a Name, Image and Color.

There are 3 characters used for the example located at `addons\dialogs\Resources\Characters`.

![Screenshot](https://coppolaemilio.com/godot/character-resource-inspector.PNG?v2)


### 2) Creating dialogs
You can set the dialog code inside the dialog node variable `dialog_script` like in the example and then add the characters that are going to be present in that conversation with the variable `dialog_characters`. 

![Screenshot](https://coppolaemilio.com/godot/characters-in-node.PNG)

Alternatively you can create a separate dialog resource for each of your dialogs if you wish to keep things logically separate, or you can create a master `DialogResource` if you prefer.
To create a `DialogResource`, right click in your FileSystem and choose `New Resource`, search for `DialogResource` and create it.
Again, it's good practice to put these inside a folder such as `Resources/Dialogs`.
Each `DialogResource` can contain a Dictionary of custom variables that will be replaced by their value when you add them to a script in the form of "This is a [custom] value" where the value for the dictionary key `custom` will replace `[custom]`.
Same as before, you must also provide the `DialogResource` with an array of your `DialogCharacterResource` files.


You can set the dialog script (.json) on the inspector variable "Dialog Json" or by setting the dialog content by changing the variable `dialog_script` of the node.

### 3) Adding the node
Now you can add the node `addons/dialogs/Dialog.tscn` to your scenes, assign the desired variable values or `DialogResource` file and use it on your projects.

## Changelog
v0.4 - Dialog editor
 - Changed how the main editor works, instead of being a graphedit it is now an event timeline.
 - Renamed the plugin to Dialogic. Thanks to [Òscar](https://twitter.com/oscartes) for always knowing how to name things. 
 - Added a new panel to the editor
v0.3 - Using Resources
 - Removed requirement for `global.gd` and `characters.gd` autoload scripts.
 - Added `DialogResource` and `DialogCharacterResource` resources to create a cleaner way of specifying dialog content
 - Added icon to the existing dialog node.

v0.2 - Adding Characters:
 - Changed text speed to fixed per character instead of total time span
 - New character support
 - Added portrait to characters
 - Created the `fade-in` effect
 - Curly brackets introduced for character names.

v0.1 - Release
 - You can watch the presentation video here https://www.youtube.com/watch?v=TXmf4FP8OCA
---

## Credits
Code made by [Emilio Coppola](https://github.com/coppolaemilio).

Contributors: [Toen](https://twitter.com/ToenAndreMC), [Òscar Villarreal](https://twitter.com/oscartes), [Tom Glenn](https://github.com/tomglenn)

Placeholder images are from Toen's YouTube DF series:
 - https://toen.world/
 - https://www.youtube.com/watch?v=B1ggwiat7PM

### Thank you to all my Patreons for making this possible!
- Mike King
- Allyson Ota
- Buskmann12
- David T. Baptiste
- Francisco Lepe
- Problematic Dave
- Rienk Kroese
- Tyler Dean Osborne

Support me on [Patreon https://www.patreon.com/coppolaemilio](https://www.patreon.com/coppolaemilio)

MIT License
