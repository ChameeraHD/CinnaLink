import 'dart:convert';
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
  print('Map: $map');

  final jsonStr = jsonEncode(map);
  print('Json: $jsonStr');

  final decodedMap = jsonDecode(jsonStr);
  final unmappedUser = AppUser.fromMap(decodedMap);

  print('Successfully parsed: ${unmappedUser.username}');
}
