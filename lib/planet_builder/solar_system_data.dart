import 'planet_model.dart';

class SolarPlanetData {
  final String name;
  final String subtitle;
  final String description;
  final String funFact;
  final String distanceFromSun; // e.g. "57.9 million km"
  final String orbitalPeriod; // e.g. "88 Earth days"
  final String diameter;
  final String temperature;
  final List<String> keyFacts;
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
    required this.model,
  });
}

final List<SolarPlanetData> solarSystemPlanets = [
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

  SolarPlanetData(
    name: 'Venus',
    subtitle: 'The Hellish Twin',
    description:
        'Venus is often called Earth\'s twin because of its similar size and mass, but the resemblance '
        'ends there. It is the hottest planet in our solar system with surface temperatures reaching '
        '465°C — hot enough to melt lead. Its thick atmosphere of carbon dioxide traps heat in a '
        'runaway greenhouse effect. Venus rotates backwards compared to most planets, so the Sun '
        'rises in the west and sets in the east.',
    funFact:
        'Venus spins so slowly that a day on Venus (243 Earth days) is actually longer than its year (225 Earth days)!',
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

  SolarPlanetData(
    name: 'Earth',
    subtitle: 'Our Home Planet',
    description:
        'Earth is the only known planet to harbor life. About 71% of its surface is covered by water, '
        'earning it the nickname "the Blue Planet." It has a protective magnetic field and an ozone '
        'layer that shields life from harmful solar radiation. Earth\'s single large moon stabilizes '
        'its axial tilt, helping to maintain a stable climate over millions of years.',
    funFact:
        'Earth is the densest planet in the solar system. It\'s also the only planet not named after a god!',
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

  SolarPlanetData(
    name: 'Mars',
    subtitle: 'The Red Planet',
    description:
        'Mars is a cold desert world with a thin atmosphere. Its red color comes from iron oxide '
        '(rust) on its surface. Mars has the tallest volcano in the solar system — Olympus Mons, '
        'standing 21 km high. It also has a canyon system, Valles Marineris, that stretches '
        '4,000 km across. Scientists believe Mars once had liquid water and may have harbored '
        'microbial life billions of years ago.',
    funFact:
        'Mars has two tiny moons, Phobos and Deimos, which are thought to be captured asteroids.',
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

  SolarPlanetData(
    name: 'Jupiter',
    subtitle: 'The Giant King',
    description:
        'Jupiter is the largest planet in our solar system — so large that all other planets '
        'could fit inside it. It is a gas giant with no solid surface. Its most famous feature '
        'is the Great Red Spot, a storm that has been raging for over 350 years. Jupiter has '
        'a powerful magnetic field and at least 95 known moons, including Ganymede — the largest '
        'moon in the solar system.',
    funFact:
        'Jupiter\'s Great Red Spot is a storm larger than Earth that has been going on for centuries!',
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

  SolarPlanetData(
    name: 'Saturn',
    subtitle: 'Lord of the Rings',
    description:
        'Saturn is instantly recognizable by its stunning ring system, the most extensive in the '
        'solar system. These rings are made of ice and rock, ranging in size from tiny grains to '
        'chunks as large as houses. Saturn is a gas giant and the least dense planet — it would '
        'float on water! It has 146 known moons, including Titan, which has a thick atmosphere '
        'and lakes of liquid methane.',
    funFact:
        'Saturn is so light for its size that it would float if you could find an ocean big enough!',
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

  SolarPlanetData(
    name: 'Uranus',
    subtitle: 'The Sideways Planet',
    description:
        'Uranus is an ice giant with a unique feature: it rotates on its side, with an axial tilt '
        'of 98 degrees. This means its poles experience 42 years of continuous sunlight followed by '
        '42 years of darkness. Uranus appears blue-green due to methane in its atmosphere. '
        'Despite being farther from the Sun, its internal heat is oddly low, making it the '
        'coldest planet in the solar system.',
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

  SolarPlanetData(
    name: 'Neptune',
    subtitle: 'The Windy World',
    description:
        'Neptune is the farthest planet from the Sun and the windiest. Winds on Neptune can reach '
        '2,100 km/h — the fastest in the solar system. It is an ice giant with a striking deep '
        'blue color caused by methane in its atmosphere. Neptune has a large moon called Triton '
        'that orbits backwards, suggesting it was captured from the Kuiper Belt. It takes '
        '165 Earth years to complete one orbit of the Sun.',
    funFact:
        'Neptune was the first planet to be predicted by math before it was actually observed through a telescope!',
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
