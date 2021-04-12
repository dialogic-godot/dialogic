tool
extends OptionButton

const DialogicDB = preload("res://addons/dialogic/Core/DialogicDatabase.gd")
const DialogicUtil = preload("res://addons/dialogic/Core/DialogicUtil.gd")

const ICON_PATH = "res://addons/dialogic/assets/Images/character-tab.svg"

var _char_db = null

func _ready() -> void:
	_char_db = DialogicDB.Characters.get_database()
	
	for _item_idx in range(get_item_count()):
		var _idx = clamp(_item_idx-1, 0, get_item_count())
		remove_item(_idx)
	
	add_item("[Empty]")
	select(0)
	
	var _idx = 1
	for resource in _char_db.resources.get_resources():
		
		DialogicUtil.Logger.print(self,"Creating a character item")
		
		var _char = resource
		var _char_icon = load(ICON_PATH)
		add_icon_item(_char_icon, _char.display_name)
		set_item_metadata(_idx, {"character":_char})
		_idx += 1

# This method probably will fall if there's 2 characters with the same name
func select_item_by_name(name:String) -> void:
	for _item_idx in range(get_item_count()):
		var _idx = clamp(_item_idx-1, 0, get_item_count())
		var _item_text = get_item_text(_idx)
		if _item_text == name:
			select(_idx)

func select_item_by_resource(resource:DialogicCharacterResource) -> void:
	for _item_idx in range(get_item_count()):
		var _idx = clamp(_item_idx, 0, get_item_count())
		var _item_resource = get_item_metadata(_idx)
		if _item_resource is Dictionary and "character" in _item_resource:
			if _item_resource["character"] == resource:
				select(_idx)
