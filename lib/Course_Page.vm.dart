import 'package:cloud_firestore/cloud_firestore.dart';

class CoursePageViewModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> fetchCourses(String universityId) async {
    final querySnapshot = await _firestore
        .collection('universities')
        .doc(universityId)
        .collection('courses')
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // ✅ Add this line
      return data;
    }).toList();
  }

}
