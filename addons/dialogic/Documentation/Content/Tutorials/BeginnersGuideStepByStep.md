# First dialogic game: step by step
Let's begin creating your first dialog with dialogic!

- [Meeting the dialogic tab](#meeting-the-dialogic-tab)
- [Creating your first character](#creating-your-first-character)
- [Creating your first timeline](#creating-your-first-timeline)
- [Adding your first DialogNode to a scene](#adding-your-first-dialognode-to-a-scene)
- [Making your first definition](#making-your-first-definition)
- [Create your first dialog theme](#create-your-first-dialog-theme)
- [How to export your game](#how-to-export-the-game)
- [How to export your game](#how-to-export-the-game)

- - -
## Meeting the dialogic tab
All the things related to your dialog will be done in the dialogic tab. You can access it like the 2D and 3D tab on the very top of the editor. You can access all the things you create with dialogic here.  
![Dialogic Tab](https://github.com/Jowan-Spooner/dialogic/blob/plugin-docs/addons/dialogic/Documentation/Content/Tutorials/Images/Dialogic_Tab.PNG)

Let's have a look into the toolbar at the top.

![Toolbar](https://github.com/Jowan-Spooner/dialogic/blob/plugin-docs/addons/dialogic/Documentation/Content/Tutorials/Images/Toolbar.PNG)

Here you can create dialogics four "ressources": 
* **Timelines** that represent a list of events. Control characters, make them talk, change the background, ask questions, emit signals and more!
* **Characters** that represent your characters. You can set a name, a description, a color, and set different images for expressions.
* **Definitions** that can be used as variables (to branch your story or be used inside the texts) or as information for the player (a name and description are shwon when the player hovers over the word).
* **Themes** that specify how your dialog is looking. There are many settings you can tweak to suit your need.

You will hear more on each of them later.

All your ressources are shown in the big master tree on the left. You can select on which you want to work there.

Let's continue! What is the most important thing for a dialog? Someone to talk to. So we will create our first character.

- - -
## Creating your first character
Click the little character icon in the toolbar to create a new character. You will see the character editor now.
![Empty Character Editor](https://user-images.githubusercontent.com/42868150/114406042-80f02e80-9ba7-11eb-9c52-798d4a67f8d8.PNG)


We will go over it step by step.
Go on and give your character a name and a color. You can ignore the rest of these settings for now.
![YFD Character NameColor](https://github.com/Jowan-Spooner/dialogic/blob/plugin-docs/addons/dialogic/Documentation/Content/Tutorials/Images/YFD_Character_NameColor.PNG)
Next let's add a default look for them. You can select a file by clicking the tree dots.
![grafik](https://user-images.githubusercontent.com/42868150/114315214-32d32080-9afe-11eb-8b80-660f68b8623e.png)

If you do not have a image to use right now, you can use the default dwarf from the Example Assets folder inside the dialogic folder.

> ⚠️ THERE SHOULD BE AN EXPLENATION FOR OFFSET AND SCALE. I HOPE THE PORTRAITS WORK OUT OF THE BOX IN THE NEXT STABLE RELEASE.

This is all for now. You can create a second character just like this.

When you are ready let's create our first ever dialog!

- - -
## Creating your first timeline
Timelines specify what events happen in which order. Create a new timline with the icon in the toolbar.
You can now see the timeline editor. You can find all possible events on the right.
![grafik](https://user-images.githubusercontent.com/42868150/114315458-6498b700-9aff-11eb-830d-9472b16f82a1.png)


### | Give it a name
Let's first give our timeline a proper name. To do so doubleclick the ressource on the right. Give it a name of your liking.
![grafik](https://user-images.githubusercontent.com/42868150/114315551-be00e600-9aff-11eb-9aac-5ecd78cebe0d.png)


### | Now let's talk about the EVENTS!

You can click each of the buttons on the rigth to add the event to the timeline. Or you can drag and drop it to the position you want. 

You can select events by left clicking them. When you click one of the event buttons on the right, new events will be added below the selected one.

You can select events and delte them with CRTL + DEL.

In the timeline you can reorder the events by dragging and dropping them. You can also move the selected event up/down with ALT+UP/ALT+DOWN.

### | Let's do it!
The events are sorted on the right so you can more easily find them. Let's look at the first three. We will use them to built our first timeline. 

Click on the `Character Join` button and drag it onto the timeline. Drop it there (by releasing the mouse button).

All of the events have settings to customize them. For the `Character Join` event, we can set a character that should join, it's portrait (only if the character has more then one) and the position at which the character should be standing by selecting one of the five positions.

When you have done that, add a `Text` event the same way.

For this event we can specify which character talks, the portrait they have while saying it (if they have more then one) and what they say. On default, linebreaks split the message and empty lines are just ignored.

Let your character say something!

If you are ready let the character leave with the `Character Leave` event.
You can find explenations for all events and their settings further down in the [refrence](#refrence).

### | On we go
Now your dialog is ready to be played! But how? Let's find out!

- - -
## Adding your first DialogNode to a scene

There are two ways of doing this, using gdscript or the scene editor.

### | Instancing the scene using gdscript
Using the `Dialogic` class you can add dialogs from code easily:

```
var new_dialog = Dialogic.start('Your Timeline Name Here')
add_child(new_dialog)
```
### | Instancing the scene using the editor
Using the editor, you can drag and drop the scene located at `/addons/dialogic/Dialog.tscn` and set the current timeline via the inspector.

### | Run, game, run!
If you have done one of the previous steps, run your game (F5). I hope you will see your dialog appear. If not check if you missed something. You can also always ask for help on the discord.

Before you start to make your own dialog, let us introduce some more cool things!
- - -
## Making your first definition
This is already pretty cool, but let's make things more complex. We mentioned them earlier but here they are: Definitons.

### | Make one?
Create a new definition by clicking the X-icon in the toolbar. You will now see the definition editor.

Here you can give your definition a name and a default value, but behold. Do you see that `Type` button? It's very important because it differentiates to types of definitions that are very diffrent:

A `Variable` just has a name and a value. These definitions can be used to store information (that can be inserted into text events) and to use that information in condition events.

An `Extra Information` is used for extra information. WOW. Sorry. If the name of such a definition is inside a text, the player can hover over it and see a box with information appear.

### | Make one!
Let's first create a `variable`, so make sure that type is selected. We will call it weapon and give it a default value of "knife". 

### | And... another one!
Now let's create another defintion, this time of type `Extra Information`. Select the type.

I will call mine "Hogwarts" and use the same as the title. I will enter some usefull information and some lore to be displayed at the bottom.

### | Now use them. Do it!
These definitions are nice and everything. But let's put them to actual use.

Go back into your timeline. Add a new `Text` event.
Now we want to mention the characters weapon. We will write the name of the definition in brackets:
> ⚠️ ADD IMAGE HERE

Test the game. The definitions name is replaced by it's value.
Let's get even more crazy. Add a `Set Value` event and drag it above the `Text` event from earlier. In the event select the variable and set it's value to "Axe".

Now play the game again. Can you spot the difference?

### | What about the Extra information

To use the extra information definitions you don't have to put them in brackets. Just use the word somewhere in your text. Let's try it out. Add a text event that contains the name of your extra information definition.

Run the game and hover over the word. Cool, right?

- - -
## Create your first dialog theme
- - -
## How to export the game
When you export a project using Dialogic, you need to add `*.json, *.cfg` on the Resources tab (see the image below). This allows Godot to pack the files from the `/dialogic` folder.

![Screenshot](https://coppolaemilio.com/images/dialogic/exporting-2.png?v2)

## Behind the scenes
If you wonder how all of this works, here is some (very) short explantaion.

All the ressources are saved as jsons in a dialogic folder in your games root directory.

Boom. There you go :). I'm to lazy to explain more.
