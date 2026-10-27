import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:ui' as ui;
import 'package:mobile_shared/mobile_shared.dart';
import 'package:smartspace_client/features/reports/models/report_detail_model.dart';
import 'package:smartspace_client/features/reports/models/report_dto.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/features/reports/services/report_background_upload_service.dart';
import 'package:smartspace_client/features/reports/services/report_service.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';

class CreateReportController extends ChangeNotifier {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final addressController = TextEditingController();
  final locationDescController = TextEditingController();
  final latController = TextEditingController();
  final lngController = TextEditingController();

  ReportDetailModel? _reportToEdit;
  ReportDetailModel? get reportToEdit => _reportToEdit;
  bool get isEditing => _reportToEdit != null;

  final List<String> _existingImageUrls = [];
  List<String> get existingImageUrls => _existingImageUrls;

  final List<Uint8List> _images = [];
  List<Uint8List> get images => _images;

  int get totalImagesCount => _existingImageUrls.length + _images.length;

  bool _isAnonymous = false;
  bool get isAnonymous => _isAnonymous;

  double? _latitude;
  double? get latitude => _latitude;

  double? _longitude;
  double? get longitude => _longitude;

  bool _isLoadingLocation = false;
  bool get isLoadingLocation => _isLoadingLocation;

  bool _isSubmittingEdit = false;
  bool get isSubmittingEdit => _isSubmittingEdit;

  String? _titleError;
  String? get titleError => _titleError;

  String? _descError;
  String? get descError => _descError;

  CreateReportController() {
    latController.addListener(_onLatChanged);
    lngController.addListener(_onLngChanged);
    _getCurrentLocation();
  }

  void initForEdit(ReportDetailModel report) {
    if (_reportToEdit?.id == report.id) return;
    _reportToEdit = report;
    titleController.text = report.title;
    descriptionController.text = report.description;
    addressController.text = report.address ?? '';
    locationDescController.text = report.locationDescription ?? '';
    _latitude = report.latitude;
    _longitude = report.longitude;
    latController.text = report.latitude.toString();
    lngController.text = report.longitude.toString();
    _isAnonymous = report.isAnonymous;
    _existingImageUrls.clear();
    _existingImageUrls.addAll(report.imageUrls);
    _images.clear();
    notifyListeners();
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
    // If in edit mode with existing coordinates, do not override
    if (_reportToEdit != null && _latitude != null && _longitude != null) {
      return;
    }

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
      if (_reportToEdit == null) {
        setLocation(position.latitude, position.longitude);
      }
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
    if (totalImagesCount >= 10) {
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

  void removeExistingImage(int index) {
    _existingImageUrls.removeAt(index);
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

  Future<bool> submitEdit(BuildContext context, {Function(ReportDetailModel)? onSuccess}) async {
    if (!validate(context)) return false;
    if (_reportToEdit == null) return false;

    final l10n = AppLocalizations.of(context)!;

    // Business rule: Only pending reports can be edited
    if (_reportToEdit!.status != ReportStatus.pending) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.editReportOnlyPending)),
      );
      return false;
    }

    _isSubmittingEdit = true;
    notifyListeners();

    try {
      // 1. Upload newly picked images
      List<String> newUploadedUrls = [];
      for (int i = 0; i < _images.length; i++) {
        String url = await mediaUploadUtil.uploadMedia(
          _images[i],
          'report_edit_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
        );
        if (url.isNotEmpty) {
          newUploadedUrls.add(url);
        }
      }

      // 2. Combine existing with new
      final allImages = [..._existingImageUrls, ...newUploadedUrls];

      // 3. Build DTO
      final dto = ReportDto(
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        imageUrls: allImages,
        latitude: _latitude ?? 0.0,
        longitude: _longitude ?? 0.0,
        isAnonymous: _isAnonymous,
        address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
        locationDescription: locationDescController.text.trim().isEmpty ? null : locationDescController.text.trim(),
      );

      // 4. Request API
      final response = await reportService.updateReport(_reportToEdit!.id, dto);

      if (response.success && response.data != null) {
        if (onSuccess != null) {
          onSuccess(response.data!);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.updateReportSuccess),
              backgroundColor: Colors.green,
            ),
          );
        }
        return true;
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message.isNotEmpty ? response.message : l10n.genericError),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    } finally {
      _isSubmittingEdit = false;
      notifyListeners();
    }
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
