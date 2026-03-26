import 'package:expense_tracker/models/wallet.dart';
import 'package:expense_tracker/providers/envelope_provider.dart';
import 'package:expense_tracker/services/database_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

class FakeWallet extends Fake implements Wallet {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeWallet());
  });

  group('EnvelopeProvider', () {
    late MockDatabaseService mockDatabaseService;
    late EnvelopeProvider provider;

    setUp(() {
      mockDatabaseService = MockDatabaseService();
      provider = EnvelopeProvider(databaseService: mockDatabaseService);
    });

    test('loadWallets loads wallets and clears error', () async {
      final wallets = [
        Wallet(
          id: 1,
          name: 'An uong',
          iconCode: 1,
          budget: 200000,
          balance: 150000,
        ),
      ];

      when(
        () => mockDatabaseService.getWallets(),
      ).thenAnswer((_) async => wallets);

      await provider.loadWallets();

      expect(provider.isLoading, false);
      expect(provider.errorMessage, isNull);
      expect(provider.wallets, wallets);
      verify(() => mockDatabaseService.getWallets()).called(1);
    });

    test('addEnvelope throws ArgumentError when name is empty', () async {
      expect(
        () => provider.addEnvelope('   ', 123, 1000),
        throwsA(isA<ArgumentError>()),
      );

      verifyNever(() => mockDatabaseService.insertWallet(any()));
    });

    test(
      'addEnvelope throws StateError when duplicate normalized name exists',
      () async {
        provider.wallets = [
          Wallet(
            id: 10,
            name: '  du lich   he  ',
            iconCode: 1,
            budget: 5000,
            balance: 5000,
          ),
        ];

        expect(
          () => provider.addEnvelope('Du   Lich He', 12, 10000),
          throwsA(isA<StateError>()),
        );

        verifyNever(() => mockDatabaseService.insertWallet(any()));
      },
    );

    test('updateEnvelope recalculates balance from spent amount', () async {
      provider.wallets = [
        Wallet(
          id: 5,
          name: 'Mua sam',
          iconCode: 1,
          budget: 100000,
          balance: 70000,
        ),
      ];

      when(
        () => mockDatabaseService.updateWalletBasic(any()),
      ).thenAnswer((_) async => 1);
      when(() => mockDatabaseService.getWallets()).thenAnswer(
        (_) async => [
          Wallet(
            id: 5,
            name: 'Mua sam moi',
            iconCode: 2,
            budget: 150000,
            balance: 120000,
          ),
        ],
      );
      when(() => mockDatabaseService.getWalletById(5)).thenAnswer(
        (_) async => Wallet(
          id: 5,
          name: 'Mua sam moi',
          iconCode: 2,
          budget: 150000,
          balance: 120000,
        ),
      );
      when(
        () => mockDatabaseService.getTransactionsByWallet(5),
      ).thenAnswer((_) async => []);

      await provider.updateEnvelope(
        id: 5,
        name: 'Mua sam moi',
        iconCode: 2,
        budget: 150000,
      );

      final captured = verify(
        () => mockDatabaseService.updateWalletBasic(captureAny()),
      ).captured;
      final updatedWallet = captured.single as Wallet;

      expect(updatedWallet.id, 5);
      expect(updatedWallet.name, 'Mua sam moi');
      expect(updatedWallet.budget, 150000);
      expect(updatedWallet.balance, 120000);
      verify(() => mockDatabaseService.getWallets()).called(1);
      verify(() => mockDatabaseService.getWalletById(5)).called(1);
      verify(() => mockDatabaseService.getTransactionsByWallet(5)).called(1);
    });

    test('deleteEnvelope clears selection and reloads wallets', () async {
      provider.selectedWallet = Wallet(
        id: 1,
        name: 'Cu',
        iconCode: 0,
        budget: 1,
        balance: 1,
      );
      provider.selectedWalletTransactions = [
        {'id': 1, 'amount': 1000},
      ];

      when(
        () => mockDatabaseService.deleteWallet(1),
      ).thenAnswer((_) async => 1);
      when(() => mockDatabaseService.getWallets()).thenAnswer((_) async => []);

      await provider.deleteEnvelope(1);

      expect(provider.selectedWallet, isNull);
      expect(provider.selectedWalletTransactions, isEmpty);
      verify(() => mockDatabaseService.deleteWallet(1)).called(1);
      verify(() => mockDatabaseService.getWallets()).called(1);
    });
  });
}
