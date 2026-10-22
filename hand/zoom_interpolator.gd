# Ported from openblack: src/Common/ZoomInterpolator.h and src/Common/ZoomInterpolator.cpp (GPL v3).
class_name ZoomInterpolator
extends RefCounted
## openblack's camera easing curve, the original game's: a quartic from p0 to p1 over t in [0, 1]
## that starts with velocity v0 and ends with velocity v1 (velocities per unit of t).
## f(t) = m0*t + (6 - 3*m0 - 3*m1)*t^2 + (3*m0 + 5*m1 - 8)*t^3 + (3 - m0 - 2*m1)*t^4, with m = v / (p1 - p0).

var p0: float
var p1: float
var v0: float
var v1: float


func _init(start: float, end: float, start_velocity: float = 0.0, end_velocity: float = 0.0) -> void:
	p0 = start
	p1 = end
	v0 = start_velocity
	v1 = end_velocity


func position_at(t: float) -> float:
	if p0 == p1:
		return p0
	var pr := p1 - p0
	var m0 := v0 / pr
	var m1 := v1 / pr
	var t2 := t * t
	var t3 := t2 * t
	var t4 := t2 * t2
	var f := t * m0 + t2 * (-3.0 * m0 - 3.0 * m1 + 6.0) + t3 * (3.0 * m0 + 5.0 * m1 - 8.0) + t4 * (-m0 - 2.0 * m1 + 3.0)
	return f * pr + p0


func velocity_at(t: float) -> float:
	if p0 == p1:
		return 0.0
	var pr := p1 - p0
	var m0 := v0 / pr
	var m1 := v1 / pr
	var t2 := t * t
	var t3 := t2 * t
	var f := m0 + t * 2.0 * (-3.0 * m0 - 3.0 * m1 + 6.0) + t2 * 3.0 * (3.0 * m0 + 5.0 * m1 - 8.0) + t3 * 4.0 * (-m0 - 2.0 * m1 + 3.0)
	return f * pr
