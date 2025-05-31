import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'PdfViewerPage.dart';

class ChapterPage extends StatelessWidget {
  final String courseId;
  final String subjectId;
  final String courseName;
  final String universityName;
  final String subjectName;

  const ChapterPage({
    super.key,
    required this.courseId,
    required this.subjectId,
    required this.courseName,
    required this.universityName,
    required this.subjectName,
  });

  @override
  Widget build(BuildContext context) {
    final chaptersRef = FirebaseFirestore.instance
        .collection('courses')
        .doc(courseId)
        .collection('subjects')
        .doc(subjectId)
        .collection('chapters');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(courseName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(universityName, style: const TextStyle(fontSize: 14, color: Colors.white70)),
          ],
        ),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: chaptersRef.get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No chapters found.'));
          }

          final chapters = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chapters.length,
            itemBuilder: (context, index) {
              final chapter = chapters[index];
              final data = chapter.data() as Map<String, dynamic>;
              final name = data['name'] ?? 'Unnamed Chapter';
              final driveId = data['pdfDriveId'];

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      if (driveId != null && driveId.toString().isNotEmpty) {
                        final pdfUrl = 'https://drive.google.com/uc?export=download&id=$driveId';
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PdfViewerPage(
                              pdfUrl: pdfUrl,
                              title: name, // chapter name
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("PDF not available.")),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1B5E20), width: 1.2),
                      ),
                      child: Row(
                        children: [
                          // Container(
                          //   padding: const EdgeInsets.all(10),
                          //   decoration: BoxDecoration(
                          //     color: const Color(0xFF1B5E20).withOpacity(0.1),
                          //     borderRadius: BorderRadius.circular(8),
                          //   ),
                          //   child: const Icon(Icons.menu_book, color: Color(0xFF1B5E20), size: 26),
                          // ),
                          // const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              '${index + 1}. $name',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.black45),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
