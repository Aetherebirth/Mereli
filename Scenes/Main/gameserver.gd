extends Node2D
class_name Connection

signal connected
signal disconnected

static var is_peer_connected: bool

@export var default_port: int = 6944
@export var max_clients: int
@export var use_localhost_in_editor: bool

@onready var verification_process = $PlayerVerification

var peer

var expected_tokens = {}

var player_state_collection := {}

func _ready() -> void:
	var args = parse_cmdline_args()
	start_server(args)
	connected.connect(func(): Connection.is_peer_connected = true)
	disconnected.connect(func(): Connection.is_peer_connected = false)
	disconnected.connect(disconnect_all)


func parse_cmdline_args() -> Dictionary:
	var cmdline_args = OS.get_cmdline_args()
	var args = {}
	
	var i: int = 0
	while(i<len(cmdline_args)):
		if cmdline_args[i]=="--port":
			args.port = int(cmdline_args[i+1])
			i+=1
		i+=1
	if not "port" in args:
		args.port = default_port
	return args

func start_server(args: Dictionary) -> void:
	if max_clients == 0:
		max_clients = 32
	
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(args.port, max_clients)
	if err != OK:
		print("Cannot start server. Err: " + str(err))
		disconnected.emit()
		return
	else:
		print("Server started on port " + str(args.port))
		connected.emit()
	
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)


func peer_connected(id: int) -> void:
	print("Peer connected: " + str(id))
	verification_process.start(id)


func peer_disconnected(id: int) -> void:
	print("Peer disconnected: " + str(id))
	DespawnPlayer(id)
	get_node(str(id)).queue_free()


func disconnect_all() -> void:
	multiplayer.peer_connected.disconnect(peer_connected)
	multiplayer.peer_disconnected.disconnect(peer_disconnected)


@rpc("any_peer", "reliable")
func FetchPlayerStats():
	print("Client requested stats")
	var player_id = multiplayer.get_remote_sender_id()
	ReturnPlayerStats(player_id, get_node(str(player_id)).player_private_data)

@rpc("authority", "call_remote", "reliable")
func ReturnPlayerStats(player_id, results):
	print(results)
	ReturnPlayerStats.rpc_id(player_id, results)

@rpc("authority", "call_remote", "reliable")
func FetchToken(player_id):
	FetchToken.rpc_id(player_id)

@rpc("any_peer", "call_remote", "reliable")
func ReturnToken(token):
	var player_id = multiplayer.get_remote_sender_id()
	print(token)
	verification_process.Verify(player_id, token, expected_tokens[token])

@rpc("authority", "call_remote", "reliable")
func ReturnTokenVerificationResults(player_id, result):
	ReturnTokenVerificationResults.rpc_id(player_id, result)
	if(result==true):
		SpawnNewPlayer(player_id, Vector2(10, 10))
		
@rpc("authority", "call_remote", "reliable")
func SpawnNewPlayer(player_id, position):
	SpawnNewPlayer.rpc_id(0, player_id, position)

@rpc("authority", "call_remote", "reliable")
func DespawnPlayer(player_id):
	player_state_collection.erase(player_id)
	DespawnPlayer.rpc_id(0, player_id)



@rpc("any_peer", "call_remote", "unreliable")
func SendPlayerState(player_state):
	var player_id = multiplayer.get_remote_sender_id()
	if player_state_collection.has(player_id): # Check if player is known in current collection
		if player_state_collection[player_id]["T"] < player_state["T"]:
			player_state_collection[player_id] = player_state # Replace player state in the collection
	else:
		player_state_collection[player_id] = player_state

@rpc("any_peer", "call_remote", "unreliable")
func SendWorldState(world_state):
	SendWorldState.rpc_id(0, world_state)

func _on_token_expiration_timeout():
	var current_time = int(Time.get_unix_time_from_system())
	var token_time
	if expected_tokens=={}:
		pass
	else:
		for token in expected_tokens.keys():
			token_time = int(token.right(10))
			if current_time - token_time >= 30:
				expected_tokens.erase(token)
		print("Expected Tokens:")
		print(expected_tokens)
		

@rpc("any_peer", "call_remote", "reliable")
func FetchServerTime(client_time):
	var player_id = multiplayer.get_remote_sender_id()
	ReturnServerTime(player_id, int(Time.get_unix_time_from_system()*1000), client_time)

@rpc("authority", "call_remote", "reliable")
func ReturnServerTime(player_id, server_time, client_time):
	ReturnServerTime.rpc_id(player_id, server_time, client_time)

@rpc("any_peer", "call_remote", "reliable")
func DetermineLatency(client_time):
	var player_id = multiplayer.get_remote_sender_id()
	ReturnLatency.rpc_id(player_id, client_time)
	
@rpc("authority", "call_remote", "reliable")
func ReturnLatency(client_time):pass


@rpc("any_peer", "call_remote", "reliable")
func AskPlayerData(player_id):
	ReceivePlayerData.rpc_id(multiplayer.get_remote_sender_id(), player_id, get_node(str(player_id)).player_public_data)

@rpc("authority", "call_remote", "reliable")
func ReceivePlayerData(player_id, data):pass


## Chat system
@rpc("any_peer", "call_remote", "reliable")
func SendChatMessage(message: String, tab: String):
	var player_id = multiplayer.get_remote_sender_id()
	if(message.begins_with("/")):
		ProcessCommand(player_id, message.replace("/", ""))
	else:
		print("%s:%s"%[str(player_id), message])
		BroadcastChatMessage(player_id, message, tab)
const help_text = "Available commands:\n- /help\n- /kick <player>"
func ProcessCommand(player_id: int, text: String):
	var command = text.split(" ")
	match command[0]:
		"help":
			ShowChatText(player_id, help_text)
		"kick":
			if(len(command)==2):
				var target = command[1]
				var target_node = GetNodeByUsername(target)
				if(target_node):
					ShowChatText(player_id, "%s was kicked !"%target)
				else:
					ShowChatText(player_id, "Target not found")
			else:
				ShowChatText(player_id, "Invalid syntax")
		_:
			ShowChatText(player_id, help_text)

func GetNodeByUsername(username: String):
	for node in get_children():
		if(is_instance_of(node, "PlayerContainer") and node.player_public_data.username==username):
			return node

@rpc("authority", "call_remote", "reliable")
func ShowChatText(player_id: int, text: String):
	ShowChatText.rpc_id(player_id, text)

@rpc("authority", "call_remote", "reliable")
func BroadcastChatMessage(player_id: int, message: String, tab: String):
	if(tab=="server"):
		BroadcastChatMessage.rpc_id(0, player_id, message, "server")
	elif(tab=="squad"):
		# Only broadcast to squad members
		BroadcastChatMessage.rpc_id(0, player_id, message, "squad")
