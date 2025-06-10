import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Indicates whether the user is currently walking according to the
/// pedometer status stream.
final walkingProvider = StateProvider<bool>((ref) => false);
