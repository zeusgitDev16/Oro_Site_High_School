import 'package:flutter/material.dart';
import 'package:oro_site_high_school/flow/student/student_courses_logic.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// Student Lesson Viewer
/// Displays lesson content with navigation and completion tracking
/// UI only - logic in StudentCoursesLogic
class StudentLessonViewer extends StatefulWidget {
  final int lessonId;
  final StudentCoursesLogic logic;

  const StudentLessonViewer({
    super.key,
    required this.lessonId,
    required this.logic,
  });

  @override
  State<StudentLessonViewer> createState() => _StudentLessonViewerState();
}

class _StudentLessonViewerState extends State<StudentLessonViewer> {
  @override
  void initState() {
    super.initState();
    // Load lesson after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.logic.loadLesson(widget.lessonId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.logic,
      builder: (context, _) {
        final lesson = widget.logic.getLessonById(widget.lessonId);

        if (lesson == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Lesson Not Found'),
            ),
            body: const Center(
              child: Text('Lesson not found'),
            ),
          );
        }

        if (widget.logic.isLoadingLesson) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Loading...'),
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Scaffold(
          appBar: _buildAppBar(lesson),
          body: _buildLessonContent(lesson),
          bottomNavigationBar: _buildBottomBar(lesson),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(Map<String, dynamic> lesson) {
    final isCompleted = lesson['isCompleted'] as bool;

    return AppBar(
      title: Text(
        lesson['title'],
        style: const TextStyle(fontSize: 16),
      ),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 1,
      actions: [
        if (isCompleted)
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 6),
                const Text(
                  'Completed',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLessonContent(Map<String, dynamic> lesson) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lesson header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.library_books, color: Colors.blue, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson['title'],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (lesson['duration'] != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            lesson['duration'],
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Video player (if available)
          if (lesson['videoUrl'] != null) ...[
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_circle_outline, size: 64, color: Colors.grey.shade600),
                    const SizedBox(height: 12),
                    Text(
                      'Video Player',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Video playback will be implemented',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Lesson content (Markdown)
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: MarkdownBody(
                data: lesson['content'] ?? 'No content available',
                styleSheet: MarkdownStyleSheet(
                  h1: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  h2: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  h3: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  p: TextStyle(fontSize: 15, height: 1.6, color: Colors.grey.shade800),
                  listBullet: const TextStyle(fontSize: 15),
                  code: TextStyle(
                    backgroundColor: Colors.grey.shade100,
                    fontFamily: 'monospace',
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Attachments
          if (lesson['attachments'] != null && (lesson['attachments'] as List).isNotEmpty) ...[
            const Text(
              'Attachments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...(lesson['attachments'] as List).map((attachment) => _buildAttachmentCard(attachment)),
            const SizedBox(height: 24),
          ],

          // Mark as complete button
          if (!(lesson['isCompleted'] as bool)) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _markAsCompleted(lesson);
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Mark as Completed'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachmentCard(String filename) {
    final extension = filename.split('.').last.toUpperCase();
    Color color = Colors.blue;
    IconData icon = Icons.insert_drive_file;

    if (extension == 'PDF') {
      color = Colors.red;
      icon = Icons.picture_as_pdf;
    } else if (extension == 'DOC' || extension == 'DOCX') {
      color = Colors.blue;
      icon = Icons.description;
    } else if (extension == 'XLS' || extension == 'XLSX') {
      color = Colors.green;
      icon = Icons.table_chart;
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          filename,
          style: const TextStyle(fontSize: 14),
        ),
        subtitle: Text(
          extension,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.download, size: 20),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Downloading $filename...'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomBar(Map<String, dynamic> lesson) {
    final moduleId = lesson['moduleId'] as int;
    final lessons = widget.logic.getLessonsForModule(moduleId);
    final currentIndex = lessons.indexWhere((l) => l['id'] == lesson['id']);

    final hasPrevious = currentIndex > 0;
    final hasNext = currentIndex < lessons.length - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (hasPrevious)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  final previousLesson = lessons[currentIndex - 1];
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentLessonViewer(
                        lessonId: previousLesson['id'],
                        logic: widget.logic,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Previous'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            )
          else
            const Expanded(child: SizedBox()),
          const SizedBox(width: 16),
          if (hasNext)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  final nextLesson = lessons[currentIndex + 1];
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentLessonViewer(
                        lessonId: nextLesson['id'],
                        logic: widget.logic,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Next'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            )
          else
            const Expanded(child: SizedBox()),
        ],
      ),
    );
  }

  void _markAsCompleted(Map<String, dynamic> lesson) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Completed'),
        content: const Text('Have you finished this lesson?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              widget.logic.markLessonCompleted(lesson['id']);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Lesson marked as completed!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Complete'),
          ),
        ],
      ),
    );
  }
}
