extends RefCounted
## Map layout of Kingdom B: the fortress city of Akropolis Aigidos and the land around it.
## Everything that needs to know "where is what" reads from here, so the map can be
## reshaped in one place.
##
##   City (inside the outer wall) -> Plateau (grass ring) -> Cliffs -> Lowlands below
##   The only way down the cliffs is the Serpent's Way, starting at the north gate.

const R_CASTLE := 470.0      # eight-sided royal wall around the castle
const R_WALL := 1400.0       # outer city wall
const R_CLIFF := 2050.0      # edge of the plateau
const CLIFF_HALF := 70.0
const RING_ROAD := 820.0
const WORLD_HALF := 4400.0

const GATE_IN := Vector2(0, -1320)
const GATE_OUT := Vector2(0, -1500)
const SOUTH_GATE := Vector2(0, 1400)

# Haldor's walled neighbourhood beside the north gate road
const YARD_RECT := Rect2(-520, -1210, 460, 310)
const FORGE_POS := Vector2(-220, -1080)
const HALDOR_POS := Vector2(-160, -1026)
const YARD_DOOR := Vector2(-60, -1055)   # gap in the yard fence

const SERPENT_WAY := [
	Vector2(0, -1300), Vector2(0, -1700), Vector2(180, -1930), Vector2(420, -2150),
	Vector2(560, -2380), Vector2(450, -2600), Vector2(800, -2900), Vector2(1350, -3150),
	Vector2(2100, -3300), Vector2(3000, -3600), Vector2(4300, -3700)]
const ELDER_PATH := [
	Vector2(560, -2380), Vector2(100, -2500), Vector2(-500, -2620),
	Vector2(-1100, -2760), Vector2(-1700, -2900)]

# Places from the city plan
const INN_POS := Vector2(760, -560)
const OUTPOST_POS := Vector2(-980, -2560)
const MINE_POS := Vector2(1260, -2470)
const WATCHTOWERS := [Vector2(-300, -1700), Vector2(340, -1640), Vector2(1760, 0), Vector2(-1760, 0), Vector2(0, 1760)]
## Areas kept clear of random houses, trees and rocks: [centre, radius]
const RESERVED := [
	[Vector2(760, -560), 120.0], [Vector2(-980, -2560), 150.0], [Vector2(1180, -2400), 230.0],
	[Vector2(-300, -1700), 60.0], [Vector2(340, -1640), 60.0], [Vector2(1760, 0), 60.0],
	[Vector2(-1760, 0), 60.0], [Vector2(0, 1760), 60.0]]


static func reserved(p: Vector2, pad := 0.0) -> bool:
	for r in RESERVED:
		if p.distance_to(r[0]) < r[1] + pad:
			return true
	return false


const RAMP_TOP := Vector2(150, -1900)
const RAMP_BOTTOM := Vector2(560, -2380)
const QUARRY := Vector2(1100, -2350)
const DEN := Vector2(-1800, -2950)


static func dist_to_path(p: Vector2, path: Array) -> float:
	var best := INF
	for i in path.size() - 1:
		var a: Vector2 = path[i]
		var b: Vector2 = path[i + 1]
		var q := Geometry2D.get_closest_point_to_segment(p, a, b)
		best = minf(best, p.distance_to(q))
	return best


static func road_dist(p: Vector2) -> float:
	return minf(dist_to_path(p, SERPENT_WAY), dist_to_path(p, ELDER_PATH))


## Distance to the nearest of the 8 streets that run out from the castle.
static func spoke_dist(p: Vector2) -> float:
	var best := INF
	for k in 8:
		var dir := Vector2.from_angle(-PI / 2.0 + k * PI / 4.0)
		if p.dot(dir) > 0.0:
			best = minf(best, absf(p.cross(dir)))
	return best


static func is_market(p: Vector2) -> bool:
	var r := p.length()
	var a := p.angle()
	return r > 900.0 and r < 1330.0 and a > -1.50 and a < -1.15


static func is_field(p: Vector2) -> bool:
	var r := p.length()
	var a := p.angle()
	return r > 900.0 and r < 1330.0 and a >= -1.15 and a < -0.88


static func biome(p: Vector2) -> String:
	if absf(p.x) > 4050.0 or absf(p.y) > 4050.0:
		return "mountain"
	var r := p.length()
	if r < R_CASTLE + 20.0:
		return "castle"
	if r < R_WALL + 30.0:
		if spoke_dist(p) < 34.0 or absf(r - RING_ROAD) < 32.0 or absf(r - (R_CASTLE + 60.0)) < 30.0:
			return "street"
		if is_market(p):
			return "market"
		if is_field(p):
			return "field"
		if YARD_RECT.has_point(p):
			return "yard"
		return "town"
	if road_dist(p) < 40.0:
		return "road"
	if absf(r - R_CLIFF) < CLIFF_HALF:
		return "cliff"
	if r < R_CLIFF:
		return "plateau"
	if absf(p.y - (-3750.0 + sin(p.x / 480.0) * 160.0)) < 36.0:
		return "stream"
	if p.x < -300.0 and p.y < 1800.0:
		return "elder"
	if r < 2800.0 and p.y < 400.0 and p.x > -300.0:
		return "foothills"
	return "lowlands"


## 0 = inside the city walls, 1 = on the plateau, 2 = below the cliffs
static func zone(p: Vector2) -> int:
	var r := p.length()
	if r < R_WALL:
		return 0
	if r < R_CLIFF:
		return 1
	return 2


## Next point to walk toward so the guide arrow follows gates and the Serpent's Way.
static func next_waypoint(from: Vector2, target: Vector2) -> Vector2:
	# Haldor's yard is fenced: line up with its opening, then walk straight through
	var in_yard := YARD_RECT.has_point(from)
	if zone(from) == 0 and in_yard != YARD_RECT.has_point(target):
		var lined_up := absf(from.y - YARD_DOOR.y) < 22.0 and absf(from.x - YARD_DOOR.x) < 75.0
		var inside_spot := YARD_DOOR + Vector2(-55, 0)
		var outside_spot := YARD_DOOR + Vector2(55, 0)
		if in_yard:
			return outside_spot if lined_up else inside_spot
		if from.distance_to(outside_spot) > 30.0 and not lined_up:
			return outside_spot
		return inside_spot
	var zf := zone(from)
	var zt := zone(target)
	if zf == 2:
		var goal := target if zt == 2 else RAMP_BOTTOM
		if (from.x < -300.0 or goal.x < -300.0) and from.distance_to(goal) > 350.0:
			return follow_path(from, goal, ELDER_PATH)
	if zf == zt:
		return target
	var in_gate := absf(from.x) < 90.0 and from.y < -1240.0 and from.y > -1580.0
	var on_ramp := dist_to_path(from, SERPENT_WAY) < 90.0 and from.y < -1850.0 and from.y > -2420.0
	if zf < zt:
		if zf == 0:
			return GATE_OUT if in_gate else GATE_IN
		return RAMP_BOTTOM if on_ramp else RAMP_TOP
	if zf == 2:
		return RAMP_TOP if on_ramp else RAMP_BOTTOM
	return GATE_IN if in_gate else GATE_OUT


## Walk along a path toward whichever end is closer to the goal.
static func follow_path(from: Vector2, goal: Vector2, path: Array) -> Vector2:
	var pts := path.duplicate()
	if (pts[0] as Vector2).distance_to(goal) < (pts[pts.size() - 1] as Vector2).distance_to(goal):
		pts.reverse()
	var best_i := 0
	var best := INF
	for i in pts.size() - 1:
		var q := Geometry2D.get_closest_point_to_segment(from, pts[i], pts[i + 1])
		var d := from.distance_to(q)
		if d < best:
			best = d
			best_i = i
	var nxt: Vector2 = pts[best_i + 1]
	if from.distance_to(nxt) < 80.0 and best_i + 2 < pts.size():
		nxt = pts[best_i + 2]
	if best_i + 1 == pts.size() - 1 and from.distance_to(nxt) < 120.0:
		return goal
	return nxt
