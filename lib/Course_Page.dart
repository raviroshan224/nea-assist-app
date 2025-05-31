import 'package:flutter/material.dart';
import 'Course_Page.vm.dart';
import 'package:nea_assist/Subject_Page.dart';

class CourseContentPage extends StatelessWidget {
  final String universityName;
  final String universityId;


  const CourseContentPage({
    super.key,
    required this.universityName,
    required this.universityId,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = CoursePageViewModel();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: Text(
          universityName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        centerTitle: true,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // const Text(
            //   "Select Your Course",
            //   style: TextStyle(
            //     fontSize: 20,
            //     fontWeight: FontWeight.w600,
            //     color: Colors.black87,
            //   ),
            // ),
            // const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: viewModel.fetchCourses(universityId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No courses found.'));
                  }

                  final courses = snapshot.data!;

                  return GridView.builder(
                    itemCount: courses.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 4 / 3,
                    ),
                      itemBuilder: (context, index) {
                        final course = courses[index];
                        return _CourseCard(
                          courseId: course['id'], // Pass courseId here
                          name: course['name'] ?? 'Unnamed Course',
                          universityName: universityName,
                          universityId: universityId,  // Add this parameter
                        );
                      },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseCard extends StatefulWidget {
  final String courseId;
  final String name;
  final String universityName;
  final String universityId;  // Add this



  const _CourseCard({
    required this.courseId,
    required this.name,
    required this.universityName,
    required this.universityId,  // Add this

  });

  @override
  State<_CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<_CourseCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: _hovering ? (Matrix4.identity()..scale(1.02)) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: _hovering ? 16 : 10,
              offset: const Offset(4, 4),
            )
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SubjectPage(
                    courseId: widget.courseId,
                    courseName: widget.name,
                    universityName: widget.universityName,
                    universityId: widget.universityId,  // use widget.universityId
                  ),
                ),
              );
            },
            child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                widget.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1B5E20),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
