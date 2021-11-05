# Can I create a timeline using GDScript?

Yes! it is a bit harder since you will have to create each event yourself, and to do that they have to be **valid**. You can check already created timelines with a text editor and see how an event should look like. A better tutorial and improvements will come soon.

**In the meantime**: to see what kind of events need to be passed to `set_dialog_script`, you can create a timeline through the editor, save it, and view the file in the text editor. Copy the json events, paste them into your gdscript (where they'll be treated as dictionaries), and edit them to your needs. 


## Example
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

## Event IDs
...tell Dialogic whether the event is Text, a Question, etc.
The ID codes are as follows (list incomplete):

```gdscript
var D_TEXT = 'dialogic_001'
var D_JOIN = 'dialogic_002'
var D_LEAVE = 'dialogic_003'
var D_QUESTION = 'dialogic_010'
var D_CHOICE = 'dialogic_011'
var D_CONDITION = 'dialogic_012'
var D_END_BRANCH = 'dialogic_013'
var D_SET_VALUE = 'dialogic_014'
var D_BACKGROUND = 'dialogic_021'
var D_CLOSE = 'dialogic_022'
var D_WAIT = 'dialogic_023'
var D_AUDIO = 'dialogic_030'
var D_BGM = 'dialogic_031'
var D_SCENE = 'dialogic_041'
var D_SIGNAL = 'dialogic_040'
```
