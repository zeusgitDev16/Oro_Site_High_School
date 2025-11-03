import 'package:flutter/material.dart';
import 'package:oro_site_high_school/screens/teacher/resources/upload_resource_screen.dart';
import 'package:oro_site_high_school/screens/teacher/resources/resource_details_screen.dart';

class MyResourcesScreen extends StatefulWidget {
  const MyResourcesScreen({super.key});

  @override
  State<MyResourcesScreen> createState() => _MyResourcesScreenState();
}

class _MyResourcesScreenState extends State<MyResourcesScreen> {
  String _selectedCourse = 'All Courses';
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isGridView = true;

  final List<String> _courses = ['All Courses', 'Mathematics 7', 'Science 7'];
  final List<String> _categories = [
    'All',
    'Lesson',
    'Activity',
    'Video',
    'Document',
    'Presentation',
    'Other'
  ];

  // Mock resource data
  late List<Map<String, dynamic>> _resources;

  @override
  void initState() {
    super.initState();
    _resources = [
      {
        'id': 'res-1',
        'title': 'Algebra Basics - Module 1',
        'course': 'Mathematics 7',
        'category': 'Lesson',
        'type': 'PDF',
        'size': '2.5 MB',
        'uploadDate': DateTime.now().subtract(const Duration(days: 2)),
        'downloads': 28,
        'description': 'Introduction to algebraic expressions and equations',
      },
      {
        'id': 'res-2',
        'title': 'Photosynthesis Video Lecture',
        'course': 'Science 7',
        'category': 'Video',
        'type': 'MP4',
        'size': '45.8 MB',
        'uploadDate': DateTime.now().subtract(const Duration(days: 5)),
        'downloads': 32,
        'description': 'Detailed explanation of photosynthesis process',
      },
      {
        'id': 'res-3',
        'title': 'Practice Problems Set 1',
        'course': 'Mathematics 7',
        'category': 'Activity',
        'type': 'DOCX',
        'size': '1.2 MB',
        'uploadDate': DateTime.now().subtract(const Duration(days: 7)),
        'downloads': 25,
        'description': 'Practice problems for algebra basics',
      },
      {
        'id': 'res-4',
        'title': 'Cell Structure Presentation',
        'course': 'Science 7',
        'category': 'Presentation',
        'type': 'PPTX',
        'size': '8.3 MB',
        'uploadDate': DateTime.now().subtract(const Duration(days: 10)),
        'downloads': 30,
        'description': 'PowerPoint presentation on cell structure',
      },
      {
        'id': 'res-5',
        'title': 'Geometry Formulas Reference',
        'course': 'Mathematics 7',
        'category': 'Document',
        'type': 'PDF',
        'size': '1.8 MB',
        'uploadDate': DateTime.now().subtract(const Duration(days: 15)),
        'downloads': 35,
        'description': 'Quick reference guide for geometry formulas',
      },
    ];
  }

  List<Map<String, dynamic>> get _filteredResources {
    return _resources.where((resource) {
      final matchesCourse = _selectedCourse == 'All Courses' ||
          resource['course'] == _selectedCourse;
      final matchesCategory =
          _selectedCategory == 'All' || resource['category'] == _selectedCategory;
      final matchesSearch = resource['title']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          resource['description']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
      return matchesCourse && matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Resources'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            tooltip: _isGridView ? 'List View' : 'Grid View',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UploadResourceScreen(),
                ),
              );
            },
            tooltip: 'Upload Resource',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          _buildStatistics(),
          Expanded(
            child: _isGridView
                ? _buildGridView()
                : _buildListView(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const UploadResourceScreen(),
            ),
          );
        },
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload Resource'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search resources...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCourse,
                  decoration: InputDecoration(
                    labelText: 'Course',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.school),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  items: _courses
                      .map((course) => DropdownMenuItem(
                            value: course,
                            child: Text(course),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCourse = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.category),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  items: _categories
                      .map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    final totalResources = _resources.length;
    final totalDownloads =
        _resources.fold(0, (sum, r) => sum + (r['downloads'] as int));
    final totalSize = _resources.fold(0.0, (sum, r) {
      final sizeStr = r['size'].toString().split(' ')[0];
      return sum + double.parse(sizeStr);
    });

    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Resources',
              totalResources.toString(),
              Icons.library_books,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Total Downloads',
              totalDownloads.toString(),
              Icons.download,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Total Size',
              '${totalSize.toStringAsFixed(1)} MB',
              Icons.storage,
              Colors.purple,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Avg Downloads',
              (totalDownloads / totalResources).toStringAsFixed(0),
              Icons.trending_up,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView() {
    if (_filteredResources.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _filteredResources.length,
      itemBuilder: (context, index) {
        return _buildResourceGridCard(_filteredResources[index]);
      },
    );
  }

  Widget _buildListView() {
    if (_filteredResources.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _filteredResources.length,
      itemBuilder: (context, index) {
        return _buildResourceListCard(_filteredResources[index]);
      },
    );
  }

  Widget _buildResourceGridCard(Map<String, dynamic> resource) {
    final fileType = resource['type'] as String;
    final iconData = _getFileIcon(fileType);
    final iconColor = _getFileColor(fileType);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResourceDetailsScreen(resource: resource),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, color: iconColor, size: 40),
              ),
              const SizedBox(height: 12),
              Text(
                resource['title'],
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                resource['course'],
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(Icons.download, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${resource['downloads']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    resource['size'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResourceListCard(Map<String, dynamic> resource) {
    final fileType = resource['type'] as String;
    final iconData = _getFileIcon(fileType);
    final iconColor = _getFileColor(fileType);
    final uploadDate = resource['uploadDate'] as DateTime;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResourceDetailsScreen(resource: resource),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, color: iconColor, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource['title'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      resource['course'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Uploaded ${uploadDate.day}/${uploadDate.month}/${uploadDate.year}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      resource['category'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.download, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${resource['downloads']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        resource['size'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No resources found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or upload a new resource',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String type) {
    switch (type.toUpperCase()) {
      case 'PDF':
        return Icons.picture_as_pdf;
      case 'DOCX':
      case 'DOC':
        return Icons.description;
      case 'PPTX':
      case 'PPT':
        return Icons.slideshow;
      case 'MP4':
      case 'AVI':
      case 'MOV':
        return Icons.video_library;
      case 'MP3':
      case 'WAV':
        return Icons.audio_file;
      case 'ZIP':
      case 'RAR':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String type) {
    switch (type.toUpperCase()) {
      case 'PDF':
        return Colors.red;
      case 'DOCX':
      case 'DOC':
        return Colors.blue;
      case 'PPTX':
      case 'PPT':
        return Colors.orange;
      case 'MP4':
      case 'AVI':
      case 'MOV':
        return Colors.purple;
      case 'MP3':
      case 'WAV':
        return Colors.green;
      case 'ZIP':
      case 'RAR':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
}
