# Can I create a timeline using GDScript?

Yes! it is a bit harder since you will have to create each event yourself, and to do that they have to be **valid**. You can check already created timelines with a text editor and see how an event should look like. A better tutorial and improvements will come soon.


A simple example:

```gdscript

func _ready():

 var gdscript_dialog = Dialogic.start('')

 gdscript_dialog.set_dialog_script( {

 "events":[

 { 'event_id':'dialogic_001', "text": "This dialog was created using GDScript!"}

 ]

 })

 add_child(gdscript_dialog)

```