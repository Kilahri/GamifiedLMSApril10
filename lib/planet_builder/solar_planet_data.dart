import 'planet_model.dart';
import 'package:flutter/material.dart';

// ── Element data for kid-friendly chemistry display ─────────────────────────

class PlanetElement {
  final String symbol; // e.g. "N₂"
  final String name; // e.g. "Nitrogen"
  final String emoji;
  final double percentage; // 0–100
  final String kidFriendly; // grade-6 explanation
  final Color displayColor;

  const PlanetElement({
    required this.symbol,
    required this.name,
    required this.emoji,
    required this.percentage,
    required this.kidFriendly,
    required this.displayColor,
  });
}

// We import Color via a lightweight barrel so the data file stays pure-Dart.
// In your project, swap this with: import 'package:flutter/material.dart';

// ── Planet data ──────────────────────────────────────────────────────────────

class SolarPlanetData {
  final String name;
  final String subtitle;
  final String description;
  final String funFact;
  final String distanceFromSun;
  final String orbitalPeriod;
  final String diameter;
  final String temperature;
  final List<String> keyFacts;
  final List<PlanetElement> elements; // ← NEW
  final String chemistryNote; // ← NEW  one-liner for kids
  final PlanetModel model;

  const SolarPlanetData({
    required this.name,
    required this.subtitle,
    required this.description,
    required this.funFact,
    required this.distanceFromSun,
    required this.orbitalPeriod,
    required this.diameter,
    required this.temperature,
    required this.keyFacts,
    required this.elements,
    required this.chemistryNote,
    required this.model,
  });
}

// ── Data ─────────────────────────────────────────────────────────────────────

final List<SolarPlanetData> solarSystemPlanets = [
  // ── Mercury ───────────────────────────────────────────────────────────────
  SolarPlanetData(
    name: 'Mercury',
    subtitle: 'The Swift Planet',
    description:
        'Mercury is the smallest planet in our solar system and the closest to the Sun. '
        'Despite being so close to the Sun, it is not the hottest planet — that title belongs to Venus. '
        'Mercury has almost no atmosphere to retain heat, so temperatures swing wildly between '
        '-180°C at night and 430°C during the day. Its surface is heavily cratered, resembling our Moon.',
    funFact:
        'A day on Mercury (sunrise to sunrise) lasts 176 Earth days — longer than its year of 88 days!',
    distanceFromSun: '57.9 million km',
    orbitalPeriod: '88 Earth days',
    diameter: '4,879 km',
    temperature: '-180°C to 430°C',
    keyFacts: [
      'No moons',
      'No rings',
      'Smallest planet',
      'Heavily cratered surface',
      'Extreme temperature swings',
    ],
    chemistryNote:
        'Mercury barely has an atmosphere — just a super thin wisp of gases!',
    elements: [
      PlanetElement(
        symbol: 'O',
        name: 'Oxygen',
        emoji: '💨',
        percentage: 42,
        kidFriendly:
            'Not the kind you breathe! This oxygen floats as single atoms, way too thin to survive in.',
        displayColor: Color(0xFF4FC3F7),
      ),
      PlanetElement(
        symbol: 'Na',
        name: 'Sodium',
        emoji: '🧂',
        percentage: 29,
        kidFriendly:
            'Yes — like the salt on your french fries! The Sun blasts sodium atoms off the surface.',
        displayColor: Color(0xFFFFD54F),
      ),
      PlanetElement(
        symbol: 'H₂',
        name: 'Hydrogen',
        emoji: '🫧',
        percentage: 22,
        kidFriendly:
            'The lightest element in the universe. Hydrogen is the same gas that makes balloons float!',
        displayColor: Color(0xFF90CAF9),
      ),
      PlanetElement(
        symbol: 'He',
        name: 'Helium',
        emoji: '🎈',
        percentage: 6,
        kidFriendly:
            'The same gas that makes your voice squeaky at birthday parties — also found on Mercury!',
        displayColor: Color(0xFFFFCC02),
      ),
      PlanetElement(
        symbol: 'K',
        name: 'Potassium',
        emoji: '🍌',
        percentage: 1,
        kidFriendly:
            'Bananas are full of potassium — and so is Mercury\'s thin atmosphere (in tiny amounts)!',
        displayColor: Color(0xFF66BB6A),
      ),
    ],
    model: PlanetModel(
      size: 0.15,
      atmosphere: AtmosphereType.none,
      hasRings: false,
      moonCount: 0,
      color: PlanetColor.orange,
      ownerId: 'solar_system',
      ownerName: 'Solar System',
    ),
  ),

  // ── Venus ─────────────────────────────────────────────────────────────────
  SolarPlanetData(
    name: 'Venus',
    subtitle: 'The Hellish Twin',
    description:
        'Venus is often called Earth\'s twin because of its similar size and mass, but the resemblance '
        'ends there. It is the hottest planet in our solar system with surface temperatures reaching '
        '465°C — hot enough to melt lead. Its thick atmosphere of carbon dioxide traps heat in a '
        'runaway greenhouse effect. Venus rotates backwards compared to most planets.',
    funFact:
        'A day on Venus (243 Earth days) is longer than its year (225 Earth days)!',
    distanceFromSun: '108.2 million km',
    orbitalPeriod: '225 Earth days',
    diameter: '12,104 km',
    temperature: '465°C (avg)',
    keyFacts: [
      'Hottest planet',
      'Thick toxic atmosphere',
      'Spins backwards',
      'No moons',
      'Brightest object after Sun & Moon',
    ],
    chemistryNote:
        'Venus has a super thick, poisonous atmosphere that traps heat like a giant oven!',
    elements: [
      PlanetElement(
        symbol: 'CO₂',
        name: 'Carbon Dioxide',
        emoji: '🏭',
        percentage: 96.5,
        kidFriendly:
            'This is the same gas you breathe OUT and plants breathe IN. On Venus there\'s SO much of it that it traps heat like a blanket — making it 465°C!',
        displayColor: Color(0xFFFF7043),
      ),
      PlanetElement(
        symbol: 'N₂',
        name: 'Nitrogen',
        emoji: '🌬️',
        percentage: 3.5,
        kidFriendly:
            'About 78% of Earth\'s air is nitrogen. On Venus it\'s only a tiny bit, mixed into that deadly CO₂ soup.',
        displayColor: Color(0xFF4FC3F7),
      ),
      PlanetElement(
        symbol: 'SO₂',
        name: 'Sulfur Dioxide',
        emoji: '🌋',
        percentage: 0.015,
        kidFriendly:
            'This smelly gas comes from volcanoes. It creates Venus\'s thick yellow clouds of sulfuric acid — basically acid rain!',
        displayColor: Color(0xFFFFD54F),
      ),
    ],
    model: PlanetModel(
      size: 0.45,
      atmosphere: AtmosphereType.toxic,
      hasRings: false,
      moonCount: 0,
      color: PlanetColor.orange,
      ownerId: 'solar_system',
      ownerName: 'Solar System',
    ),
  ),

  // ── Earth ─────────────────────────────────────────────────────────────────
  SolarPlanetData(
    name: 'Earth',
    subtitle: 'Our Home Planet',
    description:
        'Earth is the only known planet to harbor life. About 71% of its surface is covered by water, '
        'earning it the nickname "the Blue Planet." It has a protective magnetic field and an ozone '
        'layer that shields life from harmful solar radiation. Earth\'s single large moon stabilizes '
        'its axial tilt, helping to maintain a stable climate over millions of years.',
    funFact:
        'Earth is the densest planet in the solar system — it\'s also the only planet not named after a god!',
    distanceFromSun: '149.6 million km',
    orbitalPeriod: '365.25 Earth days',
    diameter: '12,742 km',
    temperature: '-88°C to 58°C',
    keyFacts: [
      '1 moon',
      'Only known life',
      '71% water surface',
      'Protective magnetic field',
      'Perfect atmospheric balance',
    ],
    chemistryNote:
        'Earth\'s atmosphere is like a perfect recipe — just the right mix to support life!',
    elements: [
      PlanetElement(
        symbol: 'N₂',
        name: 'Nitrogen',
        emoji: '🌬️',
        percentage: 78,
        kidFriendly:
            'Most of the air you breathe is nitrogen! It dilutes the oxygen so fires don\'t burn out of control and we don\'t get too much oxygen at once.',
        displayColor: Color(0xFF4FC3F7),
      ),
      PlanetElement(
        symbol: 'O₂',
        name: 'Oxygen',
        emoji: '🫁',
        percentage: 21,
        kidFriendly:
            'This is the part of air YOU need to survive! Every breath you take, your lungs grab the oxygen and send it to every cell in your body.',
        displayColor: Color(0xFF66BB6A),
      ),
      PlanetElement(
        symbol: 'Ar',
        name: 'Argon',
        emoji: '💡',
        percentage: 1,
        kidFriendly:
            'Argon is a "noble gas" — it doesn\'t react with anything. It\'s used inside light bulbs to stop the metal from burning up!',
        displayColor: Color(0xFFAB47BC),
      ),
      PlanetElement(
        symbol: 'CO₂',
        name: 'Carbon Dioxide',
        emoji: '🌱',
        percentage: 0.04,
        kidFriendly:
            'Plants LOVE this gas — they eat it to make food through photosynthesis! It also helps keep Earth warm enough for life.',
        displayColor: Color(0xFFFFD54F),
      ),
      PlanetElement(
        symbol: 'H₂O',
        name: 'Water Vapour',
        emoji: '💧',
        percentage: 1,
        kidFriendly:
            'Invisible water floating in the air! It forms clouds, rain, and snow — part of the water cycle that keeps all life going.',
        displayColor: Color(0xFF26C6DA),
      ),
    ],
    model: PlanetModel(
      size: 0.46,
      atmosphere: AtmosphereType.earth,
      hasRings: false,
      moonCount: 1,
      color: PlanetColor.blue,
      ownerId: 'solar_system',
      ownerName: 'Solar System',
    ),
  ),

  // ── Mars ──────────────────────────────────────────────────────────────────
  SolarPlanetData(
    name: 'Mars',
    subtitle: 'The Red Planet',
    description:
        'Mars is a cold desert world with a thin atmosphere. Its red color comes from iron oxide '
        '(rust) on its surface. Mars has the tallest volcano in the solar system — Olympus Mons, '
        'standing 21 km high. Scientists believe Mars once had liquid water and may have harbored '
        'microbial life billions of years ago.',
    funFact:
        'Mars has two tiny moons, Phobos and Deimos, thought to be captured asteroids.',
    distanceFromSun: '227.9 million km',
    orbitalPeriod: '687 Earth days',
    diameter: '6,779 km',
    temperature: '-125°C to 20°C',
    keyFacts: [
      '2 moons',
      'Tallest volcano in solar system',
      'Thin CO₂ atmosphere',
      'Evidence of ancient water',
      'Red iron oxide surface',
    ],
    chemistryNote:
        'Mars is basically covered in rust — that\'s what makes it red!',
    elements: [
      PlanetElement(
        symbol: 'CO₂',
        name: 'Carbon Dioxide',
        emoji: '🏭',
        percentage: 95.3,
        kidFriendly:
            'Almost all of Mars\'s thin air is CO₂ — the gas you breathe out. You definitely cannot breathe on Mars!',
        displayColor: Color(0xFFFF7043),
      ),
      PlanetElement(
        symbol: 'N₂',
        name: 'Nitrogen',
        emoji: '🌬️',
        percentage: 2.6,
        kidFriendly:
            'A small amount of nitrogen drifts in the Martian air, but nowhere near enough to mix with breathable oxygen.',
        displayColor: Color(0xFF4FC3F7),
      ),
      PlanetElement(
        symbol: 'Ar',
        name: 'Argon',
        emoji: '💡',
        percentage: 1.9,
        kidFriendly:
            'This harmless gas is also found on Earth. Scientists use it to check if spacecraft are leaking — it shows up on special sensors.',
        displayColor: Color(0xFFAB47BC),
      ),
      PlanetElement(
        symbol: 'Fe₂O₃',
        name: 'Iron Oxide',
        emoji: '🦀',
        percentage: 0, // surface, not atmosphere
        kidFriendly:
            'RUST! The entire surface of Mars is covered in iron oxide — the same red-brown stuff you see on old nails left in the rain.',
        displayColor: Color(0xFFEF5350),
      ),
    ],
    model: PlanetModel(
      size: 0.28,
      atmosphere: AtmosphereType.thin,
      hasRings: false,
      moonCount: 2,
      color: PlanetColor.red,
      ownerId: 'solar_system',
      ownerName: 'Solar System',
    ),
  ),

  // ── Jupiter ───────────────────────────────────────────────────────────────
  SolarPlanetData(
    name: 'Jupiter',
    subtitle: 'The Giant King',
    description:
        'Jupiter is the largest planet in our solar system — so large that all other planets '
        'could fit inside it. It is a gas giant with no solid surface. Its most famous feature '
        'is the Great Red Spot, a storm larger than Earth that has raged for over 350 years.',
    funFact:
        'Jupiter\'s Great Red Spot is a storm bigger than Earth that has been going on for centuries!',
    distanceFromSun: '778.5 million km',
    orbitalPeriod: '11.9 Earth years',
    diameter: '139,820 km',
    temperature: '-110°C (cloud tops)',
    keyFacts: [
      '95 known moons',
      'Largest planet',
      'Great Red Spot storm',
      'Faint ring system',
      'Strong magnetic field',
    ],
    chemistryNote:
        'Jupiter is basically a giant ball of gas — mostly hydrogen and helium, like the Sun!',
    elements: [
      PlanetElement(
        symbol: 'H₂',
        name: 'Hydrogen',
        emoji: '🫧',
        percentage: 89,
        kidFriendly:
            'Jupiter is 89% hydrogen — the same fuel rockets use! Deep inside, the pressure is so extreme that hydrogen turns into a liquid metal that conducts electricity.',
        displayColor: Color(0xFF90CAF9),
      ),
      PlanetElement(
        symbol: 'He',
        name: 'Helium',
        emoji: '🎈',
        percentage: 10,
        kidFriendly:
            'About 10% of Jupiter is helium — the balloon gas! Together with hydrogen, this makes Jupiter similar in chemistry to the Sun.',
        displayColor: Color(0xFFFFCC02),
      ),
      PlanetElement(
        symbol: 'CH₄',
        name: 'Methane',
        emoji: '💨',
        percentage: 0.3,
        kidFriendly:
            'Methane is a smelly gas (the same one in natural gas stoves at home). On Jupiter it floats in the upper clouds.',
        displayColor: Color(0xFF66BB6A),
      ),
      PlanetElement(
        symbol: 'NH₃',
        name: 'Ammonia',
        emoji: '🧹',
        percentage: 0.026,
        kidFriendly:
            'Ammonia smells horrible — like strong cleaning liquid. Jupiter\'s clouds are partly made of ammonia ice crystals that give it those swirling coloured bands!',
        displayColor: Color(0xFFFFD54F),
      ),
    ],
    model: PlanetModel(
      size: 0.95,
      atmosphere: AtmosphereType.thick,
      hasRings: true,
      moonCount: 5,
      color: PlanetColor.orange,
      ownerId: 'solar_system',
      ownerName: 'Solar System',
    ),
  ),

  // ── Saturn ────────────────────────────────────────────────────────────────
  SolarPlanetData(
    name: 'Saturn',
    subtitle: 'Lord of the Rings',
    description:
        'Saturn is instantly recognizable by its stunning ring system, the most extensive in the '
        'solar system. These rings are made of ice and rock, ranging in size from tiny grains to '
        'chunks as large as houses. Saturn is a gas giant and the least dense planet — it would '
        'float on water!',
    funFact:
        'Saturn would float if you could find an ocean big enough to put it in!',
    distanceFromSun: '1.43 billion km',
    orbitalPeriod: '29.5 Earth years',
    diameter: '116,460 km',
    temperature: '-178°C (avg)',
    keyFacts: [
      '146 known moons',
      'Iconic ring system',
      'Least dense planet',
      'Titan has thick atmosphere',
      'Visible rings from Earth',
    ],
    chemistryNote:
        'Saturn\'s rings are made of billions of chunks of ice and rock — from tiny grains to house-sized boulders!',
    elements: [
      PlanetElement(
        symbol: 'H₂',
        name: 'Hydrogen',
        emoji: '🫧',
        percentage: 96,
        kidFriendly:
            'Even more hydrogen than Jupiter! Saturn is like a lighter, fluffier version of Jupiter. All that hydrogen with very little solid stuff makes it the least dense planet.',
        displayColor: Color(0xFF90CAF9),
      ),
      PlanetElement(
        symbol: 'He',
        name: 'Helium',
        emoji: '🎈',
        percentage: 3,
        kidFriendly:
            'Saturn\'s helium is slowly sinking toward the center, releasing heat as it falls — like a very slow rainstorm of helium droplets!',
        displayColor: Color(0xFFFFCC02),
      ),
      PlanetElement(
        symbol: 'CH₄',
        name: 'Methane',
        emoji: '💨',
        percentage: 0.4,
        kidFriendly:
            'Methane gives some of Saturn\'s upper atmosphere a faint blue tinge when sunlight hits it just right.',
        displayColor: Color(0xFF66BB6A),
      ),
      PlanetElement(
        symbol: 'H₂O',
        name: 'Water Ice',
        emoji: '🧊',
        percentage: 0, // ring composition
        kidFriendly:
            'The RINGS are mostly water ice! Billions of icy chunks orbit Saturn, some tiny as dust and some as big as a school bus.',
        displayColor: Color(0xFF26C6DA),
      ),
    ],
    model: PlanetModel(
      size: 0.88,
      atmosphere: AtmosphereType.thick,
      hasRings: true,
      moonCount: 5,
      color: PlanetColor.orange,
      ownerId: 'solar_system',
      ownerName: 'Solar System',
    ),
  ),

  // ── Uranus ────────────────────────────────────────────────────────────────
  SolarPlanetData(
    name: 'Uranus',
    subtitle: 'The Sideways Planet',
    description:
        'Uranus is an ice giant with a unique feature: it rotates on its side, with an axial tilt '
        'of 98 degrees. This means its poles experience 42 years of continuous sunlight followed by '
        '42 years of darkness. Uranus appears blue-green due to methane in its atmosphere.',
    funFact:
        'Uranus rolls around the Sun like a bowling ball — it spins almost completely on its side!',
    distanceFromSun: '2.87 billion km',
    orbitalPeriod: '84 Earth years',
    diameter: '50,724 km',
    temperature: '-224°C (min)',
    keyFacts: [
      '27 known moons',
      'Tilted 98° on its axis',
      'Coldest planetary temperature',
      'Ice giant',
      'Faint ring system',
    ],
    chemistryNote:
        'Methane gas absorbs red light and reflects blue — that\'s why Uranus looks teal!',
    elements: [
      PlanetElement(
        symbol: 'H₂',
        name: 'Hydrogen',
        emoji: '🫧',
        percentage: 83,
        kidFriendly:
            'Like Jupiter and Saturn, Uranus starts with lots of hydrogen. But deeper down it gets very icy and slushy — quite different from the gas giants!',
        displayColor: Color(0xFF90CAF9),
      ),
      PlanetElement(
        symbol: 'He',
        name: 'Helium',
        emoji: '🎈',
        percentage: 15,
        kidFriendly:
            'Uranus has more helium (by percentage) than Jupiter does. That\'s a lot of balloon gas floating around a very cold, faraway world.',
        displayColor: Color(0xFFFFCC02),
      ),
      PlanetElement(
        symbol: 'CH₄',
        name: 'Methane',
        emoji: '🎨',
        percentage: 2.3,
        kidFriendly:
            'This is the COLOUR PAINTER of Uranus! Methane absorbs red and orange light from the Sun, so only blue and green light bounces back — giving Uranus its beautiful teal colour.',
        displayColor: Color(0xFF26C6DA),
      ),
      PlanetElement(
        symbol: 'NH₃',
        name: 'Ammonia Ice',
        emoji: '🧊',
        percentage: 0, // deep interior
        kidFriendly:
            'Deep inside Uranus, ammonia and water mix under massive pressure to form a thick, slushy layer sometimes called a "water-ammonia ocean." Weird!',
        displayColor: Color(0xFF80DEEA),
      ),
    ],
    model: PlanetModel(
      size: 0.7,
      atmosphere: AtmosphereType.thick,
      hasRings: true,
      moonCount: 4,
      color: PlanetColor.teal,
      ownerId: 'solar_system',
      ownerName: 'Solar System',
    ),
  ),

  // ── Neptune ───────────────────────────────────────────────────────────────
  SolarPlanetData(
    name: 'Neptune',
    subtitle: 'The Windy World',
    description:
        'Neptune is the farthest planet from the Sun and the windiest. Winds on Neptune can reach '
        '2,100 km/h — the fastest in the solar system. It is an ice giant with a striking deep '
        'blue color caused by methane in its atmosphere. It takes 165 Earth years to orbit the Sun.',
    funFact:
        'Neptune was the first planet predicted by math before it was seen through a telescope!',
    distanceFromSun: '4.50 billion km',
    orbitalPeriod: '165 Earth years',
    diameter: '49,244 km',
    temperature: '-214°C (avg)',
    keyFacts: [
      '16 known moons',
      'Fastest winds in solar system',
      'Ice giant',
      'Triton orbits backwards',
      'Predicted before discovery',
    ],
    chemistryNote:
        'Neptune\'s wild winds are powered by heat escaping from its core — even though it\'s far from the Sun!',
    elements: [
      PlanetElement(
        symbol: 'H₂',
        name: 'Hydrogen',
        emoji: '🫧',
        percentage: 80,
        kidFriendly:
            'Even this distant, freezing world is mostly hydrogen. Scientists think underneath the gases there\'s a huge slushy ocean of water and ammonia.',
        displayColor: Color(0xFF90CAF9),
      ),
      PlanetElement(
        symbol: 'He',
        name: 'Helium',
        emoji: '🎈',
        percentage: 19,
        kidFriendly:
            'Neptune has more helium than you might expect. Together with hydrogen it forms most of the planet\'s thick, swirling atmosphere.',
        displayColor: Color(0xFFFFCC02),
      ),
      PlanetElement(
        symbol: 'CH₄',
        name: 'Methane',
        emoji: '🎨',
        percentage: 1.5,
        kidFriendly:
            'Just like Uranus, methane makes Neptune blue! But Neptune\'s blue is DEEPER and richer — scientists think there\'s another unknown gas helping create that stunning colour.',
        displayColor: Color(0xFF1565C0),
      ),
      PlanetElement(
        symbol: 'H₂O',
        name: 'Water & Ices',
        emoji: '🌊',
        percentage: 0, // deep interior
        kidFriendly:
            'Deep in Neptune\'s interior, water, methane, and ammonia are crushed into "superionic ice" — a bizarre state where the water is solid AND conducts electricity at the same time!',
        displayColor: Color(0xFF4FC3F7),
      ),
    ],
    model: PlanetModel(
      size: 0.68,
      atmosphere: AtmosphereType.thick,
      hasRings: false,
      moonCount: 4,
      color: PlanetColor.blue,
      ownerId: 'solar_system',
      ownerName: 'Solar System',
    ),
  ),
];
