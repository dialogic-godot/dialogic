tool
extends Tree

# Takes care about the tree behaviour
# Here is where the magic is done

const DialogicUtil = preload("res://addons/dialogic/Core/DialogicUtil.gd")

var _base_resource = null

var root

func _ready() -> void:
	root = create_item()
	set_hide_root(true)

	if _base_resource:
		update_tree()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.scancode == KEY_DELETE and not event.echo:
		if not event.pressed and get_selected():
			remove_item(get_selected())


func update_tree() -> void:
	if not _base_resource:
		DialogicUtil.Logger.print(self,"No base resource")
		return

	if get_root():
		get_root().free()
		clear()
		root = create_item()
	
	for resource in _base_resource.resources:
		create_tree_item(resource)


func create_tree_item(with_resource)->void:
	DialogicUtil.Logger.print(self,"Creating a new tree item with:")
	var f = File.new()
	if not f.file_exists(with_resource):
		# I hate when the resource_path doesn't exist
		# this prevents that loader doesn't load empty strings
		DialogicUtil.Logger.print(self,["The resource doesn't exist", with_resource])
		return
	
	var _resource = ResourceLoader.load(with_resource, "")
	
	if not _resource:
		DialogicUtil.Logger.print(self,"no resource")
		return
	
	if _resource is EncodedObjectAsID:
		_resource = instance_from_id(_resource.object_id)
		DialogicUtil.Logger.print(self,["get resource by id:", _resource])
	
	if not is_instance_valid(_resource):
		DialogicUtil.Logger.print(self,["instance is not valid",_resource])
		return
	
	var _item = create_item()
	_item.set_text(0, _resource.get_good_name(_resource.resource_path))
	_item.set_tooltip(0, _resource.resource_path.get_file())
	_item.set_metadata(0, _resource.resource_path)
	DialogicUtil.Logger.print(self,"Tree item created")

func remove_item(item:TreeItem = null):
	if not item:
		return
	DialogicUtil.Logger.print(self,["Attempt to delete item", item.get_metadata(0)])

func rename_item(item:TreeItem = null):
	item.set_editable(0, true)

func set_base(resource:Resource):
	_base_resource = resource
	update_tree()

func _on_base_resource_change():
	update_tree()
