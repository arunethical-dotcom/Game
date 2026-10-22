extends RefCounted
## Map layout of Kingdom B: the fortress city of Akropolis Aigidos and the land around it.
## Everything that needs to know "where is what" reads from here, so the map can be
## reshaped in one place.
##
##   City (inside the outer wall) -> Plateau (grass ring) -> Cliffs -> Lowlands below
##   The only way down the cliffs is the Serpent's Way, starting at the north gate.

# The Royal Citadel fills the centre of the city (see citadel.gd).
const CIT_WALL := Rect2(-1100, -1000, 2200, 1920)   # curtain wall line
const CIT_MOAT := Rect2(-1190, -1150, 2380, 2170)   # outer edge of the moat
const CIT_GATE := Vector2(0, 920)                    # main gate, south
const CIT_BRIDGE := Rect2(-64, 920, 128, 100)

const R_WALL := 2600.0       # outer city wall
const R_CLIFF := 3250.0      # edge of the plateau
const CLIFF_HALF := 70.0
const RING_ROAD := 1720.0    # ring street around the citadel moat
const WORLD_HALF := 5600.0
const MARKET_R := Vector2(2000.0, 2540.0)   # inner and outer radius of market and fields

const GATE_IN := Vector2(0, -2520)
const GATE_OUT := Vector2(0, -2700)
const SOUTH_GATE := Vector2(0, 2600)

# Haldor's walled neighbourhood beside the north gate road
const YARD_RECT := Rect2(-520, -2410, 460, 310)
const FORGE_POS := Vector2(-220, -2280)
const HALDOR_POS := Vector2(-160, -2226)
const YARD_DOOR := Vector2(-60, -2255)   # gap in the yard fence

const SERPENT_WAY := [
	Vector2(0, -2500), Vector2(0, -2900), Vector2(180, -3130), Vector2(420, -3350),
	Vector2(560, -3580), Vector2(450, -3800), Vector2(800, -4100), Vector2(1350, -4350),
	Vector2(2100, -4500), Vector2(3000, -4800), Vector2(5500, -4900)]
const ELDER_PATH := [
	Vector2(560, -3580), Vector2(100, -3700), Vector2(-500, -3820),
	Vector2(-1100, -3960), Vector2(-1700, -4100)]

# Places from the city plan
const INN_POS := Vector2(1390, -1260)
const OUTPOST_POS := Vector2(-980, -3760)
const MINE_POS := Vector2(1260, -3670)
const WATCHTOWERS := [Vector2(-300, -2900), Vector2(340, -2840), Vector2(2950, 0), Vector2(-2950, 0), Vector2(0, 2950)]
## Areas kept clear of random houses, trees and rocks: [centre, radius]
const RESERVED := [
	[INN_POS, 120.0], [OUTPOST_POS, 150.0], [Vector2(1180, -3600), 230.0],
	[Vector2(-300, -2900), 60.0], [Vector2(340, -2840), 60.0], [Vector2(2950, 0), 60.0],
	[Vector2(-2950, 0), 60.0], [Vector2(0, 2950), 60.0]]


static func in_citadel(p: Vector2, pad := 0.0) -> bool:
	return CIT_MOAT.grow(pad).has_point(p)


static func reserved(p: Vector2, pad := 0.0) -> bool:
	for r in RESERVED:
		if p.distance_to(r[0]) < r[1] + pad:
			return true
	return false


const RAMP_TOP := Vector2(150, -3100)
const RAMP_BOTTOM := Vector2(560, -3580)
const QUARRY := Vector2(1100, -3550)
const DEN := Vector2(-1800, -4150)


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
	return r > MARKET_R.x and r < MARKET_R.y and a > -1.50 and a < -1.24


static func is_field(p: Vector2) -> bool:
	var r := p.length()
	var a := p.angle()
	return r > MARKET_R.x and r < MARKET_R.y and a >= -1.24 and a < -1.04


static func biome(p: Vector2) -> String:
	if absf(p.x) > WORLD_HALF - 350.0 or absf(p.y) > WORLD_HALF - 350.0:
		return "mountain"
	var r := p.length()
	if in_citadel(p):
		return "citadel"
	if r < R_WALL + 30.0:
		if (spoke_dist(p) < 34.0 and r > RING_ROAD) or absf(r - RING_ROAD) < 32.0 or (absf(p.x) < 34.0 and p.y > 0.0):
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
	if absf(p.y - (-4950.0 + sin(p.x / 480.0) * 160.0)) < 36.0:
		return "stream"
	var wob := sin(p.y / 230.0) * 120.0 + sin(p.y / 97.0 + 1.3) * 50.0
	var wob2 := sin(p.x / 210.0) * 110.0 + sin(p.x / 83.0) * 45.0
	if p.x < -300.0 + wob and p.y < 3000.0 + wob2:
		return "elder"
	if r < 4000.0 and p.y < -400.0 and p.x > -300.0:
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
		return around_citadel(from, target) if zf == 0 else target
	var in_gate := absf(from.x) < 90.0 and from.y < -2440.0 and from.y > -2780.0
	var on_ramp := dist_to_path(from, SERPENT_WAY) < 90.0 and from.y < -3050.0 and from.y > -3620.0
	if zf < zt:
		if zf == 0:
			return around_citadel(from, GATE_OUT if in_gate else GATE_IN)
		return RAMP_BOTTOM if on_ramp else RAMP_TOP
	if zf == 2:
		return RAMP_TOP if on_ramp else RAMP_BOTTOM
	return GATE_IN if in_gate else GATE_OUT


## Inside the city the citadel is in the way: go out of its gate, then around its moat.
static func around_citadel(from: Vector2, goal: Vector2) -> Vector2:
	if in_citadel(from) and not in_citadel(goal):
		return Vector2(0, 1130) if from.y < 1060.0 else Vector2(0, 1180)
	var box := CIT_MOAT.grow(70)
	var blocked := false
	for i in range(1, 20):
		if box.has_point(from.lerp(goal, i / 20.0)):
			blocked = true
			break
	if not blocked or in_citadel(goal):
		return goal
	# standing right beside the moat: first step away from it
	var m := CIT_MOAT
	if m.grow(24.0).has_point(from):
		if from.y >= m.end.y:
			return Vector2(from.x, m.end.y + 50.0)
		if from.y <= m.position.y:
			return Vector2(from.x, m.position.y - 50.0)
		return Vector2(m.end.x + 50.0 if from.x > 0.0 else m.position.x - 50.0, from.y)
	var side := -1.0 if from.x + goal.x < 0.0 else 1.0
	var cx := side * (box.end.x + 30.0)
	if absf(from.x - cx) > 70.0:
		return Vector2(cx, clampf(from.y, box.position.y - 40.0, box.end.y + 40.0))
	return Vector2(cx, box.position.y - 80.0 if goal.y < from.y else box.end.y + 80.0)


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
