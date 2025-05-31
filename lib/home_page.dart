import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'Course_Page.dart'; // Update path if needed
import 'comming_soon_page.dart'; // Not used in this code, can be removed

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, String>> universities = [];
  List<Map<String, String>> schoolBoards = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchInstitutions();
  }

  /// Fetches university and board data from Firestore
  Future<void> fetchInstitutions() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('universities').get();

      final universityList = <Map<String, String>>[];
      final boardList = <Map<String, String>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final type = data['type'] ?? '';
        final name = data['name']?.toString() ?? '';
        final logoUrl = data['logoUrl']?.toString() ?? '';

        final entry = {
          'id': doc.id,
          'name': name,
          'logoUrl': logoUrl,
        };

        if (type == 'university') {
          universityList.add(entry);
        } else if (type == 'board') {
          boardList.add(entry);
        }
      }

      setState(() {
        universities = universityList;
        schoolBoards = boardList;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Builds a section for either universities or school boards
  Widget buildSection(String title, List<Map<String, String>> items) {
    if (items.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 12),
        Divider(thickness: 1.5, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 5 / 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            final name = item['name'] ?? 'Unknown';
            final logoUrl = item['logoUrl'] ?? '';

            return Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              elevation: 3,
              shadowColor: Colors.black26,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CourseContentPage(
                        universityId: item["id"]!,
                        universityName: name,

                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 44,
                        width: 44,
                        alignment: Alignment.center,
                        child: logoUrl.isNotEmpty
                            ? Image.network(
                          logoUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.school, size: 36, color: Colors.grey),
                        )
                            : const Icon(Icons.school, size: 36, color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text("NEA Assist - Learn Anywhere"),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildSection("Universities", universities),
            buildSection("School Boards", schoolBoards),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
