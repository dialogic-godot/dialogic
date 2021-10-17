# Updating to 1.3

1.3 has brought some big changes, and a few changed the behavior in a way that might break some older code of yours. 
This was mainly due to the removal of the DialogicSingleton as well of the implementation of a new saving system.

Here is everything you need to do to successfully updated (as far as we know):

## 1. Updating and removing the Dialogic Singleton
- Make a full project backup just in case you lose some data while upgrading
- Disable the current installed Dialogic plugin (Project Settings/Plugins)
- Remove the `/addons/dialogic` folder from your project
- Remove the DialogicSingleton (Project Settings/Autoloads)
- Paste the new Dialogic 1.3 into the addons folder
- Enable the new Dialogic from the plugin menu (Project Settings/Plugins)

## 2. Remove the reset_saves argument in Dialogic.start()
The Dialogic.start() function no longer has a reset_saves argument, so you will have to get rid of that, wherever you used it.

Instead you will have to use Dialogic.load() when your game starts and Dialogic.reset_saves() if you want to reset the definitions. Learn more about the new saving system [here](./Saving.md).

## 3. Remove Dialogic.start_from_save()
This can now be done with by calling Dialogic.load() and then Dialogic.start('').
You can add a default timeline (used if nothing could be loaded) as the second argument:

`
Dialogic.load()
var dialog = Dialogic.start('', 'Chapter1')
`

## 4. Check autosave setting
The autosave settings have been removed in favor of a single one. Check if you want it to be enabled, because it is on by default.

## 5. Learn the new saving system
There are some more less straight-forward changes to the saving system (no set_timeline() anymore) so I suggest [learning how it should be done now](./Saving.md). Good luck!

## 6. Redo the typing audio
If one of your themes used the typing audio effects, you will have to redo it with the new and improved system.
