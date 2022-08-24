extends Node
class_name CustomEventConverter

# This is an extension to the Converter to allow for converting custom scenes
# This will take a 1.x event node with a custom scene, and let you convert it to the new format
# One type is provided for example. If you wish to convert them into a new format, add it here as another Match case
# Otherwise, it will just create it as a commment with the parameters in it for you to do in-editor


static func convertCustomEvent(event):
	var returnString = ""
	
	match event['event_id']:
		"comment_001":
			# Example node, a custom event to simply store comments, as there wasn't a built-in one in 1.x
			returnString += "# " + event['comment_text'] 
	
	return returnString
