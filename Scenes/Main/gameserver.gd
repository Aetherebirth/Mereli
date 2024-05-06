extends Node2D
class_name Connection

signal connected
signal disconnected

static var is_peer_connected: bool

@export var default_port: int = 6944
@export var max_clients: int
@export var default_ip: String = "127.0.0.1"
@export var use_localhost_in_editor: bool

var peer

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
	$PlayerVerification.start(id)


func peer_disconnected(id: int) -> void:
	print("Peer disconnected: " + str(id))


func disconnect_all() -> void:
	multiplayer.peer_connected.disconnect(peer_connected)
	multiplayer.peer_disconnected.disconnect(peer_disconnected)


@rpc("any_peer", "reliable")
func FetchPlayerStats():
	print("Client requested stats")
	var player_id = multiplayer.get_remote_sender_id()
	ReturnPlayerStats(player_id, get_node(str(player_id)).player_data)

@rpc("authority", "call_remote", "reliable")
func ReturnPlayerStats(player_id, results):
	print(results)
	ReturnPlayerStats.rpc_id(player_id, results)









