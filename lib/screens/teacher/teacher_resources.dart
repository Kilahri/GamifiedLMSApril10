import 'package:flutter/material.dart';

class TeacherResourcesScreen extends StatefulWidget {
  final String currentUsername;

  const TeacherResourcesScreen({super.key, required this.currentUsername});

  @override
  State<TeacherResourcesScreen> createState() => _TeacherResourcesScreenState();
}

class _TeacherResourcesScreenState extends State<TeacherResourcesScreen> {
  final Color _primaryAccentColor = const Color(0xFF415A77);
  final Color _sectionTitleColor = const Color(0xFF98C1D9);

  String _searchQuery = "";
  String _selectedCategory = "All";

  final List<String> _categories = [
    "All",
    "Getting Started",
    "Teaching Guides",
    "Templates & Tools",
    "Video Tutorials",
    "Professional Development",
    "Help & Support",
  ];

  final List<Map<String, dynamic>> _resources = [
    {
      "title": "Platform Quick Start Guide",
      "category": "Getting Started",
      "type": "PDF",
      "description": "Learn how to navigate the platform in 10 minutes",
      "icon": Icons.rocket_launch,
      "color": Colors.blue,
    },
    {
      "title": "First Week Checklist",
      "category": "Getting Started",
      "type": "Checklist",
      "description": "Essential tasks for your first week teaching",
      "icon": Icons.checklist,
      "color": Colors.green,
    },
    {
      "title": "Lesson Plan Template",
      "category": "Templates & Tools",
      "type": "Template",
      "description": "Downloadable lesson planning template",
      "icon": Icons.description,
      "color": Colors.orange,
    },
    {
      "title": "Classroom Management Strategies",
      "category": "Teaching Guides",
      "type": "Guide",
      "description": "Effective techniques for managing virtual classrooms",
      "icon": Icons.school,
      "color": Colors.purple,
    },
    {
      "title": "Creating Engaging Content",
      "category": "Video Tutorials",
      "type": "Video",
      "description": "15-minute tutorial on creating student content",
      "icon": Icons.play_circle_filled,
      "color": Colors.red,
    },
    {
      "title": "Assessment Best Practices",
      "category": "Teaching Guides",
      "type": "Guide",
      "description": "How to create fair and effective assessments",
      "icon": Icons.assessment,
      "color": Colors.teal,
    },
    {
      "title": "Grading Rubric Template",
      "category": "Templates & Tools",
      "type": "Template",
      "description": "Customizable grading rubric for assignments",
      "icon": Icons.grade,
      "color": Colors.amber,
    },
    {
      "title": "Parent Communication Templates",
      "category": "Templates & Tools",
      "type": "Template",
      "description": "Pre-written emails for common scenarios",
      "icon": Icons.email,
      "color": Colors.indigo,
    },
    {
      "title": "Platform Features Overview",
      "category": "Video Tutorials",
      "type": "Video",
      "description": "Complete walkthrough of all platform features",
      "icon": Icons.video_library,
      "color": Colors.red,
    },
    {
      "title": "Differentiated Instruction Guide",
      "category": "Teaching Guides",
      "type": "Guide",
      "description": "Strategies for diverse learning needs",
      "icon": Icons.diversity_3,
      "color": Colors.deepPurple,
    },
    {
      "title": "Educational Technology Trends",
      "category": "Professional Development",
      "type": "Article",
      "description": "Latest trends in educational technology",
      "icon": Icons.trending_up,
      "color": Colors.cyan,
    },
    {
      "title": "Effective Feedback Strategies",
      "category": "Professional Development",
      "type": "Webinar",
      "description": "How to provide constructive student feedback",
      "icon": Icons.feedback,
      "color": Colors.pink,
    },
    {
      "title": "Frequently Asked Questions",
      "category": "Help & Support",
      "type": "FAQ",
      "description": "Answers to common teacher questions",
      "icon": Icons.help_outline,
      "color": Colors.blueGrey,
    },
    {
      "title": "Troubleshooting Guide",
      "category": "Help & Support",
      "type": "Guide",
      "description": "Solutions to common technical issues",
      "icon": Icons.build,
      "color": Colors.brown,
    },
    {
      "title": "Science Experiment Ideas",
      "category": "Teaching Guides",
      "type": "Collection",
      "description": "50+ hands-on science experiments",
      "icon": Icons.science,
      "color": Colors.lightGreen,
    },
  ];

  List<Map<String, dynamic>> get _filteredResources {
    return _resources.where((resource) {
      final matchesCategory =
          _selectedCategory == "All" ||
          resource["category"] == _selectedCategory;
      final matchesSearch =
          _searchQuery.isEmpty ||
          resource["title"].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          resource["description"].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _openResource(Map<String, dynamic> resource) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1B263B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(resource["icon"], color: resource["color"], size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    resource["title"],
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: resource["color"].withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    resource["type"],
                    style: TextStyle(
                      color: resource["color"],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  resource["description"],
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 16),
                Text(
                  "Category: ${resource["category"]}",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Close",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Opening "${resource["title"]}"...'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryAccentColor,
                ),
                icon: const Icon(
                  Icons.open_in_new,
                  color: Colors.white,
                  size: 18,
                ),
                label: const Text(
                  "Open",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B263B),
        elevation: 0,
        title: const Text(
          "Teacher Resources",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1B263B),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search resources...",
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54),
                          onPressed: () {
                            setState(() {
                              _searchQuery = "";
                            });
                          },
                        )
                        : null,
                filled: true,
                fillColor: const Color(0xFF0D1B2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Category Filter
          Container(
            height: 50,
            color: const Color(0xFF1B263B),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: const Color(0xFF0D1B2A),
                    selectedColor: _primaryAccentColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Results Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  "${_filteredResources.length} resources found",
                  style: TextStyle(
                    color: _sectionTitleColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Resources List
          Expanded(
            child:
                _filteredResources.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 80,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No resources found",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Try adjusting your search or filters",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredResources.length,
                      itemBuilder: (context, index) {
                        final resource = _filteredResources[index];

                        return Card(
                          color: const Color(0xFF1B263B),
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _openResource(resource),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: resource["color"].withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      resource["icon"],
                                      color: resource["color"],
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          resource["title"],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          resource["description"],
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: resource["color"]
                                                    .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                resource["type"],
                                                style: TextStyle(
                                                  color: resource["color"],
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              resource["category"],
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.5,
                                                ),
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.white.withOpacity(0.3),
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
