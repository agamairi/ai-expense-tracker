import 'package:flutter_test/flutter_test.dart';
import 'package:ai_expense_tracker/domain/services/slm_engine_service.dart';
import 'package:ai_expense_tracker/domain/repositories/app_rule_repository.dart';
import 'package:ai_expense_tracker/domain/models/app_rule.dart';
import 'package:ai_expense_tracker/domain/models/enums.dart';

class FakeAppRuleRepository implements AppRuleRepository {
  @override
  Future<List<AppRule>> getAllRules() async => [];
  @override
  Future<int> insertRule(AppRule rule) async => 0;
  @override
  Future<void> updateRule(AppRule rule) async {}
  @override
  Future<void> deleteRule(int id) async {}
}

void main() {
  late SlmEngineService service;

  setUp(() {
    service = SlmEngineService(FakeAppRuleRepository());
  });

  test('parses well-formed response correctly', () {
    final args = {
      'amount': '42.50',
      'currency': 'USD',
      'transaction_type': 'DEBIT',
      'merchant': 'Starbucks',
      'category': 'Dining'
    };
    final result = service.parseResponse(args, 'raw text');
    expect(result, isNotNull);
    expect(result!.amount, 42.50);
    expect(result.currency, 'USD');
    expect(result.type, TransactionType.debit);
    expect(result.merchant, 'Starbucks');
    expect(result.category, TransactionCategory.dining);
  });

  test('falls back to USD when CURRENCY is an unsubstituted placeholder', () {
    final args = {
      'amount': '42.50',
      'currency': '<str>',
      'transaction_type': 'DEBIT',
      'merchant': 'Starbucks',
      'category': 'Dining'
    };
    final result = service.parseResponse(args, 'raw');
    expect(result!.currency, 'USD');
  });

  test('falls back to Unknown when MERCHANT is empty or <str>', () {
    var args = {
      'amount': '10',
      'currency': 'USD',
      'transaction_type': 'DEBIT',
      'merchant': '<str>',
      'category': 'Dining'
    };
    var result = service.parseResponse(args, 'raw');
    expect(result!.merchant, 'Unknown');
    
    args['merchant'] = '';
    result = service.parseResponse(args, 'raw');
    expect(result!.merchant, 'Unknown');
  });

  test('normalizes lowercase or mixed-case currency to uppercase', () {
    final args = {
      'amount': '10',
      'currency': 'usd',
      'transaction_type': 'DEBIT',
      'merchant': 'X',
      'category': 'Dining'
    };
    final result = service.parseResponse(args, 'raw');
    expect(result!.currency, 'USD');
    
    args['currency'] = 'Usd';
    final result2 = service.parseResponse(args, 'raw');
    expect(result2!.currency, 'USD');
  });

  test('falls back to 0 when AMOUNT is malformed', () {
    final args = {
      'amount': 'bad',
      'currency': 'USD',
      'transaction_type': 'DEBIT',
      'merchant': 'X',
      'category': 'Dining'
    };
    final result = service.parseResponse(args, 'raw');
    expect(result!.amount, 0.0);
  });

  test('falls back to other when CATEGORY is unrecognized', () {
    final args = {
      'amount': '10',
      'currency': 'USD',
      'transaction_type': 'DEBIT',
      'merchant': 'X',
      'category': 'bad_category'
    };
    final result = service.parseResponse(args, 'raw');
    expect(result!.category, TransactionCategory.other);
  });

  test('parses CREDIT correctly and defaults to DEBIT otherwise', () {
    final argsCredit = {
      'amount': '10',
      'currency': 'USD',
      'transaction_type': 'CREDIT',
      'merchant': 'X',
      'category': 'Dining'
    };
    final resultCredit = service.parseResponse(argsCredit, 'raw');
    expect(resultCredit!.type, TransactionType.credit);

    final argsDebit = {
      'amount': '10',
      'currency': 'USD',
      'transaction_type': 'something_else',
      'merchant': 'X',
      'category': 'Dining'
    };
    final resultDebit = service.parseResponse(argsDebit, 'raw');
    expect(resultDebit!.type, TransactionType.debit);
    
    final argsMissing = {
      'amount': '10',
      'currency': 'USD',
      'merchant': 'X',
      'category': 'Dining'
    };
    final resultMissing = service.parseResponse(argsMissing, 'raw');
    expect(resultMissing!.type, TransactionType.debit);
  });
  test('falls back to regex extraction when amount is 0', () {
    final args = {
      'currency': 'USD',
      'transaction_type': 'DEBIT',
      'merchant': 'Subway',
      'category': 'Dining'
    };
    
    // First match is the answer if no $
    final result1 = service.parseResponse(args, 'spent 42.50 at Subway');
    expect(result1!.amount, 42.50);

    // Adjacent $ is preferred
    final result2 = service.parseResponse(args, 'Order 1234: paid 100\$ at Subway');
    expect(result2!.amount, 100.0);
    
    // Adjacent $ is preferred over first match
    final result3 = service.parseResponse(args, 'Date 2023, paid \$15.99 at Subway');
    expect(result3!.amount, 15.99);
  });

  test('forces TransactionType.credit when category is Income even if transaction_type is DEBIT', () {
    final args = {
      'amount': '1000',
      'currency': 'USD',
      'transaction_type': 'DEBIT',
      'merchant': 'Test',
      'category': 'Income'
    };
    final result = service.parseResponse(args, 'I got 1000 as income');
    expect(result, isNotNull);
    expect(result!.amount, 1000.0);
    expect(result.type, TransactionType.credit);
    expect(result.category, TransactionCategory.income);
  });
}
