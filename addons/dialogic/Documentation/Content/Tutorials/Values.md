# Values

Values are a dialogic resource that allows to store strings and integers and easily reference them with dialogic. 

Once created, a value with a name (e.g. `PlayerName` or `PlayerStrength`) can be added into text events by using square brackets:
![Value is being used](./Images/ValueInUse.PNG)

It can also be used in conditions (Condition Event, Choice Event).

From outside values can be accessed using the DialogiClass:
``` 
func _ready():
    Dialogic.set_variable('PlayerName', 'John')
    if Dialogic.get_variable('PlayerStrength') > 10:
         print("Wow, so strong!")
```

You can also use the whole path when referencing variables. In text this could look like `[Characters/Player/Name]`, in code like `Dialogic.set_variable('Characters/Player/Name', 'Sally')`.

