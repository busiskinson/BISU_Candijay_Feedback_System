import 'package:flutter/material.dart';

/// Lets any screen show a SnackBar on whichever screen is currently
/// visible — even right after a navigation change, where the old
/// screen's own ScaffoldMessenger would otherwise be gone.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
GlobalKey<ScaffoldMessengerState>();