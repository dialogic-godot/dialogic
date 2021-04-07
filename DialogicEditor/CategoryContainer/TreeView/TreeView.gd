extends Tree

var _base_resource = null

var root

func _ready() -> void:
	root = create_item()
	set_hide_root(true)

	if _base_resource:
		update_tree()

func update_tree() -> void:
	if get_root():
		get_root().free()
		root = create_item()
	
	for resource in _base_resource.resources:
		var f = File.new()
		if not f.file_exists(resource):
			# I hate when the resource_path doesn't exist
			# this prevents that loader doesn't load empty strings
			continue
		
		var _resource = ResourceLoader.load(resource, "")
		
		if not _resource:
			print("no resource")
			continue
		
		if resource is EncodedObjectAsID:
			_resource = instance_from_id(resource.object_id)
			print("get resource by id: ", _resource)
		
		if not is_instance_valid(_resource):
			print("instance is not valid")
			continue
		
		var _item = create_item(root)
		_item.set_text(0, _resource.resource_path)


func set_base(resource:Resource):
	_base_resource = resource
	update_tree()

func _on_base_resource_change():
	update_tree()
