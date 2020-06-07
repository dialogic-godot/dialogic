# Simple Dialog Addon v0.1
A simple Godot dialog addon to use in any kind of project. 

![Screenshot](https://coppolaemilio.com/godot/dialog-screenshot.png)

## How to use:
You first need to create a `global.gd` script for storing variables.  
Inside your `global.gd` add a dictionary variable called `custom_variables`.  
`var custom_variables = {}`.  
Then go to: `Project`>`Project Settings...`>`AutoLoad` and add the script `global.gd` with name `global` and **enable** the `Singleton` option.

Now you can add the node `addons/dialogs/Dialog.tscn` to your scenes and use it on your projects.

You can set the dialog script (.json) on the inspector variable "External File" or by setting the dialog content by changing the variable `dialog_script` of the node.

### Credits
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