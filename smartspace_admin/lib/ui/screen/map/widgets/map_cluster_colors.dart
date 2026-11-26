import 'package:flutter/material.dart';
import 'package:mobile_shared/core/theme/app_semantic_colors.dart';
import 'package:mobile_shared/features/map/cluster/cluster_layer_colors.dart';

/// Màu cluster trên bản đồ Admin: cụm có phản ánh chờ duyệt là việc cần chú ý
/// → Warning (theo `design.md`), không phải Error.
ClusterLayerColors adminClusterColors(BuildContext context) =>
    ClusterLayerColors.fromTheme(
      Theme.of(context),
      alert: AppSemanticColors.of(context).warning,
    );
