extends Node3D

func enter_trigger(body):
	if body.name == "enemy" and body.destination == self:
		body.pick_destination(body.destination_value)
