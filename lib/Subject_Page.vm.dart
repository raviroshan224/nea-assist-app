import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SubjectPageViewModel extends ChangeNotifier {
  final String courseId;

  SubjectPageViewModel(this.courseId);

  bool loading = false;
  List<Map<String, dynamic>> subjectStructure = [];

  Future<void> loadSubjects() async {
    loading = true;
    notifyListeners();

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .collection('subjects')
          .get();

      final List<Map<String, dynamic>> fetchedSubjects = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'],
          'year': data['year'],
          'semester': data['semester'],
        };
      }).toList();

      final Map<String, Map<String, List<Map<String, dynamic>>>> groupedSubjects = {};

      for (var subject in fetchedSubjects) {
        final year = subject['year'];
        final semester = subject['semester'];

        groupedSubjects.putIfAbsent(year, () => {});
        groupedSubjects[year]!.putIfAbsent(semester, () => []);
        groupedSubjects[year]![semester]!.add(subject);
      }

      final List<Map<String, dynamic>> result = [];

      groupedSubjects.forEach((year, semesters) {
        final List<Map<String, dynamic>> semesterList = [];

        semesters.forEach((semester, subjects) {
          subjects.sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));
          semesterList.add({
            'semester': semester,
            'subjects': subjects,
          });
        });

        semesterList.sort((a, b) {
          int semA = int.tryParse(RegExp(r'\d+').firstMatch(a['semester'])?.group(0) ?? '0') ?? 0;
          int semB = int.tryParse(RegExp(r'\d+').firstMatch(b['semester'])?.group(0) ?? '0') ?? 0;
          return semA.compareTo(semB);
        });

        result.add({
          'year': year,
          'semesters': semesterList,
        });
      });

      result.sort((a, b) {
        int yearA = int.tryParse(RegExp(r'\d+').firstMatch(a['year'])?.group(0) ?? '0') ?? 0;
        int yearB = int.tryParse(RegExp(r'\d+').firstMatch(b['year'])?.group(0) ?? '0') ?? 0;
        return yearA.compareTo(yearB);
      });

      subjectStructure = result;
    } catch (e) {
      print("Error fetching subjects: $e");
    }

    loading = false;
    notifyListeners();
  }
}
