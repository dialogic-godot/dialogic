# Dialogic v0.8 ![Godot v3.2](https://img.shields.io/badge/godot-v3.2.4-%23478cbf)
Create dialogs, characters and scenes to display conversations in your Godot games. 

![Screenshot](https://coppolaemilio.com/images/dialogic/dialogic08.png)

## ⚠️ Under development! ⚠️
The plugin is not production ready, this means that it will not work in your game right now unless you know what you are doing. Make sure to follow the repo for the next update.

---

## FAQ 
### 🔷 How can I install Dialogic?
To install a Dialogic, download it as a ZIP archive. All releases are listed here: https://github.com/coppolaemilio/dialogic/releases. Then extract the ZIP archive and move the `addons/` folder it contains into your project folder.

If you want to know more you can read the [official documentation page](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html).

### 🔷 Can I use Dialogic in one of my projects?
Yes, you can use Dialogic to make any kind of game (even commercial ones). The project is developed under the [MIT License](https://github.com/coppolaemilio/dialogic/blob/master/LICENSE).

---

## Changelog
### 🆕 v0.8 - WIP
 - Moved the theme editor tool icon to the left
 - Themes:
    - Added a color background as an option
    - Reduced the vertical size needed to show all options
    - Style your choice buttons! (Color, background, etc...)
 - In game dialog:
    - Change timeline event is now working
    - Audio event can play sounds
    - Character join (left, center and right) working
    - Focus in and out of portraits when speaking
    - Character leave events working
    - Basic question/answers support
    - Better scene resizing and position
    - Button styles
 - Timelines:
    - Moved the event buttons to a new column
    - When creating a `Question` event a `End Branch` event will be added automatically
    - Added a warning for `Choice` events on the root level of indentation
    - Disabled unfinished events
    - The Change Timeline event tells you your current timeline (this is for going back to the start)


### v0.7 - Looking good
 - Video: https://youtu.be/wREIVj55eBM
 - New plugin tab icon
 - Removed legacy files
 - From the theme tab you can now:
    - Pick the default text color
    - Set the sadows and shadow offset
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

To view the full changelog [click here](https://github.com/coppolaemilio/dialogic/blob/master/CHANGELOG.md). 

---

## Credits
Code made by [Emilio Coppola](https://github.com/coppolaemilio).

Contributors: [Toen](https://twitter.com/ToenAndreMC), Òscar, [Tom Glenn](https://github.com/tomglenn), 

Placeholder images are from Toen's YouTube DF series:
 - https://toen.world/
 - https://www.youtube.com/watch?v=B1ggwiat7PM

### Thank you to all my [Patreons](https://www.patreon.com/coppolaemilio) for making this possible!
- Mike King
- Allyson Ota
- Buskmann12
- David T. Baptiste
- Francisco Lepe
- Problematic Dave
- Rienk Kroese
- Tyler Dean Osborne
- Gemma M. Rull
- Alex Barton
- Joe Constant
- Kyncho
- JDA
- Chris Shove
- Luke Peters
- Wapiti

Support me on [Patreon https://www.patreon.com/coppolaemilio](https://www.patreon.com/coppolaemilio)

[MIT License](https://github.com/coppolaemilio/dialogic/blob/master/LICENSE)