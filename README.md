# Dialogic - v1.1 ![Godot v3.3](https://img.shields.io/badge/godot-v3.3-%23478cbf)


![Screenshot](https://coppolaemilio.com/images/dialogic/dialogic-hero-1.0.png?v)

Create dialogs, characters and scenes to display conversations in your Godot games. 

## Contents

- [Changelog](https://github.com/coppolaemilio/dialogic/blob/main/docs/changelog.md)
- [Installation](#-installation)
- [Basic Usage](https://github.com/coppolaemilio/dialogic/blob/main/docs/usage.md)
- [FAQ](#-faq)
- [Source structure](https://github.com/coppolaemilio/dialogic/blob/main/docs/source.md)
- [Credits](#-credits)

---

## ⚙ Installation

To install a Dialogic, download it as a ZIP archive. All releases are listed here: https://github.com/coppolaemilio/dialogic/releases. Then extract the ZIP archive and move the `addons/` folder it contains into your project folder. Then, enable the plugin in project settings.

If you want to know more about installing plugins you can read the [official documentation page](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html).

You can also install Dialogic using the **AssetLib** tab in the editor, but the version here will not be the latest one available since it takes some time for it to be approved.

---

## ❔ FAQ 

### 🔷 How can I make a dialog show up in game?
There are two ways of doing this; using gdscript or the scene editor.

Using the `Dialogic` class you can add dialogs from code easily:

```gdscript
var new_dialog = Dialogic.start('Your Timeline Name Here')
add_child(new_dialog)
```
And using the editor, you can drag and drop the scene located at `/addons/dialogic/Dialog.tscn` and set the current timeline via the inspector.

### 🔷 Can I use Dialogic in one of my projects?
Yes, you can use Dialogic to make any kind of game (even commercial ones). The project is developed under the [MIT License](https://github.com/coppolaemilio/dialogic/blob/master/LICENSE). Please remember to credit!


### 🔷 Why are you not using graph nodes?
Because of how the graph nodes are, the screen gets full of UI elements and it gets harder to follow.
If you want to use graph based editors you can try [Levraut's LE Dialogue Editor](https://levrault.itch.io/le-dialogue-editor) or [EXP Godot Dialog System](https://github.com/EXPWorlds/Godot-Dialog-System).


### 🔷 The plugin is cool! Why is it not shipped with Godot?
I see a lot of people saying that the plugin should come with Godot, but I believe this should stay as a plugin since most of the people making games won't be using it. I'm flattered by your comments but this will remain a plugin :)


### 🔷 Can I use C# with Dialogic?
It is experimental! So if you want to try it out and you find issues, let us know.
Usage:
```cs
public override void _Ready()
  {
    var dialog = DialogicSharp.Start("Greeting", false);
    AddChild(dialog);
  }
```
This is the PR that added this feature: https://github.com/coppolaemilio/dialogic/pull/217


---

### 📦 Preparing the export

When you export a project using Dialogic, you need to add `*.json, *.cfg` on the Resources tab (see the image below). This allows Godot to pack the files from the `/dialogic` folder.

![Screenshot](https://coppolaemilio.com/images/dialogic/exporting-2.png?v2)

---

## ❤ Credits
Code made by [Emilio Coppola](https://github.com/coppolaemilio).

Contributors: [Toen](https://twitter.com/ToenAndreMC), Òscar, [Arnaud](https://github.com/arnaudvergnet), [ellogwen](https://github.com/ellogwen), [Jowan-Spooner](https://github.com/Jowan-Spooner), [Tim Krief](https://github.com/timkrief),  [and more!](https://github.com/coppolaemilio/dialogic/graphs/contributors)

Documentation page generated using: https://documentation.page/ by [Francisco Presencia](https://francisco.io/)

Placeholder images are from Toen's YouTube DF series:
 - https://toen.world/
 - https://www.youtube.com/watch?v=B1ggwiat7PM

### Thank you to all my [Patreons](https://www.patreon.com/coppolaemilio) for making this possible!

Mike King,
Tyler Dean Osborne,
Problematic Dave,
Allyson Ota,
Francisco Lepe,
Gemma M. Rull,
Alex Barton,
Joe Constant,
Kycho,
JDA,
Kersla Margdel,
Chris Shove,
Luke Peters,
Wapiti,
Penny,
Garrett Guillotte,
Sl Tu,
Alex Harry,
Rokatansky,
Karl Anderson,
GammaGames,
Taankydaanky,
Alex (Well Done Games),
GodofGrunts,
Tim Krief,
Daniel Cheney,
Carlo Cabanilla,
Flaming Potato,
Joseph Catrambone,
AzulCrescent

Support me on [Patreon https://www.patreon.com/coppolaemilio](https://www.patreon.com/coppolaemilio)

[MIT License](https://github.com/coppolaemilio/dialogic/blob/main/LICENSE)
