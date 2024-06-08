extends Node
class_name MovementUtils

static func get_closest_player_to_position_or_null(entity: EntityContainer):
	var all_players = entity.get_tree().get_nodes_in_group("player")
	var closest_player = null
 
	if (all_players.size() > 0):
		closest_player = all_players[0]
		var distance_to_closest_player = entity.global_position.distance_squared_to(closest_player.global_position)
		for player in all_players:
			var distance_to_this_player = entity.global_position.distance_squared_to(player.global_position)
			if (distance_to_this_player < distance_to_closest_player):
				distance_to_closest_player = distance_to_this_player
				closest_player = player
	return closest_player
