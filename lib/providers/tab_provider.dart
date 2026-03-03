// lib/providers/tab_provider.dart
import 'package:flutter/material.dart';

class TabProvider extends ChangeNotifier {
  int _currentIndex = 0;
  bool _shouldRefreshArtworks = false;

  int get currentIndex => _currentIndex;
  bool get shouldRefreshArtworks => _shouldRefreshArtworks;

  void switchToTab(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void requestArtworkRefresh() {
    _shouldRefreshArtworks = true;
    notifyListeners();
  }

  void clearRefreshFlag() {
    _shouldRefreshArtworks = false;
  }
}