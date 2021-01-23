# Dialogic v0.9 ![Godot v3.2](https://img.shields.io/badge/godot-v3.2.4-%23478cbf)
Create dialogs, characters and scenes to display conversations in your Godot games. 

![Screenshot](https://coppolaemilio.com/images/dialogic/dialogic08.png)

## ⚠️ Under development! ⚠️
The plugin is not production ready, this means that it will not work in your game right now unless you know what you are doing. Make sure to follow the repo for the next update.

---

## Changelog

### 🆕 v0.9 - WIP
  - Moved `Dialog.tscn` to the root of the addon so it is easier to find.
  - New tool: Glossary Editor
  - New default asset: Glossary Font
  - Theme Editor:
    - Added new options to customize the glossary popup (still not working)
  - Timeline Editor:
    - Added categories for the events.
    - New `Emit Signal` event. This event will make the Dialog node emit a signal called `dialogic_signal`. You can connect this in a moment of your timeline with other scripts.
    - New `Change Scene` event. You can change the current Scene to whatever `.tscn` you pick. This will happen instantly, but in the future I'll add some transition effects so it is not that abrupt.
    - New `Wait Seconds` event. This will hide the dialog and wait X seconds until continuing with the rest of the timeline. 
    - Re-adding the `End Branch` event.
  - New `Dialogic` class. With this new class you can add dialogs from code easily:
    ```
    var new_dialog = Dialogic.start('Your Timeline Name Here')
    add_child(new_dialog)
    ```
    To connect signals you can also do:
    ```
    func _ready():
        var new_dialog = Dialogic.start('Your Timeline Name Here')
        add_child(new_dialog)
        new_dialog.connect("dialogic_signal", self, 'signal_from_dialogic')

    func signal_from_dialogic(value):
        print(value)
    ```

  - Bug fixes:
    - Fixing an error when having an empty join event in a timeline.

To view the full changelog [click here](https://github.com/coppolaemilio/dialogic/blob/master/CHANGELOG.md). 

---

## FAQ 
### 🔷 How can I install Dialogic?
To install a Dialogic, download it as a ZIP archive. All releases are listed here: https://github.com/coppolaemilio/dialogic/releases. Then extract the ZIP archive and move the `addons/` folder it contains into your project folder.

If you want to know more you can read the [official documentation page](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html).

### 🔷 Can I use Dialogic in one of my projects?
Yes, you can use Dialogic to make any kind of game (even commercial ones). The project is developed under the [MIT License](https://github.com/coppolaemilio/dialogic/blob/master/LICENSE).


### 🔷 Why are the dialogs are not working when exporting my project?
When you export a project using Dialogic, you need to add `*.json` on the Resources tab (see the image below) and also make sure to copy the `dialogic` folder to the same place where the executable of your game is (again, see bottom right side of the image).
![Screenshot](https://coppolaemilio.com/images/dialogic/exporting.png)

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