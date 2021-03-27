### v0.9 - House keeping
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