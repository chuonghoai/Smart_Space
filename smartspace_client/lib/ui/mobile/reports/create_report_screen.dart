import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:smartspace_client/ui/mobile/reports/create_report_controller.dart';
import 'package:smartspace_client/features/reports/providers/report_providers.dart';

class CreateReportScreen extends ConsumerWidget {
  const CreateReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.createReportTitle),
      ),
      body: const _CreateReportForm(),
    );
  }
}

class _CreateReportForm extends ConsumerWidget {
  const _CreateReportForm();

  void _showImageSourceActionSheet(
    BuildContext context,
    CreateReportController controller,
  ) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.pickImage),
              onTap: () {
                controller.pickImage(ImageSource.gallery, context);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text(l10n.takePhoto),
              onTap: () {
                controller.pickImage(ImageSource.camera, context);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(createReportControllerProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          TextField(
            controller: controller.titleController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l10n.reportTitleLabel,
              errorText: controller.titleError,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Description
          TextField(
            controller: controller.descriptionController,
            maxLines: 3,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              labelText: l10n.reportDescLabel,
              errorText: controller.descError,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Address
          TextField(
            controller: controller.addressController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l10n.reportAddressLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Location Description
          TextField(
            controller: controller.locationDescController,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: l10n.reportLocationDescLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Anonymous check
          CheckboxListTile(
            title: Text(l10n.reportAnonymous),
            value: controller.isAnonymous,
            onChanged: (val) => controller.setIsAnonymous(val ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),

          // Map
          Text(l10n.reportLocationDescLabel, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller.latController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller.lngController,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.hardEdge,
            child: controller.isLoadingLocation
                ? const Center(child: CircularProgressIndicator())
                : (controller.latitude != null && controller.longitude != null)
                ? FlutterMap(
                    options: MapOptions(
                          initialCenter: LatLng(controller.latitude!, controller.longitude!),
                      initialZoom: 15.0,
                      onTap: (tapPosition, point) {
                        controller.setLocation(point.latitude, point.longitude);
                      },
                    ),
                    children: [
                      TileLayer(
                            urlTemplate: 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                          ),
                      MarkerLayer(
                        markers: [
                          Marker(
                                point: LatLng(controller.latitude!, controller.longitude!),
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Center(child: Text(l10n.reloadLocation)),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: controller.reloadLocation,
            icon: const Icon(Icons.my_location),
            label: Text(l10n.reloadLocation),
          ),
          const SizedBox(height: 16),

          // Images
          Text(l10n.pickImage, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int i = 0; i < controller.images.length; i++)
                Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: MemoryImage(controller.images[i]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => controller.removeImage(i),
                      ),
                    ),
                  ],
                ),
              if (controller.images.length < 10)
                InkWell(
                  onTap: () => _showImageSourceActionSheet(context, controller),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add_a_photo, size: 40),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),

          // Submit button
          ElevatedButton(
            onPressed: () {
              // Show dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => AlertDialog(
                  content: Row(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(width: 16),
                      Expanded(child: Text(l10n.uploadingReport)),
                    ],
                  ),
                ),
              );

              final reportsNotifier = ref.read(reportsProvider.notifier);

              // Allow UI to render the dialog before submitting and popping to home
              Future.delayed(const Duration(milliseconds: 500), () {
                if (!context.mounted) return;
                Navigator.of(context).pop();
                controller.submit(
                  context,
                  onSuccess: (report) {
                    reportsNotifier.addNewReport(report);
                  },
                );
              });
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: Text(l10n.submitReport),
          ),
        ],
      ),
    );
  }
}
