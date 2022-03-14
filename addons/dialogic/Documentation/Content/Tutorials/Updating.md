# Updating to 1.4

1.4 has brought some big changes, and a few changed the behavior in a way that might break some older code of yours. 
This assumes you are upgrading from version 1.3.

Here is everything you need to do to successfully updated (as far as we know):

## 1. Make a backup of your project
  - Close your project/Godot
  - Make a full project backup just in case you lose some data while upgrading
  - Remove the `/addons/dialogic` folder from your project 
  - Paste the new Dialogic 1.4 into the addons folder
  - Open your project/Godot again
  - Enable the new Dialogic from the plugin menu (Project Settings/Plugins)

## Update the call node events target functions
  - The `Call Node Event` now sends arguments instead of a single array. If you were using it in one of your timelines you will need to update the functions you are calling to accommodate this. So if the function you were calling before was something like `func hello(Array)` now it should be `func hello(argument1, argument2, argument3, ...)` with as many arguments as you have in the event settings.