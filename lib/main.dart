// main.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'classifier.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:camera/camera.dart';

void main() {
  runApp(MedicinalPlantsClassifier());
}

class MedicinalPlantsClassifier extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chinese Medicinal Plants Classifier',
      theme: ThemeData(
        primarySwatch: Colors.green,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.green).copyWith(
          primary: Color(0xFF388E3C), // A beautiful shade of green
          secondary: Color(0xFF81C784), // A lighter shade for accents
        ),
        appBarTheme: AppBarTheme(
          color: Color(0xFF2E7D32), // Darker green for AppBar
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF66BB6A), // Button color
            foregroundColor: Colors.white, // Text color on buttons
          ),
        ),
      ),
      home: ClassifierHomePage(title: 'Chinese Medicinal Plants Classifier'),
    );
  }
}

class ClassifierHomePage extends StatefulWidget {
  final String title;

  ClassifierHomePage({Key? key, required this.title}) : super(key: key);

  @override
  _ClassifierHomePageState createState() => _ClassifierHomePageState();
}

class _ClassifierHomePageState extends State<ClassifierHomePage> {
  final ImagePicker _picker = ImagePicker();
  File? _image;
  Map<String, dynamic>? _prediction;
  bool _isLoading = false;
  late Classifier _classifier;
  bool _isInitialized = false;
  String? _initializationError;

  // Define class descriptions
  final Map<String, String> classDescriptions = {
    "Alpinia katsumadai Hayata - Cao Dou Kou": "A medicinal rhizome known for its aromatic and therapeutic properties.",
    "Amomi Fructus - Sha Ren": "Fruit of the Amomum species, used in traditional Chinese medicine for digestive health.",
    "Amomi Fructus Rotundus - Bai Dou Kou": "A variant of Amomi Fructus with a round shape, enhancing its medicinal efficacy.",
    "Armeniacae Semen Amarum - Ku Xing Ren": "Bitter apricot seeds utilized for respiratory and digestive treatments.",
    "Chaenomelis Fructus - Mu Gua": "Fruit of the Chaenomeles plant, employed in herbal remedies for various ailments.",
    "Cornifructus - Shan Zhu Yu": "Corn fruit, used traditionally to strengthen the kidneys and secure essence.",
    "Crataegi Fructus - Shan Zha": "Hawthorn fruit, renowned for supporting cardiovascular health and digestion.",
    "Foeniculi Fructus - Xiao Hui Xiang": "Fennel seeds, commonly used as a spice and for digestive aid.",
    "Forsythiae Fructus - Lian Qiao": "Fruit of the Forsythia plant, used in detoxification and anti-inflammatory treatments.",
    "Gardeniae Fructus - Zhi Zi": "Gardenia fruit, employed in reducing heat and inflammation in the body.",
    "Kochiae Fructus - Di Fu Zi": "Fruit of Kochia scoparia, used as a diuretic and for treating edema.",
    "Lycii Fructus - Gou Qi Zi": "Goji berries, celebrated for their antioxidant properties and immune support.",
    "Mume Fructus - Wu Mei": "Japanese apricot, used to soothe the stomach and alleviate thirst.",
    "Other": "The plant does not match any known categories.",
    "Persicae Semen - Tao Ren": "Peach seeds, utilized to promote blood circulation and alleviate pain.",
    "Psoralea corylifolia - Bu Gu Zhi": "Seeds of Psoralea corylifolia, used in treating skin conditions like vitiligo.",
    "Rosae Laevigatae Fructus - Jin Ying Zi": "Fruit of the Rugosa rose, known for its high vitamin content and antioxidant benefits.",
    "Rubi Fructus - Fu Pen Zi": "Fruit from the Rubus genus, used in nutritional supplements for their health benefits.",
    "Schisandrae Chinensis Fructus - Wu Wei Zi": "Schisandra berries, valued for their adaptogenic properties and liver support.",
    "Toosendan Fructus - Chuan Lian Zi": "Fruit of the Toosendan tree, employed in detoxifying herbal formulas.",
    "Trichosanthes kirilowii - Tian Hua Fen": "Herb used in traditional remedies for coughs and as a natural expectorant."
  };

  // Define class uses
  final Map<String, String> classUses = {
    "Alpinia katsumadai Hayata - Cao Dou Kou": "Used in aromatherapy and as a flavoring agent in culinary dishes.",
    "Amomi Fructus - Sha Ren": "Employed to aid digestion, relieve nausea, and reduce abdominal bloating.",
    "Amomi Fructus Rotundus - Bai Dou Kou": "Used similarly to Sha Ren with enhanced potency for digestive disorders.",
    "Armeniacae Semen Amarum - Ku Xing Ren": "Used to treat coughs, asthma, and improve respiratory health.",
    "Chaenomelis Fructus - Mu Gua": "Utilized in herbal teas and to support liver function and detoxification.",
    "Cornifructus - Shan Zhu Yu": "Applied in formulations to strengthen the kidneys and enhance essence.",
    "Crataegi Fructus - Shan Zha": "Used to support heart health, improve blood circulation, and aid digestion.",
    "Foeniculi Fructus - Xiao Hui Xiang": "Commonly used to alleviate bloating, enhance digestion, and as a culinary spice.",
    "Forsythiae Fructus - Lian Qiao": "Employed in detoxifying herbal formulas and to reduce inflammation.",
    "Gardeniae Fructus - Zhi Zi": "Used to reduce heat, treat infections, and alleviate inflammation.",
    "Kochiae Fructus - Di Fu Zi": "Used as a diuretic to promote urine production and reduce swelling.",
    "Lycii Fructus - Gou Qi Zi": "Consumed as a health supplement for immune support, vision enhancement, and longevity.",
    "Mume Fructus - Wu Mei": "Used to soothe the stomach, alleviate thirst, and reduce body heat.",
    "Other": "No specific uses available for unidentified plants.",
    "Persicae Semen - Tao Ren": "Used to promote blood circulation, alleviate pain, and treat cardiovascular conditions.",
    "Psoralea corylifolia - Bu Gu Zhi": "Applied in treatments for skin conditions, bone health, and to enhance libido.",
    "Rosae Laevigatae Fructus - Jin Ying Zi": "Consumed for its high vitamin C content, immune support, and antioxidant benefits.",
    "Rubi Fructus - Fu Pen Zi": "Used in nutritional supplements for their antioxidant properties and overall health benefits.",
    "Schisandrae Chinensis Fructus - Wu Wei Zi": "Used to enhance mental performance, reduce stress, and support liver health.",
    "Toosendan Fructus - Chuan Lian Zi": "Employed in detoxifying herbal remedies and to treat digestive disorders.",
    "Trichosanthes kirilowii - Tian Hua Fen": "Used to treat coughs, clear phlegm, and as a natural expectorant."
  };

  @override
  void initState() {
    super.initState();
    _classifier = Classifier();
    _initializeClassifier();
  }

  Future<void> _initializeClassifier() async {
    setState(() {
      _isLoading = true;
    });
    try {
      print("Initializing classifier...");
      await _classifier.initialize();
      print("Classifier initialized.");
      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });
    } catch (e) {
      print("Initialization Error: $e");
      setState(() {
        _initializationError = e.toString();
        _isLoading = false;
      });
      _showErrorDialog("Initialization Error", e.toString());
    }
  }

  @override
  void dispose() {
    _classifier.close();
    super.dispose();
  }

  // Permission handling methods

  /// Retrieve Android SDK version
  Future<int> _getAndroidSdkVersion() async {
    if (Platform.isAndroid) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.sdkInt;
    }
    return 0; // Default for non-Android platforms
  }

  /// Check and request camera permission
  Future<bool> _checkAndRequestCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isGranted) {
      return true;
    } else if (status.isDenied || status.isRestricted || status.isLimited) {
      status = await Permission.camera.request();
      return status.isGranted;
    } else if (status.isPermanentlyDenied) {
      // Open app settings
      _showPermissionDeniedDialog('Camera'); // or 'Media'(Android 13 & above), 'Storage'(Android 12 & below).
      return false;
    }
    return false;
  }

  /// Check and request storage/media permissions based on Android version
  Future<bool> _checkAndRequestMediaPermission() async {
    if (Platform.isAndroid) {
      int sdkVersion = await _getAndroidSdkVersion();
      if (sdkVersion >= 33) {
        // For Android 13 and above, use READ_MEDIA_IMAGES
        var status = await Permission.photos.status; // 'photos' maps to READ_MEDIA_IMAGES
        if (status.isGranted) {
          return true;
        } else if (status.isDenied || status.isRestricted || status.isLimited) {
          status = await Permission.photos.request();
          return status.isGranted;
        } else if (status.isPermanentlyDenied) {
          _showPermissionDeniedDialog('Media');
          return false;
        }
      } else {
        // For Android 12 and below, use READ_EXTERNAL_STORAGE
        var status = await Permission.storage.status;
        if (status.isGranted) {
          return true;
        } else if (status.isDenied || status.isRestricted || status.isLimited) {
          status = await Permission.storage.request();
          return status.isGranted;
        } else if (status.isPermanentlyDenied) {
          _showPermissionDeniedDialog('Storage');
          return false;
        }
      }
    } else if (Platform.isIOS) {
      // For iOS, use photos permission
      var status = await Permission.photos.status;
      if (status.isGranted) {
        return true;
      } else if (status.isDenied || status.isRestricted || status.isLimited) {
        status = await Permission.photos.request();
        return status.isGranted;
      } else if (status.isPermanentlyDenied) {
        _showPermissionDeniedDialog('Photos');
        return false;
      }
    }
    return false;
  }

  Future<void> _pickImage(ImageSource source) async {
    bool hasPermission = false;

    if (source == ImageSource.camera) {
      hasPermission = await _checkAndRequestCameraPermission();
    } else if (source == ImageSource.gallery) {
      hasPermission = await _checkAndRequestMediaPermission();
    }

    if (!hasPermission) {
      // Permission was not granted, so exit the method.
      return;
    }

    if (source == ImageSource.camera) {
      // **Check if camera is available and working**
      try {
        List<CameraDescription> cameras = await availableCameras();
        if (cameras.isEmpty) {
          throw Exception("No image is selected");
        }
        // Optionally, you can check specific camera properties here
      } catch (e) {
        _showErrorDialog("No Image Selected Error", e.toString());
        return;
      }
    }

    // Proceed with picking the image
    try {
      final pickedFile = await _picker.pickImage(source: source, imageQuality: 85);

      if (pickedFile != null) {
        setState(() {
          _isLoading = true;
          _image = File(pickedFile.path);
          _prediction = null;
        });

        // Perform classification
        try {
          Map<String, dynamic> result = await _classifier.classifyImage(_image!);

          String predictedLabel = result['label'];
          double accuracy = result['accuracy'];

          // Check if accuracy is below threshold
          if (accuracy < 0.4) {
            // Since "Other" is at index 13
            int otherId = 13; // You can also use _classifier.labelsList.indexOf('Other');

            // Override the prediction to "Other"
            predictedLabel = 'Other';
            result['id'] = otherId;
            // Optionally, adjust accuracy or keep the original
          }

          // Retrieve description and uses
          String description = classDescriptions[predictedLabel] ?? "Description not available.";
          String uses = classUses[predictedLabel] ?? "Uses not available.";

          setState(() {
            _prediction = {
              // 'id': result['id'], // Commented out Predicted ID
              'label': predictedLabel,
              // 'accuracy': accuracy, // Commented out Accuracy
              'description': description,
              'uses': uses,
            };
            _isLoading = false;
          });
        } catch (e) {
          setState(() {
            _isLoading = false;
          });
          _showErrorDialog("Invalid File Type", e.toString());
        }
      }
    } catch (e) {
      _showErrorDialog("Image Selection Error", e.toString());
    }
  }

  void _showPermissionDeniedDialog(String permissionName) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$permissionName Permission Required'),
          content: Text(
              'This app needs $permissionName access to function properly. Please grant permission in the app settings.'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Open Settings'),
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildImage() {
    if (_image != null) {
      return Image.file(
        _image!,
        height: 300,
        fit: BoxFit.cover,
      );
    } else {
      return Container(
        height: 300,
        color: Colors.grey[300],
        child: Center(
          child: Text(
            'No image selected.',
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
          ),
        ),
      );
    }
  }

  Widget _buildPrediction() {
    if (_prediction != null) {
      return Card(
        elevation: 4.0,
        margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 0.0),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text(
              //   'Predicted ID: ${_prediction!['id']}', // Commented out Predicted ID
              //   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              // ),
              SizedBox(height: 5),
              Text(
                'Predicted Label: ${_prediction!['label']}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              // Text(
              //   'Accuracy: ${( _prediction!['accuracy'] * 100).toStringAsFixed(2)}%', // Commented out Accuracy
              //   style: TextStyle(fontSize: 16),
              // ),
              SizedBox(height: 15),
              Text(
                'Description:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Text(
                '${_prediction!['description']}',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 15),
              Text(
                'Uses:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Text(
                '${_prediction!['uses']}',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 15),
              if (_prediction!['label'] == 'Other')
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.redAccent),
                    SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'The model is not confident about this prediction. Please consult an expert for accurate identification.',
                        style: TextStyle(fontSize: 14, color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
    } else {
      return Text(
        'No prediction yet.',
        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
      );
    }
  }

  Widget _buildButtons() {
    if (_isInitialized) {
      return Column(
        children: [
          ElevatedButton.icon(
            icon: Icon(Icons.camera_alt),
            label: Text('Take Photo'),
            onPressed: () => _pickImage(ImageSource.camera),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton.icon(
            icon: Icon(Icons.photo_library),
            label: Text('Choose from Gallery'),
            onPressed: () => _pickImage(ImageSource.gallery),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
            ),
          ),
        ],
      );
    } else if (_isLoading) {
      return CircularProgressIndicator();
    } else if (_initializationError != null) {
      return Text(
        'Failed to initialize classifier.',
        style: TextStyle(fontSize: 16, color: Colors.red),
      );
    } else {
      return Container(); // Empty container if not initialized and not loading
    }
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildImage(),
              SizedBox(height: 20),
              _isLoading && !_isInitialized
                  ? CircularProgressIndicator()
                  : _buildPrediction(),
              SizedBox(height: 20),
              _buildButtons(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: TextStyle(color: Colors.white)),
      ),
      body: _buildContent(),
    );
  }
}
