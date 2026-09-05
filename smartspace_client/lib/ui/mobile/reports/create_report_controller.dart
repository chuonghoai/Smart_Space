import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:ui' as ui;
import 'package:smartspace_client/features/reports/models/report_dto.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/features/reports/services/report_background_upload_service.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';

class CreateReportController extends ChangeNotifier {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final addressController = TextEditingController();
  final locationDescController = TextEditingController();
  final latController = TextEditingController();
  final lngController = TextEditingController();

  final List<Uint8List> _images = [];
  List<Uint8List> get images => _images;

  bool _isAnonymous = false;
  bool get isAnonymous => _isAnonymous;

  double? _latitude;
  double? get latitude => _latitude;

  double? _longitude;
  double? get longitude => _longitude;

  bool _isLoadingLocation = false;
  bool get isLoadingLocation => _isLoadingLocation;

  String? _titleError;
  String? get titleError => _titleError;

  String? _descError;
  String? get descError => _descError;

  CreateReportController() {
    latController.addListener(_onLatChanged);
    lngController.addListener(_onLngChanged);
    _getCurrentLocation();
  }

  void _onLatChanged() {
    final lat = double.tryParse(latController.text);
    if (lat != null && lat != _latitude) {
      _latitude = lat;
      notifyListeners();
    }
  }

  void _onLngChanged() {
    final lng = double.tryParse(lngController.text);
    if (lng != null && lng != _longitude) {
      _longitude = lng;
      notifyListeners();
    }
  }

  void setIsAnonymous(bool value) {
    _isAnonymous = value;
    notifyListeners();
  }

  Future<void> _getCurrentLocation() async {
    _isLoadingLocation = true;
    notifyListeners();

    final l10n = lookupAppLocalizations(ui.PlatformDispatcher.instance.locale);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        throw Exception(l10n.locationServicesDisabled);
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception(l10n.locationPermissionsDenied);
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception(l10n.locationPermissionsPermanentlyDenied);
      } 

      Position position = await Geolocator.getCurrentPosition();
      setLocation(position.latitude, position.longitude);
    } catch (e) {
      // Handle location error gracefully
    } finally {
      _isLoadingLocation = false;
      notifyListeners();
    }
  }

  void reloadLocation() {
    _getCurrentLocation();
  }

  void setLocation(double lat, double lng) {
    _latitude = lat;
    _longitude = lng;
    if (latController.text != lat.toString()) latController.text = lat.toString();
    if (lngController.text != lng.toString()) lngController.text = lng.toString();
    notifyListeners();
  }

  Future<void> pickImage(ImageSource source, BuildContext context) async {
    if (_images.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.maxImagesError)),
      );
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      _images.add(bytes);
      notifyListeners();
    }
  }

  void removeImage(int index) {
    _images.removeAt(index);
    notifyListeners();
  }

  bool validate(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    bool isValid = true;
    _titleError = null;
    _descError = null;

    if (titleController.text.trim().isEmpty) {
      _titleError = l10n.requiredFieldError;
      isValid = false;
    }

    if (descriptionController.text.trim().isEmpty) {
      _descError = l10n.requiredFieldError;
      isValid = false;
    }

    notifyListeners();
    return isValid;
  }

  void submit(BuildContext context, {Function(ReportModel)? onSuccess}) {
    if (!validate(context)) return;

    final l10n = AppLocalizations.of(context)!;

    final dto = ReportDto(
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      imageUrls: [],
      latitude: _latitude ?? 0.0,
      longitude: _longitude ?? 0.0,
      isAnonymous: _isAnonymous,
      address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
      locationDescription: locationDescController.text.trim().isEmpty ? null : locationDescController.text.trim(),
    );

    // Bắt đầu background upload
    reportBackgroundUploadService.startUploadAndCreateReport(
      dto, 
      _images,
      onSuccess: onSuccess,
    );

    // Hiện snackbar đang gửi
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: ListenableBuilder(
          listenable: reportBackgroundUploadService,
          builder: (context, child) {
            final current = reportBackgroundUploadService.currentStep;
            final total = reportBackgroundUploadService.totalSteps;
            return Text(l10n.sendingReportProgress(current, total));
          },
        ),
        duration: const Duration(seconds: 15),
      ),
    );

    // Route về Home ngay lập tức
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    addressController.dispose();
    locationDescController.dispose();
    latController.dispose();
    lngController.dispose();
    super.dispose();
  }
}

final createReportControllerProvider = ChangeNotifierProvider.autoDispose<CreateReportController>((ref) {
  return CreateReportController();
});
