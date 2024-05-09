extends Node

signal connected
signal disconnected

static var is_peer_connected: bool

@export var default_port: int = 6945
@export var max_clients: int
@export var default_ip: String = "127.0.0.1"
@export var use_localhost_in_editor: bool

@onready var hub = $"."

var network = ENetMultiplayerPeer.new()
var logon_attempts : int
var hub_api

func _ready() -> void:
	print("Connecting to Server Hub...")
	hub_api = MultiplayerAPI.create_default_interface()
	network.create_client(default_ip,default_port)
	get_tree().set_multiplayer(hub_api, hub.get_path())
	hub_api.multiplayer_peer = network
	
	hub_api.connected_to_server.connect(_connected_to_server)
	hub_api.connection_failed.connect(_connection_failed)
	hub_api.server_disconnected.connect(_disconnected_from_server)


@rpc("any_peer", "reliable")
func DistributeLoginToken(token, player_private_data):
	print("Received token from hub")
	get_node("/root/GameServer").expected_tokens[token] = player_private_data
	

func _connection_failed() -> void:
	print("Connection to Server Hub failed")
	disconnected.emit()
func _connected_to_server() -> void:
	print("Connected to Server Hub")
func _disconnected_from_server() -> void:
	print("Disconnected from Server Hub")
