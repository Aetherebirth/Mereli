extends Node

@onready var entity_container_scenes = {
	"player": preload("res://Scenes/Instances/PlayerContainer.tscn"),
	"npc": preload("res://Scenes/Instances/NPCContainer.tscn")
}

func _ready():
	CreateEntityContainer("npc", GuidHelper.GenerateGuid(), {"P": Vector2(0, 0)}, {"name": "Billy"})

func _physics_process(delta):
	var entity_state_collection = get_parent().entity_state_collection
	var NPCs = entity_state_collection.npc
	for entity_type in entity_state_collection.keys():
		for entity: EntityContainer in get_parent().get_node("Entities/%s"%entity_type).get_children():
			if entity_state_collection[entity_type].has(entity.name):
				entity_state_collection[entity_type][entity.name]["T"] = int(Time.get_unix_time_from_system()*1000)
				entity_state_collection[entity_type][entity.name]["P"] = entity.global_position
			else:
				entity_state_collection[entity_type][entity.name] = {
					"T": int(Time.get_unix_time_from_system()*1000),
					"P": entity.global_position
				}


func CreateEntityContainer(entity_type: String, entity_id: String, private_data: Dictionary, public_data={}):
	var new_container: EntityContainer = entity_container_scenes[entity_type].instantiate()
	new_container.name = str(entity_id)
	new_container.private_data = private_data
	new_container.public_data = public_data
	get_parent().get_node("Entities/%s"%entity_type).add_child(new_container, true)
	var container = get_parent().get_node("Entities/%s"%entity_type).get_node(str(entity_id))
	return container
