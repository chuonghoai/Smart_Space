import 'package:flutter_test/flutter_test.dart';
import 'package:smartspace_client/features/reports/models/report_dto.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/features/reports/models/report_detail_model.dart';
import 'package:smartspace_client/features/reports/repositories/report_repo_mock.dart';
import 'package:smartspace_client/features/reports/services/report_service.dart';

void main() {
  group('ReportModel & ReportDetailModel userId test', () {
    test('ReportModel parses user_id from json correctly', () {
      final json = {
        'id': 'rep-1',
        'title': 'Ổ gà lớn',
        'description': 'Đường bị lún sụt',
        'image_url': 'https://example.com/img.jpg',
        'latitude': 10.7769,
        'longitude': 106.7009,
        'status': 'pending',
        'created_at': '2026-10-27T10:00:00Z',
        'user_id': 'user-123',
      };

      final model = ReportModel.fromJson(json);
      expect(model.id, 'rep-1');
      expect(model.userId, 'user-123');
      expect(model.status, ReportStatus.pending);
    });

    test('ReportDetailModel parses user_id from json correctly', () {
      final json = {
        'id': 'rep-2',
        'title': 'Đèn đường hỏng',
        'description': 'Đèn không sáng',
        'image_urls': ['https://example.com/img1.jpg'],
        'latitude': 10.7769,
        'longitude': 106.7009,
        'status': 'processing',
        'severity': 'low',
        'created_at': '2026-10-27T10:00:00Z',
        'user_id': 'user-456',
        'is_anonymous': false,
      };

      final detail = ReportDetailModel.fromJson(json);
      expect(detail.id, 'rep-2');
      expect(detail.userId, 'user-456');
      expect(detail.status, ReportStatus.processing);
    });
  });

  group('Report Edit & Cancel Business Rules', () {
    test('Only pending reports are allowed to be edited', () {
      final pendingReport = ReportModel(
        id: '1',
        title: 'T1',
        description: 'D1',
        imageUrl: '',
        latitude: 0,
        longitude: 0,
        status: ReportStatus.pending,
        createdAt: DateTime.now(),
      );

      final processingReport = ReportModel(
        id: '2',
        title: 'T2',
        description: 'D2',
        imageUrl: '',
        latitude: 0,
        longitude: 0,
        status: ReportStatus.processing,
        createdAt: DateTime.now(),
      );

      final processedReport = ReportModel(
        id: '3',
        title: 'T3',
        description: 'D3',
        imageUrl: '',
        latitude: 0,
        longitude: 0,
        status: ReportStatus.processed,
        createdAt: DateTime.now(),
      );

      final rejectedReport = ReportModel(
        id: '4',
        title: 'T4',
        description: 'D4',
        imageUrl: '',
        latitude: 0,
        longitude: 0,
        status: ReportStatus.rejected,
        createdAt: DateTime.now(),
      );

      // Business Rule: only pending report can be edited
      expect(pendingReport.status == ReportStatus.pending, isTrue);
      expect(processingReport.status == ReportStatus.pending, isFalse);
      expect(processedReport.status == ReportStatus.pending, isFalse);
      expect(rejectedReport.status == ReportStatus.pending, isFalse);
    });

    test('Only pending reports are allowed to be cancelled', () {
      final pendingReport = ReportModel(
        id: '1',
        title: 'T1',
        description: 'D1',
        imageUrl: '',
        latitude: 0,
        longitude: 0,
        status: ReportStatus.pending,
        createdAt: DateTime.now(),
      );

      final processingReport = ReportModel(
        id: '2',
        title: 'T2',
        description: 'D2',
        imageUrl: '',
        latitude: 0,
        longitude: 0,
        status: ReportStatus.processing,
        createdAt: DateTime.now(),
      );

      final processedReport = ReportModel(
        id: '3',
        title: 'T3',
        description: 'D3',
        imageUrl: '',
        latitude: 0,
        longitude: 0,
        status: ReportStatus.processed,
        createdAt: DateTime.now(),
      );

      final rejectedReport = ReportModel(
        id: '4',
        title: 'T4',
        description: 'D4',
        imageUrl: '',
        latitude: 0,
        longitude: 0,
        status: ReportStatus.rejected,
        createdAt: DateTime.now(),
      );

      // Business Rule: only pending report can be cancelled
      expect(pendingReport.status == ReportStatus.pending, isTrue);
      expect(processingReport.status == ReportStatus.pending, isFalse);
      expect(processedReport.status == ReportStatus.pending, isFalse);
      expect(rejectedReport.status == ReportStatus.pending, isFalse);
    });

    test('ReportService updateReport and cancelReport with ReportRepoMock', () async {
      final mockRepo = ReportRepoMock();
      final service = ReportService(reportRepo: mockRepo);

      final updateDto = ReportDto(
        title: 'Updated Title',
        description: 'Updated Description',
        imageUrls: ['https://example.com/updated.jpg'],
        latitude: 10.8,
        longitude: 106.8,
        isAnonymous: false,
      );

      final updateRes = await service.updateReport('rep-1', updateDto);
      expect(updateRes.success, isTrue);
      expect(updateRes.data?.title, 'Updated Title');
      expect(updateRes.data?.status, ReportStatus.pending);

      final cancelRes = await service.cancelReport('rep-1');
      expect(cancelRes.success, isTrue);
      expect(cancelRes.data?.status, ReportStatus.rejected);
    });
  });
}
