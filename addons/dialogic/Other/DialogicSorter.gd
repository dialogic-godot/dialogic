extends Node
class_name DialgicSorter


static func key_available(key, a: Dictionary) -> bool:
	return key in a.keys() and not a[key].empty()


static func get_compare_value(a: Dictionary) -> String:
	if key_available('display_name', a):
		return a['display_name']
	
	if key_available('name', a):
		return a['name']
	
	if key_available('id', a):
		return a['id']
	
	if 'metadata' in a.keys():
		var a_metadata = a['metadata']
		if key_available('name', a_metadata):
			return a_metadata['name']
		if key_available('file', a_metadata):
			return a_metadata['file']
	return ''


static func sort_resources(a: Dictionary, b: Dictionary):
	return get_compare_value(a).to_lower() < get_compare_value(b).to_lower()
