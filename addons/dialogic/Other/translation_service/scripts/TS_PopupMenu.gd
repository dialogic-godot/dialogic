tool
extends PopupMenu

export(PoolStringArray) var items_text_keys:PoolStringArray

func _enter_tree():
	for _item_idx in range(get_item_count()):
		if _item_idx+1 > items_text_keys.size():
			# Verify if the index is bigger than the Array
			return
	
		set_item_metadata(_item_idx, items_text_keys[_item_idx])
		var _item_meta = get_item_metadata(_item_idx)
		set_item_text(_item_idx, tr(_item_meta))
	pass
