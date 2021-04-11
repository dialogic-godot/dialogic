tool
extends DialogicDatabaseResource

const DialogicUtil = preload("res://addons/dialogic/Core/DialogicUtil.gd")


func add(res:Resource):
	if not(res is DialogicTimelineResource):
		push_error("resource is not a timeline")
		return
	if res in resources.get_resources():
		push_warning("A resource is already there")
		var _r_array = resources.get_resources()
		var _idx = _r_array.find(res)
		if _idx != -1:
			_r_array[_idx] = res
			save(DialogicResources.TIMELINEDB_PATH)
			emit_signal("changed")
		return
	DialogicUtil.Logger.print(self,["adding a resource:",res.resource_path])
	(resources as ResourceArray).add(res)
	save(DialogicResources.TIMELINEDB_PATH)
	emit_signal("changed")

func remove(item) -> void:
	if not(item is DialogicTimelineResource):
		push_error("item is not a timeline")
		return
	DialogicUtil.Logger.print(self,["removing a resource:",item.resource_path])
	(resources as ResourceArray).remove(item)
	save(DialogicResources.TIMELINEDB_PATH)
	emit_signal("changed")


func scan_timelines_folder() -> void:
	push_warning("Scanning timelines folder")
	var _d:Directory = Directory.new()
	if _d.open(DialogicResources.TIMELINES_DIR) == OK:
		_d.list_dir_begin(false, true)
		var _file_name = _d.get_next()
		while _file_name != "":
			if not _d.current_is_dir():
				var _current_resources_files = []
				var _c_res = resources.get_resources()
				for _r in _c_res:
					if _r:
						var _r_file = _r.resource_path.get_file()
						_current_resources_files.append(_r_file)
				
				if not(_file_name in _current_resources_files):
					push_warning("File {} is not in the timeline database. Adding...".format({"":_file_name}))
					_current_resources_files.append(_file_name)
					add(load(DialogicResources.TIMELINES_DIR+"/"+_file_name))
						
					
			_file_name = _d.get_next()
		_d.list_dir_end()
		push_warning("Done")

func _to_string() -> String:
	return "[TimelineDatabase]"
