extends Node
# Autoload this as "NoiseBus" in Project Settings > Autoload.
#
# Any object (player footsteps, doors, thrown objects, breaking glass...)
# calls NoiseBus.emit_noise(global_position, radius, loudness) whenever it
# makes a sound. Enemies subscribe to `noise_emitted` and decide for
# themselves whether the noise is inside their hearing range.

signal noise_emitted(position: Vector3, radius: float, loudness: float)

func emit_noise(position: Vector3, radius: float, loudness: float = 1.0) -> void:
	noise_emitted.emit(position, radius, loudness)
