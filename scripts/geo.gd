extends RefCounted
## Map layout of Kingdom B: the fortress city of Akropolis Aigidos and the land around it.
## Everything that needs to know "where is what" reads from here, so the map can be
## reshaped in one place.
##
##   City (inside the outer wall) -> Plateau (grass ring) -> Cliffs -> Lowlands below
##   The only way down the cliffs is the Serpent's Way, starting at the north gate.

# The city was grown 1.45x around the larger Royal Citadel (stage 10). Positions designed
# for the first, smaller city are multiplied by K; sizes (yards, road widths) stay the same.
const K := 1.45

# The Royal Citadel fills the centre of the city (see citadel.gd). It is designed on a
# 100 x 90 tile plan (32 px tiles) whose top-left corner is CIT_ORIGIN, so plan tile
# (50, 45) is the city centre (0, 0).
const TILE := 32
const CIT_ORIGIN := Vector2(-1600, -1440)
const CIT_MOAT := Rect2(-1600, -1440, 3200, 2880)    # (0,0)-(100,90): outer edge of the moat
const CIT_WALL := Rect2(-1440, -1248, 2880, 2496)    # (5,6)-(95,84): curtain wall line
const CIT_GATE := Vector2(0, 1248)                   # main gate in the south wall
const CIT_BRIDGE := Rect2(-96, 1312, 192, 128)       # (47,86)-(53,90)

const R_WALL := 2600.0 * K       # outer city wall
const R_CLIFF := 3250.0 * K      # edge of the plateau
const CLIFF_HALF := 70.0
const RING_ROAD := 1720.0 * K    # ring street around the citadel moat
const WORLD_HALF := 14000.0      # grown south for the Royal Castle on its lake (stage 13)
const MARKET_R := Vector2(2000.0, 2540.0) * K   # inner and outer radius of market and fields

const GATE_IN := Vector2(0, -2520) * K
const GATE_OUT := Vector2(0, -2700) * K
const SOUTH_GATE := Vector2(0, 2600) * K

# Haldor's walled neighbourhood beside the north gate road (moved north with the gate)
const YARD_SHIFT := Vector2(0, -2410.0 * (K - 1.0))
const YARD_RECT := Rect2(Vector2(-520, -2410) + YARD_SHIFT, Vector2(460, 310))
const FORGE_POS := Vector2(-220, -2280) + YARD_SHIFT
const HALDOR_POS := Vector2(-160, -2226) + YARD_SHIFT
const YARD_DOOR := Vector2(-60, -2255) + YARD_SHIFT   # gap in the yard fence

const SERPENT_WAY := [
	Vector2(0, -2500) * K, Vector2(0, -2900) * K, Vector2(180, -3130) * K, Vector2(420, -3350) * K,
	Vector2(560, -3580) * K, Vector2(450, -3800) * K, Vector2(800, -4100) * K, Vector2(1350, -4350) * K,
	Vector2(2100, -4500) * K, Vector2(3000, -4800) * K, Vector2(5500, -4900) * K]
const ELDER_PATH := [
	Vector2(560, -3580) * K, Vector2(100, -3700) * K, Vector2(-500, -3820) * K,
	Vector2(-1100, -3960) * K, Vector2(-1700, -4100) * K]

# Places from the city plan
const INN_POS := Vector2(1390, -1260) * K
const OUTPOST_POS := Vector2(-980, -3760) * K
const MINE_POS := Vector2(1260, -3670) * K
const WATCHTOWERS := [Vector2(-300, -2900) * K, Vector2(340, -2840) * K, Vector2(2950, 0) * K, Vector2(-2950, 0) * K, Vector2(260, 2950) * K]
## Areas kept clear of random houses, trees and rocks: [centre, radius]
const RESERVED := [
	[INN_POS, 120.0], [OUTPOST_POS, 150.0], [Vector2(1180, -3600) * K, 230.0],
	[Vector2(-300, -2900) * K, 60.0], [Vector2(340, -2840) * K, 60.0], [Vector2(2950, 0) * K, 60.0],
	[Vector2(-2950, 0) * K, 60.0], [Vector2(260, 2950) * K, 60.0],
	[Vector2(150, -3100) * K, 140.0], [Vector2(560, -3580) * K, 160.0]]   # top and foot of the ramp


## World position of a citadel plan tile (top-left corner of the tile).
static func tile(x: float, y: float) -> Vector2:
	return CIT_ORIGIN + Vector2(x, y) * TILE


## World rect of a citadel plan tile range [x0, x1) x [y0, y1).
static func trect(x0: float, y0: float, x1: float, y1: float) -> Rect2:
	return Rect2(tile(x0, y0), Vector2(x1 - x0, y1 - y0) * TILE)


# The city centre is now a town square (the castle moved to its own lake, stage 13).
const TOWN_SQUARE := Rect2(-640, -640, 1280, 1280)

# The Royal Castle stands on its own lake south of the city (castle_outer.gd). It is the
# castle map art/castle4/castle_map.png (864 x 864, cleaned from the 1728 px original by
# tools/castle_mask4.py) shown at CASTLE_S world px per map px: map pixel (432, y) is
# world x = 0, and the map's top edge is world y = CASTLE_O.y.
const CASTLE_S := 5.0
const CASTLE_MAP := 864.0
const CASTLE_O := Vector2(-2160, 5616)
const CASTLE_AREA := Rect2(-2160, 5616, 4320, 4320)
# the road from the city's south gate, down the cliffs, round the west of the lake to the
# south end of the castle's causeway
const SOUTH_ROAD := [Vector2(0, 2600 * K - 20), Vector2(0, 4300), Vector2(-1200, 5200), Vector2(-2500, 6200),
		Vector2(-2500, 9300), Vector2(-1300, 10150), Vector2(0, 10150), Vector2(0, 9930)]


## World position of a point on the reference map.
static func rp(x: float, y: float) -> Vector2:
	return CASTLE_O + Vector2(x, y) * CASTLE_S


static func in_castle(p: Vector2, pad := 0.0) -> bool:
	return CASTLE_AREA.grow(pad).has_point(p)


static func in_citadel(p: Vector2, pad := 0.0) -> bool:
	return TOWN_SQUARE.grow(pad).has_point(p)


static func reserved(p: Vector2, pad := 0.0) -> bool:
	if in_castle(p, pad + 200.0) or dist_to_path(p, SOUTH_ROAD) < 60.0 + pad:
		return true
	for r in RESERVED:
		if p.distance_to(r[0]) < r[1] + pad:
			return true
	return false


const RAMP_TOP := Vector2(150, -3100) * K
const RAMP_BOTTOM := Vector2(560, -3580) * K
const QUARRY := Vector2(1100, -3550) * K
const DEN := Vector2(-1800, -4150) * K


static func dist_to_path(p: Vector2, path: Array) -> float:
	var best := INF
	for i in path.size() - 1:
		var a: Vector2 = path[i]
		var b: Vector2 = path[i + 1]
		var q := Geometry2D.get_closest_point_to_segment(p, a, b)
		best = minf(best, p.distance_to(q))
	return best


static func road_dist(p: Vector2) -> float:
	return minf(minf(dist_to_path(p, SERPENT_WAY), dist_to_path(p, ELDER_PATH)), dist_to_path(p, SOUTH_ROAD))


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
		return "market"
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
	if absf(p.y - (-4950.0 * K + sin(p.x / 480.0) * 160.0)) < 36.0:
		return "stream"
	var wob := sin(p.y / 230.0) * 120.0 + sin(p.y / 97.0 + 1.3) * 50.0
	var wob2 := sin(p.x / 210.0) * 110.0 + sin(p.x / 83.0) * 45.0
	if p.x < -300.0 * K + wob and p.y < 3000.0 * K + wob2:
		return "elder"
	if r < 4000.0 * K and p.y < -400.0 * K and p.x > -300.0 * K:
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
	var on_ramp_now := dist_to_path(from, SERPENT_WAY) < 90.0 and from.y < -3050.0 * K and from.y > -3620.0 * K
	if zf == 2 and zt == 2 and on_ramp_now and from.distance_to(RAMP_BOTTOM) > 110.0 and target.distance_to(RAMP_BOTTOM) < from.distance_to(target) + 400.0:
		return RAMP_BOTTOM   # finish walking down the ramp before turning off it
	if zf == 2:
		var goal := target if zt == 2 else RAMP_BOTTOM
		if (from.x < -300.0 * K or goal.x < -300.0 * K) and from.distance_to(goal) > 350.0:
			return follow_path(from, goal, ELDER_PATH)
	if zf == zt:
		return around_citadel(from, target) if zf == 0 else target
	var in_gate := absf(from.x) < 90.0 and from.y < -2440.0 * K and from.y > -2780.0 * K
	var on_ramp := dist_to_path(from, SERPENT_WAY) < 90.0 and from.y < -3050.0 * K and from.y > -3620.0 * K
	if zf < zt:
		if zf == 0:
			return around_citadel(from, GATE_OUT if in_gate else GATE_IN)
		return RAMP_BOTTOM if on_ramp else RAMP_TOP
	if zf == 2:
		return RAMP_TOP if on_ramp else RAMP_BOTTOM
	return GATE_IN if in_gate else GATE_OUT


## Inside the city the citadel is in the way: go out of its gate, then around its moat.
static func around_citadel(from: Vector2, goal: Vector2) -> Vector2:
	return goal   # the town square is open ground: nothing to walk around
	if in_citadel(from) and not in_citadel(goal):
		return Vector2(0, CIT_MOAT.end.y + 110.0) if from.y < CIT_MOAT.end.y + 40.0 else Vector2(0, CIT_MOAT.end.y + 160.0)
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
