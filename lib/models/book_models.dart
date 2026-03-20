// lib/models/book_models.dart - SHARED DATA MODELS

class Book {
  final String title;
  final String image;
  final String summary;
  final String theme;
  final List<BookChapter> chapters;
  final String author;
  final int readTime;
  final String funFact;

  Book({
    required this.title,
    required this.image,
    required this.summary,
    required this.theme,
    required this.chapters,
    required this.author,
    required this.readTime,
    required this.funFact,
  });
}

class BookChapter {
  final String title;
  final String content;
  final List<String> keyPoints;
  final String didYouKnow;
  final List<QuizQuestion> quizQuestions;

  BookChapter({
    required this.title,
    required this.content,
    required this.keyPoints,
    required this.didYouKnow,
    required this.quizQuestions,
  });
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String explanation;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });
}

// Sample Book Data
final List<Book> scienceBooks = [
  Book(
    title: "Amazing Changes of Matter! 🔬",
    image: "lib/assets/statesofmatter.jpg",
    summary:
        "Discover the super cool properties of matter and how it magically changes between solid, liquid, and gas states!",
    theme: "Chemistry",
    author: "Prof. Alex Chen",
    readTime: 15,
    funFact:
        "Did you know? Water is the only substance on Earth that naturally exists in all three states at the same time!",
    chapters: [
      BookChapter(
        title: "🧊 Three States of Matter",
        content:
            """Imagine everything around you - your desk, the air you breathe, even the water you drink - they're all made of something called MATTER! Matter is like the building blocks of everything in the universe.

Matter comes in three main forms, kind of like ice cream comes in different flavors:

Solids are Super Strong! 💪
Solids keep their shape no matter what! Think about a rock, a book, or an ice cube. The tiny particles (we call them atoms and molecules) inside solids are packed together really tight, like students standing in a crowded hallway. They can only wiggle a tiny bit in place. That's why you can pick up a solid and it doesn't flow through your fingers!

Liquids Love to Flow! 💧
Liquids are the relaxed cousins of solids. They have a set volume (amount), but they'll take the shape of any container you put them in. Pour water into a cup - it becomes cup-shaped! Pour it into a bowl - now it's bowl-shaped! The particles in liquids are still close together, but they can slide past each other like people dancing at a party.

Gases are Free Spirits! 💨
Gases are the ultimate free spirits - they spread out to fill up any space they're in! The air around you is full of gases, but you can't see most of them. Gas particles zoom around super fast with lots of space between them, like kids running around in a huge playground.

The coolest part? The difference between these three states is all about how much energy the particles have and how close together they are!""",
        keyPoints: [
          "Solid = Particles packed tight, keeps its shape",
          "Liquid = Particles slide past each other, flows freely",
          "Gas = Particles spread far apart, fills any space",
          "It's all about particle arrangement and energy!",
        ],
        didYouKnow:
            "🌟 Fun Fact: Your pencil is a solid, but the graphite inside is made of the same element (carbon) as diamonds! The only difference is how the atoms are arranged.",
        quizQuestions: [
          QuizQuestion(
            question: "What happens to particles in a solid?",
            options: [
              "They fly around freely",
              "They vibrate in place",
              "They disappear",
              "They turn into liquid",
            ],
            correctAnswer: 1,
            explanation:
                "Great job! Solid particles are packed tightly and can only vibrate in their fixed positions.",
          ),
          QuizQuestion(
            question: "Which state of matter takes the shape of its container?",
            options: ["Solid", "Liquid", "Gas", "Both liquid and gas"],
            correctAnswer: 3,
            explanation:
                "Awesome! Both liquids and gases take the shape of their container - liquids flow to fit, and gases expand to fill the entire space!",
          ),
        ],
      ),
    ],
  ),
  Book(
    title: "Earth Day Every Day 🌍",
    image: "lib/assets/earthScience.png",
    summary:
        "Explore our amazing planet Earth from the inside out! Learn about its layers, rotation, seasons, and our place in the universe!",
    theme: "Earth Science",
    author: "Dr. Maria Stone",
    readTime: 20,
    funFact:
        "Earth is the only planet not named after a god - its name comes from the Old English word 'ertha' meaning ground!",
    chapters: [
      BookChapter(
        title: "🌍 Earth's Amazing Layers",
        content:
            """Imagine Earth is like a giant jawbreaker candy - it has different layers! Let's dig deep and discover what's under our feet.

The Crust: Where We Live! 🏠
The crust is Earth's outer shell - the ground you walk on! It's like the skin of an apple, super thin compared to the rest of Earth. Under the oceans, it's only about 5 kilometers thick, but under continents it can be up to 70 kilometers thick. All life on Earth lives on this thin rocky crust!

The Mantle: Earth's Gooey Middle! 🌋
Below the crust is the mantle - the thickest layer of Earth! It's made of hot, dense rock that's so hot it flows veeeery slowly, like super thick honey or lava lamp fluid. The mantle is about 2,900 kilometers thick! Even though it flows, it's not liquid - it's more like silly putty that moves over millions of years.

The mantle's movement is super important because it causes the crust above to shift and move, creating mountains, earthquakes, and volcanoes!""",
        keyPoints: [
          "Crust: Thin outer layer where we live (5-70 km)",
          "Mantle: Thickest layer, hot flowing rock (2,900 km)",
          "Outer Core: Liquid metal, creates magnetic field",
          "Inner Core: Solid metal ball at the center, super hot!",
        ],
        didYouKnow:
            "🌟 Fun Fact: If Earth were shrunk to the size of an apple, the crust would be thinner than the apple's skin! We literally live on a paper-thin shell!",
        quizQuestions: [
          QuizQuestion(
            question: "Which layer of Earth do we live on?",
            options: ["Mantle", "Crust", "Outer Core", "Inner Core"],
            correctAnswer: 1,
            explanation:
                "Correct! We live on the crust, the thin outer layer of Earth.",
          ),
        ],
      ),
    ],
  ),
];

final List<Book> spaceBooks = [
  Book(
    title: "Plant Power! 🌱",
    image: "lib/assets/plantScience.jpg",
    summary:
        "Discover the amazing world of plants! Learn how they grow, make their own food, and reproduce in super cool ways!",
    theme: "Biology",
    author: "Dr. Green Leaf",
    readTime: 22,
    funFact:
        "The largest living organism on Earth is a fungus in Oregon that covers 2,385 acres - that's bigger than 1,600 football fields!",
    chapters: [
      BookChapter(
        title: "🌿 Plant Parts: A Team That Works Together!",
        content:
            """Plants are like amazing living machines! Each part has its own special job, and they all work together to keep the plant alive and healthy. Let's meet the team!

Roots: The Underground Heroes! 🦸‍♂️
Roots live underground where you can't see them, but they're super important! They have two main jobs:

Job 1 - Anchor the Plant: Roots spread out underground like an anchor, holding the plant firmly in the soil so wind and rain can't knock it over. Strong roots = strong plant!

Job 2 - Drink Up!: Roots are like straws that suck up water and minerals from the soil. They have tiny root hairs (like little fingers) that increase the surface area and help them absorb even more!

Some plants, like carrots and sweet potatoes, also use their roots as storage containers for food!""",
        keyPoints: [
          "Roots: anchor plant + absorb water and minerals",
          "Stem: supports plant + transports water and food",
          "Leaves: make food through photosynthesis",
          "Flowers: reproductive parts that make seeds",
          "Seeds: contain baby plant + stored food",
        ],
        didYouKnow:
            "🌟 Fun Fact: The world's tallest trees (California Redwoods) can grow over 100 meters tall - that's as tall as a 30-story building! Yet they all started from tiny seeds!",
        quizQuestions: [
          QuizQuestion(
            question: "What is the main job of roots?",
            options: [
              "Make food",
              "Anchor plant and absorb water",
              "Make seeds",
              "Catch sunlight",
            ],
            correctAnswer: 1,
            explanation:
                "Correct! Roots anchor the plant in soil and absorb water and minerals that the plant needs!",
          ),
        ],
      ),
    ],
  ),
];

final featuredBook = scienceBooks[0];
