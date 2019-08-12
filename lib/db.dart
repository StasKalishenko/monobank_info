import 'package:monobank_info/statementInfo.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBProvider {
  DBProvider._();
  static final DBProvider db = DBProvider._();

  static Database _database;

  _initStructure(db) async {
    await createTable(db, "statements", {
      "id": "TEXT PRIMARY KEY",
      "description": "TEXT",
      "amount": "INTEGER",
      "operationAmount": "INTEGER",
      "currencyCode": "INTEGER",
      "time": "INTEGER",
      "mcc": "INTEGER"
    });
  }

  initDB() async {
    String path = join(await getDatabasesPath(), "monolytics_database.db");
    return await openDatabase(path, version: 1, onCreate: (db, version) async {
      await _initStructure(db);
    }, onOpen: (db) async {
      await _initStructure(db);
    });
  }

  Future<Database> get database async {
    if (_database != null) {
      return _database;
    }
    _database = await initDB();
    return _database;
  }

  createTable(db, tableName, Map<String, dynamic> config) async {
    String sql = "CREATE TABLE IF NOT EXISTS " + tableName + "(";
    var columns = [];
    config.forEach((columnName, columnType) {
      columns.add(columnName + " " + columnType);
    });
    sql += columns.join(", ") + ")";
    await db.execute(sql);
  }

  Future<List<StatementInfo>> getStatements() async {
    final db = await database;
    List<Map<String, dynamic>> _localStatements = await db.query("statements");
    return List.generate(_localStatements.length, (i) {
      return StatementInfo(
          id: _localStatements[i]["id"],
          description: _localStatements[i]["description"],
          amount: _localStatements[i]["amount"],
          operationAmount: _localStatements[i]["operationAmount"],
          currencyCode: _localStatements[i]["currencyCode"],
          time: _localStatements[i]["time"],
          mcc: _localStatements[i]["mcc"]);
    });
  }

  addStatement(StatementInfo statement) async {
    final db = await database;
    db.insert("statements", statement.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
