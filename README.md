# Simple Dialog Addon
A simple Godot dialog addon to use in any kind of project. 

## How to use:
You first need to create a `global.gd` script for storing variables.  
Inside your `global.gd` add a dictionary variable called `custom_variables`.  
`var custom_variables = {}`.  
Then go to: `Project`>`Project Settings...`>`AutoLoad` and add the script `global.gd` with name `global` and **enable** the `Singleton` option.

Now you can add the node `addons/dialogs/Dialog.tscn` to your scenes and use it on your projects.

You can set the dialog script (.json) on the inspector variable "External File".

You can also set the dialog content by changing the variable `dialog_script` of the node.


The placeholder images are from Toen's YouTube DF series:
 - https://toen.world/
 - https://www.youtube.com/watch?v=B1ggwiat7PM