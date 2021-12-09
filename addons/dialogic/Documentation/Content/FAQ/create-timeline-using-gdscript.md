# Creating timeline in code?

**Can I create a timeline using GDScript?**

Yes! It's a bit harder since you will have to create each event yourself, and each event has to be **valid.** To get an idea for how to build one properly, open an already created timeline with a text editor and see how we set ours up as an example for yourself. We'll be adding a better tutorial and documentation on this process eventually.


Here's a simple example:

```

func _ready():

 var gdscript_dialog = Dialogic.start('')

 gdscript_dialog.dialog_node.dialog_script = {

 "events":[

 { 'event_id':'dialogic_001', "text": "This dialog was created using GDScript!"}

 ]

 }

 add_child(gdscript_dialog)

```
