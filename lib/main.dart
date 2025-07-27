import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const PDFViewerApp());
}

class PDFViewerApp extends StatelessWidget {
  const PDFViewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Viewer App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? filePath;

  Future<void> pickPDFFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      setState(() {
        filePath = result.files.single.path!;
      });

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PDFViewerScreen(filePath: filePath!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF Viewer')),
      body: Center(
        child: ElevatedButton(
          onPressed: pickPDFFile,
          child: const Text('Select PDF File'),
        ),
      ),
    );
  }
}

class PDFViewerScreen extends StatefulWidget {
  final String filePath;

  const PDFViewerScreen({super.key, required this.filePath});

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  late PDFViewController pdfViewController;
  int totalPages = 0;
  int currentPage = 0;
  bool isReady = false;

  Future<void> saveLastPage(int page) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(widget.filePath, page);
  }

  Future<void> loadLastPage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? savedPage = prefs.getInt(widget.filePath);
    if (savedPage != null) {
      setState(() {
        currentPage = savedPage;
      });
      pdfViewController.setPage(savedPage);
    }
  }

  @override
  void initState() {
    super.initState();
    loadLastPage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reading PDF')),
      body: Stack(
        children: [
          PDFView(
            filePath: widget.filePath,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: true,
            pageFling: true,
            defaultPage: currentPage,
            onRender: (pages) {
              setState(() {
                totalPages = pages ?? 0;
                isReady = true;
              });
            },
            onViewCreated: (PDFViewController controller) {
              pdfViewController = controller;
            },
            onPageChanged: (page, _) {
              setState(() {
                currentPage = page ?? 0;
              });
              saveLastPage(currentPage);
            },
          ),
          if (!isReady)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
      bottomNavigationBar: isReady
          ? BottomAppBar(
        color: Colors.blueGrey[50],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: currentPage > 0
                  ? () {
                currentPage--;
                pdfViewController.setPage(currentPage);
              }
                  : null,
              icon: const Icon(Icons.navigate_before),
            ),
            Text('Page ${currentPage + 1} / $totalPages'),
            IconButton(
              onPressed: currentPage < totalPages - 1
                  ? () {
                currentPage++;
                pdfViewController.setPage(currentPage);
              }
                  : null,
              icon: const Icon(Icons.navigate_next),
            ),
          ],
        ),
      )
          : null,
    );
  }
}
