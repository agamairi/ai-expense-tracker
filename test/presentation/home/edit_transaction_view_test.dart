import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_expense_tracker/presentation/home/edit_transaction_view.dart';
import 'package:ai_expense_tracker/domain/models/transaction.dart' as model;
import 'package:ai_expense_tracker/domain/models/enums.dart';

void main() {
  setUpAll(() {
    // Mock the path_provider channel to avoid MissingPluginException when AppDatabase._internal() calls getApplicationDocumentsDirectory()
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return '.';
        }
        if (methodCall.method == 'getTemporaryDirectory') {
          return '.';
        }
        return null;
      },
    );
  });

  Widget createTestWidget({model.Transaction? transaction}) {
    return MaterialApp(
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          settings: RouteSettings(
            name: '/',
            arguments: transaction,
          ),
          builder: (context) => const EditTransactionView(),
        );
      },
    );
  }

  // NOTE: This test is narrowly scoped to title-text/mode-detection behavior 
  // because EditTransactionView tightly couples to AppDatabase.instance and its 
  // file-backed _internal() constructor. Mocking the database for full widget tests 
  // would require deeper refactoring (e.g., dependency injection).
  testWidgets('displays "Add Transaction" when in create mode (no arguments)', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(transaction: null));
    await tester.pumpAndSettle();
    
    expect(find.text('Add Transaction'), findsOneWidget);
    expect(find.text('Edit Transaction'), findsNothing);
  });

  testWidgets('displays "Edit Transaction" when in edit mode (transaction provided)', (WidgetTester tester) async {
    final transaction = model.Transaction(
      id: 1,
      timestamp: DateTime.now(),
      amount: 10.0,
      currency: 'USD',
      type: TransactionType.debit,
      merchant: 'Test',
      category: TransactionCategory.dining,
      accountId: 1,
      rawText: 'raw',
      status: TransactionStatus.pending,
    );
    
    await tester.pumpWidget(createTestWidget(transaction: transaction));
    await tester.pumpAndSettle();
    
    expect(find.text('Edit Transaction'), findsOneWidget);
    expect(find.text('Add Transaction'), findsNothing);
  });
}
