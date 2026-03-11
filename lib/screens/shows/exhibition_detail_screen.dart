// lib/screens/shows/exhibition_detail_screen.dart
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

class ExhibitionDetailScreen extends StatefulWidget {
  final String id;
  const ExhibitionDetailScreen({super.key, required this.id});

  @override
  State<ExhibitionDetailScreen> createState() => _ExhibitionDetailScreenState();
}

class _ExhibitionDetailScreenState extends State<ExhibitionDetailScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _ex;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _api.get(ApiConfig.exhibition(widget.id));
      final data = res.data as Map<String, dynamic>;
      setState(() {
        _ex = data['data'] ?? data;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Exhibition load error: $e');
      setState(() => _loading = false);
    }
  }

  String? _getCoverUrl() {
    if (_ex == null) return null;
    final cover = _ex!['coverImage'];
    if (cover is Map) return cover['url']?.toString();
    if (cover is String && cover.isNotEmpty) return cover;
    return null;
  }

  void _handleShare() {
    if (_ex != null) Share.share('Check out "${_ex!['title']}"');
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
        title: const Text('Delete Exhibition',
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
        await _api.delete(ApiConfig.exhibition(widget.id));
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  bool get _isOwner {
    final auth = context.read<AuthProvider>();
    final currentUser = auth.user;
    final org = _ex?['organizer'];
    if (currentUser == null || org == null) return false;
    final orgId = (org is Map ? org['_id'] ?? org : org).toString();
    return orgId == currentUser.id;
  }

  String _formatPrice(num price, String currency) {
    return NumberFormat.simpleCurrency(name: currency, decimalDigits: 0)
        .format(price);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          backgroundColor: AppColors.bg,
          body:
              Center(child: CircularProgressIndicator(color: AppColors.teal)));
    }
    if (_ex == null) {
      return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(backgroundColor: AppColors.bg),
          body: const Center(
              child: Text('Exhibition not found',
                  style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: AppFontSize.md,
                      fontWeight: FontWeight.w300))));
    }

    final ex = _ex!;
    final coverUrl = _getCoverUrl();
    final org = ex['organizer'];
    final dfShort = DateFormat('MMM d');
    final dfFull = DateFormat('MMM d, yyyy');

    var dateStr = '';
    if (ex['startDate'] != null) {
      dateStr = dfShort.format(DateTime.parse(ex['startDate']));
      if (ex['endDate'] != null)
        dateStr += ' — ${dfFull.format(DateTime.parse(ex['endDate']))}';
    }

    final artists = (ex['artists'] as List?)?.cast<dynamic>() ?? [];
    final artworks = (ex['artworks'] as List?)?.cast<dynamic>() ?? [];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: coverUrl != null ? 360 : 200,
          pinned: true,
          backgroundColor: AppColors.bg,
          leading: _circleButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.pop(context)),
          actions: [
            _circleButton(icon: Icons.share_rounded, onTap: _handleShare),
            const SizedBox(width: AppSpacing.sm)
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
                          AppColors.bg
                        ]))),
                  ])
                : _heroPlaceholder(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 120),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ex['status'] != null)
                        Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: _statusBadge(ex['status'])),
                      Text(ex['title'] ?? '',
                          style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w200,
                              color: AppColors.text,
                              letterSpacing: 0.5,
                              height: 1.2)),
                      if (ex['isFeatured'] == true)
                        Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            child: Row(children: [
                              Icon(Icons.star_rounded,
                                  size: 16, color: AppColors.amber),
                              const SizedBox(width: 4),
                              Text('Featured',
                                  style: TextStyle(
                                      fontSize: AppFontSize.sm,
                                      color: AppColors.amber,
                                      fontWeight: FontWeight.w500)),
                            ])),
                    ]),
              ),

              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      if (dateStr.isNotEmpty)
                        _infoPill(Icons.calendar_today_rounded, dateStr),
                      if (ex['location'] != null &&
                          ex['location'].toString().isNotEmpty)
                        _infoPill(Icons.location_on_outlined, ex['location']),
                      if (ex['isVirtual'] == true)
                        _infoPill(Icons.language_rounded, 'Virtual'),
                      if (ex['isFree'] == true)
                        _infoPill(Icons.confirmation_num_outlined, 'Free')
                      else if (ex['ticketPrice'] != null)
                        _infoPill(
                            Icons.confirmation_num_outlined,
                            _formatPrice(
                                ex['ticketPrice'], ex['currency'] ?? 'NOK')),
                      if (ex['views'] != null)
                        _infoPill(
                            Icons.visibility_outlined, '${ex['views']} views'),
                    ]),
              ),

              // Organizer
              if (org is Map<String, dynamic>) ...[
                const SizedBox(height: AppSpacing.xl),
                _buildOrganizer(org)
              ],

              // Actions
              const SizedBox(height: AppSpacing.xl),
              Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Row(children: [
                    if (ex['virtualUrl'] != null && ex['isVirtual'] == true)
                      Expanded(
                          child: _actionBtn('Visit Online',
                              icon: Icons.open_in_new_rounded, filled: true)),
                    if (ex['virtualUrl'] != null &&
                        ex['isVirtual'] == true &&
                        ex['isFree'] != true &&
                        ex['ticketPrice'] != null)
                      const SizedBox(width: AppSpacing.md),
                    if (ex['isFree'] != true && ex['ticketPrice'] != null)
                      Expanded(
                          child: _actionBtn('Get Tickets',
                              icon: Icons.confirmation_num_outlined,
                              filled: true)),
                  ])),

              // Description
              if (ex['description'] != null &&
                  ex['description'].toString().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxl),
                _sectionBlock('ABOUT',
                    child: Text(ex['description'],
                        style: const TextStyle(
                            fontSize: AppFontSize.md,
                            color: AppColors.textSecondary,
                            height: 1.7,
                            fontWeight: FontWeight.w300))),
              ],

              // Artists
              if (artists.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                _sectionBlock('ARTISTS',
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: artists.map((a) {
                        final artist =
                            a is Map<String, dynamic> ? a : {'_id': a};
                        return _artistChip(artist);
                      }).toList(),
                    )),
              ],

              // Artworks
              if (artworks.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                _sectionHeader('ARTWORKS'),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 200,
                  child: ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    scrollDirection: Axis.horizontal,
                    itemCount: artworks.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.md),
                    itemBuilder: (_, i) => _artworkCard(artworks[i]),
                  ),
                ),
              ],

              // Delete
              if (_isOwner) ...[
                const SizedBox(height: AppSpacing.xxl),
                Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
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
                                child: Text('Delete Exhibition',
                                    style: TextStyle(
                                        fontSize: AppFontSize.md,
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w500)))))),
              ],
            ]),
          ),
        ),
      ]),
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
                child: Icon(icon, size: 20, color: Colors.white))));
  }

  Widget _heroPlaceholder() => Container(
      color: AppColors.surfaceDim,
      child: const Center(
          child:
              Icon(Icons.image_rounded, size: 48, color: AppColors.textMuted)));

  Widget _statusBadge(String status) {
    final configs = {
      'upcoming': (AppColors.teal.withValues(alpha: 0.12), AppColors.teal),
      'ongoing': (const Color(0xFF1e2d4a), const Color(0xFF60a5fa)),
      'past': (AppColors.surfaceDim, AppColors.textMuted),
      'cancelled': (AppColors.error.withValues(alpha: 0.12), AppColors.error),
    };
    final entry = configs[status];
    final bg = entry?.$1 ?? AppColors.teal.withValues(alpha: 0.12);
    final fg = entry?.$2 ?? AppColors.teal;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(AppRadius.full)),
        child: Text(status.toUpperCase(),
            style: TextStyle(
                fontSize: AppFontSize.xxs,
                fontWeight: FontWeight.w600,
                color: fg,
                letterSpacing: 1.5)));
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
        ]));
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
            ])));
  }

  Widget _avatarPlaceholder(double size) => Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
          shape: BoxShape.circle, color: AppColors.surfaceDim),
      child: Icon(Icons.person_rounded,
          size: size * 0.5, color: AppColors.textMuted));

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
                const SizedBox(width: 8)
              ],
              Text(label,
                  style: TextStyle(
                      fontSize: AppFontSize.sm,
                      fontWeight: FontWeight.w600,
                      color: filled ? AppColors.textInverse : AppColors.text)),
            ])));
  }

  Widget _sectionHeader(String label) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Text(label,
          style: const TextStyle(
              fontSize: AppFontSize.xxs,
              letterSpacing: 2.5,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600)));

  Widget _sectionBlock(String label, {required Widget child}) => Padding(
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
      ]));

  Widget _artistChip(Map<String, dynamic> artist) {
    return GestureDetector(
        onTap: () => _navigateToProfile(artist),
        child: Container(
            padding:
                const EdgeInsets.only(left: 4, right: 14, top: 4, bottom: 4),
            decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(color: AppColors.borderLight)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (artist['avatar'] != null)
                ClipOval(
                    child: Image.network(artist['avatar'],
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _avatarPlaceholder(32)))
              else
                _avatarPlaceholder(32),
              const SizedBox(width: AppSpacing.sm),
              Text(artist['displayName'] ?? artist['name'] ?? '',
                  style: const TextStyle(
                      fontSize: AppFontSize.sm,
                      color: AppColors.text,
                      fontWeight: FontWeight.w500)),
            ])));
  }

  Widget _artworkCard(dynamic item) {
    final art =
        item is Map<String, dynamic> ? item : <String, dynamic>{'_id': item};
    final img = (art['images'] as List?)?.isNotEmpty == true
        ? art['images'][0]['url']
        : null;
    return GestureDetector(
        onTap: () {},
        child: SizedBox(
            width: 140,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: img != null
                      ? Image.network(img,
                          width: 140,
                          height: 160,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              width: 140,
                              height: 160,
                              color: AppColors.surfaceDim))
                      : Container(
                          width: 140,
                          height: 160,
                          color: AppColors.surfaceDim,
                          child: const Center(
                              child: Icon(Icons.image_rounded,
                                  size: 28, color: AppColors.textMuted)))),
              const SizedBox(height: AppSpacing.sm),
              Text(art['title'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: AppFontSize.sm,
                      color: AppColors.text,
                      fontWeight: FontWeight.w400)),
            ])));
  }
}
