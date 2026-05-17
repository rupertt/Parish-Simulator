extends Node

var players: Dictionary = {}

func set_players(player_list: Array) -> void:
	players.clear()
	for item in player_list:
		if typeof(item) == TYPE_DICTIONARY and item.has("id"):
			players[String(item["id"])] = item

func upsert_player(player: Dictionary) -> void:
	if player.has("id"):
		players[String(player["id"])] = player

func remove_player(player_id: String) -> void:
	players.erase(player_id)

func count() -> int:
	return players.size()
