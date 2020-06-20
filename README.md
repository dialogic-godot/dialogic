# Simple Dialog Addon v0.2
A simple Godot dialog addon to use in any kind of project. 

![Screenshot](https://coppolaemilio.com/godot/dialog-screenshot.png)

## How to use:
You first need to create a `DialogCharacterResource` for each character you wish to have in your dialog.
To do this, right click in your FileSystem and choose `New Resource`, search for `DialogCharacterResource` and create it.
It's good practice to put these inside a `Resources/Characters` folder.
You can assign each character a Name, Image and Color.

Once you have created your characters it's time to create a `DialogResource` for your dialog.
Note you can create a separate dialog resource for each of your dialogs if you wish to keep things logically separate, or you can create a master `DialogResource` if you prefer.
To create a `DialogResource`, right click in your FileSystem and choose `New Resource`, search for `DialogResource` and create it.
Again, it's good practice to put these inside a folder such as `Resources/Dialogs`.
Each `DialogResource` can contain a Dictionary of custom variables that will be replaced by their value when you add them to a script in the form of "This is a [custom] value" where the value for the dictionary key `custom` will replace `[custom]`.
You must also provide the `DialogResource` with an array of your `DialogCharacterResource` files.
You can set the dialog script (.json) on the inspector variable "Dialog Json" or by setting the dialog content by changing the variable `dialog_script` of the node.

Now you can add the node `addons/dialogs/Dialog.tscn` to your scenes, assign the desired `DialogResource` file and use it on your projects.

## Changelog
v0.3
 - Removed requirement for `global.gd` and `characters.gd` autoload scripts.
 - Added `DialogResource` and `DialogCharacterResource` resources to create a cleaner way of specifying dialog content

v0.2:
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

Placeholder images are from Toen's YouTube DF series:
 - https://toen.world/
 - https://www.youtube.com/watch?v=B1ggwiat7PM

Thank you to all my Patreons for making this possible!
- Mike King
- Allyson Ota
- Buskmann12
- David T. Baptiste
- Francisco Lepe
- Problematic Dave
- Rienk Kroese
- Tyler Dean Osborne

Support me at [Patreon https://www.patreon.com/coppolaemilio](https://www.patreon.com/coppolaemilio)

MIT License
