import 'package:flutter_test/flutter_test.dart';
import 'package:siber_kalkan/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('JSON serialization/deserialization', () {
      final user = UserModel(
        uid: 'user-123',
        role: 'elderly',
        displayName: 'Ahmet Bey',
        pairedWith: 'guardian-456',
        pairingCode: '123456',
        fcmToken: 'token-abc',
      );

      final json = user.toJson();
      final restored = UserModel.fromJson(json);

      expect(restored.uid, 'user-123');
      expect(restored.role, 'elderly');
      expect(restored.displayName, 'Ahmet Bey');
      expect(restored.pairedWith, 'guardian-456');
      expect(restored.pairingCode, '123456');
      expect(restored.fcmToken, 'token-abc');
    });

    test('isElderly and isGuardian return correct values', () {
      final elderly = UserModel(uid: '1', role: 'elderly', displayName: 'x');
      expect(elderly.isElderly, true);
      expect(elderly.isGuardian, false);

      final guardian = UserModel(uid: '2', role: 'guardian', displayName: 'x');
      expect(guardian.isElderly, false);
      expect(guardian.isGuardian, true);
    });

    test('isPaired returns correct values', () {
      final unpaired = UserModel(uid: '1', role: 'elderly', displayName: 'x');
      expect(unpaired.isPaired, false);

      final paired = UserModel(
        uid: '1', role: 'elderly', displayName: 'x', pairedWith: 'abc',
      );
      expect(paired.isPaired, true);

      final emptyPair = UserModel(
        uid: '1', role: 'elderly', displayName: 'x', pairedWith: '',
      );
      expect(emptyPair.isPaired, false);
    });

    test('copyWith preserves and overrides fields', () {
      final original = UserModel(
        uid: '1', role: 'elderly', displayName: 'Ali',
      );
      final updated = original.copyWith(role: 'guardian', displayName: 'Veli');
      expect(updated.uid, '1');
      expect(updated.role, 'guardian');
      expect(updated.displayName, 'Veli');
    });
  });
}
