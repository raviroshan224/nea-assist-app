import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerPage extends StatefulWidget {
  final String pdfUrl;
  final String title;
  const PdfViewerPage({Key? key, required this.pdfUrl, required this.title}) : super(key: key);

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  bool isLoading = false;

  Future<void> _downloadPdfToUser() async {
    final status = await Permission.storage.request();
    if (!mounted) return;
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission denied')),
      );
      return;
    }

    final dir = await getExternalStorageDirectory();
    if (dir == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to access storage')),
      );
      return;
    }

    String? chosenDir = await _pickDownloadDirectory(dir.path);
    if (chosenDir == null) return;

    try {
      setState(() => isLoading = true);

      final response = await http.get(Uri.parse(widget.pdfUrl));
      final bytes = response.bodyBytes;
      final file = File('$chosenDir/downloaded_file.pdf');
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF downloaded to $chosenDir')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download failed')),
      );
    }
  }

  Future<String?> _pickDownloadDirectory(String startDir) async {
    String? selectedDir = startDir;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Download folder'),
          content: Text('Will download to:\n$selectedDir'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    return selectedDir;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF1B5E20),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download PDF',
            onPressed: isLoading ? null : _downloadPdfToUser,
          ),
        ],
      ),
      body: Stack(
        children: [
          SfPdfViewer.network(widget.pdfUrl),
          if (isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
