extends Area2D

@export var interaction_name: String = "House Door"

var player_near := false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta):
	if player_near and Input.is_action_just_pressed("interact"):
		print("Interacted with: " + interaction_name)

func _on_body_entered(body):
	if body.name == "Player" or body.is_in_group("player"):
		player_near = true
		print("Press E to interact with the door")

func _on_body_exited(body):
	if body.name == "Player" or body.is_in_group("player"):
		player_near = false
