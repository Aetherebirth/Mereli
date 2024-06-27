extends Node

@onready var main_interface = get_parent()

var awaiting_verification = {}

func start(player_id):
	awaiting_verification[player_id] = {"Timestamp": int(Time.get_unix_time_from_system())}
	main_interface.FetchToken(player_id)

func Verify(player_id, token: String, private_data: Dictionary):
	var token_verification = false
	while int(Time.get_unix_time_from_system()) - int(token.right(10)) <= 30:
		if main_interface.expected_tokens.has(token):
			token_verification = true
			CreatePlayerContainer(str(player_id), private_data)
			awaiting_verification.erase(player_id)
			main_interface.expected_tokens.erase(token)
			break
		else:
			await get_tree().create_timer(2.0).timeout
	main_interface.ReturnTokenVerificationResults(player_id, token_verification)
	if token_verification == false: #this is to make sure people are disconnected
		awaiting_verification.erase(player_id)
		main_interface.network.disconnect_peer(player_id)


func CreatePlayerContainer(player_id: String, private_data: Dictionary):
	var container = get_parent().get_node("EntityProcessing").CreateEntityContainer(EntityHelper.Type.PLAYER, player_id, private_data)
	FillPlayerContainer(player_id, container, private_data)

func FillPlayerContainer(player_id, player_container, private_data):
	player_container.public_data = ServerData.test_data.duplicate(true)
	player_container.public_data.name = private_data.name
	player_container.public_data.guild = private_data.guild
	player_container.private_data = private_data
	var player_guild = player_container.public_data.guild
	print(player_guild)
	if(get_parent().player_guilds.has(str(player_guild.id))):
		get_parent().player_guilds[str(player_guild.id)].append(player_id)
	else:
		get_parent().player_guilds[str(player_guild.id)] = [player_id]


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

