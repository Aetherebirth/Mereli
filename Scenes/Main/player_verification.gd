extends Node

@onready var player_container_scene = preload("res://Scenes/Instances/PlayerContainer.tscn")

func start(player_id):
	# Token verification here
	CreatePlayerContainer(player_id)


func CreatePlayerContainer(player_id):
	var new_player_container = player_container_scene.instantiate()
	new_player_container.name = str(player_id)
	get_parent().add_child(new_player_container, true)
	var player_container = get_parent().get_node(str(player_id))
	FillPlayerContainer(player_container)

func FillPlayerContainer(player_container):
	player_container.player_data = ServerData.test_data
