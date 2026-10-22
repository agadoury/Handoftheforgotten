class_name PilotNoise
## The pilot's value noise and fbm, ported bit for bit (docs/pilot/index.html, "Math, noise, curves")
## so the island's terrain matches the pilot's exactly. Integer maths wraps to 32 bits like JavaScript's Math.imul.

const MASK32 := 0xFFFFFFFF
const OCTAVES := 4
const LACUNARITY := 2.03


static func hash2(ix: int, iy: int) -> float:
	var h := (_imul(ix, 374761393) + _imul(iy, 668265263)) & MASK32
	h = _imul(h ^ (h >> 13), 1274126177)
	h = h ^ (h >> 16)
	return float(h) / 4294967295.0


static func vnoise(x: float, y: float) -> float:
	var ix := floori(x)
	var iy := floori(y)
	var fx := x - ix
	var fy := y - iy
	var ux := fx * fx * (3.0 - 2.0 * fx)
	var uy := fy * fy * (3.0 - 2.0 * fy)
	var a := lerpf(hash2(ix, iy), hash2(ix + 1, iy), ux)
	var b := lerpf(hash2(ix, iy + 1), hash2(ix + 1, iy + 1), ux)
	return lerpf(a, b, uy) * 2.0 - 1.0


static func fbm(x: float, y: float) -> float:
	var s := 0.0
	var a := 0.5
	var f := 1.0
	for _i in OCTAVES:
		s += a * vnoise(x * f, y * f)
		f *= LACUNARITY
		a *= 0.5
	return s


static func _imul(a: int, b: int) -> int:
	return (a * b) & MASK32
