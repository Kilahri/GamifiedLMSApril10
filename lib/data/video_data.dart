// video_data.dart
class ScienceLesson {
  final String title;
  final String emoji;
  final String description;
  final String videoUrl;
  final String duration;
  final List<String> keyTopics;
  final String funFact;
  final List<String> moreFacts;
  final List<QuizQuestion> quizQuestions;

  ScienceLesson({
    required this.title,
    required this.emoji,
    required this.description,
    required this.videoUrl,
    required this.duration,
    required this.keyTopics,
    required this.funFact,
    required this.moreFacts,
    required this.quizQuestions,
  });
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String explanation;
  final String emoji;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.emoji,
  });
}

// Science Lessons Database for Grade 6
final List<ScienceLesson> scienceLessons = [
  ScienceLesson(
    title: "The Amazing Water Cycle",
    emoji: "💧",
    description:
        "Discover how water moves around our planet! Learn about evaporation, condensation, and precipitation - the three main processes that keep water cycling through Earth's atmosphere, land, and oceans. This is one of nature's most important recycling systems!",
    videoUrl: "lib/assets/videos/theWaterCycle.mp4",
    duration: "5 min",
    keyTopics: [
      "Evaporation: How water turns into invisible gas",
      "Condensation: How clouds are formed",
      "Precipitation: Rain, snow, sleet, and hail",
      "The continuous cycle that never stops",
      "Why the water cycle is important for life",
    ],
    funFact:
        "The water you drink today might have been drunk by a dinosaur millions of years ago! Water keeps recycling through the water cycle.",
    moreFacts: [
      "97% of Earth's water is salty ocean water. Only 3% is fresh water!",
      "A single cloud can weigh more than 100 elephants! That's about 500,000 kg of water vapor.",
      "The water cycle has no beginning or end - it's been happening for over 3 billion years!",
      "Plants release water vapor through their leaves in a process called transpiration - it's like plants sweating!",
    ],
    quizQuestions: [
      QuizQuestion(
        question:
            "What is the process called when water turns from liquid into gas?",
        options: ["Condensation", "Evaporation", "Precipitation", "Freezing"],
        correctAnswer: 1,
        explanation:
            "Correct! Evaporation is when liquid water turns into water vapor (gas) using heat energy from the sun.",
        emoji: "🌡️",
      ),
      QuizQuestion(
        question: "What do we call water that falls from the sky?",
        options: [
          "Evaporation",
          "Transpiration",
          "Precipitation",
          "Condensation",
        ],
        correctAnswer: 2,
        explanation:
            "Great job! Precipitation is any form of water (rain, snow, sleet, or hail) that falls from clouds to the ground.",
        emoji: "🌧️",
      ),
      QuizQuestion(
        question:
            "When water vapor cools down and turns back into liquid, this is called...",
        options: ["Evaporation", "Condensation", "Precipitation", "Melting"],
        correctAnswer: 1,
        explanation:
            "Perfect! Condensation happens when water vapor cools and changes back into tiny water droplets, forming clouds!",
        emoji: "☁️",
      ),
    ],
  ),

  ScienceLesson(
    title: "Our Solar System Adventure",
    emoji: "🌍",
    description:
        "Take a journey through space! Learn about the Sun, the eight planets, moons, asteroids, and comets. Discover what makes Earth special and why planets orbit the Sun. Get ready to explore our cosmic neighborhood!",
    videoUrl: "lib/assets/videos/planetSolarSystem.mp4",
    duration: "8 min",
    keyTopics: [
      "The Sun: Our star at the center of everything",
      "The 8 planets and their unique features",
      "Why Earth is perfect for life",
      "Moons, asteroids, and comets",
      "How gravity keeps everything in orbit",
    ],
    funFact:
        "Jupiter is so big that 1,300 Earths could fit inside it! It also has a giant storm called the Great Red Spot that's been raging for over 300 years.",
    moreFacts: [
      "The Sun is so big that 1.3 million Earths could fit inside it!",
      "One day on Venus (243 Earth days) is longer than one year on Venus (225 Earth days)!",
      "Saturn's rings are made of billions of pieces of ice and rock, some as small as grains of sand!",
      "If you could drive to the Sun at highway speed, it would take about 177 years to get there!",
    ],
    quizQuestions: [
      QuizQuestion(
        question: "How many planets are in our solar system?",
        options: ["7 planets", "8 planets", "9 planets", "10 planets"],
        correctAnswer: 1,
        explanation:
            "Correct! There are 8 planets in our solar system. Pluto was reclassified as a dwarf planet in 2006.",
        emoji: "🪐",
      ),
      QuizQuestion(
        question: "Which planet is known as the Red Planet?",
        options: ["Venus", "Mercury", "Mars", "Jupiter"],
        correctAnswer: 2,
        explanation:
            "Yes! Mars is called the Red Planet because its surface is covered with rust-colored iron oxide (rust)!",
        emoji: "🔴",
      ),
      QuizQuestion(
        question: "What keeps the planets orbiting around the Sun?",
        options: ["Magnets", "Gravity", "Wind", "Rocket power"],
        correctAnswer: 1,
        explanation:
            "Excellent! The Sun's powerful gravity pulls on all the planets and keeps them in orbit around it.",
        emoji: "🌟",
      ),
    ],
  ),

  ScienceLesson(
    title: "Plant Power: Photosynthesis",
    emoji: "🌱",
    description:
        "Discover the amazing superpower that plants have! Learn how plants use sunlight, water, and carbon dioxide to make their own food and produce the oxygen we breathe. This process, called photosynthesis, is one of the most important reactions on Earth!",
    videoUrl: "lib/assets/videos/photosynthesis.mp4",
    duration: "5 min",
    keyTopics: [
      "How plants make food from sunlight",
      "The role of chlorophyll (the green pigment)",
      "What plants need: sunlight, water, CO₂",
      "Why photosynthesis is important for all life",
      "How plants produce oxygen for us to breathe",
    ],
    funFact:
        "One large tree can produce enough oxygen in one year for two people to breathe! That's why forests are called the 'lungs of the Earth'.",
    moreFacts: [
      "Plants convert sunlight into food so efficiently that they capture more energy than all human technology combined!",
      "About 70% of Earth's oxygen comes from tiny ocean plants called phytoplankton!",
      "The Amazon Rainforest produces about 20% of the world's oxygen - that's why it's so important to protect!",
      "Without photosynthesis, there would be no food, no oxygen, and no life as we know it on Earth!",
    ],
    quizQuestions: [
      QuizQuestion(
        question: "What do plants make during photosynthesis?",
        options: [
          "Water and carbon dioxide",
          "Glucose (sugar) and oxygen",
          "Chlorophyll and roots",
          "Sunlight and soil",
        ],
        correctAnswer: 1,
        explanation:
            "Perfect! Plants make glucose (sugar for food) and oxygen during photosynthesis. We breathe that oxygen!",
        emoji: "🍃",
      ),
      QuizQuestion(
        question: "What gives plants their green color?",
        options: ["Water", "Sunlight", "Chlorophyll", "Oxygen"],
        correctAnswer: 2,
        explanation:
            "Correct! Chlorophyll is the green pigment in leaves that captures sunlight energy for photosynthesis.",
        emoji: "💚",
      ),
      QuizQuestion(
        question:
            "Which gas do plants take IN from the air during photosynthesis?",
        options: ["Oxygen", "Nitrogen", "Carbon dioxide", "Hydrogen"],
        correctAnswer: 2,
        explanation:
            "Great! Plants take in carbon dioxide (CO₂) from the air and use it to make food during photosynthesis.",
        emoji: "🌬️",
      ),
    ],
  ),

  ScienceLesson(
    title: "States of Matter",
    emoji: "🧊",
    description:
        "Everything around you is made of matter! Learn about the three states of matter - solids, liquids, and gases - and discover how matter can change from one state to another. See how adding or removing heat causes amazing transformations!",
    videoUrl: "lib/assets/videos/statesOfMatter.mp4",
    duration: "7 min",
    keyTopics: [
      "Solids: particles packed tightly together",
      "Liquids: particles that can flow",
      "Gases: particles spread far apart",
      "How heat causes state changes",
      "Melting, freezing, evaporation, and condensation",
    ],
    funFact:
        "Water is the only substance on Earth that naturally exists in all three states at the same time - ice (solid), liquid water, and water vapor (gas) in the air!",
    moreFacts: [
      "The particles in a gas move so fast they can reach speeds of over 400 meters per second!",
      "When water freezes into ice, it actually expands! That's why ice floats and why frozen water bottles can crack.",
      "Your body is about 60% water - you're mostly made of liquid!",
      "Dry ice is frozen carbon dioxide - it goes directly from solid to gas without becoming liquid first! This is called sublimation.",
    ],
    quizQuestions: [
      QuizQuestion(
        question:
            "In which state of matter are particles packed tightly and vibrate in place?",
        options: ["Liquid", "Solid", "Gas", "Plasma"],
        correctAnswer: 1,
        explanation:
            "Correct! In solids, particles are packed tightly together and can only vibrate in their fixed positions.",
        emoji: "📦",
      ),
      QuizQuestion(
        question:
            "What do we call the process when liquid water turns into water vapor?",
        options: ["Freezing", "Melting", "Evaporation", "Condensation"],
        correctAnswer: 2,
        explanation:
            "Yes! Evaporation is when liquid turns into gas. The sun's heat helps water evaporate from puddles, oceans, and lakes!",
        emoji: "☀️",
      ),
      QuizQuestion(
        question: "At what temperature does water freeze into ice?",
        options: ["100°C", "50°C", "0°C", "-20°C"],
        correctAnswer: 2,
        explanation:
            "Perfect! Water freezes (and melts) at 0°C or 32°F. This is why ice forms when it gets really cold!",
        emoji: "❄️",
      ),
    ],
  ),

  ScienceLesson(
    title: "Ecosystems and Food Webs",
    emoji: "🦁",
    description:
        "Discover how living things depend on each other for survival! Learn about producers, consumers, decomposers, and how energy flows through food chains and food webs. Understand why every organism plays an important role in keeping ecosystems healthy and balanced.",
    videoUrl: "lib/assets/videos/foodChain.mp4",
    duration: "7 min",
    keyTopics: [
      "Producers: plants that make their own food",
      "Consumers: animals that eat other organisms",
      "Decomposers: nature's recyclers",
      "Food chains and food webs",
      "How energy flows through ecosystems",
    ],
    funFact:
        "A single owl can eat over 1,000 mice in a year! If owls disappeared, there would be way too many mice eating all the plants. Everything in nature is connected!",
    moreFacts: [
      "Earthworms are amazing decomposers - they can eat their own weight in soil and dead leaves every day!",
      "The ocean's food web starts with tiny phytoplankton (microscopic plants) that feed the entire ocean ecosystem!",
      "If all the insects disappeared, most birds would starve, then many larger animals would too - the whole food web would collapse!",
      "Fungi and bacteria decompose 90% of all dead plant and animal material, returning nutrients to the soil!",
    ],
    quizQuestions: [
      QuizQuestion(
        question: "What do we call organisms that make their own food?",
        options: ["Consumers", "Producers", "Decomposers", "Predators"],
        correctAnswer: 1,
        explanation:
            "Correct! Producers (like plants) make their own food through photosynthesis. They're the foundation of all food chains!",
        emoji: "🌿",
      ),
      QuizQuestion(
        question: "Which of these is a decomposer?",
        options: ["Lion", "Tree", "Mushroom", "Rabbit"],
        correctAnswer: 2,
        explanation:
            "Yes! Mushrooms are decomposers (along with bacteria). They break down dead material and return nutrients to the soil!",
        emoji: "🍄",
      ),
      QuizQuestion(
        question: "What do arrows in a food web show?",
        options: [
          "Direction of movement",
          "Direction of energy flow",
          "How fast animals run",
          "Where animals live",
        ],
        correctAnswer: 1,
        explanation:
            "Great! Arrows show the direction energy flows - from the organism being eaten to the organism that eats it!",
        emoji: "➡️",
      ),
    ],
  ),
];
