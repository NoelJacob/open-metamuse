import 'package:material_ui/material_ui.dart';

import 'internal/api.dart';

mixin RunAsync<T extends StatefulWidget> on State<T> {
  bool _busy = false;
  String? _error;

  bool get busyAsync => _busy;
  String? get errorAsync => _error;

  set busyAsync(bool x) {
    if (mounted) {
      setState(() {
        _busy = x;
      });
    }
  }

  set errorAsync(String x) {
    if (mounted) {
      setState(() {
        _error = x;
      });
    }
  }

  void clearAsync() {
    if (mounted) {
      setState(() {
        _busy = false;
        _error = null;
      });
    }
  }

  List<Widget> errorMessageAsync() {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return [
      if (errorAsync != null) ...[
        const SizedBox(height: 12),
        Text(errorAsync!, style: tt.labelSmall!.copyWith(color: cs.error)),
      ],
    ];
  }

  Future<void> runAsync(Future<void> Function() fn) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await fn();
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }
}
