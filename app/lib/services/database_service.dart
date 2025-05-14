import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/RotaResponse.dart';
import '../models/pedido.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'pedidos_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(
      '''
      CREATE TABLE pedidos(
        id INTEGER PRIMARY KEY,
        origemLongitude TEXT,
        origemLatitude TEXT,
        destinoLongitude TEXT,
        destinoLatitude TEXT,
        tipoMercadoria TEXT,
        status TEXT,
        dataCriacao TEXT,
        dataAtualizacao TEXT,
        dataEntregaEstimada TEXT,
        distanciaKm REAL,
        tempoEstimadoMinutos INTEGER,
        clienteId INTEGER,
        motoristaId INTEGER,
        rotaMotorista TEXT
      )
      ''',
    );
  }

  Future<void> insertPedido(Pedido pedido) async {
    final Database db = await database;

    Map<String, dynamic> pedidoMap = {
      'id': pedido.id,
      'origemLongitude': pedido.origemLongitude,
      'origemLatitude': pedido.origemLatitude,
      'destinoLongitude': pedido.destinoLongitude,
      'destinoLatitude': pedido.destinoLatitude,
      'tipoMercadoria': pedido.tipoMercadoria,
      'status': pedido.status,
      'dataCriacao': pedido.dataCriacao.toIso8601String(),
      'dataAtualizacao': pedido.dataAtualizacao.toIso8601String(),
      'dataEntregaEstimada': pedido.dataEntregaEstimada?.toIso8601String(),
      'distanciaKm': pedido.distanciaKm,
      'tempoEstimadoMinutos': pedido.tempoEstimadoMinutos,
      'clienteId': pedido.clienteId,
      'motoristaId': pedido.motoristaId,
      'rotaMotorista': pedido.rotaMotorista != null
          ? jsonEncode(pedido.rotaMotorista?.toJson())
          : null,
    };

    await db.insert(
      'pedidos',
      pedidoMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Pedido>> getPedidosByCliente(int clienteId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pedidos',
      where: 'clienteId = ?',
      whereArgs: [clienteId],
    );

    return List.generate(maps.length, (i) {
      return Pedido(
        id: maps[i]['id'],
        origemLongitude: maps[i]['origemLongitude'],
        origemLatitude: maps[i]['origemLatitude'],
        destinoLongitude: maps[i]['destinoLongitude'],
        destinoLatitude: maps[i]['destinoLatitude'],
        tipoMercadoria: maps[i]['tipoMercadoria'],
        status: maps[i]['status'],
        dataCriacao: DateTime.parse(maps[i]['dataCriacao']),
        dataAtualizacao: DateTime.parse(maps[i]['dataAtualizacao']),
        dataEntregaEstimada: maps[i]['dataEntregaEstimada'] != null
            ? DateTime.parse(maps[i]['dataEntregaEstimada'])
            : null,
        distanciaKm: maps[i]['distanciaKm'],
        tempoEstimadoMinutos: maps[i]['tempoEstimadoMinutos'],
        clienteId: maps[i]['clienteId'],
        motoristaId: maps[i]['motoristaId'],
        rotaMotorista: maps[i]['rotaMotorista'] != null
            ? RotaResponse.fromJson(jsonDecode(maps[i]['rotaMotorista']))
            : null,
      );
    });
  }
}
