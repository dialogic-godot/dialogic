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