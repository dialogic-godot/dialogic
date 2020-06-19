# Simple Dialog Addon v0.2
A simple Godot dialog addon to use in any kind of project. 

![Screenshot](https://coppolaemilio.com/godot/github-portrait.png?v1)

## How to use:
You first need to create a `global.gd` and a `characters.gd` script for storing variables.  

Inside your `global.gd` add a dictionary variable called `custom_variables`.  
`var custom_variables = {}`.

On your `characters.gd` you need to define your custom characters. If you want to run the example you can copy and paste this values:
```
extends Node

var Zas = {
	'name': 'Zas',
	'image': "res://addons/dialogs/Images/portraits/df-1.png",
	'color': Color(0.304688, 0.445923, 1)
}

var Kubuk = {
	'name': 'Kubuk',
	'image': "res://addons/dialogs/Images/portraits/df-2.png",
	'color': Color(0.632689, 0.157166, 0.804688)
}

var Iteb = {
	'name': 'Iteb',
	'image': "res://addons/dialogs/Images/portraits/df-3.png",
	'color': Color(0.253906, 1, 0.44043)
}
```

Then go to: `Project`>`Project Settings...`>`AutoLoad` and add the script `global.gd` with name `global`, the script `characters.gd` with name `characters` and **enable** the `Singleton` option.

![Screenshot](https://coppolaemilio.com/godot/dialog-script-settings.png)

Now you can add the node `addons/dialogs/Dialog.tscn` to your scenes and use it on your projects.

You can set the dialog script (.json) on the inspector variable "External File" or by setting the dialog content by changing the variable `dialog_script` of the node.

## Changelog
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
