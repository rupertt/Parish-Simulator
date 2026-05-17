extends Node

signal connected(client_id: String, players: Array)
signal disconnected()
signal connection_failed(reason: String)
signal snapshot_received(players: Array)
signal player_joined(player: Dictionary)
signal player_left(player_id: String)
signal ping_updated(milliseconds: int)

const SEND_INTERVAL := 0.05
const PING_INTERVAL := 2.0

var socket := WebSocketPeer.new()
var client_id := ""
var _connected := false
var _last_input := Vector2.ZERO
var _last_facing := "down"
var _send_timer := 0.0
var _ping_timer := 0.0
var _join_sent := false
var _join_payload: Dictionary = {}

func connect_to_server(url: String, player_name: String) -> void:
	disconnect_from_server()
	socket = WebSocketPeer.new()
	GameState.set_connection_status("Connecting")
	var error := socket.connect_to_url(url)
	if error != OK:
		GameState.set_connection_status("Connection failed")
		connection_failed.emit("Could not open WebSocket: %s" % error)
		return
	_connected = true
	_join_sent = false
	_join_payload = {
		"type": "join",
		"name": player_name,
		"characterId": GameState.character_id
	}

func disconnect_from_server() -> void:
	if _connected:
		socket.close()
	_connected = false
	client_id = ""
	_join_sent = false
	_join_payload = {}

func set_local_input(direction: Vector2, facing: String) -> void:
	_last_input = direction
	_last_facing = facing

func _process(delta: float) -> void:
	if not _connected:
		return

	socket.poll()
	var state := socket.get_ready_state()
	if state == WebSocketPeer.STATE_CLOSED:
		_connected = false
		GameState.set_connection_status("Offline")
		disconnected.emit()
		return

	while socket.get_available_packet_count() > 0:
		_handle_packet(socket.get_packet().get_string_from_utf8())

	if state != WebSocketPeer.STATE_OPEN:
		return

	if not _join_sent:
		_join_sent = true
		_send_json(_join_payload)

	_send_timer += delta
	if _send_timer >= SEND_INTERVAL:
		_send_timer = 0.0
		_send_json({
			"type": "input",
			"input": {
				"x": _last_input.x,
				"y": _last_input.y,
				"facing": _last_facing
			}
		})

	_ping_timer += delta
	if _ping_timer >= PING_INTERVAL:
		_ping_timer = 0.0
		_send_json({
			"type": "ping",
			"sentAt": Time.get_ticks_msec()
		})

func _handle_packet(text: String) -> void:
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return

	var message := parsed as Dictionary
	match String(message.get("type", "")):
		"welcome":
			client_id = String(message.get("id", ""))
			GameState.set_connection_status("Connected")
			connected.emit(client_id, message.get("players", []))
		"snapshot":
			snapshot_received.emit(message.get("players", []))
		"player_joined":
			player_joined.emit(message.get("player", {}))
		"player_left":
			player_left.emit(String(message.get("id", "")))
		"pong":
			var sent_at := int(message.get("sentAt", Time.get_ticks_msec()))
			ping_updated.emit(Time.get_ticks_msec() - sent_at)
		"error":
			connection_failed.emit(String(message.get("message", "Network error")))

func _send_json(payload: Dictionary) -> void:
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		socket.send_text(JSON.stringify(payload))
