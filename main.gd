extends Control

const URL := preload("res://url.gd")
const HTTP := preload("res://http.gd")
const DebugUtils := preload("res://debugutils.gd")

var http := HTTP.new()
@onready var bodyLabel := %Body as Label
@onready var statusLabel := %Status as Label

func _ready() -> void:
	const SAMPLE_URL := "https://httpbin.org/get"
	var url := URL.new()
	var err := url.parse(SAMPLE_URL)
	assert(err == OK)
	assert(url.to_string() == SAMPLE_URL)

	var body: PackedByteArray = await http.request(url)
	bodyLabel.text = body.get_string_from_utf8()


func _process(_delta: float) -> void:
	var debug := DebugUtils.new()
	var busy := http.is_busy()
	var error := http.last_error
	var status := debug.get_enum_key("HTTPClient", "Status", http.get_status())
	var text := "busy: %s\nerror: %s\nstatus: %s" % [busy, error, status]

	statusLabel.text = text
	http.poll()
