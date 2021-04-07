#class_name TimelineResourceFormatLoader
extends ResourceFormatLoader

func get_recognized_extensions() -> PoolStringArray:
	var extensions = ["tmln"]
	return PoolStringArray(extensions)

func get_resource_type(path: String) -> String:
	var _ext = path.get_extension().to_lower()
	if _ext == ["tmln"]:
		return "Resource"
	return ""

func handles_type(typename: String) -> bool:
	return typename == "Resource"

