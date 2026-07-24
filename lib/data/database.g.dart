// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, Transaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 3,
      maxTextLength: 3,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TransactionType, int> type =
      GeneratedColumn<int>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<TransactionType>($TransactionsTable.$convertertype);
  static const VerificationMeta _merchantMeta = const VerificationMeta(
    'merchant',
  );
  @override
  late final GeneratedColumn<String> merchant = GeneratedColumn<String>(
    'merchant',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TransactionCategory, int>
  category = GeneratedColumn<int>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<TransactionCategory>($TransactionsTable.$convertercategory);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawTextMeta = const VerificationMeta(
    'rawText',
  );
  @override
  late final GeneratedColumn<String> rawText = GeneratedColumn<String>(
    'raw_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TransactionStatus, int> status =
      GeneratedColumn<int>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<TransactionStatus>($TransactionsTable.$converterstatus);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    timestamp,
    amount,
    currency,
    type,
    merchant,
    category,
    accountId,
    rawText,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Transaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('merchant')) {
      context.handle(
        _merchantMeta,
        merchant.isAcceptableOrUnknown(data['merchant']!, _merchantMeta),
      );
    } else if (isInserting) {
      context.missing(_merchantMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('raw_text')) {
      context.handle(
        _rawTextMeta,
        rawText.isAcceptableOrUnknown(data['raw_text']!, _rawTextMeta),
      );
    } else if (isInserting) {
      context.missing(_rawTextMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      type: $TransactionsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}type'],
        )!,
      ),
      merchant: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merchant'],
      )!,
      category: $TransactionsTable.$convertercategory.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}category'],
        )!,
      ),
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}account_id'],
      )!,
      rawText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_text'],
      )!,
      status: $TransactionsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}status'],
        )!,
      ),
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TransactionType, int, int> $convertertype =
      const EnumIndexConverter<TransactionType>(TransactionType.values);
  static JsonTypeConverter2<TransactionCategory, int, int> $convertercategory =
      const EnumIndexConverter<TransactionCategory>(TransactionCategory.values);
  static JsonTypeConverter2<TransactionStatus, int, int> $converterstatus =
      const EnumIndexConverter<TransactionStatus>(TransactionStatus.values);
}

class Transaction extends DataClass implements Insertable<Transaction> {
  final int id;
  final DateTime timestamp;
  final double amount;
  final String currency;
  final TransactionType type;
  final String merchant;
  final TransactionCategory category;
  final int accountId;
  final String rawText;
  final TransactionStatus status;
  const Transaction({
    required this.id,
    required this.timestamp,
    required this.amount,
    required this.currency,
    required this.type,
    required this.merchant,
    required this.category,
    required this.accountId,
    required this.rawText,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['amount'] = Variable<double>(amount);
    map['currency'] = Variable<String>(currency);
    {
      map['type'] = Variable<int>(
        $TransactionsTable.$convertertype.toSql(type),
      );
    }
    map['merchant'] = Variable<String>(merchant);
    {
      map['category'] = Variable<int>(
        $TransactionsTable.$convertercategory.toSql(category),
      );
    }
    map['account_id'] = Variable<int>(accountId);
    map['raw_text'] = Variable<String>(rawText);
    {
      map['status'] = Variable<int>(
        $TransactionsTable.$converterstatus.toSql(status),
      );
    }
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      timestamp: Value(timestamp),
      amount: Value(amount),
      currency: Value(currency),
      type: Value(type),
      merchant: Value(merchant),
      category: Value(category),
      accountId: Value(accountId),
      rawText: Value(rawText),
      status: Value(status),
    );
  }

  factory Transaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transaction(
      id: serializer.fromJson<int>(json['id']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      amount: serializer.fromJson<double>(json['amount']),
      currency: serializer.fromJson<String>(json['currency']),
      type: $TransactionsTable.$convertertype.fromJson(
        serializer.fromJson<int>(json['type']),
      ),
      merchant: serializer.fromJson<String>(json['merchant']),
      category: $TransactionsTable.$convertercategory.fromJson(
        serializer.fromJson<int>(json['category']),
      ),
      accountId: serializer.fromJson<int>(json['accountId']),
      rawText: serializer.fromJson<String>(json['rawText']),
      status: $TransactionsTable.$converterstatus.fromJson(
        serializer.fromJson<int>(json['status']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'amount': serializer.toJson<double>(amount),
      'currency': serializer.toJson<String>(currency),
      'type': serializer.toJson<int>(
        $TransactionsTable.$convertertype.toJson(type),
      ),
      'merchant': serializer.toJson<String>(merchant),
      'category': serializer.toJson<int>(
        $TransactionsTable.$convertercategory.toJson(category),
      ),
      'accountId': serializer.toJson<int>(accountId),
      'rawText': serializer.toJson<String>(rawText),
      'status': serializer.toJson<int>(
        $TransactionsTable.$converterstatus.toJson(status),
      ),
    };
  }

  Transaction copyWith({
    int? id,
    DateTime? timestamp,
    double? amount,
    String? currency,
    TransactionType? type,
    String? merchant,
    TransactionCategory? category,
    int? accountId,
    String? rawText,
    TransactionStatus? status,
  }) => Transaction(
    id: id ?? this.id,
    timestamp: timestamp ?? this.timestamp,
    amount: amount ?? this.amount,
    currency: currency ?? this.currency,
    type: type ?? this.type,
    merchant: merchant ?? this.merchant,
    category: category ?? this.category,
    accountId: accountId ?? this.accountId,
    rawText: rawText ?? this.rawText,
    status: status ?? this.status,
  );
  Transaction copyWithCompanion(TransactionsCompanion data) {
    return Transaction(
      id: data.id.present ? data.id.value : this.id,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      amount: data.amount.present ? data.amount.value : this.amount,
      currency: data.currency.present ? data.currency.value : this.currency,
      type: data.type.present ? data.type.value : this.type,
      merchant: data.merchant.present ? data.merchant.value : this.merchant,
      category: data.category.present ? data.category.value : this.category,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      rawText: data.rawText.present ? data.rawText.value : this.rawText,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('type: $type, ')
          ..write('merchant: $merchant, ')
          ..write('category: $category, ')
          ..write('accountId: $accountId, ')
          ..write('rawText: $rawText, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    timestamp,
    amount,
    currency,
    type,
    merchant,
    category,
    accountId,
    rawText,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.id == this.id &&
          other.timestamp == this.timestamp &&
          other.amount == this.amount &&
          other.currency == this.currency &&
          other.type == this.type &&
          other.merchant == this.merchant &&
          other.category == this.category &&
          other.accountId == this.accountId &&
          other.rawText == this.rawText &&
          other.status == this.status);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<int> id;
  final Value<DateTime> timestamp;
  final Value<double> amount;
  final Value<String> currency;
  final Value<TransactionType> type;
  final Value<String> merchant;
  final Value<TransactionCategory> category;
  final Value<int> accountId;
  final Value<String> rawText;
  final Value<TransactionStatus> status;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.type = const Value.absent(),
    this.merchant = const Value.absent(),
    this.category = const Value.absent(),
    this.accountId = const Value.absent(),
    this.rawText = const Value.absent(),
    this.status = const Value.absent(),
  });
  TransactionsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime timestamp,
    required double amount,
    required String currency,
    required TransactionType type,
    required String merchant,
    required TransactionCategory category,
    required int accountId,
    required String rawText,
    required TransactionStatus status,
  }) : timestamp = Value(timestamp),
       amount = Value(amount),
       currency = Value(currency),
       type = Value(type),
       merchant = Value(merchant),
       category = Value(category),
       accountId = Value(accountId),
       rawText = Value(rawText),
       status = Value(status);
  static Insertable<Transaction> custom({
    Expression<int>? id,
    Expression<DateTime>? timestamp,
    Expression<double>? amount,
    Expression<String>? currency,
    Expression<int>? type,
    Expression<String>? merchant,
    Expression<int>? category,
    Expression<int>? accountId,
    Expression<String>? rawText,
    Expression<int>? status,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timestamp != null) 'timestamp': timestamp,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (type != null) 'type': type,
      if (merchant != null) 'merchant': merchant,
      if (category != null) 'category': category,
      if (accountId != null) 'account_id': accountId,
      if (rawText != null) 'raw_text': rawText,
      if (status != null) 'status': status,
    });
  }

  TransactionsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? timestamp,
    Value<double>? amount,
    Value<String>? currency,
    Value<TransactionType>? type,
    Value<String>? merchant,
    Value<TransactionCategory>? category,
    Value<int>? accountId,
    Value<String>? rawText,
    Value<TransactionStatus>? status,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      merchant: merchant ?? this.merchant,
      category: category ?? this.category,
      accountId: accountId ?? this.accountId,
      rawText: rawText ?? this.rawText,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(
        $TransactionsTable.$convertertype.toSql(type.value),
      );
    }
    if (merchant.present) {
      map['merchant'] = Variable<String>(merchant.value);
    }
    if (category.present) {
      map['category'] = Variable<int>(
        $TransactionsTable.$convertercategory.toSql(category.value),
      );
    }
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (rawText.present) {
      map['raw_text'] = Variable<String>(rawText.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(
        $TransactionsTable.$converterstatus.toSql(status.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('type: $type, ')
          ..write('merchant: $merchant, ')
          ..write('category: $category, ')
          ..write('accountId: $accountId, ')
          ..write('rawText: $rawText, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }
}

class $AppRulesTable extends AppRules with TableInfo<$AppRulesTable, AppRule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _merchantRegexMeta = const VerificationMeta(
    'merchantRegex',
  );
  @override
  late final GeneratedColumn<String> merchantRegex = GeneratedColumn<String>(
    'merchant_regex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TransactionCategory, int>
  assignedCategory =
      GeneratedColumn<int>(
        'assigned_category',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<TransactionCategory>(
        $AppRulesTable.$converterassignedCategory,
      );
  @override
  List<GeneratedColumn> get $columns => [id, merchantRegex, assignedCategory];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppRule> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('merchant_regex')) {
      context.handle(
        _merchantRegexMeta,
        merchantRegex.isAcceptableOrUnknown(
          data['merchant_regex']!,
          _merchantRegexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_merchantRegexMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppRule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppRule(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      merchantRegex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merchant_regex'],
      )!,
      assignedCategory: $AppRulesTable.$converterassignedCategory.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}assigned_category'],
        )!,
      ),
    );
  }

  @override
  $AppRulesTable createAlias(String alias) {
    return $AppRulesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TransactionCategory, int, int>
  $converterassignedCategory = const EnumIndexConverter<TransactionCategory>(
    TransactionCategory.values,
  );
}

class AppRule extends DataClass implements Insertable<AppRule> {
  final int id;
  final String merchantRegex;
  final TransactionCategory assignedCategory;
  const AppRule({
    required this.id,
    required this.merchantRegex,
    required this.assignedCategory,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['merchant_regex'] = Variable<String>(merchantRegex);
    {
      map['assigned_category'] = Variable<int>(
        $AppRulesTable.$converterassignedCategory.toSql(assignedCategory),
      );
    }
    return map;
  }

  AppRulesCompanion toCompanion(bool nullToAbsent) {
    return AppRulesCompanion(
      id: Value(id),
      merchantRegex: Value(merchantRegex),
      assignedCategory: Value(assignedCategory),
    );
  }

  factory AppRule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppRule(
      id: serializer.fromJson<int>(json['id']),
      merchantRegex: serializer.fromJson<String>(json['merchantRegex']),
      assignedCategory: $AppRulesTable.$converterassignedCategory.fromJson(
        serializer.fromJson<int>(json['assignedCategory']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'merchantRegex': serializer.toJson<String>(merchantRegex),
      'assignedCategory': serializer.toJson<int>(
        $AppRulesTable.$converterassignedCategory.toJson(assignedCategory),
      ),
    };
  }

  AppRule copyWith({
    int? id,
    String? merchantRegex,
    TransactionCategory? assignedCategory,
  }) => AppRule(
    id: id ?? this.id,
    merchantRegex: merchantRegex ?? this.merchantRegex,
    assignedCategory: assignedCategory ?? this.assignedCategory,
  );
  AppRule copyWithCompanion(AppRulesCompanion data) {
    return AppRule(
      id: data.id.present ? data.id.value : this.id,
      merchantRegex: data.merchantRegex.present
          ? data.merchantRegex.value
          : this.merchantRegex,
      assignedCategory: data.assignedCategory.present
          ? data.assignedCategory.value
          : this.assignedCategory,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppRule(')
          ..write('id: $id, ')
          ..write('merchantRegex: $merchantRegex, ')
          ..write('assignedCategory: $assignedCategory')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, merchantRegex, assignedCategory);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppRule &&
          other.id == this.id &&
          other.merchantRegex == this.merchantRegex &&
          other.assignedCategory == this.assignedCategory);
}

class AppRulesCompanion extends UpdateCompanion<AppRule> {
  final Value<int> id;
  final Value<String> merchantRegex;
  final Value<TransactionCategory> assignedCategory;
  const AppRulesCompanion({
    this.id = const Value.absent(),
    this.merchantRegex = const Value.absent(),
    this.assignedCategory = const Value.absent(),
  });
  AppRulesCompanion.insert({
    this.id = const Value.absent(),
    required String merchantRegex,
    required TransactionCategory assignedCategory,
  }) : merchantRegex = Value(merchantRegex),
       assignedCategory = Value(assignedCategory);
  static Insertable<AppRule> custom({
    Expression<int>? id,
    Expression<String>? merchantRegex,
    Expression<int>? assignedCategory,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (merchantRegex != null) 'merchant_regex': merchantRegex,
      if (assignedCategory != null) 'assigned_category': assignedCategory,
    });
  }

  AppRulesCompanion copyWith({
    Value<int>? id,
    Value<String>? merchantRegex,
    Value<TransactionCategory>? assignedCategory,
  }) {
    return AppRulesCompanion(
      id: id ?? this.id,
      merchantRegex: merchantRegex ?? this.merchantRegex,
      assignedCategory: assignedCategory ?? this.assignedCategory,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (merchantRegex.present) {
      map['merchant_regex'] = Variable<String>(merchantRegex.value);
    }
    if (assignedCategory.present) {
      map['assigned_category'] = Variable<int>(
        $AppRulesTable.$converterassignedCategory.toSql(assignedCategory.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppRulesCompanion(')
          ..write('id: $id, ')
          ..write('merchantRegex: $merchantRegex, ')
          ..write('assignedCategory: $assignedCategory')
          ..write(')'))
        .toString();
  }
}

class $AccountsTable extends Accounts with TableInfo<$AccountsTable, Account> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _balanceMeta = const VerificationMeta(
    'balance',
  );
  @override
  late final GeneratedColumn<double> balance = GeneratedColumn<double>(
    'balance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 3,
      maxTextLength: 3,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, balance, currency];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Account> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('balance')) {
      context.handle(
        _balanceMeta,
        balance.isAcceptableOrUnknown(data['balance']!, _balanceMeta),
      );
    } else if (isInserting) {
      context.missing(_balanceMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Account map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Account(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      balance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}balance'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class Account extends DataClass implements Insertable<Account> {
  final int id;
  final String name;
  final double balance;
  final String currency;
  const Account({
    required this.id,
    required this.name,
    required this.balance,
    required this.currency,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['balance'] = Variable<double>(balance);
    map['currency'] = Variable<String>(currency);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      name: Value(name),
      balance: Value(balance),
      currency: Value(currency),
    );
  }

  factory Account.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      balance: serializer.fromJson<double>(json['balance']),
      currency: serializer.fromJson<String>(json['currency']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'balance': serializer.toJson<double>(balance),
      'currency': serializer.toJson<String>(currency),
    };
  }

  Account copyWith({
    int? id,
    String? name,
    double? balance,
    String? currency,
  }) => Account(
    id: id ?? this.id,
    name: name ?? this.name,
    balance: balance ?? this.balance,
    currency: currency ?? this.currency,
  );
  Account copyWithCompanion(AccountsCompanion data) {
    return Account(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      balance: data.balance.present ? data.balance.value : this.balance,
      currency: data.currency.present ? data.currency.value : this.currency,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Account(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('balance: $balance, ')
          ..write('currency: $currency')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, balance, currency);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Account &&
          other.id == this.id &&
          other.name == this.name &&
          other.balance == this.balance &&
          other.currency == this.currency);
}

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<int> id;
  final Value<String> name;
  final Value<double> balance;
  final Value<String> currency;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.balance = const Value.absent(),
    this.currency = const Value.absent(),
  });
  AccountsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required double balance,
    required String currency,
  }) : name = Value(name),
       balance = Value(balance),
       currency = Value(currency);
  static Insertable<Account> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<double>? balance,
    Expression<String>? currency,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (balance != null) 'balance': balance,
      if (currency != null) 'currency': currency,
    });
  }

  AccountsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<double>? balance,
    Value<String>? currency,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (balance.present) {
      map['balance'] = Variable<double>(balance.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('balance: $balance, ')
          ..write('currency: $currency')
          ..write(')'))
        .toString();
  }
}

class $BudgetsTable extends Budgets with TableInfo<$BudgetsTable, Budget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<TransactionCategory, int>
  category = GeneratedColumn<int>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<TransactionCategory>($BudgetsTable.$convertercategory);
  static const VerificationMeta _monthlyLimitMeta = const VerificationMeta(
    'monthlyLimit',
  );
  @override
  late final GeneratedColumn<double> monthlyLimit = GeneratedColumn<double>(
    'monthly_limit',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, category, monthlyLimit];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budgets';
  @override
  VerificationContext validateIntegrity(
    Insertable<Budget> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('monthly_limit')) {
      context.handle(
        _monthlyLimitMeta,
        monthlyLimit.isAcceptableOrUnknown(
          data['monthly_limit']!,
          _monthlyLimitMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_monthlyLimitMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Budget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Budget(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      category: $BudgetsTable.$convertercategory.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}category'],
        )!,
      ),
      monthlyLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monthly_limit'],
      )!,
    );
  }

  @override
  $BudgetsTable createAlias(String alias) {
    return $BudgetsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TransactionCategory, int, int> $convertercategory =
      const EnumIndexConverter<TransactionCategory>(TransactionCategory.values);
}

class Budget extends DataClass implements Insertable<Budget> {
  final int id;
  final TransactionCategory category;
  final double monthlyLimit;
  const Budget({
    required this.id,
    required this.category,
    required this.monthlyLimit,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['category'] = Variable<int>(
        $BudgetsTable.$convertercategory.toSql(category),
      );
    }
    map['monthly_limit'] = Variable<double>(monthlyLimit);
    return map;
  }

  BudgetsCompanion toCompanion(bool nullToAbsent) {
    return BudgetsCompanion(
      id: Value(id),
      category: Value(category),
      monthlyLimit: Value(monthlyLimit),
    );
  }

  factory Budget.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Budget(
      id: serializer.fromJson<int>(json['id']),
      category: $BudgetsTable.$convertercategory.fromJson(
        serializer.fromJson<int>(json['category']),
      ),
      monthlyLimit: serializer.fromJson<double>(json['monthlyLimit']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'category': serializer.toJson<int>(
        $BudgetsTable.$convertercategory.toJson(category),
      ),
      'monthlyLimit': serializer.toJson<double>(monthlyLimit),
    };
  }

  Budget copyWith({
    int? id,
    TransactionCategory? category,
    double? monthlyLimit,
  }) => Budget(
    id: id ?? this.id,
    category: category ?? this.category,
    monthlyLimit: monthlyLimit ?? this.monthlyLimit,
  );
  Budget copyWithCompanion(BudgetsCompanion data) {
    return Budget(
      id: data.id.present ? data.id.value : this.id,
      category: data.category.present ? data.category.value : this.category,
      monthlyLimit: data.monthlyLimit.present
          ? data.monthlyLimit.value
          : this.monthlyLimit,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Budget(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('monthlyLimit: $monthlyLimit')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, category, monthlyLimit);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Budget &&
          other.id == this.id &&
          other.category == this.category &&
          other.monthlyLimit == this.monthlyLimit);
}

class BudgetsCompanion extends UpdateCompanion<Budget> {
  final Value<int> id;
  final Value<TransactionCategory> category;
  final Value<double> monthlyLimit;
  const BudgetsCompanion({
    this.id = const Value.absent(),
    this.category = const Value.absent(),
    this.monthlyLimit = const Value.absent(),
  });
  BudgetsCompanion.insert({
    this.id = const Value.absent(),
    required TransactionCategory category,
    required double monthlyLimit,
  }) : category = Value(category),
       monthlyLimit = Value(monthlyLimit);
  static Insertable<Budget> custom({
    Expression<int>? id,
    Expression<int>? category,
    Expression<double>? monthlyLimit,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (category != null) 'category': category,
      if (monthlyLimit != null) 'monthly_limit': monthlyLimit,
    });
  }

  BudgetsCompanion copyWith({
    Value<int>? id,
    Value<TransactionCategory>? category,
    Value<double>? monthlyLimit,
  }) {
    return BudgetsCompanion(
      id: id ?? this.id,
      category: category ?? this.category,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (category.present) {
      map['category'] = Variable<int>(
        $BudgetsTable.$convertercategory.toSql(category.value),
      );
    }
    if (monthlyLimit.present) {
      map['monthly_limit'] = Variable<double>(monthlyLimit.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetsCompanion(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('monthlyLimit: $monthlyLimit')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $AppRulesTable appRules = $AppRulesTable(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $BudgetsTable budgets = $BudgetsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    transactions,
    appRules,
    accounts,
    budgets,
  ];
}

typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> id,
      required DateTime timestamp,
      required double amount,
      required String currency,
      required TransactionType type,
      required String merchant,
      required TransactionCategory category,
      required int accountId,
      required String rawText,
      required TransactionStatus status,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> id,
      Value<DateTime> timestamp,
      Value<double> amount,
      Value<String> currency,
      Value<TransactionType> type,
      Value<String> merchant,
      Value<TransactionCategory> category,
      Value<int> accountId,
      Value<String> rawText,
      Value<TransactionStatus> status,
    });

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TransactionType, TransactionType, int>
  get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get merchant => $composableBuilder(
    column: $table.merchant,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TransactionCategory, TransactionCategory, int>
  get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TransactionStatus, TransactionStatus, int>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get merchant => $composableBuilder(
    column: $table.merchant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TransactionType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get merchant =>
      $composableBuilder(column: $table.merchant, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TransactionCategory, int> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get rawText =>
      $composableBuilder(column: $table.rawText, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TransactionStatus, int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          Transaction,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (
            Transaction,
            BaseReferences<_$AppDatabase, $TransactionsTable, Transaction>,
          ),
          Transaction,
          PrefetchHooks Function()
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<TransactionType> type = const Value.absent(),
                Value<String> merchant = const Value.absent(),
                Value<TransactionCategory> category = const Value.absent(),
                Value<int> accountId = const Value.absent(),
                Value<String> rawText = const Value.absent(),
                Value<TransactionStatus> status = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                timestamp: timestamp,
                amount: amount,
                currency: currency,
                type: type,
                merchant: merchant,
                category: category,
                accountId: accountId,
                rawText: rawText,
                status: status,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime timestamp,
                required double amount,
                required String currency,
                required TransactionType type,
                required String merchant,
                required TransactionCategory category,
                required int accountId,
                required String rawText,
                required TransactionStatus status,
              }) => TransactionsCompanion.insert(
                id: id,
                timestamp: timestamp,
                amount: amount,
                currency: currency,
                type: type,
                merchant: merchant,
                category: category,
                accountId: accountId,
                rawText: rawText,
                status: status,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      Transaction,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (
        Transaction,
        BaseReferences<_$AppDatabase, $TransactionsTable, Transaction>,
      ),
      Transaction,
      PrefetchHooks Function()
    >;
typedef $$AppRulesTableCreateCompanionBuilder =
    AppRulesCompanion Function({
      Value<int> id,
      required String merchantRegex,
      required TransactionCategory assignedCategory,
    });
typedef $$AppRulesTableUpdateCompanionBuilder =
    AppRulesCompanion Function({
      Value<int> id,
      Value<String> merchantRegex,
      Value<TransactionCategory> assignedCategory,
    });

class $$AppRulesTableFilterComposer
    extends Composer<_$AppDatabase, $AppRulesTable> {
  $$AppRulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get merchantRegex => $composableBuilder(
    column: $table.merchantRegex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TransactionCategory, TransactionCategory, int>
  get assignedCategory => $composableBuilder(
    column: $table.assignedCategory,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$AppRulesTableOrderingComposer
    extends Composer<_$AppDatabase, $AppRulesTable> {
  $$AppRulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get merchantRegex => $composableBuilder(
    column: $table.merchantRegex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get assignedCategory => $composableBuilder(
    column: $table.assignedCategory,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppRulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppRulesTable> {
  $$AppRulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get merchantRegex => $composableBuilder(
    column: $table.merchantRegex,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<TransactionCategory, int>
  get assignedCategory => $composableBuilder(
    column: $table.assignedCategory,
    builder: (column) => column,
  );
}

class $$AppRulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppRulesTable,
          AppRule,
          $$AppRulesTableFilterComposer,
          $$AppRulesTableOrderingComposer,
          $$AppRulesTableAnnotationComposer,
          $$AppRulesTableCreateCompanionBuilder,
          $$AppRulesTableUpdateCompanionBuilder,
          (AppRule, BaseReferences<_$AppDatabase, $AppRulesTable, AppRule>),
          AppRule,
          PrefetchHooks Function()
        > {
  $$AppRulesTableTableManager(_$AppDatabase db, $AppRulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppRulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppRulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> merchantRegex = const Value.absent(),
                Value<TransactionCategory> assignedCategory =
                    const Value.absent(),
              }) => AppRulesCompanion(
                id: id,
                merchantRegex: merchantRegex,
                assignedCategory: assignedCategory,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String merchantRegex,
                required TransactionCategory assignedCategory,
              }) => AppRulesCompanion.insert(
                id: id,
                merchantRegex: merchantRegex,
                assignedCategory: assignedCategory,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppRulesTable,
      AppRule,
      $$AppRulesTableFilterComposer,
      $$AppRulesTableOrderingComposer,
      $$AppRulesTableAnnotationComposer,
      $$AppRulesTableCreateCompanionBuilder,
      $$AppRulesTableUpdateCompanionBuilder,
      (AppRule, BaseReferences<_$AppDatabase, $AppRulesTable, AppRule>),
      AppRule,
      PrefetchHooks Function()
    >;
typedef $$AccountsTableCreateCompanionBuilder =
    AccountsCompanion Function({
      Value<int> id,
      required String name,
      required double balance,
      required String currency,
    });
typedef $$AccountsTableUpdateCompanionBuilder =
    AccountsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<double> balance,
      Value<String> currency,
    });

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get balance =>
      $composableBuilder(column: $table.balance, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsTable,
          Account,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (Account, BaseReferences<_$AppDatabase, $AccountsTable, Account>),
          Account,
          PrefetchHooks Function()
        > {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> balance = const Value.absent(),
                Value<String> currency = const Value.absent(),
              }) => AccountsCompanion(
                id: id,
                name: name,
                balance: balance,
                currency: currency,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required double balance,
                required String currency,
              }) => AccountsCompanion.insert(
                id: id,
                name: name,
                balance: balance,
                currency: currency,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsTable,
      Account,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (Account, BaseReferences<_$AppDatabase, $AccountsTable, Account>),
      Account,
      PrefetchHooks Function()
    >;
typedef $$BudgetsTableCreateCompanionBuilder =
    BudgetsCompanion Function({
      Value<int> id,
      required TransactionCategory category,
      required double monthlyLimit,
    });
typedef $$BudgetsTableUpdateCompanionBuilder =
    BudgetsCompanion Function({
      Value<int> id,
      Value<TransactionCategory> category,
      Value<double> monthlyLimit,
    });

class $$BudgetsTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TransactionCategory, TransactionCategory, int>
  get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<double> get monthlyLimit => $composableBuilder(
    column: $table.monthlyLimit,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BudgetsTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get monthlyLimit => $composableBuilder(
    column: $table.monthlyLimit,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BudgetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TransactionCategory, int> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<double> get monthlyLimit => $composableBuilder(
    column: $table.monthlyLimit,
    builder: (column) => column,
  );
}

class $$BudgetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BudgetsTable,
          Budget,
          $$BudgetsTableFilterComposer,
          $$BudgetsTableOrderingComposer,
          $$BudgetsTableAnnotationComposer,
          $$BudgetsTableCreateCompanionBuilder,
          $$BudgetsTableUpdateCompanionBuilder,
          (Budget, BaseReferences<_$AppDatabase, $BudgetsTable, Budget>),
          Budget,
          PrefetchHooks Function()
        > {
  $$BudgetsTableTableManager(_$AppDatabase db, $BudgetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<TransactionCategory> category = const Value.absent(),
                Value<double> monthlyLimit = const Value.absent(),
              }) => BudgetsCompanion(
                id: id,
                category: category,
                monthlyLimit: monthlyLimit,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required TransactionCategory category,
                required double monthlyLimit,
              }) => BudgetsCompanion.insert(
                id: id,
                category: category,
                monthlyLimit: monthlyLimit,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BudgetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BudgetsTable,
      Budget,
      $$BudgetsTableFilterComposer,
      $$BudgetsTableOrderingComposer,
      $$BudgetsTableAnnotationComposer,
      $$BudgetsTableCreateCompanionBuilder,
      $$BudgetsTableUpdateCompanionBuilder,
      (Budget, BaseReferences<_$AppDatabase, $BudgetsTable, Budget>),
      Budget,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$AppRulesTableTableManager get appRules =>
      $$AppRulesTableTableManager(_db, _db.appRules);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$BudgetsTableTableManager get budgets =>
      $$BudgetsTableTableManager(_db, _db.budgets);
}
