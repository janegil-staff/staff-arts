// lib/providers/artwork_provider.dart
import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../models/artwork_model.dart';
import '../services/api_service.dart';

class ArtworkProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<ArtworkModel> _artworks = [];
  List<ArtworkModel> _featured = [];
  bool _loading = false;
  String? _error;
  int _page = 1;
  bool _hasMore = true;

  List<ArtworkModel> get artworks => _artworks;
  List<ArtworkModel> get featured => _featured;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  Future<void> fetchArtworks({
    bool refresh = false,
    Map<String, dynamic>? filters,
  }) async {
    if (_loading) return;
    if (refresh) {
      _page = 1;
      _hasMore = true;
      _artworks = [];
    }
    if (!_hasMore) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final params = <String, dynamic>{
        'page': _page,
        'limit': 20,
        // ✅ don't send status=all — backend ignores unknown values
        // default is 'published', which is what we want
        ...?filters,
      };
      final res = await _api.get(ApiConfig.artworks, params: params);
      final body = res.data as Map<String, dynamic>;

      // ✅ API returns { success: true, data: [...] }
      final list = (body['data'] as List? ?? [])
          .map<ArtworkModel>((j) => ArtworkModel.fromJson(j as Map<String, dynamic>))
          .toList();

      _artworks.addAll(list);
      _hasMore = list.length >= 20;
      _page++;
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> fetchFeatured() async {
    try {
      final res = await _api.get(ApiConfig.artworks, params: {
        'featured': true,
        'limit': 10,
      });
      final body = res.data as Map<String, dynamic>;

      // ✅ same fix
      _featured = (body['data'] as List? ?? [])
          .map<ArtworkModel>((j) => ArtworkModel.fromJson(j as Map<String, dynamic>))
          .toList();

      notifyListeners();
    } catch (_) {}
  }

  Future<void> likeArtwork(String id) async {
    try {
      await _api.post(ApiConfig.artworkLike(id));
      notifyListeners();
    } catch (_) {}
  }
}