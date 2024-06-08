extends EntityContainer

func _physics_process(delta):
	var closest_player = MovementUtils.get_closest_player_to_position_or_null(self)
	if closest_player && (global_position.distance_squared_to(closest_player.global_position)>300):
		global_position = lerp(global_position, closest_player.global_position, .1)
