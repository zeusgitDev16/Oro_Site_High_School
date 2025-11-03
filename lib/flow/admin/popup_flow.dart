import 'dart:async';
import 'package:flutter/material.dart';

/// Manages popup state and behavior for admin dashboard
/// Optimized click-based approach with smooth transitions
/// Singleton pattern ensures only one instance exists globally
class PopupFlow extends ChangeNotifier {
  // State variables
  OverlayEntry? _popupOverlay;
  int? _currentPopupIndex;

  // Singleton instance
  static final PopupFlow _instance = PopupFlow._internal();

  // Private constructor
  PopupFlow._internal();

  // Factory constructor returns the singleton instance
  factory PopupFlow() {
    return _instance;
  }

  // Getters
  int? get currentPopupIndex => _currentPopupIndex;
  bool get isPopupVisible => _popupOverlay != null;

  /// Get the singleton instance (for use in popup widgets)
  static PopupFlow get instance => _instance;

  /// Shows a popup at the specified position
  /// Automatically closes previous popup and opens new one
  void showPopup(
    BuildContext context,
    Widget popup, {
    required double top,
    required int index,
    double sidebarWidth = 200, // Default for admin dashboard, can be overridden
  }) {
    // ONLY toggle if clicking the SAME item that's currently open
    if (_currentPopupIndex == index && _popupOverlay != null) {
      hidePopup();
      return;
    }

    // If switching to a DIFFERENT popup, remove the old one first
    if (_popupOverlay != null && _currentPopupIndex != index) {
      _popupOverlay?.remove();
      _popupOverlay = null;
    }

    // Set current popup index BEFORE creating the overlay
    _currentPopupIndex = index;

    // Create and show the new popup
    _popupOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Transparent background to detect clicks outside
          // Start AFTER the sidebar to avoid capturing sidebar clicks
          Positioned(
            left: sidebarWidth,
            top: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: hidePopup,
              child: Container(color: Colors.transparent),
            ),
          ),
          // The actual popup - absorb pointer to prevent background clicks
          Positioned(
            left: sidebarWidth + 20,
            top: top,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                // Prevent clicks from reaching background
              },
              child: Material(color: Colors.transparent, child: popup),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_popupOverlay!);
    notifyListeners();
  }

  /// Hides the current popup immediately
  void hidePopup() {
    if (_popupOverlay != null) {
      _popupOverlay?.remove();
      _popupOverlay = null;
      _currentPopupIndex = null;
      notifyListeners();
    }
  }

  /// Cleanup resources
  /// Note: Since this is a singleton, dispose should NOT be called
  /// The instance persists for the lifetime of the app
  @override
  void dispose() {
    // Don't call super.dispose() to prevent the singleton from being disposed
    // Just clear the popup
    _popupOverlay?.remove();
    _popupOverlay = null;
    _currentPopupIndex = null;
  }
}
