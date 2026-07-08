import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'lib/app_state.dart';

void main() {
  final user = AppUser(
    id: 'u-123',
    name: 'Test Name',
    username: 'test_user',
    password: 'password123',
    role: UserRole.worker,
  );

  final map = user.toMap();
  debugPrint('Map: $map');

  final jsonStr = jsonEncode(map);
  debugPrint('Json: $jsonStr');

  final decodedMap = jsonDecode(jsonStr);
  final unmappedUser = AppUser.fromMap(decodedMap);

  debugPrint('Successfully parsed: ${unmappedUser.username}');
}
