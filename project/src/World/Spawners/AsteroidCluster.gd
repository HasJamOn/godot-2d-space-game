# Cluster of Asteroid nodes in the world.
# Spawns asteroids and keeps track of the available resources in the cluster.
class_name AsteroidCluster
extends Node2D

signal cluster_depleted

const AsteroidScene := preload("res://src/World/DockingPoint/Asteroid.tscn")

# Ore left in the cluster.
var iron_amount := 0.0 setget set_iron_amount


func _init() -> void:
	set_as_toplevel(true)


# Spawns a new random count of asteroids and adds them as children.
func spawn_asteroids(
	rng: RandomNumberGenerator,
	count_min := 1,
	count_max := 5,
	spawn_radius := 150.0,
	asteroid_radius := 75.0
) -> void:
	var count = rng.randi_range(count_min, count_max)
	var immunity_radius := pow(asteroid_radius, 2)

	for _i in range(count):
		var angle := rng.randf() * 2 * PI
		var radius := spawn_radius * sqrt(rng.randf())
		var spawn_position := Vector2(radius * cos(angle), radius * sin(angle))
		for asteroid in get_children():
			if spawn_position.distance_squared_to(asteroid.position) < immunity_radius:
				continue

		var asteroid = _create_asteroid(rng, spawn_position)
		asteroid.connect("mined", self, "_on_Asteroid_mined")
		asteroid.connect("depleted", self, "_on_Asteroid_depleted")
		add_child(asteroid)
		iron_amount += asteroid.iron_amount

	Events.emit_signal("asteroid_cluster_spawned", get_children())


func set_iron_amount(value: float) -> void:
	iron_amount = min(value, 0.0)
	if is_equal_approx(iron_amount, 0.0):
		emit_signal("cluster_depleted")
		queue_free()


func _create_asteroid(rng: RandomNumberGenerator, location: Vector2) -> Asteroid:
	var asteroid: Asteroid = AsteroidScene.instance()
	asteroid.setup(rng)
	asteroid.global_position = location
	asteroid.rotation = rng.randf_range(0, PI * 2)
	Events.emit_signal("asteroid_spawned", asteroid)
	return asteroid


func _on_Asteroid_mined(amount: float) -> void:
	self.iron_amount -= amount


func _on_Asteroid_depleted() -> void:
	if get_child_count() == 1:
		emit_signal("cluster_depleted")
