import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class ChapterPageViewModel extends ChangeNotifier {
  final List<Map<String, dynamic>> _chapters = [];
  List<Map<String, dynamic>> get chapters => _chapters;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadChapters(String universityId, String courseId, String subjectId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('universities')
          .doc(universityId)
          .collection('courses')
          .doc(courseId)
          .collection('subjects')
          .doc(subjectId)
          .collection('chapters')
          .get();

      _chapters.clear();
      for (var doc in snapshot.docs) {
        _chapters.add(doc.data());
      }
    } catch (e) {
      debugPrint('Failed to load chapters: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
