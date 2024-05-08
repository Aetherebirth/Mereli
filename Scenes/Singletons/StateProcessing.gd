extends Node
class_name StateProcessing

var world_state = {}

func _physics_process(delta):
	if not get_parent().player_state_collection.is_empty():
		world_state = get_parent().player_state_collection.duplicate(true)
		for player_id in world_state.keys():
			world_state[player_id].erase("T")
		world_state["T"] = int(Time.get_unix_time_from_system()*1000)
		# Verifications
		# Anti-Cheat
		# cuts (chunking / maps)
		# Physic checks
		# Anything else you have to do
		get_parent().SendWorldState(world_state)

