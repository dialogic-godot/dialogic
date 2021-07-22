## v1.2.5 - Possibly breaking eveything. We will never know.
- Loading timeline events on batches to speedup big timelines
- Reduced the amount of nodes inside events to improve loading times
- Fixing the "first time running" bug where you had to reboot dialogic after enabling it for the first time
- Fixing a bug where if you had a node selected in the editor you couldn't open any resource picker
- Fixed a bug when trying to add a new resource after removing one
- Fixed the issue that allowed you to keep loading messages after a dialog close event
- Enabling bbcode to glossary entries
- Simplified some internal code
- Adding new setting to the Set Background event to add fade-in time
- Fixed an issue that caused nested timelines to be deleted whem moving directories [[zaknafean]](https://github.com/zaknafean)
- Settings Editor
  - Added a default action key selector so you don't have to set it per theme. The theme action key settings will overwrite the one set in settings. 
  - Added new setting to select Dialogic's Canvas Layer [[RedXGames]](https://github.com/RedXGames)

## v1.2.4 - Gotta go fast
- Fixed an issue with the default scale of the portraits
- Trying to simplify and remove legacy code:
  - EditorView.gd
    - Unified the remove resource confirmation dialogs
    - Removed pointless variable definitions

## v1.2.3 - Two releases in one day?
- Hopefully, final attempt to fix the weird event creation bug [[Jowan-Spooner](https://github.com/Jowan-Spooner)] Thanks [[Drawsi](https://github.com/Drawsi)] for the report and testing!

## v1.2.2 - Here we go again :')
- Set Value Event: There is now a dice symbol that (when toggled) will reveal to boxes for a minimum and a maximum random number to choose from [[Jowan-Spooner](https://github.com/Jowan-Spooner)]
- Making a small delay on choices to prevent the people that spam "next" to accidentally select the first option
- Fixed some issues when creating new events in the timeline

## v1.2.1 - Get them while they're hot!
- You can now specify for how long to wait in `[nw]` events. `[nw=3]` or whatever number of seconds you want it to wait
- Fixed some issues with the CanvasLayer
- Fixed some issues when creating dialogs using GDScript
- Fixed an issue when changing the current timeline
- Improved the internals of `MasterTree.gd` [[Jowan-Spooner](https://github.com/Jowan-Spooner)]
- Fixed some issues with the `[nw]` command [[Jowan-Spooner](https://github.com/Jowan-Spooner)]
- Improved the Timeline Editor performance when loading timelines
- Removed the `focus_mode` warning
- Added a new page to the docs about the [Text Events](https://github.com/coppolaemilio/dialogic/blob/main/docs/events/TextEvent.md)
- Fixed a bug when trying to skip fade-in dialog animations [[idontkillcoyotes](https://github.com/idontkillcoyotes)]
- Fixed an issue with typing sounds in exported projects
- Fixed an issue when selecting folders for typing sounds in exporting projects; Thank you [AnidemDex](https://github.com/AnidemDex)!


## v1.2 - Organize it!
- Functionality
  - Added extra options to allow the user to disable/enable saving of definitions and current timeline [[Arnaud](https://github.com/arnaudvergnet)]
  - `Dialogic.start()` will add a CanvasLayer by default to avoid the confusion of not seeing Dialogic when using a camera. [[AnidemDex](https://github.com/AnidemDex)]
  - Fixed many issues with portraits fading in and out
  - Fixed a bug that prevented the BackgroundMusic event to work correctly [[Jowan-Spooner](https://github.com/Jowan-Spooner)]
  - Experimental translation added! (This change simply adds a new setting to always treat text as a translation key, instead of displaying it directly. When on, text is sent through tr() before any additional checks are performed on it) [[bojjenclon]](https://github.com/bojjenclon)

- Editor
  - Added sub-folders to all the resources to better organize your project [[Jowan-Spooner](https://github.com/Jowan-Spooner)]
  - Improved resource picker aware of sub-folders [[Jowan-Spooner](https://github.com/Jowan-Spooner)]

- Dialog
  - Adding `[nw]` commands to automatically skip the text after 2 seconds without user input (Will be improved in future versions)
  - Choices can now print the definition values using the regular `[definition]` syntax
  - Next indicator is no longer visible when there are options to select
  - You can now use `[speed=3]` or any number to change the speed of an individual event text speed

- Theme Editor
  - Added new fonts selector for italics, bold, and names [[Jowan-Spooner](https://github.com/Jowan-Spooner)]
  - Added new Box Padding settings to the name label.
  - Added a new option to make the dialog backgrounds full width
  - You can now set a character for the preview message
  - Three positions for the name label: Left, Center and Right
  - You can set the vertical and horizontal offset of the name label
  - Added a new option to enable single portrait mode. In this mode, once the characters join the dialog, only one of them will be visible without the need of making them join and leave every time
  - Added a simple fade in animation for dialogs. You can change how long it takes in the `Dialog Box` tab
  - New tab added: Audio
    - In the audio tab, you can select a sound or set of sounds to play while the text is being typed in the dialog. [[Tim Krief](https://github.com/timkrief)]

- Character Editor
  - You can now add a scene as a portrait, so you can now use AnimatedSprite or whatever you might need
  - You can set nicknames to characters [[zakary93](https://github.com/zakary93)]
  - Fixed a bug when coloring the names of characters in text [[zakary93](https://github.com/zakary93)]
  - Added the resolution of the selected portrait image on the preview box
  - You can now import a folder to automatically add all the images inside as portraits
  - Removed the legacy "Default Speaker" option. I might revisit something like this in the future

- Timeline Editor
  - You can now select multiple events (`CRTL` for adding/removing an event, `SHIFT` for range select) [[Jowan-Spooner](https://github.com/Jowan-Spooner)]
  - You can now use `CRTL+C`, `CRTL+X` and `CRTL+V` to copy, cut and paste events [[Jowan-Spooner](https://github.com/Jowan-Spooner)]
  - You can use `CRTL+D` to duplicate the selection [[Jowan-Spooner](https://github.com/Jowan-Spooner)]
  - You can use `CRTL+A` and `CRTL+SHIFT+A` to select/deselect all events [[Jowan-Spooner](https://github.com/Jowan-Spooner)]
  - Some shortcuts where redone: Remove events with `DEL`, move selection up/down with the `UP` and `DOWN` arrow keys [[Jowan-Spooner](https://github.com/Jowan-Spooner)]
  - A SetGlossary event was added that allows to change the info of a glossary item during the game [[Jowan-Spooner](https://github.com/Jowan-Spooner)]
  - You can now set the portrait of a character based on a definition [[bojjenclon]](https://github.com/bojjenclon)
  - New resource picker styles
  - Modified the label on the emit signal event so it is easier to understand [[Jowan-Spooner](https://github.com/Jowan-Spooner)]
  - Updated the look of some events and added some useful event warnings

- Other stuff
  - Events have id's now. Nothing should change for the user, but it will be easier to manage the inclusion of new events or modifying existing ones [[Jowan-Spooner](https://github.com/Jowan-Spooner)]
  - Fixed a non-breaking bug that printed some errors on the terminal

- And many more! (kinda hate not listing all the changes, but don't remember all of them)

## v1.1 - With a little help from my friends
- Improved event dragging and selection [[Arnaud Vergnet](https://github.com/arnaudvergnet)]
- Fixed a bug that prevented the deletion of Characters [[AnidemDex](https://github.com/AnidemDex)]
- Fixed a bug that allowed you to overwrite the event on the theme preview dialog
- Added a folder icon to each section of the resource tree
- Greatly improved how the plugin is displayed in different display scales
- You can now filter resources from the main view [[ellogwen](https://github.com/ellogwen)]
- You can now duplicate themes (from the context menu) [[ellogwen](https://github.com/ellogwen)]
- Organized the images and other assets into a tidier structure [[Jowan-Spooner](https://github.com/Jowan-Spooner)] _**Warning!** If you were using the example portrait assets you will have to load them again manually on the character editor_
- You can now create resources by right clicking the section and selecting "+ New" [[Tim Krief](https://github.com/timkrief)]
- Remade all the PopupMenu items in gdscript and replaced the icons with native editor theme ones.
- Experimental: Added a static proxy for C# projects. _Testing wanted!_ [[mscharley](https://github.com/mscharley)]
- Timeline:
  - New event `Call Node`: Call a Godot NodePath and a method name. In addition you can add arguments as well. The Timeline will execute those methods and wait for completion, if the method in question is async and/or yielding [[ellogwen](https://github.com/ellogwen)]
  - You now can drag and drop events into the timeline! [[ellogwen](https://github.com/ellogwen)]
  - You can un select a selected event by clicking it [[ellogwen](https://github.com/ellogwen)]
  - The `Scene Event` can now take other Scenes (`.tscn`) files as backgrounds. [[ellogwen](https://github.com/ellogwen)]
  - The `If Condition` event can now use definition variables as values to compare against [[ellogwen](https://github.com/ellogwen)]
  - You can now hide `Choice events` if a definition doesn't meet some requirements [[Arnaud](https://github.com/arnaudvergnet)]
  - You can now select a character to ask a question in the `Question Event` [[Tim Krief](https://github.com/timkrief)]
  - Added very basic syntax highlighting to the `Text Event` editor
  - Fixed an indenting bug when removing events 
  - The `Character Join` event now has a mirror option [[Jowan-Spooner](https://github.com/Jowan-Spooner)]
  - The `Close Dialog` has a new setting for the duration of the fade-out animation. [[Tim Krief](https://github.com/timkrief)]
  - `Scene Event` renamed to `Change Background` to better represent what it does. [[Jowan-Spooner](https://github.com/Jowan-Spooner)] 
  - Both `Audio Event` and `Background Music` got more settings (audio Bus, volume, fade-length) [[Jowan-Spooner](https://github.com/Jowan-Spooner)] 

  - Shortcuts added! [[ellogwen](https://github.com/ellogwen)]
    - Selecting previous and next event in the timeline with `CTRL + UP` and `CTRL + DOWN`
    - Moving currently selected event up and down the timeline `ALT + UP` and `ALT + DOWN`
    - Remove the currently selected event node and selects the next/last event node `CTRL DELETE`
    - Create a new text event node below the currently selected and focus it's textbox to continue writing `CTRL T`
- Character Editor
  - There is an option `mirror portraits` below the portrait preview now, that will mirror all portraits when they appear in the game [[Jowan-Spooner](https://github.com/Jowan-Spooner)]
  - Fixed a bug that prevented portrait previews to display if the extension was in capital letters. 
- Theme Editor
  - Refreshed the UI to make room for more properties for each section
  - A reload of the preview dialog is performed when you change a property so you don't have to click the "preview changes" all the time
  - Removed the limitation of only 100px for the padding of the dialog box
  - Added a new option for changing the color modulation of the dialog background image
  - Added new customization options (scale, and offset) to the next indicator image
  - Added modulation settings to the name label background texture and the choices buttons background textures [[Jowan-Spooner](https://github.com/Jowan-Spooner)]
  - Added an option to use native buttons styles for choices [[Tim Krief](https://github.com/timkrief)]
  - Added an advanced option to use a custom scene as a button for choices [[Arnaud Vergnet](https://github.com/arnaudvergnet)]
  - Added new settings to set a fixed size for choice buttons (This is used to prevent premade texture stretching)
  - Fixed a bug where the text alignment wasn't being shown on the preview
  - Fixed a bug with the name label shadow
  - Fixed a bug with the "auto color" option in game
- Dialog node
  - You can now use [br] to insert line breaks
  - Questions now properly show the theme text alignment
  - Options now show up when the question text finished displaying [[Arnaud Vergnet](https://github.com/arnaudvergnet)]
  - The close dialog now performs a fade-out animation
  - Fixed a bug where Glossary Definitions plain text was being added to the name label
  - Fixed an issue when trying to display small sprites as characters portraits
  - Fixed a bug where portraits didn't come to the front when being focused [[AnidemDex](https://github.com/AnidemDex)]
  - Fixed a bug when the display stretch was set to `2D`
  - Fixed a bug where empty text lines were not removed properly [[Arnaud Vergnet](https://github.com/arnaudvergnet)]
- Settings
  - Added a new option to enable advanced theme settings [[Arnaud Vergnet](https://github.com/arnaudvergnet)]
  - Added a new option to toggle the character "focus"/"dim" while speaking 
- Added a button in timeline inspector plugin to open the selected timeline in the editor [[ellogwen](https://github.com/ellogwen)]
- Special thanks to [Jowan-Spooner](https://github.com/Jowan-Spooner) for the QA and the facelift on the theme editor

To view previous changes [click here](https://github.com/coppolaemilio/dialogic/blob/main/CHANGELOG.md). 

## v1.0 - We made it! 🎉
  - When upgrading from 0.9 to the current version things might not work as expected:
    - ⚠ **PLEASE MAKE A BACKUP OF YOUR PROJECT BEFORE UPGRADING** ⚠
    - Glossary variables will be lost
    - Glossary related events will not be loaded (`If condition Event` and `Set Value Event`)
    - The theme you made in the 0.9 theme editor will be lost. You will have to remake it.
  - Video https://youtu.be/MeaS3zZxpbA
  - New layout:
    - All editors in the same screen. Say goodbye to tabs!
    - You can now rename resources by double clicking them
    - New Settings panel for advanced properties
      - Settings:
        - Re-added the auto color for character names in text messages
        - Removing empty Text Event from timelines
        - New lines to create new Text Event messages
        - Propagation of input to the rest of the Tree
  - Character Editor:
    - Set the scale of your character's portrait
    - Add offset to the portrait
  - Timeline Editor:
    - New `Theme event` to change the theme in the middle of a timeline
    - New `Background Music Event` to play music in your dialog. Music can crossfade when changing track and fade in/out when starting/stopping.
    - Re-enabled the `Scene Event`
    - Allow making basic calculations such as `+`, `-`, `*`, `/` in `Set value events`.
  - Theme Editor:
    - You can now add multiple themes.
    - Moved the preview button to the left side so it is never hidden by default in small screens.
    - New section to edit how the character names are displayed.
    - New properties:
      - `Box size` set the width and height of the dialogue box in pixels
      - `Alignment` you can now align the text displayed (Left, Center, Right)
      - `Bottom Gap` The distance between the bottom of the screen and the start of the dialog box.
      - `Next animation` Set an animation for the "Next Dialog Indicator"
  - Glossary was renamed to Definitions. I feel like the word `Definitions` cover both "variables" and "lore" a bit better.
  - Definitions:
    - Dynamic types! All variables are just dynamic, so they can be ints, floats or strings.
    - The name of a character can be set to be a definition.
    - You can display definition values in a Text Event by doing: `[definition name here]`.
  - Fixed many resource issues with exported games
  - New icons all around.
  - Added some basic light theme support. This is not finished, but it is on a much better state than before.
  - The events now emit signals. Thank you [Jesse Lieberg](https://github.com/GammaGames) for your first contribution!
  - Special thanks to [Arnaud Vergnet](https://github.com/arnaudvergnet) for all your work in improving Definitions, conditional events and many more! 🙇‍♂️

## v0.9 - House keeping
  - Video: https://youtu.be/pL0RWVmlM6g
  - Moved `Dialog.tscn` to the root of the addon so it is easier to find.
  - Added a link to the documentation from the editor
  - Refactored a lot of the code and continued splitting the main plugin code into smaller pieces.
  - Rewrote most of the saving and branching systems.
  - New tool: Glossary Editor
    - You are now able to write extra lore for any word and Dialogic will create a hover card with that extra information.
    - You can create `strings` and `number` variables.
    - You can access to those variables from the `Dialogic` Class: `Dialogic.get_var('variable_name')`
  - In game:
    - Portraits changes are reflected in-game.
    - Many small improvements.
  - Theme Editor:
    - New default asset: Glossary Font
    - Added new options to customize the glossary popup
  - Timeline Editor:
    - Added categories for the events.
    - Color coded some of the events in the same category to avoid having a distracting rainbow in the timelines.
    - Conditional event working, but only with "equal to". More conditions coming later.
    - Renamed the `End Branch` file names to match the name of the event. This will break the conditionals you have, but this is the time for making breaking changes. Sorry!
    - New `Set Value` event. Change the current value of a glossary variable inside a timeline. This will reset when you close the game, so a saving system will have to be added on the next version.
    - New `Emit Signal` event. This event will make the Dialog node emit a signal called `dialogic_signal`. You can connect this in a moment of your timeline with other scripts.
    - New `Change Scene` event. You can change the current Scene to whatever `.tscn` you pick. This will happen instantly, but in the future I'll add some transition effects so it is not that abrupt.
    - New `Wait Seconds` event. This will hide the dialog and wait X seconds until continuing with the rest of the timeline. 
    - Created independent Character and Portrait picker for reusing in event nodes.
    - Portrait picker added to `Text Events` and `Character Join` events.
    - `Text Events` text editor vertical size grows witch each line added.
    - `Text Events` now properly create a new message for each line inside the text editor.
    - `Text Events` Line count are now displayed next to the preview text when folded.
    - Re-adding the `End Branch` event just in case you removed the end and you want to add it again in the timeline.
    - Renamed the `Copy Timeline ID` right click menu option to `Copy Timeline Name` since you now have to use that to set the current timeline from code instead of the ID.
    - Fixed several bugs that corrupted saved files
    - Thanks to [mindtonix](https://github.com/mindtonix) and [Crystalwarrior](https://github.com/Crystalwarrior) for your first contribution on the choice buttons 
  - New `Dialogic` class. With this new class you can add dialogs from code easily:
    ```
    var new_dialog = Dialogic.start('Your Timeline Name Here')
    add_child(new_dialog)
    ```
    To connect signals you can also do:

    ```swift
    func _ready():
        var new_dialog = Dialogic.start('Your Timeline Name Here')
        add_child(new_dialog)
        new_dialog.connect("dialogic_signal", self, 'signal_from_dialogic')

    func signal_from_dialogic(value):
        print(value)
    ```

## v0.8 - Dialog enters the game
 - Video: https://youtu.be/NfTyRrsdB1I
 - Moved the theme editor tool icon to the left
 - Theme Editor:
    - Added a color background as an option
    - Reduced the vertical size needed to show all options
    - Style your choice buttons! (Color, background, etc...)
    - Better default support for unchanged styles
 - Timeline Editor:
    - Moved the event buttons to a new column
    - When creating a `Question` two `Choice` events and a `End Branch` event will be added automatically
    - Added a warning for `Choice` events on the root level of indentation
    - Disabled unfinished events
    - The Change Timeline event tells you your current timeline (this is for going back to the start)
    - New `Close Dialog` event. This event closes the dialog whenever it is called.
    - When renaming a dialog the popup's text field is already selected and focused.
 - In game dialog:
    - You can now select the current timeline from the inspector without manually copying the timeline id.
    - Change timeline event is now working
    - Audio event can play sounds
    - Character join (left, center and right) working
    - Focus in and out of portraits when speaking
    - Character leave events working
    - Basic question/answers support
    - Better scene resizing and position
    - Button styles

## v0.7 - Looking good
 - Video: https://youtu.be/wREIVj55eBM
 - New plugin tab icon
 - Removed legacy files
 - From the theme tab you can now:
   - Pick the default text color
   - Set the shadows and shadow offset
   - Select your own fonts (.tres)
   - Set background and next indicator images
   - Choose an action to trigger the "next" event
   - Preview changes in a dialog
   - Change text speed
   - Set text margins
 - Characters tab
   - Added context menu
   - Moved the Remove Character button to a context menu
   - You can open the working directory
 - Timeline tab
   - Added context menu
   - You can remove timelines now
   - Right click no longer renames timelines, to do so you have to use the new menu
   - You can open the working directory
   - You can copy the timeline ID

## v0.6 - Character portraits
 - Video: https://youtu.be/okWYt_yGKNI
 - Splitting the main script into smaller pieces
 - Characters
   - Characters welcome screen when there are 0
   - Different display name
   - Autosave enabled on characters
   - Character portraits
   - Added Default Speaker setting
 - Events:
   - Text block now has a portrait dropdown

## v0.5 - Indentation Magic
 - Video: https://youtu.be/mrTyWy2TJOM
 - Added new events:
   - Choice
   - End branch
   - Change Timeline
 - You can now drag and drop events in a timeline
 - Made new icons for the editor tabs
 - Added some tooltips
 - Restructured the events node structure to add indentation
 - Changed event default colors

## v0.4 - Dialogic
 - Video: https://youtu.be/Hf_gywa6vZE
 - Changed how the main editor works, instead of being a graphedit it is now an event timeline.
 - Renamed the plugin to Dialogic. Thanks to Òscar for always knowing how to name things. 
 - Moved all data to .json files
 - Broke the addon for working. Nice :)

## v0.3 - Using Resources
 - Video: https://youtu.be/PzzOE4LbGAo
 - Removed requirement for `global.gd` and `characters.gd` autoload scripts.
 - Added `DialogResource` and `DialogCharacterResource` resources to create a cleaner way of specifying dialog content
 - Added icon to the existing dialog node.

## v0.2 - Adding Characters:
 - Changed text speed to fixed per character instead of total time span
 - New character support
 - Added portrait to characters
 - Created the `fade-in` effect
 - Curly brackets introduced for character names.

## v0.1 - Release
 - You can watch the presentation video here https://youtu.be/TXmf4FP8OCA