import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  late String _databaseName = "TrusmiOnTime.db";
  late int _databaseVersion = 1;

  late String table = 'tbl_ip_address';
  late String columnId = 'id_ip';
  late String columnName = 'name';
  late String columnIpAddress = 'ip_address';
  late String columnIsActive = 'is_active';

  //make this a singleton class
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  //only have a single app-wide reference to the database
  var _database;
  Future<Database> get database async {
    if (_database != null) return _database;

    //lazily instatiate the db the first time it is accessed
    _database = await _initDatabase();
    return _database;
  }

  //this opens the database (and creates it if it does'nt exist)
  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  //SQL code to create the database table
  Future _onCreate(Database db, int version) async {
    await db.execute('''
        CREATE TABLE $table (
          $columnId INTEGER PRIMARY KEY,
          $columnIpAddress TEXT NOT NULL,
          $columnName TEXT NOT NULL,
          $columnIsActive INTEGER NOT NULL
        )''');
  }

  // Helper methods

  // Inserts a row in the database where each key in the Map is a column name
  // and the value is the column value. The return value is the id of the
  // inserted row.
  Future<int> insert(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(table, row);
  }

  // All of the rows are returned as a list of maps, where each map is
  // a key-value list of columns.
  Future<List<Map<String, dynamic>>> queryAllRows() async {
    Database db = await instance.database;
    return await db.query(table);
  }

  // All of the methods (insert, query, update, delete) can also be done using
  // raw SQL commands. This method uses a raw query to give the row count.
  Future<int?> queryRowCount() async {
    Database db = await instance.database;
    return Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $table'));
  }

  // All of methods (insert, query, update, delete) can also be done using
  // raw SQL commands. This method uses a row query to give the row count.
  Future<int> update(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row[columnId];
    return await db.update(table, row, where: '$columnId = ?', whereArgs: [id]);
  }

  // Deletes the row specified by the id. The number of affected rows is
  // returned. This should be 1 as long as the row exists.
  Future<int> delete(int id) async {
    Database db = await instance.database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> deleteAll() async {
    Database db = await instance.database;
    return await db.delete(table);
  }
}
