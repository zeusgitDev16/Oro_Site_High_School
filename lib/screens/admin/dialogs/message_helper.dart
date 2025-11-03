import 'package:flutter/material.dart';
import 'package:oro_site_high_school/flow/admin/messages/messages_state.dart';
import 'package:oro_site_high_school/screens/admin/dialogs/compose_message_dialog.dart';
import 'package:oro_site_high_school/screens/admin/dialogs/inbox_dialog.dart';

/// Helper class for messaging actions
/// Use this to open message/chat dialogs from anywhere in the app
class MessageHelper {
  /// Open inbox dialog
  static void openInbox(BuildContext context, MessagesState state) {
    showDialog(
      context: context,
      builder: (_) => InboxDialog(state: state),
    );
  }

  /// Open compose dialog to message a specific user
  static void messageUser(BuildContext context, MessagesState state, User user) {
    showDialog(
      context: context,
      builder: (_) => ComposeMessageDialog(
        state: state,
        // Pre-select the user
      ),
    );
  }

  /// Open compose dialog for broadcast
  static void composeBroadcast(BuildContext context, MessagesState state) {
    showDialog(
      context: context,
      builder: (_) => ComposeMessageDialog(state: state),
    );
  }
}
