class_name EasedValue
extends RefCounted
## A number that glides to its goal along openblack's ZoomInterpolator curve.
## Changing the goal mid-glide restarts the curve from the current value and velocity,
## as openblack's Camera::Update does, so motion never snaps.

const MAX_STEP_S := 0.1

var value: float
var goal: float
var _curve: ZoomInterpolator
var _elapsed := 0.0
var _duration := 0.0


func _init(start: float) -> void:
	value = start
	goal = start


func is_moving() -> bool:
	return _curve != null


## Current velocity in units per second.
func velocity() -> float:
	if _curve == null or _duration <= 0.0:
		return 0.0
	return _curve.velocity_at(_elapsed / _duration) / _duration


func ease_to(new_goal: float, duration: float) -> void:
	if _curve != null and new_goal == goal:
		return
	if _curve == null and new_goal == value:
		goal = new_goal
		return
	# openblack normalises the carried-over velocity by the new duration.
	_curve = ZoomInterpolator.new(value, new_goal, velocity() * duration, 0.0)
	goal = new_goal
	_elapsed = 0.0
	_duration = duration


func snap(new_value: float) -> void:
	value = new_value
	goal = new_value
	_curve = null


func advance(delta: float) -> void:
	if _curve == null:
		return
	_elapsed = minf(_elapsed + minf(delta, MAX_STEP_S), _duration)
	if _elapsed >= _duration:
		snap(goal)
	else:
		value = _curve.position_at(_elapsed / _duration)
