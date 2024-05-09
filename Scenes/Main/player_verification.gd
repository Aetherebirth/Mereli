extends Node

@onready var player_container_scene = preload("res://Scenes/Instances/PlayerContainer.tscn")
@onready var main_interface = get_parent()

var awaiting_verification = {}

func start(player_id):
	awaiting_verification[player_id] = {"Timestamp": int(Time.get_unix_time_from_system())}
	main_interface.FetchToken(player_id)

func Verify(player_id, token: String, player_private_data):
	var token_verification = false
	while int(Time.get_unix_time_from_system()) - int(token.right(10)) <= 30:
		if main_interface.expected_tokens.has(token):
			token_verification = true
			CreatePlayerContainer(player_id, player_private_data)
			awaiting_verification.erase(player_id)
			main_interface.expected_tokens.erase(token)
			break
		else:
			await get_tree().create_timer(2.0).timeout
	main_interface.ReturnTokenVerificationResults(player_id, token_verification)
	if token_verification == false: #this is to make sure people are disconnected
		awaiting_verification.erase(player_id)
		main_interface.network.disconnect_peer(player_id)



func CreatePlayerContainer(player_id, player_private_data):
	var new_player_container = player_container_scene.instantiate()
	new_player_container.name = str(player_id)
	get_parent().add_child(new_player_container, true)
	var player_container = get_parent().get_node(str(player_id))
	FillPlayerContainer(player_container, player_private_data)

func FillPlayerContainer(player_container, player_private_data):
	player_container.player_public_data = ServerData.test_data
	player_container.player_public_data.username = player_private_data.username
	player_container.player_private_data = player_private_data


func _on_verification_expiration_timeout():
	var current_time = int(Time.get_unix_time_from_system())
	var start_time
	if awaiting_verification == {}:
		pass
	else:
		for key in awaiting_verification.keys():
			start_time = awaiting_verification[key].Timestamp
			if current_time - start_time >= 40:
				awaiting_verification.erase(key)
				var connected_peers = Array(multiplayer.get_peers())
				if connected_peers.has(key):
					main_interface.ReturnTokenVerificationResults(key, false)
					main_interface.network.disconnect_peer(key)
		print("Awaiting verification:")
		print(awaiting_verification)

