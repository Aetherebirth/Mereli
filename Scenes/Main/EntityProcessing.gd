extends Node

func _physics_process(delta):
	if not get_parent().entity_state_collection.npc.is_empty():
		for entity_type in get_parent().entity_state_collection:
			for entity_id in get_parent().entity_state_collection[entity_type].keys():
				get_parent().entity_state_collection[entity_type][entity_id].P += Vector2(1,1)*delta
