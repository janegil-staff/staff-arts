// lib/screens/shows/event_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tab_provider.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../profile/artist_profile_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final String id;
  const EventDetailScreen({super.key, required this.id});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _event;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _api.get(ApiConfig.event(widget.id));
      final data = res.data as Map<String, dynamic>;
      setState(() {
        _event = data['data'] ?? data;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Event load error: $e');
      setState(() => _loading = false);
    }
  }

  String? _getCoverUrl() {
    if (_event == null) return null;
    final cover = _event!['coverImage'];
    if (cover is Map) return cover['url']?.toString();
    if (cover is String && cover.isNotEmpty) return cover;
    return null;
  }

  void _handleShare() {
    if (_event != null) {
      Share.share('Check out "${_event!['title'] ?? ''}"');
    }
  }

  void _navigateToProfile(dynamic profileObj) {
    if (profileObj == null) return;
    if (profileObj is! Map<String, dynamic>) return;
    final profileId = (profileObj['_id'] ?? '').toString();
    if (profileId.isEmpty) return;
    final auth = context.read<AuthProvider>();
    final myId = (auth.user?.id ?? '').toString();
    if (myId.isNotEmpty && profileId == myId) {
      // Own profile — switch to profile tab
      Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
      context.read<TabProvider>().switchToTab(4);
      return;
    }
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => ArtistProfileScreen(userId: profileId)),
    );
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('Delete Event',
            style:
                TextStyle(color: AppColors.text, fontWeight: FontWeight.w300)),
        content: const Text('This action cannot be undone.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textMuted))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _api.delete(ApiConfig.event(widget.id));
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
        }
      }
    }
  }

  bool get _isOwner {
    final auth = context.read<AuthProvider>();
    final currentUser = auth.user;
    final org = _event?['organizer'];
    if (currentUser == null || org == null) return false;
    final orgId = (org is Map ? org['_id'] ?? org : org).toString();
    return orgId == currentUser.id;
  }

  String _formatPrice(num price, String currency) {
    final fmt = NumberFormat.simpleCurrency(name: currency, decimalDigits: 0);
    return fmt.format(price);
  }

  String _eventTypeLabel(String? type) {
    const labels = {
      'opening': 'Opening',
      'workshop': 'Workshop',
      'talk': 'Talk',
      'fair': 'Art Fair',
      'concert': 'Concert',
      'dj_set': 'DJ Set',
      'live_performance': 'Live Performance',
      'open_mic': 'Open Mic',
      'festival': 'Festival',
      'album_release': 'Album Release',
      'other': 'Event',
    };
    return labels[type] ?? 'Event';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          backgroundColor: AppColors.bg,
          body:
              Center(child: CircularProgressIndicator(color: AppColors.teal)));
    }
    if (_event == null) {
      return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(backgroundColor: AppColors.bg),
          body: const Center(
              child: Text('Event not found',
                  style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: AppFontSize.md,
                      fontWeight: FontWeight.w300))));
    }

    final ev = _event!;
    final coverUrl = _getCoverUrl();
    final org = ev['organizer'];
    final dfDate = DateFormat('EEEE, MMM d');
    final dfTime = DateFormat('h:mm a');

    String dateStr = '';
    String timeStr = '';
    if (ev['date'] != null) {
      final dt = DateTime.parse(ev['date']);
      dateStr = dfDate.format(dt);
      timeStr = dfTime.format(dt);
      if (ev['endDate'] != null) {
        timeStr += ' — ${dfTime.format(DateTime.parse(ev['endDate']))}';
      }
    }

    final rsvpCount = (ev['rsvps'] is List) ? (ev['rsvps'] as List).length : 0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: coverUrl != null ? 340 : 180,
            pinned: true,
            backgroundColor: AppColors.bg,
            leading: _circleButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.pop(context)),
            actions: [
              _circleButton(icon: Icons.share_rounded, onTap: _handleShare),
              const SizedBox(width: AppSpacing.sm),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: coverUrl != null
                  ? Stack(fit: StackFit.expand, children: [
                      Image.network(coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _heroPlaceholder()),
                      Container(
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  stops: const [
                            0.0,
                            0.3,
                            1.0
                          ],
                                  colors: [
                            Colors.black.withValues(alpha: 0.4),
                            Colors.transparent,
                            AppColors.bg,
                          ]))),
                    ])
                  : _heroPlaceholder(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              _typeBadge(ev['type'], ev['category']),
                              if (ev['isOnline'] == true) ...[
                                const SizedBox(width: AppSpacing.sm),
                                _onlineBadge()
                              ],
                            ]),
                            const SizedBox(height: AppSpacing.md),
                            Text(ev['title'] ?? '',
                                style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w200,
                                    color: AppColors.text,
                                    letterSpacing: 0.5,
                                    height: 1.2)),
                          ]),
                    ),

                    // Date card
                    if (dateStr.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xl),
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl),
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(color: AppColors.borderLight)),
                        child: Row(children: [
                          Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                  color: AppColors.teal.withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md)),
                              child: const Icon(Icons.calendar_today_rounded,
                                  size: 20, color: AppColors.teal)),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(dateStr,
                                    style: const TextStyle(
                                        fontSize: AppFontSize.md,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.text)),
                                if (timeStr.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(timeStr,
                                      style: const TextStyle(
                                          fontSize: AppFontSize.sm,
                                          color: AppColors.textSecondary)),
                                ],
                              ])),
                        ]),
                      ),
                    ],

                    // Info pills
                    const SizedBox(height: AppSpacing.lg),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      child: Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            if (ev['location'] != null &&
                                ev['location'].toString().isNotEmpty)
                              _infoPill(
                                  Icons.location_on_outlined, ev['location']),
                            if (ev['isFree'] == true)
                              _infoPill(Icons.confirmation_num_outlined, 'Free')
                            else if (ev['price'] != null && ev['price'] > 0)
                              _infoPill(
                                  Icons.confirmation_num_outlined,
                                  _formatPrice(
                                      ev['price'], ev['currency'] ?? 'NOK')),
                            if (rsvpCount > 0)
                              _infoPill(Icons.people_outline_rounded,
                                  '$rsvpCount attending'),
                            if (ev['maxAttendees'] != null)
                              _infoPill(Icons.group_outlined,
                                  'Max ${ev['maxAttendees']}'),
                          ]),
                    ),

                    // Organizer
                    if (org is Map<String, dynamic>) ...[
                      const SizedBox(height: AppSpacing.xl),
                      _buildOrganizer(org),
                    ],

                    // Actions
                    const SizedBox(height: AppSpacing.xl),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      child: Row(children: [
                        Expanded(
                            child: _actionBtn('RSVP',
                                icon: Icons.check_circle_outline_rounded,
                                filled: true)),
                        if (ev['isOnline'] == true && ev['link'] != null) ...[
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                              child: _actionBtn('Join Online',
                                  icon: Icons.open_in_new_rounded)),
                        ],
                      ]),
                    ),

                    // Description
                    if (ev['description'] != null &&
                        ev['description'].toString().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxl),
                      _sectionBlock('ABOUT',
                          child: Text(ev['description'],
                              style: const TextStyle(
                                  fontSize: AppFontSize.md,
                                  color: AppColors.textSecondary,
                                  height: 1.7,
                                  fontWeight: FontWeight.w300))),
                    ],

                    // Delete
                    if (_isOwner) ...[
                      const SizedBox(height: AppSpacing.xxl),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl),
                        child: GestureDetector(
                          onTap: _handleDelete,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.08),
                                border: Border.all(
                                    color:
                                        AppColors.error.withValues(alpha: 0.2)),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md)),
                            child: const Center(
                                child: Text('Delete Event',
                                    style: TextStyle(
                                        fontSize: AppFontSize.md,
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w500))),
                          ),
                        ),
                      ),
                    ],
                  ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: Colors.white)),
      ),
    );
  }

  Widget _heroPlaceholder() {
    return Container(
        color: AppColors.surfaceDim,
        child: const Center(
            child: Icon(Icons.event_rounded,
                size: 48, color: AppColors.textMuted)));
  }

  Widget _typeBadge(String? type, String? category) {
    final isMusicType = [
      'concert',
      'dj_set',
      'live_performance',
      'open_mic',
      'festival',
      'album_release'
    ].contains(type);
    final color = isMusicType ? const Color(0xFF818cf8) : AppColors.teal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.full)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(isMusicType ? Icons.music_note_rounded : Icons.event_rounded,
            size: 12, color: color),
        const SizedBox(width: 4),
        Text(_eventTypeLabel(type).toUpperCase(),
            style: TextStyle(
                fontSize: AppFontSize.xxs,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 1.5)),
      ]),
    );
  }

  Widget _onlineBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
          color: const Color(0xFF60a5fa).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.full)),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.language_rounded, size: 12, color: Color(0xFF60a5fa)),
        SizedBox(width: 4),
        Text('ONLINE',
            style: TextStyle(
                fontSize: AppFontSize.xxs,
                fontWeight: FontWeight.w600,
                color: Color(0xFF60a5fa),
                letterSpacing: 1.5)),
      ]),
    );
  }

  Widget _infoPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: AppColors.borderLight)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Flexible(
            child: Text(text,
                style: const TextStyle(
                    fontSize: AppFontSize.sm, color: AppColors.textSecondary),
                overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  Widget _buildOrganizer(Map<String, dynamic> org) {
    return GestureDetector(
      onTap: () => _navigateToProfile(org),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.borderLight)),
        child: Row(children: [
          if (org['avatar'] != null)
            ClipOval(
                child: Image.network(org['avatar'],
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _avatarPlaceholder(48)))
          else
            _avatarPlaceholder(48),
          const SizedBox(width: AppSpacing.md),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('ORGANIZER',
                    style: TextStyle(
                        fontSize: AppFontSize.xxs,
                        color: AppColors.textMuted,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                Text(org['displayName'] ?? org['name'] ?? '',
                    style: const TextStyle(
                        fontSize: AppFontSize.md,
                        fontWeight: FontWeight.w500,
                        color: AppColors.text)),
              ])),
          const Icon(Icons.chevron_right_rounded,
              size: 20, color: AppColors.textMuted),
        ]),
      ),
    );
  }

  Widget _avatarPlaceholder(double size) {
    return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
            shape: BoxShape.circle, color: AppColors.surfaceDim),
        child: Icon(Icons.person_rounded,
            size: size * 0.5, color: AppColors.textMuted));
  }

  Widget _actionBtn(String label,
      {IconData? icon, bool filled = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
            color: filled ? AppColors.teal : Colors.transparent,
            border: Border.all(
                color: filled ? AppColors.teal : AppColors.borderLight),
            borderRadius: BorderRadius.circular(AppRadius.md)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (icon != null) ...[
            Icon(icon,
                size: 18,
                color: filled ? AppColors.textInverse : AppColors.text),
            const SizedBox(width: 8),
          ],
          Text(label,
              style: TextStyle(
                  fontSize: AppFontSize.sm,
                  fontWeight: FontWeight.w600,
                  color: filled ? AppColors.textInverse : AppColors.text)),
        ]),
      ),
    );
  }

  Widget _sectionBlock(String label, {required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                fontSize: AppFontSize.xxs,
                letterSpacing: 2.5,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.md),
        child,
      ]),
    );
  }
}
