tool
extends OptionButton

const ICON_PATH = "res://addons/dialogic/assets/Images/Event Icons/Portrait.svg"

var character:DialogicCharacterResource setget _set_character

func _ready() -> void:
	add_items()
	
	if not character:
		visible = false
		return


func clear_items() -> void:
	for _item_idx in range(get_item_count()):
		var _idx = clamp(_item_idx-1, 0, get_item_count())
		remove_item(_idx)

func add_items() -> void:
	clear_items()
	add_item("[Empty]")
	select(0)
	
	if not character:
		return
	
	var _idx = 1
	for portrait in character.portraits.get_resources():
		var _portrait:DialogicPortraitResource = portrait
		var _portrait_icon = load(ICON_PATH)
		
		add_icon_item(_portrait_icon, _portrait.name)
		set_item_metadata(_idx, {"portrait":_portrait})
		_idx += 1

# Copied from CharactersButton
func select_item_by_resource(resource:DialogicPortraitResource) -> void:
	for _item_idx in range(get_item_count()):
		var _idx = clamp(_item_idx, 0, get_item_count())
		var _item_resource = get_item_metadata(_idx)
		if _item_resource is Dictionary and "portrait" in _item_resource:
			if _item_resource["portrait"] == resource:
				select(_idx)


func _set_character(value:DialogicCharacterResource):
	character = value
	if character:
		visible = true
	else:
		visible = false
	add_items()
