import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartspace_admin/features/account_lock/application/account_lock_providers.dart';
import 'package:smartspace_admin/features/account_lock/models/account_lock_request_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/routes/router_path.dart';
import 'package:smartspace_admin/ui/screen/users/user_detail_view.dart';
import 'package:smartspace_admin/ui/shared/image/person_avatar.dart';
import 'package:smartspace_admin/ui/shared/report_status/report_status_style.dart';

// Style "achromatic-ledger" (design-taste-frontend, seed 1001827140): chrome không màu, chữ màu mực,
// MỘT sắc màu (primary của thương hiệu) trên dữ liệu chính — số ghế bảo lãnh. Đỏ chỉ là tín hiệu:
// đồng hồ còn dưới 12 giờ, nút Bảo lãnh (hậu quả là khoá), và kết quả "đã khoá".

const _tabular = [FontFeature.tabularFigures()];
const double _phoneBreakpoint = 640;

// ─────────────────────────────────────────────────────────────────────────────
// Time helpers
// ─────────────────────────────────────────────────────────────────────────────

String formatLockTime(DateTime? time) =>
    time == null ? '—' : DateFormat('HH:mm - dd/MM/yyyy').format(time.toLocal());

String formatLockDate(DateTime? time) =>
    time == null ? '—' : DateFormat('yyyy-MM-dd').format(time.toLocal());

/// "còn 5 giờ" / "còn 40 phút" / "Đã hết giờ biểu quyết".
String lockTimeLeft(AppLocalizations l10n, DateTime? expiresAt, {DateTime? now}) {
  if (expiresAt == null) return '—';
  final left = expiresAt.difference(now ?? DateTime.now());
  if (left.isNegative || left == Duration.zero) return l10n.lockTimeOverdue;
  if (left.inHours >= 1) return l10n.lockTimeLeftHours(left.inHours);
  return l10n.lockTimeLeftMinutes(math.max(1, left.inMinutes));
}

bool lockIsUrgent(DateTime? expiresAt, {DateTime? now}) {
  if (expiresAt == null) return false;
  return expiresAt.difference(now ?? DateTime.now()) < kLockUrgentThreshold;
}

/// "2 giờ trước" — dùng lại các key thời gian tương đối đang có của app.
String lockRelativeTime(AppLocalizations l10n, DateTime? time) {
  if (time == null) return '—';
  final diff = DateTime.now().difference(time);
  if (diff.inDays > 0) return '${diff.inDays} ${l10n.dayAgo}';
  if (diff.inHours > 0) return '${diff.inHours} ${l10n.hourAgo}';
  if (diff.inMinutes > 0) return '${diff.inMinutes} ${l10n.minuteAgo}';
  return l10n.justNow;
}

String lockOutcomeText(AppLocalizations l10n, AccountLockRequestModel r) {
  final time = formatLockTime(r.resolvedAt);
  return switch (r.status) {
    LockRequestStatus.approved => l10n.lockOutcomeApproved(time),
    LockRequestStatus.rejected => l10n.lockOutcomeRejected(time),
    LockRequestStatus.cancelled => l10n.lockOutcomeCancelled(time),
    LockRequestStatus.expired => l10n.lockOutcomeExpired(time),
    LockRequestStatus.pending => lockTimeLeft(l10n, r.expiresAt),
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Status pill
// ─────────────────────────────────────────────────────────────────────────────

/// Pill màu nhạt, chữ đậm cùng sắc. Chỉ "đã thông qua" (= đã khoá) mang màu; còn lại trung tính.
class LockStatusChip extends StatelessWidget {
  final LockRequestStatus status;

  const LockStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final (Color tone, String label) = switch (status) {
      LockRequestStatus.pending => (cs.onSurfaceVariant, l10n.lockStatusPending),
      LockRequestStatus.approved => (cs.error, l10n.lockStatusApproved),
      LockRequestStatus.rejected => (cs.onSurfaceVariant, l10n.lockStatusRejected),
      LockRequestStatus.cancelled => (cs.onSurfaceVariant, l10n.lockStatusCancelled),
      LockRequestStatus.expired => (cs.onSurfaceVariant, l10n.lockStatusExpired),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        style: theme.textTheme.labelSmall?.copyWith(color: tone, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ballot: seats + 72h clock (signature element)
// ─────────────────────────────────────────────────────────────────────────────

/// Một ghế bảo lãnh / từ chối: avatar người đã bỏ phiếu trong vòng màu, hoặc vòng nét đứt khi trống.
class _Seat extends StatelessWidget {
  static const double size = 32;

  final LockPerson? voter;
  final Color tone;

  const _Seat({required this.voter, required this.tone});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final voter = this.voter;
    if (voter == null) {
      return Semantics(
        label: l10n.lockSeatEmpty,
        child: CustomPaint(
          size: Size.square(size),
          painter: _DashedCirclePainter(color: cs.outline),
        ),
      );
    }
    return Tooltip(
      message: voter.displayName,
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: tone, width: 2)),
        child: PersonAvatar(avatarUrl: voter.avatarUrl, name: voter.displayName, radius: size / 2 - 4),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;

  const _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rect = Offset.zero & size;
    const dashes = 12;
    const sweep = 2 * math.pi / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect.deflate(1), i * sweep, sweep * 0.55, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter oldDelegate) => oldDelegate.color != color;
}

/// Ghế mini trong dòng danh sách: chấm đặc = đã bảo lãnh, chấm rỗng = còn thiếu.
class LockMiniSeats extends StatelessWidget {
  final int filled;
  final int total;

  const LockMiniSeats({super.key, required this.filled, required this.total});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < total; i++)
          Container(
            width: 10,
            height: 10,
            margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < filled ? cs.primary : null,
              border: i < filled ? null : Border.all(color: cs.outline, width: 1.5),
            ),
          ),
      ],
    );
  }
}

/// Khối lớn nhất của chi tiết: ai đã bảo lãnh / từ chối, còn bao lâu, và nút bỏ phiếu ngay tại đây.
class LockBallot extends StatelessWidget {
  final AccountLockRequestModel request;
  final bool showActions;

  const LockBallot({super.key, required this.request, this.showActions = true});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final approvers = request.votes.where((v) => v.approve).map((v) => v.voter).toList();
    final rejecters = request.votes.where((v) => !v.approve).map((v) => v.voter).toList();

    Widget seatRow(String label, List<LockPerson> voters, int count, int required, Color tone) {
      return Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ),
          for (var i = 0; i < required; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _Seat(voter: i < voters.length ? voters[i] : null, tone: tone),
          ],
          const Spacer(),
          Text(
            '$count/$required',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, fontFeatures: _tabular),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.lockBallotTitle, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          seatRow(l10n.lockVoteApprove, approvers, request.approvals, request.requiredApprovals, cs.primary),
          const SizedBox(height: 10),
          seatRow(l10n.lockVoteReject, rejecters, request.rejections, request.requiredRejections, cs.onSurfaceVariant),
          const SizedBox(height: 16),
          if (request.status == LockRequestStatus.pending)
            _VotingClock(request: request)
          else
            Row(
              children: [
                Icon(
                  request.status == LockRequestStatus.approved ? Icons.lock_outline : Icons.info_outline,
                  size: 16,
                  color: request.status == LockRequestStatus.approved ? cs.error : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(lockOutcomeText(l10n, request), style: theme.textTheme.bodyMedium)),
              ],
            ),
          if (showActions) ...[
            const SizedBox(height: 16),
            LockVoteActions(request: request),
          ],
        ],
      ),
    );
  }
}

/// Thanh 72 giờ mảnh: phần đã trôi qua; chuyển đỏ khi còn dưới 12 giờ.
class _VotingClock extends StatelessWidget {
  final AccountLockRequestModel request;

  const _VotingClock({required this.request});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final now = DateTime.now();
    final start = request.createdAt ?? now;
    final end = request.expiresAt ?? now;
    final total = end.difference(start).inSeconds;
    final elapsed = now.difference(start).inSeconds;
    final progress = total <= 0 ? 1.0 : (elapsed / total).clamp(0.0, 1.0);
    final urgent = lockIsUrgent(request.expiresAt, now: now);
    final tone = urgent ? cs.error : cs.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(1),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 2,
            color: tone,
            backgroundColor: cs.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.lockDeadline(formatLockTime(request.expiresAt)),
                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
            Text(
              lockTimeLeft(l10n, request.expiresAt, now: now),
              style: theme.textTheme.bodySmall?.copyWith(
                color: tone,
                fontWeight: urgent ? FontWeight.w600 : null,
                fontFeatures: _tabular,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// List row
// ─────────────────────────────────────────────────────────────────────────────

/// Dòng hai hàng: người bị đề xuất (mực) + "Đề xuất bởi · thời gian" (xám); bên phải là ghế mini và
/// thời gian còn lại (chờ) hoặc pill kết quả + ngày (đã kết thúc).
class LockRequestRow extends StatelessWidget {
  final AccountLockRequestModel request;
  final bool selected;
  final VoidCallback onTap;

  /// Hiện nhãn "Cần bạn" — tắt khi đang ở chính bộ lọc "Cần bạn" (mọi dòng đều cần, nhãn thành nhiễu).
  final bool showAwaitingMarker;

  const LockRequestRow({
    super.key,
    required this.request,
    required this.onTap,
    this.selected = false,
    this.showAwaitingMarker = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant);
    final proposer = request.isMine ? l10n.lockProposedByYou : l10n.lockProposedBy(request.proposer.displayName);
    final pending = request.status == LockRequestStatus.pending;
    final urgent = pending && lockIsUrgent(request.expiresAt);

    return Material(
      // Dòng đang chọn: nền trung tính, không dùng màu thương hiệu (không nhầm với focus/hover)
      color: selected ? cs.surfaceContainerHighest : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              PersonAvatar(avatarUrl: request.target.avatarUrl, name: request.target.displayName, radius: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.target.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$proposer · ${lockRelativeTime(l10n, request.createdAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: muted,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (pending)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showAwaitingMarker && request.awaitsMyVote) ...[
                          Tooltip(
                            message: l10n.lockAwaitingYourVote,
                            child: Text(
                              l10n.lockFilterAwaitingMine,
                              style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        LockMiniSeats(filled: request.approvals, total: request.requiredApprovals),
                      ],
                    )
                  else
                    LockStatusChip(status: request.status),
                  const SizedBox(height: 4),
                  Text(
                    pending ? lockTimeLeft(l10n, request.expiresAt) : formatLockDate(request.resolvedAt),
                    style: muted?.copyWith(
                      color: urgent ? cs.error : null,
                      fontWeight: urgent ? FontWeight.w600 : null,
                      fontFeatures: _tabular,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dòng giữ chỗ khi đang tải: đúng kích thước dòng thật, thanh xám phẳng, không shimmer.
class LockRequestRowSkeleton extends StatelessWidget {
  const LockRequestRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final bar = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget block(double w, double h, {double r = 4}) =>
        Container(width: w, height: h, decoration: BoxDecoration(color: bar, borderRadius: BorderRadius.circular(r)));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          block(40, 40, r: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [block(160, 14), const SizedBox(height: 6), block(220, 12)],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [block(24, 10), const SizedBox(height: 6), block(56, 12)],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail panel
// ─────────────────────────────────────────────────────────────────────────────

/// Chi tiết một đề xuất. [showVoteActions] = false trên trang điện thoại (nút ghim ở đáy màn hình).
/// [onCloseOverlay]: đóng dialog trước khi điều hướng sang màn khác.
class LockRequestDetailPanel extends ConsumerWidget {
  final String requestId;
  final VoidCallback? onCloseOverlay;
  final bool showVoteActions;

  const LockRequestDetailPanel({
    super.key,
    required this.requestId,
    this.onCloseOverlay,
    this.showVoteActions = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final detailAsync = ref.watch(lockRequestDetailProvider(requestId));

    return detailAsync.when(
      loading: () => const _DetailSkeleton(),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 18, color: theme.colorScheme.error),
            const SizedBox(width: 8),
            Expanded(child: Text(error.toString().replaceFirst('Exception: ', ''))),
            TextButton(
              onPressed: () => ref.invalidate(lockRequestDetailProvider(requestId)),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
      data: (request) => _DetailBody(
        request: request,
        onCloseOverlay: onCloseOverlay,
        showVoteActions: showVoteActions,
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    final bar = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget block(double? w, double h) =>
        Container(width: w, height: h, decoration: BoxDecoration(color: bar, borderRadius: BorderRadius.circular(4)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        block(220, 16),
        const SizedBox(height: 8),
        block(280, 12),
        const SizedBox(height: 20),
        block(double.infinity, 168),
        const SizedBox(height: 24),
        block(80, 12),
        const SizedBox(height: 8),
        block(double.infinity, 48),
      ],
    );
  }
}

class _DetailBody extends ConsumerWidget {
  final AccountLockRequestModel request;
  final VoidCallback? onCloseOverlay;
  final bool showVoteActions;

  const _DetailBody({required this.request, required this.showVoteActions, this.onCloseOverlay});

  void _openReport(BuildContext context, String reportId) {
    final router = GoRouter.of(context);
    onCloseOverlay?.call();
    router.push(RouterPath.reportDetailWithId(reportId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final label = theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w500);
    final muted = theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant);
    final images = request.evidences.where((e) => e.isImage && e.imageUrl != null).toList();
    final reports = request.evidences.where((e) => !e.isImage && e.reportId != null).toList();
    final proposer = request.isMine ? l10n.lockProposedByYou : l10n.lockProposedBy(request.proposer.displayName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Đối tượng của đề xuất: tên (1 dòng), email, người đề xuất. Không breadcrumb: tab / AppBar đã
        // nêu khu vực, và breadcrumb gãy dòng trên màn hẹp.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PersonAvatar(avatarUrl: request.target.avatarUrl, name: request.target.displayName, radius: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.target.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(request.target.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: muted),
                ],
              ),
            ),
            TextButton(
              onPressed: () => showUserDetail(context, request.target.id),
              child: Text(l10n.viewUserProfile),
            ),
            if (request.canCancel)
              PopupMenuButton<String>(
                tooltip: l10n.lockMoreActions,
                icon: const Icon(Icons.more_vert),
                onSelected: (_) => confirmCancelLockRequest(context, ref, request),
                itemBuilder: (_) => [PopupMenuItem(value: 'cancel', child: Text(l10n.lockCancelAction))],
              ),
          ],
        ),
        // Người đề xuất: một dòng riêng, hết bề ngang (không bị nút "Xem người dùng" ép xuống dòng)
        Padding(
          padding: const EdgeInsets.only(left: 52, top: 4),
          child: Text('$proposer · ${lockRelativeTime(l10n, request.createdAt)}', style: muted),
        ),
        const SizedBox(height: 16),
        LockBallot(request: request, showActions: showVoteActions),
        const SizedBox(height: 24),

        // Lý do — trích dẫn với một đường kẻ mảnh bên trái
        Text(l10n.lockReasonLabel, style: label),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(border: Border(left: BorderSide(color: theme.dividerColor, width: 2))),
          child: SelectableText(request.reason, style: theme.textTheme.bodyMedium),
        ),
        const SizedBox(height: 24),

        // Bằng chứng
        Text(l10n.lockEvidenceSummary(images.length, reports.length), style: label),
        const SizedBox(height: 8),
        if (images.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in images)
                _EvidenceThumbnail(url: e.imageUrl!, onTap: () => _showImageViewer(context, e.imageUrl!)),
            ],
          ),
        if (images.isNotEmpty && reports.isNotEmpty) const SizedBox(height: 8),
        for (var i = 0; i < reports.length; i++) ...[
          if (i > 0) Divider(height: 1, color: theme.dividerColor),
          InkWell(
            onTap: () => _openReport(context, reports[i].reportId!),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      reports[i].reportTitle ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ReportStatusPill(status: reports[i].reportStatus),
                  const SizedBox(width: 12),
                  Text(
                    formatLockDate(reports[i].reportCreatedAt),
                    style: muted?.copyWith(fontFeatures: _tabular),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 18, color: cs.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),

        // Phiếu đã bỏ
        Text(l10n.lockVotesCast, style: label),
        const SizedBox(height: 4),
        if (request.votes.isEmpty)
          Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(l10n.noVotesYet, style: muted))
        else
          for (var i = 0; i < request.votes.length; i++) ...[
            if (i > 0) Divider(height: 1, color: theme.dividerColor),
            _VoteRow(vote: request.votes[i]),
          ],
      ],
    );
  }
}

class _ReportStatusPill extends StatelessWidget {
  final String? status;

  const _ReportStatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = reportStatusColor(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: tone.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(
        reportStatusLabel(AppLocalizations.of(context)!, status),
        maxLines: 1,
        softWrap: false,
        style: theme.textTheme.labelSmall?.copyWith(color: tone, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _EvidenceThumbnail extends StatelessWidget {
  final String url;
  final VoidCallback onTap;

  const _EvidenceThumbnail({required this.url, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Image.network(
          url,
          width: 96,
          height: 96,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => SizedBox(
            width: 96,
            height: 96,
            child: Icon(Icons.broken_image_outlined, color: cs.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

void _showImageViewer(BuildContext context, String url) {
  final l10n = AppLocalizations.of(context)!;
  showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          InteractiveViewer(maxScale: 4, child: Image.network(url, fit: BoxFit.contain)),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton.filledTonal(
              tooltip: l10n.closeAction,
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(dialogContext),
            ),
          ),
        ],
      ),
    ),
  );
}

class _VoteRow extends StatelessWidget {
  final LockVote vote;

  const _VoteRow({required this.vote});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PersonAvatar(avatarUrl: vote.voter.avatarUrl, name: vote.voter.displayName, radius: 14),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: vote.voter.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    TextSpan(
                      text: ' · ${vote.approve ? l10n.lockVoteApprove : l10n.lockVoteReject}',
                      style: TextStyle(color: vote.approve ? cs.primary : cs.onSurfaceVariant),
                    ),
                  ]),
                  style: theme.textTheme.bodyMedium,
                ),
                if (vote.comment != null && vote.comment!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text('“${vote.comment!}”', style: theme.textTheme.bodyMedium),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(formatLockTime(vote.createdAt), style: muted?.copyWith(fontFeatures: _tabular)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vote / cancel actions (thực hiện trong dialog, lỗi hiện ngay trong dialog)
// ─────────────────────────────────────────────────────────────────────────────

/// Hai nút bỏ phiếu hoặc lý do không được bỏ phiếu.
class LockVoteActions extends ConsumerWidget {
  final AccountLockRequestModel request;
  final double buttonHeight;

  const LockVoteActions({super.key, required this.request, this.buttonHeight = 40});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (!request.canVote) {
      final text = switch (request.voteBlockedReason) {
        LockVoteBlockedReason.proposer => l10n.lockVoteBlockedProposer,
        LockVoteBlockedReason.alreadyVoted => l10n.lockVoteBlockedAlreadyVoted,
        LockVoteBlockedReason.closed => l10n.lockVoteBlockedClosed,
        null => null,
      };
      if (text == null) return const SizedBox.shrink();
      return Text(text, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant));
    }

    final size = Size.fromHeight(buttonHeight);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _vote(context, ref, approve: false),
            style: OutlinedButton.styleFrom(minimumSize: size),
            child: Text(l10n.lockVoteReject),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: () => _vote(context, ref, approve: true),
            style: FilledButton.styleFrom(minimumSize: size, backgroundColor: cs.error, foregroundColor: cs.onError),
            child: Text(l10n.lockVoteApprove),
          ),
        ),
      ],
    );
  }

  Future<void> _vote(BuildContext context, WidgetRef ref, {required bool approve}) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final actions = ref.read(accountLockActionsProvider);
    final done = await showDialog<bool>(
      context: context,
      builder: (_) => _LockActionDialog(
        title: approve ? l10n.lockVoteApproveConfirmTitle : l10n.lockVoteRejectConfirmTitle,
        message: approve
            ? l10n.lockVoteApproveConfirmMessage(request.requiredApprovals, request.target.displayName)
            : l10n.lockVoteRejectConfirmMessage(request.requiredRejections),
        confirmLabel: approve ? l10n.lockVoteApprove : l10n.lockVoteReject,
        destructive: approve,
        withComment: true,
        onConfirm: (comment) => actions.vote(request, approve: approve, comment: comment),
      ),
    );
    if (done == true) messenger.showSnackBar(SnackBar(content: Text(l10n.lockVoteSubmitted)));
  }
}

Future<void> confirmCancelLockRequest(BuildContext context, WidgetRef ref, AccountLockRequestModel request) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final actions = ref.read(accountLockActionsProvider);
  final done = await showDialog<bool>(
    context: context,
    builder: (_) => _LockActionDialog(
      title: l10n.lockCancelAction,
      message: l10n.lockCancelConfirm(request.target.displayName),
      confirmLabel: l10n.lockCancelAction,
      onConfirm: (_) => actions.cancel(request),
    ),
  );
  if (done == true) messenger.showSnackBar(SnackBar(content: Text(l10n.lockCancelled)));
}

/// Dialog xác nhận tự gọi thao tác: hiện trạng thái đang gửi và lỗi ngay trong dialog
/// (SnackBar bị các lớp dialog / bottom sheet che). Trả `true` khi thành công.
class _LockActionDialog extends StatefulWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final bool destructive;
  final bool withComment;

  /// Trả `null` khi thành công, ngược lại là message lỗi (có thể rỗng).
  final Future<String?> Function(String comment) onConfirm;

  const _LockActionDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.onConfirm,
    this.destructive = false,
    this.withComment = false,
  });

  @override
  State<_LockActionDialog> createState() => _LockActionDialogState();
}

class _LockActionDialogState extends State<_LockActionDialog> {
  final _commentCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _submitting = true;
      _error = null;
    });
    String? error;
    try {
      error = await widget.onConfirm(_commentCtrl.text);
    } catch (_) {
      error = '';
    }
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _submitting = false;
      _error = error!.isNotEmpty ? error : l10n.lockActionFailed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AlertDialog(
      title: Text(widget.title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.message),
            if (widget.withComment) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _commentCtrl,
                enabled: !_submitting,
                maxLength: 500,
                maxLines: 3,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: l10n.lockVoteCommentHint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              LockInlineError(message: _error!),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          style: widget.destructive ? FilledButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError) : null,
          child: _submitting
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: widget.destructive ? cs.onError : cs.onPrimary,
                  ),
                )
              : Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

/// Lỗi hiện ngay trong form / dialog: icon đỏ nhỏ + câu mô tả (đỏ chỉ trên icon, không tô nền).
class LockInlineError extends StatelessWidget {
  final String message;

  const LockInlineError({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cs.error.withValues(alpha: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, size: 18, color: cs.error),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: theme.textTheme.bodySmall)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Opening the detail
// ─────────────────────────────────────────────────────────────────────────────

/// Màn hẹp: điện thoại → trang toàn màn hình (một vùng tại một thời điểm); web hẹp → dialog.
void showLockRequestDetail(BuildContext context, String requestId) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < _phoneBreakpoint) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LockRequestDetailPage(requestId: requestId)),
    );
    return;
  }
  showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 560, maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.88),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: LockRequestDetailPanel(
            requestId: requestId,
            onCloseOverlay: () => Navigator.pop(dialogContext),
          ),
        ),
      ),
    ),
  );
}

/// Trang chi tiết trên điện thoại: nội dung cuộn, hai nút bỏ phiếu ghim ở đáy (44px).
class LockRequestDetailPage extends ConsumerWidget {
  final String requestId;

  const LockRequestDetailPage({super.key, required this.requestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final request = ref.watch(lockRequestDetailProvider(requestId)).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.lockRequestsTitle)),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(lockRequestDetailProvider(requestId)),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [LockRequestDetailPanel(requestId: requestId, showVoteActions: false)],
        ),
      ),
      bottomNavigationBar: request == null || request.status != LockRequestStatus.pending
          ? null
          : Material(
              color: theme.colorScheme.surface,
              child: SafeArea(
                top: false,
                child: Container(
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.dividerColor))),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: LockVoteActions(request: request, buttonHeight: 44),
                ),
              ),
            ),
    );
  }
}
