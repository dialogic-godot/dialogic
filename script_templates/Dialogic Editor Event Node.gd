tool
extends DialogicEditorEventNode

## Use _save_resource() everywhere you update the base_resource
## properties. Then, call again _update_node_values if you want

func _ready()%VOID_RETURN%:
	if base_resource:
        # You can prepare your nodes here
		_update_node_values()
	else:
		return


func _update_node_values()%VOID_RETURN%:
    pass # Update your nodes values here


