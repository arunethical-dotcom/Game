extends RefCounted
## All dialogue lives here, so writers can edit it without touching game code.
## Each line is [speaker, text]. "Kael" is a placeholder name for the main character.

const WAKE_UP := [
	["", "Kingdom A has fallen. Under the cover of night, a lonely boy slipped across the border into Kingdom B."],
	["", "He climbed the Serpent's Way to Akropolis Aigidos, the fortress city on the cliffs, and slipped in through the north gate."],
	["", "He collapsed beside a blacksmith's woodpile. When he woke, the smell of hot iron filled the air."],
	["Kael", "...Where am I?"],
	["", "An old man is working outside the forge. Go and talk to him."],
]

const FIRST_JOB := [
	["Haldor", "Awake at last. You were half dead by my woodpile."],
	["Haldor", "I won't ask where you came from. Folk who arrive at night with no name have their reasons."],
	["Haldor", "But nobody eats free under my roof. The king has ordered new blades, and I'm short on iron."],
	["Haldor", "There's iron ore in the rocks at the foot of the cliffs. Go out the north gate and follow the Serpent's Way down."],
	["Haldor", "Bring me three chunks. Take my old hammer and break them loose."],
	["Kael", "...Thank you."],
	["Haldor", "Don't thank me. Work. And stay out of the Forest of Elders. Beasts live there."],
]

const NOT_ENOUGH := [
	["Haldor", "Three chunks of iron ore. North gate, down the Serpent's Way, the rocks at the foot of the cliffs."],
]

const READY_TO_FORGE := [
	["Haldor", "Hm. Not bad for a skinny one."],
	["Haldor", "Now watch the iron. Strike when it glows brightest. Three good strikes make a good blade."],
]

const FORGE_GREAT := [
	["Haldor", "...That is a fine blade. You've never held a hammer before? Strange."],
]

const FORGE_OK := [
	["Haldor", "It'll hold. Not the king's quality, but it'll hold."],
]

const FORGE_ROUGH := [
	["Haldor", "Crooked as a dog's leg. Still, it has an edge. Keep it."],
]

const HUNT_BRIEFING := [
	["Haldor", "Common iron is fine for soldiers. But the royal family's blades need moonsteel."],
	["Haldor", "A pack of Terrak lives in the Forest of Elders. Ancient beasts, horned, scaled like old stone."],
	["Haldor", "Their leader has moonsteel crystals grown into its back."],
	["Haldor", "I told you to stay out of that forest. Now I'm asking you to go in. Bring me that stone."],
	["Haldor", "When a Terrak roars and glows red, it's about to lunge. Roll aside, then strike."],
	["Haldor", "And come back in one piece. I'm not burying a stranger."],
]

const HUNT_REMINDER := [
	["Haldor", "The Terrak leader is in the Forest of Elders, west along the foot of the cliffs. Dodge when it lunges."],
]

const ENDING := [
	["Haldor", "You came back. And with moonsteel."],
	["Haldor", "With this, I can forge a blade fit for the king's own sons."],
	["Haldor", "..."],
	["Haldor", "I had a son once. He'd have been about your age."],
	["Kael", "What happened to him?"],
	["Haldor", "Another night. Wash up, boy. Supper's getting cold."],
	["", "For the first time in his life, Kael had somewhere to come home to."],
	["", "End of Mission 1. Thanks for playing the prototype."],
]

const KNOCKED_OUT := [
	["", "Everything went dark."],
	["Haldor", "A patrol carried you back to the gate. Rest a moment, then try again. Dodge, boy. Dodge."],
]

const IDLE_LINES := [
	["Haldor", "The fire doesn't feed itself."],
	["Haldor", "A good blade is patience, not strength."],
	["Haldor", "The king's men come for the swords at the end of the month. We'll be ready."],
]

const GUARD_NORTH := [
	["Guard", "Heading out, boy? The Serpent's Way is steep. Watch your footing near the cliff edge."],
	["Guard", "Be back before dark. The gate doesn't open for anyone after sundown."],
]

const GUARD_SOUTH := [
	["Guard", "The south gate is sealed by order of the king. Use the north gate."],
]

const GUARD_CASTLE := [
	["Royal guard", "The castle is closed to commoners. Move along."],
]

const WORKER := [
	["Captive", "(He wears the faded colours of Kingdom A, and iron chains on his ankles.)"],
	["Captive", "Don't stare, boy. If they see you talking to us, they'll think you're one of us."],
	["Kael", "..."],
]

const INNKEEPER := [
	["Innkeeper", "Welcome to the Gilded Tankard. Rooms are for paying guests, but the gossip is free."],
	["Innkeeper", "The king's daughter rides out to the watchtowers some mornings. Strange habit for a princess."],
]

const OUTPOST_GUARD := [
	["Scout", "This is the last outpost before the deep forest. Beyond here, the Terrak hunt."],
	["Scout", "If you're going in, light the fire on top of this tower if you get in trouble. Not that we'll come."],
]

const WATCH_GUARD := [
	["Watchman", "From up there you can see all the way to the old border. Kingdom A is quiet now. Too quiet."],
]

const MINER := [
	["Miner", "East Quarry. Best iron in the kingdom comes out of that hole."],
	["Miner", "Haldor's boy, are you? Take what you can break loose from the rocks out here. The deep seams are the king's."],
]

const MINE_FOREMAN := [
	["Foreman", "Half my diggers are captives from Kingdom A now. They work hard. They don't have much choice."],
]

const GUARD_CITADEL_GATE := [
	["Royal guard", "This is the Royal Citadel, boy. Haldor's apprentice, are you? Then you're here about the king's blades."],
	["Royal guard", "Go on through. Keep to the courtyard and the gardens, and touch nothing."],
]

const GUARD_HALL := [
	["Royal guard", "The Grand Throne Hall. His Majesty is not receiving today. Keep to the carpet."],
]

const GUARD_WEST_WING := [
	["Guard", "The Military Wing: barracks and armory. No one enters without the captain's leave."],
]

const GUARD_EAST_WING := [
	["Guard", "The East Wing is where the royal family lives. Turn around, boy."],
]

const PRIEST := [
	["Sister Maren", "Peace be with you. Even the conquered may pray here, though few dare to."],
	["Sister Maren", "The king's sister comes every morning. She prays for both kingdoms. Don't repeat that."],
]

const GARDENER := [
	["Gardener", "The princess planted half these roses herself. Mind your boots on the gravel."],
]

const COURT_LADY := [
	["Lady of the court", "A smith's boy, in the royal gardens? How very... unusual."],
]

const SERVANT := [
	["Servant", "Kitchens are below us, on the service floor. Busy day, the king's nephew is hosting a hunt."],
]

const STAIRS_UP := [
	["", "Stairs up to the Royal Residential Floor, where the king's family and his sister's family live."],
	["", "(This floor comes in the next update.)"],
]

const STAIRS_DOWN := [
	["", "Stairs down to the Service Floor: kitchens, dining hall and servants' quarters."],
	["", "(This floor comes in the next update.)"],
]

const VILLAGER_LINES := [
	[["Townswoman", "Since the war ended, the king's men take half of every harvest for the castle."]],
	[["Old man", "They say the king's nephew is the cruelest of the whole family. Keep your head down."]],
	[["Merchant", "Haldor's swords? Best in Aigidos. The old man doesn't talk much, though."]],
	[["Boy", "Have you seen a Terrak? My father says they're as big as horses, with horns like a ram!"]],
]
