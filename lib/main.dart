// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:dio/dio.dart';
import 'dart:io';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Database _database;
  final Dio _dio = Dio();
  String? _filePath;
  File? _file;
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final dbPath = p.join(databasesPath, 'media_manager.db');

    _database = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE Media (id INTEGER PRIMARY KEY, url TEXT, localPath TEXT)',
        );
      },
    );
  }

  Future<String> _getLocalFilePath(String fileName, String folderName) async {
    final directory = await getExternalStorageDirectory();
    final folderPath = p.join(directory!.path, folderName);
    await Directory(folderPath).create(recursive: true);
    return p.join(folderPath, fileName);
  }

  Future<File> _downloadFile(String url, String folderName) async {
    final fileName = url.split('/').last;
    final localPath = await _getLocalFilePath(fileName, folderName);

    final response = await _dio.download(url, localPath);

    if (response.statusCode == 200) {
      await _database.insert(
        'Media',
        {'url': url, 'localPath': localPath},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    return File(localPath);
  }

  Future<File?> _getFile(String url, String folderName) async {
    final result = await _database.query(
      'Media',
      where: 'url = ?',
      whereArgs: [url],
    );

    if (result.isNotEmpty) {
      String localPath = result.first['localPath'] as String;
      return File(localPath);
    } else {
      return _downloadFile(url, folderName);
    }
  }

  Future<void> _handleDownloadAndShowFile(String url, String folderName) async {
    try {
      final file = await _getFile(url, folderName);
      setState(() {
        _file = file;
        _filePath = file?.path;
      });
      if (file != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File successfully downloaded to: ${file.path}')),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageDisplayPage(file: file, filePath: file.path),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: Text('Save Locally', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flutter_dash, size: 200, color: Colors.white),
              Card(
                color: Colors.grey[800],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                margin: EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        cursorColor: Colors.yellowAccent[400],
                        style: TextStyle(color: Colors.yellowAccent[400]),
                        controller: _urlController,
                        decoration: InputDecoration(
                          labelText: 'Enter image URL',
                          labelStyle: TextStyle(color: Colors.white),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          if (_urlController.text.isNotEmpty) {
                            _handleDownloadAndShowFile(_urlController.text, 'com.example.savelocally/files');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black, backgroundColor: Colors.yellowAccent[400],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: Size(double.infinity, 50),
                        ),
                        child: Text('Download', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text('OR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.yellowAccent[400])),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _handleDownloadAndShowFile(
                  'https://picsum.photos/500',
                  'com.example.savelocally/files',
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black, backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: Size(250, 50)
                ),
                child: Text('Download A Sample'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ImageDisplayPage extends StatelessWidget {
  final File file;
  final String filePath;

  ImageDisplayPage({required this.file, required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: Text('Image Downloaded!', style: TextStyle(color: Colors.white)),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                color: Colors.grey[800],
                elevation: 4,
                margin: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Downloaded Image:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.yellowAccent[400]),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.file(
                        file,
                        width: 300,
                        height: 300,
                      ),
                    ),
                  ],
                ),
              ),
              Card(
                color: Colors.grey[800],
                elevation: 4,
                margin: EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'File path: $filePath',
                    style: TextStyle(color: Colors.lightGreen, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(300, 50),
                  backgroundColor: Colors.yellowAccent[400], foregroundColor: Colors.black,
                ),
                child: Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
