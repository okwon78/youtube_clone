import 'package:flutter/material.dart';

import '../services/auth_api.dart';
import '../services/social_auth.dart';

/// Shared submission plumbing for the auth screens. Owns the busy flag, runs an
/// async auth action inside a try/finally, and maps the common failures
/// ([SocialLoginCancelled], [AuthApiException], connection errors) to user
/// feedback so each page only has to describe the action itself.
mixin AuthSubmissionMixin<T extends StatefulWidget> on State<T> {
  bool _submitting = false;
  bool get submitting => _submitting;

  /// Runs [action] while showing the busy state. Returns false if it failed.
  /// [connectionError] is the message shown for unexpected (network) errors.
  Future<bool> runSubmission(
    Future<void> Function() action, {
    String connectionError = '서버에 연결할 수 없습니다. 게이트웨이(8080)가 켜져 있는지 확인하세요.',
  }) async {
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    try {
      await action();
      return true;
    } on SocialLoginCancelled {
      // User dismissed the provider dialog — stay on the page silently.
    } on AuthApiException catch (e) {
      showError(e.message);
    } catch (e, st) {
      debugPrint('[auth] 실패: $e\n$st');
      showError(connectionError);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
    return false;
  }

  /// Shows [message] in a snack bar, replacing any currently visible one.
  void showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
