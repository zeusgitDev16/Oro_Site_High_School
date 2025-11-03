import 'package:flutter/material.dart';
import 'package:oro_site_high_school/flow/admin/popup_flow.dart';

/// Helper class to manage popup navigation
class PopupHelper {
  /// Navigate to a screen and close the popup
  static void navigateAndClosePopup(
    BuildContext context,
    Widget destination,
  ) {
    // Close the popup first (singleton instance always available)
    PopupFlow.instance.hidePopup();
    
    // Then navigate to the destination using root navigator
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  /// Close popup without navigation
  static void closePopup() {
    PopupFlow.instance.hidePopup();
  }

  /// Show a dialog and keep popup open (for dialogs like "Add Course")
  static Future<T?> showDialogKeepPopup<T>(
    BuildContext context,
    Widget dialog,
  ) {
    return showDialog<T>(
      context: context,
      builder: (_) => dialog,
    );
  }
}
