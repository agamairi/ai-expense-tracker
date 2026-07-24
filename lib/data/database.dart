import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import 'tables.dart';
import 'package:ai_expense_tracker/domain/models/enums.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Transactions, AppRules, Accounts, Budgets])
class AppDatabase extends _$AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  AppDatabase._internal() : super(_openConnection());

  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await into(accounts).insert(
            const AccountsCompanion(
              name: Value("Checking"),
              balance: Value(0.0),
              currency: Value("USD"),
            ),
          );
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(budgets);
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));

    if (Platform.isAndroid) {
      // Workaround not needed or available in this setup
    }
    
    final cachebase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cachebase;

    return NativeDatabase.createInBackground(file);
  });
}
