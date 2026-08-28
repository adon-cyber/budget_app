import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authProvider = StreamProvider<User?>((ref) async* {
  try {
    yield Supabase.instance.client.auth.currentSession?.user;
    await for (final event in Supabase.instance.client.auth.onAuthStateChange) {
      yield event.session?.user;
    }
  } on AuthException {
    yield null;
  } catch (_) {
    yield null;
  }
});
