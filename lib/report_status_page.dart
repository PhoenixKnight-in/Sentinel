import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_page.dart'
    as h; // AppColors, serif(), _BottomBar, _PageHeader, route constants

// ─────────────────────────────────────────────────────────────────────────────
//  DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────
enum ReportStatus { submitted, review, investigating, resolved, closed }

enum ReportSeverity { low, medium, high }

class Report {
  final String caseId;
  final DateTime filedAt;
  final String title;
  final String description;
  final ReportStatus status;
  final ReportSeverity severity;
  final String? location;
  final List<StatusUpdate> updates;

  const Report({
    required this.caseId,
    required this.filedAt,
    required this.title,
    required this.description,
    required this.status,
    required this.severity,
    this.location,
    required this.updates,
  });
}

class StatusUpdate {
  final ReportStatus status;
  final String message;
  final DateTime timestamp;
  const StatusUpdate({
    required this.status,
    required this.message,
    required this.timestamp,
  });
}

// ── Sample data ───────────────────────────────────────────────────────────────
final List<Report> kSampleReports = [
  Report(
    caseId: 'TSC-2026-33235',
    filedAt: DateTime(2026, 3, 30, 16, 8),
    title: 'Harassment reported via chat',
    description:
        'Reported via quick chat. Surroundings: Alone. Silent alert: Yes.',
    status: ReportStatus.submitted,
    severity: ReportSeverity.medium,
    updates: [
      StatusUpdate(
        status: ReportStatus.submitted,
        message: 'Your complaint has been received and assigned a case number.',
        timestamp: DateTime(2026, 3, 30, 16, 8),
      ),
    ],
  ),
  Report(
    caseId: 'TSC-2026-39588',
    filedAt: DateTime(2026, 3, 30, 15, 45),
    title: 'Stalking reported via chat',
    description:
        'Reported via quick chat. Surroundings: Alone. Silent alert: Yes.',
    status: ReportStatus.submitted,
    severity: ReportSeverity.medium,
    updates: [
      StatusUpdate(
        status: ReportStatus.submitted,
        message: 'Your complaint has been received and assigned a case number.',
        timestamp: DateTime(2026, 3, 30, 15, 45),
      ),
    ],
  ),
  Report(
    caseId: 'TSC-2026-50546',
    filedAt: DateTime(2026, 3, 30, 14, 22),
    title: 'Harassment reported via chat',
    description:
        'Reported via quick chat. Surroundings: In a crowd. Silent alert: No.',
    status: ReportStatus.submitted,
    severity: ReportSeverity.medium,
    updates: [
      StatusUpdate(
        status: ReportStatus.submitted,
        message: 'Your complaint has been received and assigned a case number.',
        timestamp: DateTime(2026, 3, 30, 14, 22),
      ),
    ],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
//  REPORT STATUS LIST PAGE
// ─────────────────────────────────────────────────────────────────────────────
class ReportStatusPage extends StatefulWidget {
  const ReportStatusPage({super.key});

  @override
  State<ReportStatusPage> createState() => _ReportStatusPageState();
}

class _ReportStatusPageState extends State<ReportStatusPage> {
  ReportStatus? _filter;

  List<Report> get _filtered => _filter == null
      ? kSampleReports
      : kSampleReports.where((r) => r.status == _filter).toList();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: h.AppColors.bg,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Reports',
                      style: h.serif(size: 24, weight: FontWeight.w700),
                    ),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: h.AppColors.whiteSubtle,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: h.AppColors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),

              Container(height: 1, color: h.AppColors.whiteDim),

              const SizedBox(height: 14),

              // ── Filter chips ────────────────────────────────────────────
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _FilterChip(
                      label: 'All',
                      active: _filter == null,
                      onTap: () => setState(() => _filter = null),
                    ),
                    _FilterChip(
                      label: 'Submitted',
                      active: _filter == ReportStatus.submitted,
                      onTap: () =>
                          setState(() => _filter = ReportStatus.submitted),
                    ),
                    _FilterChip(
                      label: 'Review',
                      active: _filter == ReportStatus.review,
                      onTap: () =>
                          setState(() => _filter = ReportStatus.review),
                    ),
                    _FilterChip(
                      label: 'Investigating',
                      active: _filter == ReportStatus.investigating,
                      onTap: () =>
                          setState(() => _filter = ReportStatus.investigating),
                    ),
                    _FilterChip(
                      label: 'Resolved',
                      active: _filter == ReportStatus.resolved,
                      onTap: () =>
                          setState(() => _filter = ReportStatus.resolved),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── List ────────────────────────────────────────────────────
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) => _ReportCard(
                    report: _filtered[i],
                    onTap: () => Navigator.push(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => ReportDetailPage(report: _filtered[i]),
                      ),
                    ),
                  ),
                ),
              ),

              h.BottomBar(currentRoute: h.kRouteReportStatus),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  REPORT CARD
// ─────────────────────────────────────────────────────────────────────────────
class _ReportCard extends StatelessWidget {
  final Report report;
  final VoidCallback onTap;
  const _ReportCard({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: h.AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: h.AppColors.whiteDim, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: case ID + status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _iconForTitle(report.title),
                      size: 13,
                      color: h.AppColors.whiteSubtle,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      report.caseId,
                      style: h.serif(
                        size: 11,
                        color: h.AppColors.whiteSubtle,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(report.filedAt),
                      style: h.serif(size: 10, color: h.AppColors.whiteDim),
                    ),
                  ],
                ),
                _StatusBadge(status: report.status),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              report.title,
              style: h.serif(size: 15, weight: FontWeight.w600),
            ),
            const SizedBox(height: 5),
            Text(
              report.description,
              style: h.serif(
                size: 12,
                color: h.AppColors.whiteSubtle,
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // Bottom row: location + severity
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 12,
                      color: h.AppColors.whiteDim,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      report.location ?? 'Web preview — location unavailable',
                      style: h.serif(size: 10, color: h.AppColors.whiteDim),
                    ),
                  ],
                ),
                _SeverityBadge(severity: report.severity),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForTitle(String t) => t.toLowerCase().contains('stalk')
      ? Icons.remove_red_eye_outlined
      : Icons.warning_amber_rounded;
}

// ─────────────────────────────────────────────────────────────────────────────
//  REPORT DETAIL PAGE
// ─────────────────────────────────────────────────────────────────────────────
class ReportDetailPage extends StatelessWidget {
  final Report report;
  const ReportDetailPage({super.key, required this.report});

  static const List<ReportStatus> _lifecycle = [
    ReportStatus.submitted,
    ReportStatus.review,
    ReportStatus.investigating,
    ReportStatus.resolved,
    ReportStatus.closed,
  ];

  static const Map<ReportStatus, String> _lifecycleLabel = {
    ReportStatus.submitted: 'Submitted',
    ReportStatus.review: 'Under Review',
    ReportStatus.investigating: 'Investigating',
    ReportStatus.resolved: 'Resolved',
    ReportStatus.closed: 'Closed',
  };

  int get _currentIdx => _lifecycle.indexOf(report.status);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: h.AppColors.bg,
        body: SafeArea(
          child: Column(
            children: [
              // ── Header ─────────────────────────────────────────────────
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: h.AppColors.white,
                            size: 18,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                report.caseId,
                                style: h.serif(
                                  size: 13,
                                  color: h.AppColors.whiteSubtle,
                                  weight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                report.title,
                                style: h.serif(
                                  size: 16,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _StatusBadge(status: report.status),
                        const SizedBox(width: 12),
                      ],
                    ),
                  ),
                  Container(height: 1, color: h.AppColors.whiteDim),
                ],
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Info card ────────────────────────────────────
                      _SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _TagChip(label: _categoryLabel(report.title)),
                                const SizedBox(width: 8),
                                _SeverityBadge(severity: report.severity),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              report.description,
                              style: h.serif(
                                size: 13,
                                color: h.AppColors.whiteSubtle,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(height: 1, color: h.AppColors.whiteDim),
                            const SizedBox(height: 12),
                            _DetailRow(
                              icon: Icons.location_on_outlined,
                              text:
                                  report.location ??
                                  'Web preview — location unavailable',
                            ),
                            const SizedBox(height: 8),
                            _DetailRow(
                              icon: Icons.schedule_outlined,
                              text: 'Filed ${_formatDateLong(report.filedAt)}',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Complaint lifecycle ───────────────────────────
                      _SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Complaint Lifecycle',
                              style: h.serif(
                                size: 13,
                                weight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 18),
                            ..._lifecycle.asMap().entries.map((e) {
                              final done = e.key <= _currentIdx;
                              final isLast = e.key == _lifecycle.length - 1;
                              return _LifecycleStep(
                                label: _lifecycleLabel[e.value]!,
                                done: done,
                                isLast: isLast,
                              );
                            }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Status updates ────────────────────────────────
                      _SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status Updates',
                              style: h.serif(
                                size: 13,
                                weight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 14),
                            ...report.updates.map(
                              (u) => _UpdateItem(update: u),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              h.BottomBar(currentRoute: h.kRouteReportStatus),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SMALL REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: h.AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: h.AppColors.whiteDim, width: 1),
      ),
      child: child,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ReportStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final col = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: col.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(shape: BoxShape.circle, color: col),
          ),
          const SizedBox(width: 5),
          Text(
            _statusLabel(status),
            style: h.serif(
              size: 10,
              color: col,
              weight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final ReportSeverity severity;
  const _SeverityBadge({required this.severity});

  @override
  Widget build(BuildContext context) {
    final col = _severityColor(severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: col.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        _severityLabel(severity).toUpperCase(),
        style: h.serif(
          size: 9,
          color: col,
          weight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: h.AppColors.whiteSubtle, width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: h.serif(
          size: 9,
          color: h.AppColors.whiteSubtle,
          weight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: active ? h.AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? h.AppColors.white : h.AppColors.whiteDim,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: h.serif(
            size: 12,
            weight: FontWeight.w600,
            color: active ? h.AppColors.bg : h.AppColors.whiteSubtle,
          ),
        ),
      ),
    );
  }
}

class _LifecycleStep extends StatelessWidget {
  final String label;
  final bool done;
  final bool isLast;
  const _LifecycleStep({
    required this.label,
    required this.done,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? h.AppColors.white : Colors.transparent,
                  border: Border.all(
                    color: done ? h.AppColors.white : h.AppColors.whiteDim,
                    width: 1.5,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1,
                    color: done
                        ? h.AppColors.whiteSubtle
                        : h.AppColors.whiteDim,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              label,
              style: h.serif(
                size: 13,
                weight: done ? FontWeight.w600 : FontWeight.w400,
                color: done ? h.AppColors.white : h.AppColors.whiteDim,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdateItem extends StatelessWidget {
  final StatusUpdate update;
  const _UpdateItem({required this.update});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 6, right: 12),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: h.AppColors.white,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _statusLabel(update.status),
                style: h.serif(size: 13, weight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                update.message,
                style: h.serif(
                  size: 12,
                  color: h.AppColors.whiteSubtle,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDateLong(update.timestamp),
                style: h.serif(size: 10, color: h.AppColors.whiteDim),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DetailRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: h.AppColors.whiteDim),
        const SizedBox(width: 7),
        Text(text, style: h.serif(size: 12, color: h.AppColors.whiteSubtle)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HELPERS
// ─────────────────────────────────────────────────────────────────────────────
Color _statusColor(ReportStatus s) {
  switch (s) {
    case ReportStatus.submitted:
      return h.AppColors.amber;
    case ReportStatus.review:
      return h.AppColors.info;
    case ReportStatus.investigating:
      return h.AppColors.purple;
    case ReportStatus.resolved:
      return h.AppColors.success;
    case ReportStatus.closed:
      return h.AppColors.whiteDim;
  }
}

String _statusLabel(ReportStatus s) {
  switch (s) {
    case ReportStatus.submitted:
      return 'Submitted';
    case ReportStatus.review:
      return 'Under Review';
    case ReportStatus.investigating:
      return 'Investigating';
    case ReportStatus.resolved:
      return 'Resolved';
    case ReportStatus.closed:
      return 'Closed';
  }
}

Color _severityColor(ReportSeverity s) {
  switch (s) {
    case ReportSeverity.low:
      return h.AppColors.success;
    case ReportSeverity.medium:
      return h.AppColors.amber;
    case ReportSeverity.high:
      return h.AppColors.danger;
  }
}

String _severityLabel(ReportSeverity s) {
  switch (s) {
    case ReportSeverity.low:
      return 'Low';
    case ReportSeverity.medium:
      return 'Medium';
    case ReportSeverity.high:
      return 'High';
  }
}

String _categoryLabel(String title) {
  if (title.toLowerCase().contains('harass')) return 'Harassment';
  if (title.toLowerCase().contains('stalk')) return 'Stalking';
  return 'Incident';
}

String _formatDate(DateTime dt) {
  const m = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${m[dt.month - 1]} ${dt.day}, ${dt.year}';
}

String _formatDateLong(DateTime dt) {
  const m = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final h = dt.hour > 12
      ? dt.hour - 12
      : dt.hour == 0
      ? 12
      : dt.hour;
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  final min = dt.minute.toString().padLeft(2, '0');
  return '${m[dt.month - 1]} ${dt.day}, ${dt.year}  $h:$min $ampm';
}
