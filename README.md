![Hero Image](https://coppolaemilio.com/images/dialogic/dialogic-hero-1.3.png?v1)
Create dialogs, characters and scenes to display conversations in your Godot games. 

# Version 1.2.5 (WIP)  ![Godot v3.3](https://img.shields.io/badge/godot-v3.3-%23478cbf)

[Changelog](https://github.com/coppolaemilio/dialogic/blob/main/docs/changelog.md) — 
[Installation](#installation) — 
[Basic Usage](https://github.com/coppolaemilio/dialogic/blob/main/docs/usage.md) — 
[FAQ](#faq) — 
[Source structure](https://github.com/coppolaemilio/dialogic/blob/main/docs/source.md) — 
[Credits](#credits)

---

## Getting started

This video will teach you everything you need to know to get started with Dialogic: [https://www.youtube.com/watch?v=sYjgDIgD7AY](https://www.youtube.com/watch?v=sYjgDIgD7AY)

## Installation

To install a Dialogic, download it as a ZIP archive. All releases are listed here: [releases](https://github.com/coppolaemilio/dialogic/releases). Then extract the ZIP archive and move the `addons/` folder it contains into your project folder. Then, enable the plugin in project settings.

If you want to know more about installing plugins you can read the [official documentation page](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html).

You can also install Dialogic using the **AssetLib** tab in the editor, but the version here will not be the latest one available since it takes some time for it to be approved.

## ⚠ IMPORTANT
The Godot editor needs a reboot after enabling Dialogic for the first time. So make sure to reboot after activating it for the first time before submitting a bug request. A fix is present in the 1.2.5 version, but still being tested.


### 📦 Preparing the export

When you export a project using Dialogic, you need to add `*.json, *.cfg` on the Resources tab `Filters to export...` input field ([see image](https://coppolaemilio.com/images/dialogic/exporting-2.png?v2)). This allows Godot to pack the files from the `/dialogic` folder.

---

## FAQ 

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


### 🔷 My resolution is too small and the dialog is too big. Help!
If you are setting the resolution of your game to a very small value, you will have to create a theme in Dialogic and pick a smaller font and make the box size of the Dialog Box smaller as well. 


### 🔷 I can't see the character sprites during the dialog!
For the characters to be visible during the dialog, you need to add them to the current scene by using the "Character Join" Event. Select the character you want to add, the position and the rest of the settings. Whenever you want them to leave, use the "Character Leave" event. 

![image](https://user-images.githubusercontent.com/2206700/115998381-3a5af500-a5e7-11eb-95af-778a656a6e9e.png)


### 🔷 How do I connect signals?
Signals work the same way as in any Godot node. If you are new to gdscript you should watch this video which cover how Godot signals work: [How to Use Godot's Signals](https://www.youtube.com/watch?v=NK_SYVO7lMA). Since you probably won't, here you have a small snippet of how to connect a Dialogic **Emit Signal** event:
```gdscript
# Example for dialogic_signal
func _ready():
	var new_dialog = Dialogic.start('Your Timeline Name Here')
	add_child(new_dialog)
	new_dialog.connect("dialogic_signal", self, 'example_function')

func example_function(value):
	print('value')
```
Every event emits a signal called `event_start` when Dialogic starts that event's actions, but there are also two other named signals called `timeline_start(timeline_name)` and `timeline_end(timeline_name)` which are called at the start and at the end respectively. 

```gdscript
# Example for timeline_end
func _ready():
	var new_dialog = Dialogic.start('Your Timeline Name Here')
	add_child(new_dialog)
	new_dialog.connect('timeline_end', self, 'after_dialog')

func after_dialog(timeline_name):
	print('Now you can resume with the game :)')
```

### 🔷 Can I create a dialog using GDScript?
Yes! it is a bit harder since you will have to create each event yourself, and to do that they have to be **valid**. You can check already created timelines with a text editor and see how an event should look like. A better tutorial and improvements will come soon.

A simple example:
```gdscript
func _ready():
	var gdscript_dialog = Dialogic.start('')
	gdscript_dialog.set_dialog_script( {
		"events":[
			{ 'event_id':'dialogic_001', "text": "This dialog was created using GDScript!"}
		]
	})
	add_child(gdscript_dialog)
```

---

## Credits
Made by [Emilio Coppola](https://github.com/coppolaemilio).

Contributors:  [Arnaud](https://github.com/arnaudvergnet), [ellogwen](https://github.com/ellogwen), [Jowan-Spooner](https://github.com/Jowan-Spooner), [Tim Krief](https://github.com/timkrief),  [and more!](https://github.com/coppolaemilio/dialogic/graphs/contributors). Special thanks: [Toen](https://twitter.com/ToenAndreMC), Òscar, [Francisco Presencia](https://francisco.io/). Placeholder images are from [Toen's](https://toen.world/) [YouTube DF series](https://www.youtube.com/watch?v=B1ggwiat7PM)

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
AzulCrescent,
Hector Na Em,
Furroy,
Sergey,
Container7,
BasicIncomePlz,
p sis,
Justin,
Guy Dadon,
Sukh Atwal,
Patrick Hogan,
Jesse Priest,
Lunos,
Ceah Sharp



Support me on [Patreon https://www.patreon.com/coppolaemilio](https://www.patreon.com/coppolaemilio)

[MIT License](https://github.com/coppolaemilio/dialogic/blob/main/LICENSE)
