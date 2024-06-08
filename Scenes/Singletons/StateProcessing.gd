extends Node
class_name StateProcessing

var world_state = {}

func _physics_process(delta):
	if not get_parent().entity_state_collection.player.is_empty():
		world_state = {}
		world_state.entities = get_parent().entity_state_collection.duplicate(true)
		for entity_type in world_state.entities:
			for entity_id in world_state.entities[entity_type].keys():
				world_state.entities[entity_type][entity_id].erase("T")
				world_state.entities[entity_type][entity_id]["D"] = {}
		world_state["T"] = int(Time.get_unix_time_from_system()*1000)
		# Verifications
		# Anti-Cheat
		# cuts (chunking / maps)
		# Physic checks
		# Anything else you have to do
		get_parent().SendWorldState(world_state)

