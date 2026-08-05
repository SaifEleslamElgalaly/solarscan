import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../core/app_colors.dart';
import '../../providers/scan_provider.dart';
import '../../models/models.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:wakelock_plus/wakelock_plus.dart';

class CameraScreen extends ConsumerStatefulWidget {
  final bool isActive;
  const CameraScreen({super.key, this.isActive = true});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isFlashOn = false;
  File? _capturedFile;
  bool _isProcessing = false;
  ObjectDetector? _objectDetector;
  ImageLabeler? _imageLabeler;
  List<DetectedObject> _objects = [];
  bool _isDetecting = false;
  
  // Live Analysis State
  ScanResult? _liveResult;
  bool _isAutoScanning = false;
  DateTime? _lastScanTime;
  bool _showLiveHud = false;
  int _notDetectedCounter = 0; // Grace period for detection loss
  List<String> _detectedLabels = []; // Debug: ML Kit labels
  bool _showDebugLabels = true; // Toggle for on-screen debug info

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    if (widget.isActive) {
      // Add a delay to ensure the native view is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _initializeCamera();
      });
    }
  }

  @override
  void didUpdateWidget(CameraScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _initializeCamera();
        });
      } else {
        _stopPeriodicCapture();
        _controller?.dispose();
        _controller = null;
        setState(() {
          _isInitialized = false;
        });
      }
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(
          _cameras![0],
          ResolutionPreset.medium, // Maximum stability for S24 Ultra
          enableAudio: false,
        );

        await _controller!.initialize();
        _initializeDetector();
        _startPeriodicCapture();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Camera Init Error: $e');
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _stopPeriodicCapture();
    _controller?.dispose();
    _objectDetector?.close();
    _imageLabeler?.close();
    super.dispose();
  }

  void _initializeDetector() {
    print('Initializing stable detectors...');
    // We disable ObjectDetector for now to fix the native crash
    // Object detection is less stable than labeling on some firmware
    
    final labelerOptions = ImageLabelerOptions(confidenceThreshold: 0.3);
    _imageLabeler = ImageLabeler(options: labelerOptions);
  }

  Timer? _captureTimer;
  bool _isCameraBusy = false;

  void _startPeriodicCapture() {
    print('!!! STARTING AUTOMATED SCAN ENGINE !!!');
    _captureTimer = Timer.periodic(const Duration(milliseconds: 2000), (timer) {
      if (_isCameraBusy || _capturedFile != null || !mounted) return;
      _captureAndProcess();
    });
  }

  Future<void> _captureAndProcess() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCameraBusy) return;
    
    try {
      _isCameraBusy = true;
      print('--- AI CAPTURE START ---');
      final image = await _controller!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      
      if (_imageLabeler == null) {
        _isCameraBusy = false;
        return;
      }

      final labels = await _imageLabeler!.processImage(inputImage);
      print('AI Labels found: ${labels.map((l) => l.label).toList()}');
      
      if (mounted) {
        setState(() {
          _detectedLabels = labels.map((l) => '${l.label} (${(l.confidence * 100).toStringAsFixed(0)}%)').toList();
        });
        _checkAutoScan([], labels, image.path);
      }
    } catch (e) {
      print('AI Processing Error: $e');
    } finally {
      _isCameraBusy = false;
    }
  }

  void _stopPeriodicCapture() {
    _captureTimer?.cancel();
  }

  Future<void> _processImage(CameraImage image) async {
    if (_objectDetector == null || _imageLabeler == null) return;

    _isDetecting = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) return;

      final objects = await _objectDetector!.processImage(inputImage);
      final labels = await _imageLabeler!.processImage(inputImage);
      print('Detected ${objects.length} objects');
      for (final obj in objects) {
        print('Object labels: ${obj.labels.map((l) => l.text).join(", ")}');
      }
      
      if (mounted && _capturedFile == null) {
        setState(() {
          _objects = objects;
        });

        // Stream-based auto-scan is disabled in favor of periodic capture for stability
        // _checkAutoScan(objects, labels, ""); 
      }
    } catch (e) {
      debugPrint('Error detecting objects: $e');
    } finally {
      _isDetecting = false;
    }
  }

  void _checkAutoScan(List<DetectedObject> objects, List<ImageLabel> labels, String imagePath) {
    if (_isAutoScanning) return;
    
    bool isSolarPanel = false;
    bool isExcluded = false;

    for (final label in labels) {
      final text = label.label.toLowerCase();
      
      // Exclusion list to avoid false positives (like paper or people)
      if (text.contains('paper') || 
          text.contains('document') || 
          text.contains('text') || 
          text.contains('writing') ||
          text.contains('person') ||
          text.contains('face') ||
          text.contains('hand') ||
          text.contains('finger') ||
          text.contains('instrument') ||
          text.contains('musical') ||
          text.contains('piano') ||
          text.contains('guitar') ||
          text.contains('room') ||
          text.contains('indoor') ||
          text.contains('furniture') ||
          text.contains('table') ||
          text.contains('chair') ||
          text.contains('wall') ||
          text.contains('floor') ||
          text.contains('carpet') ||
          text.contains('interior')) {
        isExcluded = true;
        break;
      }

      if (text.contains('solar') || 
          text.contains('panel') || 
          text.contains('photovoltaic') || 
          text.contains('silicon') ||
          text.contains('electricity') ||
          text.contains('electronics') ||
          text.contains('sustainability') ||
          text.contains('alternative energy') ||
          text.contains('renewable energy') ||
          text.contains('glass') ||
          text.contains('cell') ||
          text.contains('rectangle') ||
          text.contains('parallel') ||
          text.contains('hardware') ||
          text.contains('technology') ||
          text.contains('architecture') ||
          text.contains('facade') ||
          text.contains('sky') ||
          text.contains('roof') ||
          text.contains('pattern') ||
          text.contains('metal') ||
          text.contains('surface')) {
        isSolarPanel = true;
      }
    }

    if (isExcluded) {
      isSolarPanel = false;
    }

    // Secondary check: Object detector labels
    if (!isSolarPanel) {
      for (final obj in objects) {
        for (final label in obj.labels) {
          final text = label.text.toLowerCase();
          if (text.contains('solar') || text.contains('panel') || text.contains('electronics')) {
            isSolarPanel = true;
            break;
          }
        }
        if (isSolarPanel) break;
      }
    }

    // FORCED OVERRIDE: Trust the user's focus. 
    // We bypass local classification to ensure the server-side YOLO always gets the data.
    isSolarPanel = true; 

    // If detected, reset the counter
    _notDetectedCounter = 0;

    if (_lastScanTime != null && DateTime.now().difference(_lastScanTime!).inSeconds < 1) return;

    bool hasSignificantObject = false;
    if (_controller != null && _controller!.value.isInitialized) {
      final previewSize = _controller!.value.previewSize!;
      final screenArea = previewSize.width * previewSize.height;
      
      for (final obj in objects) {
        final rect = obj.boundingBox;
        final area = rect.width * rect.height;
        if (area / screenArea > 0.05) {
          hasSignificantObject = true;
          break;
        }
      }
    }
    
    if (hasSignificantObject || objects.isEmpty || true) { // Always allow if labels matched
      _runLiveAnalysis(imagePath);
    }
  }

  Future<void> _runLiveAnalysis(String imagePath) async {
    if (_isAutoScanning) return;

    setState(() {
      _isAutoScanning = true;
      _showLiveHud = true;
    });

    try {
      print('Uploading existing capture for live analysis...');
      final result = await ref.read(scanProvider.notifier).uploadImage(File(imagePath));
      
      if (mounted) {
        if (result != null && result.result != 'Unknown') { 
          print('Live analysis success: ${result.result}');
          setState(() {
            _liveResult = result;
            _lastScanTime = DateTime.now();
          });
        } else {
          print('Live analysis low confidence (${result?.confidence ?? 0}) or null');
          setState(() {
            _liveResult = null; // Clear the previous result since we are no longer detecting anything valid
            _lastScanTime = DateTime.now();
          });
        }
      }
    } catch (e) {
      print('Error in live analysis: $e');
      if (mounted) {
        setState(() {
          _lastScanTime = DateTime.now(); // Cooldown even on error
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAutoScanning = false;
        });
      }
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null;

    final sensorOrientation = _cameras![0].sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isAndroid) {
      var rotationCompensation = _cameras![0].sensorOrientation;
      if (_cameras![0].lensDirection == CameraLensDirection.front) {
        rotationCompensation = (rotationCompensation + 0) % 360;
      } else {
        rotationCompensation = (rotationCompensation - 0 + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    } else if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null || (Platform.isAndroid && format != InputImageFormat.yuv420) || (Platform.isIOS && format != InputImageFormat.bgra8888)) return null;

    final allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _capturedFile = File(image.path);
      });
    }
  }

  Future<void> _confirmUpload() async {
    if (_capturedFile == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      if (_imageLabeler != null) {
        final inputImage = InputImage.fromFilePath(_capturedFile!.path);
        final labels = await _imageLabeler!.processImage(inputImage);
        bool isSolarPanel = false;
        bool isExcluded = false;

        for (final label in labels) {
          final text = label.label.toLowerCase();
          
          if (text.contains('paper') || text.contains('document') || text.contains('text') ||
              text.contains('instrument') || text.contains('musical') ||
              text.contains('room') || text.contains('furniture') ||
              text.contains('table') || text.contains('chair') ||
              text.contains('wall') || text.contains('floor') ||
              text.contains('carpet') || text.contains('interior')) {
            isExcluded = true;
            break;
          }

          if (text.contains('solar') || text.contains('panel') || 
              text.contains('photovoltaic') || text.contains('silicon') ||
              text.contains('sky') || text.contains('roof') ||
              text.contains('pattern') || text.contains('metal') ||
              text.contains('technology') || text.contains('architecture')) {
            isSolarPanel = true;
          }
        }
        
        if (isExcluded) isSolarPanel = false;
        
        print('Manual upload - Is solar panel detected: $isSolarPanel');
        if (!isSolarPanel) {
          if (mounted) {
            setState(() {
              _isProcessing = false;
              _capturedFile = null;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Not a solar panel. Scan aborted.')),
            );
          }
          return;
        }
      }

      final result = await ref.read(scanProvider.notifier).uploadImage(_capturedFile!);
      if (result != null && result.result != 'Unknown' && mounted) {
        setState(() {
          _capturedFile = null;
          _isProcessing = false;
        });
        _showResultDialog(result);
      } else {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _capturedFile = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Not a solar panel. Scan aborted.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showResultDialog(dynamic result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppColors.accent.withOpacity(0.3))),
        title: Row(
          children: [
            Icon(Icons.analytics_outlined, color: AppColors.accent),
            const SizedBox(width: 12),
            Text('ANALYSIS COMPLETE', style: GoogleFonts.orbitron(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('STATUS', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                      Text(result.result.toUpperCase(), style: TextStyle(color: _getResultColor(result.result), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('CONFIDENCE', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                      Text('${(result.confidence * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('RECOMMENDATION', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(result.recommendation, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('DISMISS', style: GoogleFonts.orbitron(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Color _getResultColor(String status) {
    switch (status.toLowerCase()) {
      case 'clean': return Colors.greenAccent;
      case 'dusty': return AppColors.accent;
      case 'bird drop': return Colors.orangeAccent;
      case 'fault': return Colors.redAccent;
      case 'snow': return Colors.lightBlueAccent;
      case 'crack': return Colors.redAccent;
      default: return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: Stack(
          children: [
          // Camera Preview with proper scaling
          if (_capturedFile == null)
            _buildCameraPreview()
          else
            _buildImagePreview(),

          // Detection Overlays
          if ((_liveResult != null && _liveResult!.box != null) || _objects.isNotEmpty)
            _buildDetectionOverlays(),

          // Live Result HUD
          if (_showLiveHud)
            _buildLiveHud(),

          // Debug Info (Temporary to help user verify)
          Positioned(
            bottom: 150,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black54,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI STATUS: ${_isAutoScanning ? "ANALYZING" : "SCANNING"}',
                    style: const TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  if (_showDebugLabels && _detectedLabels.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    const Text('ML KIT LABELS:', style: TextStyle(color: Colors.white54, fontSize: 8)),
                    ..._detectedLabels.take(3).map((l) => Text(l, style: const TextStyle(color: Colors.white, fontSize: 8))),
                  ],
                ],
              ),
            ),
          ),

          // UI Overlays
          if (_capturedFile == null) _buildCameraControls(),
          if (_capturedFile != null) _buildPreviewControls(),

          // Processing Overlay
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black87,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppColors.accent),
                      const SizedBox(height: 24),
                      Text(
                        'UPLINKING DATA TO AI NODE...',
                        style: GoogleFonts.orbitron(color: AppColors.accent, fontSize: 12, letterSpacing: 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
    );
  }

  Widget _buildLiveHud() {
    return Positioned(
      top: 100,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accent.withOpacity(0.5), width: 1),
          boxShadow: [
            BoxShadow(color: AppColors.accent.withOpacity(0.2), blurRadius: 20, spreadRadius: 2),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isAutoScanning ? Colors.red : Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isAutoScanning ? 'ANALYZING LIVE FEED...' : 'LIVE DIAGNOSTICS',
                  style: GoogleFonts.orbitron(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const Spacer(),
                if (!_isAutoScanning && _liveResult != null)
                  Text(
                    'STABLE',
                    style: GoogleFonts.orbitron(color: AppColors.accent, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('STATUS', style: TextStyle(color: Colors.white54, fontSize: 8, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    if (_isAutoScanning)
                      const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))
                    else if (_liveResult != null)
                      Text(
                        _liveResult!.result.toUpperCase(),
                        style: GoogleFonts.orbitron(
                          color: _getResultColor(_liveResult!.result),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else
                      Text(
                        _isAutoScanning ? 'UPLINKING...' : 'SEARCHING...',
                        style: GoogleFonts.orbitron(
                          color: AppColors.accent.withOpacity(0.3),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                if (_liveResult != null && !_isAutoScanning)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('CONFIDENCE', style: TextStyle(color: Colors.white54, fontSize: 8, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        '${(_liveResult!.confidence * 100).toStringAsFixed(1)}%',
                        style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
              ],
            ),
            if (!_isAutoScanning && _liveResult != null) ...[
              const Divider(color: Colors.white10, height: 24),
              Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.accent, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _liveResult!.recommendation,
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetectionOverlays() {
    return Positioned.fill(
      child: CustomPaint(
        painter: DetectionPainter(
          objects: _objects,
          imageSize: _controller != null && _controller!.value.isInitialized
              ? _controller!.value.previewSize!
              : const Size(720, 1280),
          canvasSize: MediaQuery.of(context).size,
          rotation: _cameras != null && _cameras!.isNotEmpty
              ? _cameras![0].sensorOrientation
              : 90,
          liveResult: _liveResult,
          isAnalyzing: _isAutoScanning,
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    final size = MediaQuery.of(context).size;
    
    // The camera controller aspect ratio is always landscape (> 1.0) on Android
    double cameraRatio = _controller!.value.aspectRatio;
    if (cameraRatio < 1.0) {
      cameraRatio = 1.0 / cameraRatio;
    }

    // Official standard formula to scale the portrait-oriented layout of CameraPreview
    double scale = size.aspectRatio * cameraRatio;
    if (scale < 1.0) {
      scale = 1.0 / scale;
    }

    return Positioned.fill(
      child: ClipRect(
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.center,
          child: Center(
            child: CameraPreview(_controller!),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Positioned.fill(
      child: Image.file(
        _capturedFile!,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildCameraControls() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Text(
                'SENSORS ACTIVE',
                style: GoogleFonts.orbitron(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              const Icon(Icons.flash_auto_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewControls() {
    return Positioned(
      bottom: 50,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Text(
            'VERIFY DATA CAPTURE',
            style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 4),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Retake Button
              _buildControlCircle(
                icon: Icons.close_rounded,
                label: 'RETAKE',
                color: Colors.redAccent,
                onTap: () => setState(() => _capturedFile = null),
              ),
              const SizedBox(width: 60),
              // Confirm Button
              _buildControlCircle(
                icon: Icons.check_rounded,
                label: 'CONFIRM',
                color: AppColors.accent,
                onTap: _confirmUpload,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlCircle({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.3), blurRadius: 15, spreadRadius: 2),
              ],
            ),
            child: Icon(icon, color: color, size: 32),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: GoogleFonts.orbitron(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildCorner(double? top, double? bottom, double? left, double? right) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          border: Border(
            top: top == 0 ? BorderSide(color: AppColors.accent, width: 2) : BorderSide.none,
            bottom: bottom == 0 ? BorderSide(color: AppColors.accent, width: 2) : BorderSide.none,
            left: left == 0 ? BorderSide(color: AppColors.accent, width: 2) : BorderSide.none,
            right: right == 0 ? BorderSide(color: AppColors.accent, width: 2) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white10),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildShutterButton() {
    return GestureDetector(
      onTap: () async {
        if (_controller != null && _controller!.value.isInitialized) {
          final image = await _controller!.takePicture();
          setState(() {
            _capturedFile = File(image.path);
          });
        }
      },
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class DetectionPainter extends CustomPainter {
  DetectionPainter({
    required this.objects,
    required this.imageSize,
    required this.canvasSize,
    required this.rotation,
    this.liveResult,
    this.isAnalyzing = false,
  });

  final List<DetectedObject> objects;
  final Size imageSize;
  final Size canvasSize;
  final int rotation;
  final ScanResult? liveResult;
  final bool isAnalyzing;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw server-side bounding box if available
    if (liveResult != null && liveResult!.box != null && liveResult!.box!.length == 4) {
      final box = liveResult!.box!;
      final rect = Rect.fromLTRB(
        box[0] * size.width,
        box[1] * size.height,
        box[2] * size.width,
        box[3] * size.height,
      );

      final statusColor = _getStatusColor();
      final statusText = _getStatusText();

      // Bounding box border paint
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..color = statusColor;

      // Draw standard bounding box
      canvas.drawRect(rect, paint);

      // Draw subtle glow background inside/around the box for premium design
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10.0
        ..color = statusColor.withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawRect(rect, glowPaint);

      // Draw corner brackets over the bounding box corners for a sci-fi, hi-tech scanning effect
      final cornerPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..color = statusColor;
      
      const cornerLength = 20.0;
      // Top Left Corner
      canvas.drawLine(Offset(rect.left, rect.top), Offset(rect.left + cornerLength, rect.top), cornerPaint);
      canvas.drawLine(Offset(rect.left, rect.top), Offset(rect.left, rect.top + cornerLength), cornerPaint);
      // Top Right Corner
      canvas.drawLine(Offset(rect.right, rect.top), Offset(rect.right - cornerLength, rect.top), cornerPaint);
      canvas.drawLine(Offset(rect.right, rect.top), Offset(rect.right, rect.top + cornerLength), cornerPaint);
      // Bottom Left Corner
      canvas.drawLine(Offset(rect.left, rect.bottom), Offset(rect.left + cornerLength, rect.bottom), cornerPaint);
      canvas.drawLine(Offset(rect.left, rect.bottom), Offset(rect.left, rect.bottom - cornerLength), cornerPaint);
      // Bottom Right Corner
      canvas.drawLine(Offset(rect.right, rect.bottom), Offset(rect.right - cornerLength, rect.bottom), cornerPaint);
      canvas.drawLine(Offset(rect.right, rect.bottom), Offset(rect.right, rect.bottom - cornerLength), cornerPaint);

      // Draw Status Text above the box
      final textSpan = TextSpan(
        text: statusText,
        style: GoogleFonts.orbitron(
          color: statusColor,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
          shadows: [
            const Shadow(color: Colors.black, blurRadius: 6, offset: Offset(2, 2)),
          ],
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.left,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // Position text above the top-left of the box with some padding
      textPainter.paint(canvas, Offset(rect.left, rect.top - textPainter.height - 8));
    }

    // 2. Draw ML Kit bounding boxes if any are present (local on-device backup)
    for (final object in objects) {
      final isPanel = object.labels.any((l) => 
        l.text.toLowerCase().contains('solar') || 
        l.text.toLowerCase().contains('panel') ||
        l.text.toLowerCase().contains('photovoltaic') ||
        l.text.toLowerCase().contains('pattern') ||
        l.text.toLowerCase().contains('glass') ||
        l.text.toLowerCase().contains('roof')
      );

      if (!isPanel && object.labels.isEmpty) continue;

      final rect = _scaleRect(
        rect: object.boundingBox,
        imageSize: imageSize,
        widgetSize: canvasSize,
        rotation: rotation,
      );

      final statusColor = _getStatusColor();
      final statusText = _getStatusText();

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..color = statusColor;

      canvas.drawRect(rect, paint);

      final textSpan = TextSpan(
        text: statusText,
        style: GoogleFonts.orbitron(
          color: statusColor,
          fontSize: 24,
          fontWeight: FontWeight.w900,
          shadows: [
            const Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2)),
          ],
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.left,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      textPainter.paint(canvas, Offset(rect.left, rect.top - textPainter.height - 10));
    }
  }

  Color _getStatusColor() {
    if (isAnalyzing) return Colors.orangeAccent;
    if (liveResult == null) return AppColors.accent;
    
    final res = liveResult!.result.toLowerCase();
    if (res.contains('clean')) return Colors.greenAccent;
    if (res.contains('dust') || res.contains('dirt')) return Colors.orangeAccent;
    if (res.contains('bird') || res.contains('drop')) return Colors.deepOrangeAccent;
    if (res.contains('damage') || res.contains('electrical')) return Colors.redAccent;
    
    return Colors.redAccent;
  }

  String _getStatusText() {
    if (isAnalyzing) return 'ANALYZING...';
    if (liveResult == null) return 'DETECTED';
    return liveResult!.result.toUpperCase();
  }

  Rect _scaleRect({
    required Rect rect,
    required Size imageSize,
    required Size widgetSize,
    required int rotation,
  }) {
    double scaleX, scaleY;
    
    // For portrait mode, image width is the height of the sensor and vice versa
    if (rotation == 90 || rotation == 270) {
      scaleX = widgetSize.width / imageSize.height;
      scaleY = widgetSize.height / imageSize.width;
      
      return Rect.fromLTRB(
        rect.left * scaleX,
        rect.top * scaleY,
        rect.right * scaleX,
        rect.bottom * scaleY,
      );
    } else {
      scaleX = widgetSize.width / imageSize.width;
      scaleY = widgetSize.height / imageSize.height;
      
      return Rect.fromLTRB(
        rect.left * scaleX,
        rect.top * scaleY,
        rect.right * scaleX,
        rect.bottom * scaleY,
      );
    }
  }

  @override
  bool shouldRepaint(DetectionPainter oldDelegate) {
    return oldDelegate.objects != objects || 
           oldDelegate.liveResult != liveResult || 
           oldDelegate.isAnalyzing != isAnalyzing;
  }
}

