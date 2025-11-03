import 'package:flutter/material.dart';
import 'package:oro_site_high_school/flow/admin/popup_flow.dart';

/// NavigatorObserver that automatically closes popups when routes change
class PopupNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Close popup for any route change (singleton instance always available)
    // Only log if there's actually a popup to close
    if (PopupFlow.instance.isPopupVisible) {
      print('[PopupObserver] Route pushed - closing popup');
    }
    PopupFlow.instance.hidePopup();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Close popup when a route is popped
    if (PopupFlow.instance.isPopupVisible) {
      print('[PopupObserver] Route popped - closing popup');
    }
    PopupFlow.instance.hidePopup();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Close popup when a route is removed
    if (PopupFlow.instance.isPopupVisible) {
      print('[PopupObserver] Route removed - closing popup');
    }
    PopupFlow.instance.hidePopup();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    // Close popup when a route is replaced
    if (PopupFlow.instance.isPopupVisible) {
      print('[PopupObserver] Route replaced - closing popup');
    }
    PopupFlow.instance.hidePopup();
  }
}
