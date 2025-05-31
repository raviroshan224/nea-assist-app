import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'chapter_page.dart';

class SubjectPage extends StatefulWidget {
  final String universityName;
  final String universityId;   // add this
  final String courseName;
  final String courseId;

  const SubjectPage({
    super.key,
    required this.universityName,
    required this.universityId,  // add this here
    required this.courseName,
    required this.courseId,
  });


  @override
  State<SubjectPage> createState() => _SubjectPageState();
}

class _SubjectPageState extends State<SubjectPage> with TickerProviderStateMixin {
  late TabController _tabController;

  String formatYear(String rawYear) {
    // Convert "year1" or "Year1" or "year 1" → "Year 1"
    final lower = rawYear.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    if (lower.startsWith('year')) {
      final numPart = lower.substring(4); // after "year"
      return 'Year ${numPart.trim()}';
    }
    return rawYear; // fallback
  }

  String formatSemester(String rawSemester) {
    // Convert "semester1" or "Semester1" or "semester 1" → "Semester 1"
    final lower = rawSemester.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    if (lower.startsWith('semester')) {
      final numPart = lower.substring(8); // after "semester"
      return 'Semester ${numPart.trim()}';
    }
    return rawSemester; // fallback
  }


  @override
  void initState() {
    super.initState();
    final vm = SubjectPageViewModel(
      universityName: widget.universityName,
      courseName: widget.courseName,
      courseId: widget.courseId,
    );
    _tabController = TabController(length: vm.subjectStructure.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SubjectPageViewModel(
        universityName: widget.universityName,
        courseName: widget.courseName,
        courseId: widget.courseId,
      ),
      child: Consumer<SubjectPageViewModel>(
        builder: (context, viewModel, _) {
          // Update TabController length if subjects loaded after init
          if (_tabController.length != viewModel.subjectStructure.length) {
            _tabController.dispose();
            _tabController = TabController(length: viewModel.subjectStructure.length, vsync: this);
          }

          return DefaultTabController(
            length: viewModel.subjectStructure.length,
            child: Scaffold(
              backgroundColor: Colors.grey[100],
              appBar: AppBar(
                backgroundColor: const Color(0xFF1B5E20),
                elevation: 0,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.courseName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.universityName,
                      style: const TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Colors.green.shade900,
                      unselectedLabelColor: Colors.black87,
                      // In TabBar tabs:
                      tabs: viewModel.subjectStructure.map((yearData) {
                        return Tab(
                          child: Text(
                            formatYear(yearData['year']),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),

                    ),
                  ),
                ),
              ),
              body: viewModel.loading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                controller: _tabController,
                children: viewModel.subjectStructure.map((yearData) {
                  return _buildYearContent(yearData);
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildYearContent(Map<String, dynamic> yearData) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        itemCount: (yearData['semesters'] as List).length,
        itemBuilder: (context, semIndex) {
          final semester = yearData['semesters'][semIndex];
          return Card(
            elevation: 0,
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatSemester(semester['semester']),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),

                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (semester['subjects'] as List).map<Widget>((subject) {
                      final subjectName = subject['name'];
                      final subjectId = subject['id'];
                      return GestureDetector(
                        onTap: () {
                          final subjectId = subject['id']; // use id instead of slug
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChapterPage(
                                courseId: widget.courseId,   // pass courseId
                                subjectId: subjectId,
                                courseName: widget.courseName,
                                universityName: widget.universityName, subjectName: subjectName,// pass subjectId
                              ),
                            ),
                          );
                        },
                        child: Chip(
                          label: Text(subjectName, style: const TextStyle(fontSize: 12)),
                          backgroundColor: Colors.green.shade100,
                        ),
                      );

                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}


// ViewModel to fetch subjects from Firestore and organize by year & semester
class SubjectPageViewModel extends ChangeNotifier {
  final String universityName;
  final String courseName;
  final String courseId;

  bool loading = true;

  // List of maps:
  // [{ "year": "Year 1", "semesters": [{ "semester": "Semester 1", "subjects": [...] }, ...] }, ...]
  List<Map<String, dynamic>> subjectStructure = [];

  SubjectPageViewModel({
    required this.universityName,
    required this.courseName,
    required this.courseId,
  }) {
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .collection('subjects')
          .get();

      // Extract raw subjects
      final rawSubjects = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'No Name',
          'year': data['year'] ?? 'Year 1',
          'semester': data['semester'] ?? 'Semester 1',
        };
      }).toList();

      // Organize by year and semester
      Map<String, Map<String, List<Map<String, String>>>> grouped = {};

      for (var subj in rawSubjects) {
        final year = subj['year'];
        final semester = subj['semester'];
        final name = subj['name'];
        final id = subj['id'];

        grouped.putIfAbsent(year, () => {});
        grouped[year]!.putIfAbsent(semester, () => []);
        grouped[year]![semester]!.add({'id': id, 'name': name});
      }


      // Convert grouped to subjectStructure format
      subjectStructure = grouped.entries.map((yearEntry) {
        final year = yearEntry.key;
        final semestersMap = yearEntry.value;

        final semestersList = semestersMap.entries.map((semEntry) {
          return {
            'semester': semEntry.key,
            'subjects': semEntry.value, // Already contains list of maps: { id, name }
          };
        }).toList();


        return {
          'year': year,
          'semesters': semestersList,
        };
      }).toList();

      // Sort years and semesters if needed (optional)
      subjectStructure.sort((a, b) {
        int yearA = int.tryParse(RegExp(r'\d+').firstMatch(a['year'])?.group(0) ?? '0') ?? 0;
        int yearB = int.tryParse(RegExp(r'\d+').firstMatch(b['year'])?.group(0) ?? '0') ?? 0;
        return yearA.compareTo(yearB);
      });

      for (var yearData in subjectStructure) {
        (yearData['semesters'] as List).sort((a, b) {
          int semA = int.tryParse(RegExp(r'\d+').firstMatch(a['semester'])?.group(0) ?? '0') ?? 0;
          int semB = int.tryParse(RegExp(r'\d+').firstMatch(b['semester'])?.group(0) ?? '0') ?? 0;
          return semA.compareTo(semB);
        });
      }


      loading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading subjects: $e');
      loading = false;
      notifyListeners();
    }
  }
}
