// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $TemasTable extends Temas with TableInfo<$TemasTable, Tema> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TemasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
      'nome', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  @override
  List<GeneratedColumn> get $columns => [id, nome];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'temas';
  @override
  VerificationContext validateIntegrity(Insertable<Tema> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nome')) {
      context.handle(
          _nomeMeta, nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta));
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tema map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tema(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      nome: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nome'])!,
    );
  }

  @override
  $TemasTable createAlias(String alias) {
    return $TemasTable(attachedDatabase, alias);
  }
}

class Tema extends DataClass implements Insertable<Tema> {
  final int id;
  final String nome;
  const Tema({required this.id, required this.nome});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['nome'] = Variable<String>(nome);
    return map;
  }

  TemasCompanion toCompanion(bool nullToAbsent) {
    return TemasCompanion(
      id: Value(id),
      nome: Value(nome),
    );
  }

  factory Tema.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tema(
      id: serializer.fromJson<int>(json['id']),
      nome: serializer.fromJson<String>(json['nome']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nome': serializer.toJson<String>(nome),
    };
  }

  Tema copyWith({int? id, String? nome}) => Tema(
        id: id ?? this.id,
        nome: nome ?? this.nome,
      );
  Tema copyWithCompanion(TemasCompanion data) {
    return Tema(
      id: data.id.present ? data.id.value : this.id,
      nome: data.nome.present ? data.nome.value : this.nome,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tema(')
          ..write('id: $id, ')
          ..write('nome: $nome')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nome);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tema && other.id == this.id && other.nome == this.nome);
}

class TemasCompanion extends UpdateCompanion<Tema> {
  final Value<int> id;
  final Value<String> nome;
  const TemasCompanion({
    this.id = const Value.absent(),
    this.nome = const Value.absent(),
  });
  TemasCompanion.insert({
    this.id = const Value.absent(),
    required String nome,
  }) : nome = Value(nome);
  static Insertable<Tema> custom({
    Expression<int>? id,
    Expression<String>? nome,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nome != null) 'nome': nome,
    });
  }

  TemasCompanion copyWith({Value<int>? id, Value<String>? nome}) {
    return TemasCompanion(
      id: id ?? this.id,
      nome: nome ?? this.nome,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemasCompanion(')
          ..write('id: $id, ')
          ..write('nome: $nome')
          ..write(')'))
        .toString();
  }
}

class $SetEntriesTable extends SetEntries
    with TableInfo<$SetEntriesTable, SetEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SetEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _numeroSetMeta =
      const VerificationMeta('numeroSet');
  @override
  late final GeneratedColumn<int> numeroSet = GeneratedColumn<int>(
      'numero_set', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _temaIdMeta = const VerificationMeta('temaId');
  @override
  late final GeneratedColumn<int> temaId = GeneratedColumn<int>(
      'tema_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES temas (id)'));
  static const VerificationMeta _descricaoMeta =
      const VerificationMeta('descricao');
  @override
  late final GeneratedColumn<String> descricao = GeneratedColumn<String>(
      'descricao', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _anoMeta = const VerificationMeta('ano');
  @override
  late final GeneratedColumn<int> ano = GeneratedColumn<int>(
      'ano', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _valorSetMeta =
      const VerificationMeta('valorSet');
  @override
  late final GeneratedColumn<double> valorSet = GeneratedColumn<double>(
      'valor_set', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _valorCompradoMeta =
      const VerificationMeta('valorComprado');
  @override
  late final GeneratedColumn<double> valorComprado = GeneratedColumn<double>(
      'valor_comprado', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _dataCompraMeta =
      const VerificationMeta('dataCompra');
  @override
  late final GeneratedColumn<DateTime> dataCompra = GeneratedColumn<DateTime>(
      'data_compra', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _quantidadeMeta =
      const VerificationMeta('quantidade');
  @override
  late final GeneratedColumn<int> quantidade = GeneratedColumn<int>(
      'quantidade', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _vendidoMeta =
      const VerificationMeta('vendido');
  @override
  late final GeneratedColumn<bool> vendido = GeneratedColumn<bool>(
      'vendido', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("vendido" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _valorVendaMeta =
      const VerificationMeta('valorVenda');
  @override
  late final GeneratedColumn<double> valorVenda = GeneratedColumn<double>(
      'valor_venda', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _dataVendaMeta =
      const VerificationMeta('dataVenda');
  @override
  late final GeneratedColumn<DateTime> dataVenda = GeneratedColumn<DateTime>(
      'data_venda', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _notasMeta = const VerificationMeta('notas');
  @override
  late final GeneratedColumn<String> notas = GeneratedColumn<String>(
      'notas', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        numeroSet,
        temaId,
        descricao,
        ano,
        valorSet,
        valorComprado,
        dataCompra,
        quantidade,
        vendido,
        valorVenda,
        dataVenda,
        notas
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'set_entries';
  @override
  VerificationContext validateIntegrity(Insertable<SetEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('numero_set')) {
      context.handle(_numeroSetMeta,
          numeroSet.isAcceptableOrUnknown(data['numero_set']!, _numeroSetMeta));
    } else if (isInserting) {
      context.missing(_numeroSetMeta);
    }
    if (data.containsKey('tema_id')) {
      context.handle(_temaIdMeta,
          temaId.isAcceptableOrUnknown(data['tema_id']!, _temaIdMeta));
    } else if (isInserting) {
      context.missing(_temaIdMeta);
    }
    if (data.containsKey('descricao')) {
      context.handle(_descricaoMeta,
          descricao.isAcceptableOrUnknown(data['descricao']!, _descricaoMeta));
    } else if (isInserting) {
      context.missing(_descricaoMeta);
    }
    if (data.containsKey('ano')) {
      context.handle(
          _anoMeta, ano.isAcceptableOrUnknown(data['ano']!, _anoMeta));
    }
    if (data.containsKey('valor_set')) {
      context.handle(_valorSetMeta,
          valorSet.isAcceptableOrUnknown(data['valor_set']!, _valorSetMeta));
    } else if (isInserting) {
      context.missing(_valorSetMeta);
    }
    if (data.containsKey('valor_comprado')) {
      context.handle(
          _valorCompradoMeta,
          valorComprado.isAcceptableOrUnknown(
              data['valor_comprado']!, _valorCompradoMeta));
    } else if (isInserting) {
      context.missing(_valorCompradoMeta);
    }
    if (data.containsKey('data_compra')) {
      context.handle(
          _dataCompraMeta,
          dataCompra.isAcceptableOrUnknown(
              data['data_compra']!, _dataCompraMeta));
    }
    if (data.containsKey('quantidade')) {
      context.handle(
          _quantidadeMeta,
          quantidade.isAcceptableOrUnknown(
              data['quantidade']!, _quantidadeMeta));
    }
    if (data.containsKey('vendido')) {
      context.handle(_vendidoMeta,
          vendido.isAcceptableOrUnknown(data['vendido']!, _vendidoMeta));
    }
    if (data.containsKey('valor_venda')) {
      context.handle(
          _valorVendaMeta,
          valorVenda.isAcceptableOrUnknown(
              data['valor_venda']!, _valorVendaMeta));
    }
    if (data.containsKey('data_venda')) {
      context.handle(_dataVendaMeta,
          dataVenda.isAcceptableOrUnknown(data['data_venda']!, _dataVendaMeta));
    }
    if (data.containsKey('notas')) {
      context.handle(
          _notasMeta, notas.isAcceptableOrUnknown(data['notas']!, _notasMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SetEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SetEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      numeroSet: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}numero_set'])!,
      temaId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tema_id'])!,
      descricao: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}descricao'])!,
      ano: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ano']),
      valorSet: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}valor_set'])!,
      valorComprado: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}valor_comprado'])!,
      dataCompra: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}data_compra']),
      quantidade: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}quantidade'])!,
      vendido: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}vendido'])!,
      valorVenda: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}valor_venda']),
      dataVenda: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}data_venda']),
      notas: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notas']),
    );
  }

  @override
  $SetEntriesTable createAlias(String alias) {
    return $SetEntriesTable(attachedDatabase, alias);
  }
}

class SetEntry extends DataClass implements Insertable<SetEntry> {
  final int id;
  final int numeroSet;
  final int temaId;
  final String descricao;
  final int? ano;
  final double valorSet;
  final double valorComprado;
  final DateTime? dataCompra;
  final int quantidade;
  final bool vendido;
  final double? valorVenda;
  final DateTime? dataVenda;
  final String? notas;
  const SetEntry(
      {required this.id,
      required this.numeroSet,
      required this.temaId,
      required this.descricao,
      this.ano,
      required this.valorSet,
      required this.valorComprado,
      this.dataCompra,
      required this.quantidade,
      required this.vendido,
      this.valorVenda,
      this.dataVenda,
      this.notas});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['numero_set'] = Variable<int>(numeroSet);
    map['tema_id'] = Variable<int>(temaId);
    map['descricao'] = Variable<String>(descricao);
    if (!nullToAbsent || ano != null) {
      map['ano'] = Variable<int>(ano);
    }
    map['valor_set'] = Variable<double>(valorSet);
    map['valor_comprado'] = Variable<double>(valorComprado);
    if (!nullToAbsent || dataCompra != null) {
      map['data_compra'] = Variable<DateTime>(dataCompra);
    }
    map['quantidade'] = Variable<int>(quantidade);
    map['vendido'] = Variable<bool>(vendido);
    if (!nullToAbsent || valorVenda != null) {
      map['valor_venda'] = Variable<double>(valorVenda);
    }
    if (!nullToAbsent || dataVenda != null) {
      map['data_venda'] = Variable<DateTime>(dataVenda);
    }
    if (!nullToAbsent || notas != null) {
      map['notas'] = Variable<String>(notas);
    }
    return map;
  }

  SetEntriesCompanion toCompanion(bool nullToAbsent) {
    return SetEntriesCompanion(
      id: Value(id),
      numeroSet: Value(numeroSet),
      temaId: Value(temaId),
      descricao: Value(descricao),
      ano: ano == null && nullToAbsent ? const Value.absent() : Value(ano),
      valorSet: Value(valorSet),
      valorComprado: Value(valorComprado),
      dataCompra: dataCompra == null && nullToAbsent
          ? const Value.absent()
          : Value(dataCompra),
      quantidade: Value(quantidade),
      vendido: Value(vendido),
      valorVenda: valorVenda == null && nullToAbsent
          ? const Value.absent()
          : Value(valorVenda),
      dataVenda: dataVenda == null && nullToAbsent
          ? const Value.absent()
          : Value(dataVenda),
      notas:
          notas == null && nullToAbsent ? const Value.absent() : Value(notas),
    );
  }

  factory SetEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SetEntry(
      id: serializer.fromJson<int>(json['id']),
      numeroSet: serializer.fromJson<int>(json['numeroSet']),
      temaId: serializer.fromJson<int>(json['temaId']),
      descricao: serializer.fromJson<String>(json['descricao']),
      ano: serializer.fromJson<int?>(json['ano']),
      valorSet: serializer.fromJson<double>(json['valorSet']),
      valorComprado: serializer.fromJson<double>(json['valorComprado']),
      dataCompra: serializer.fromJson<DateTime?>(json['dataCompra']),
      quantidade: serializer.fromJson<int>(json['quantidade']),
      vendido: serializer.fromJson<bool>(json['vendido']),
      valorVenda: serializer.fromJson<double?>(json['valorVenda']),
      dataVenda: serializer.fromJson<DateTime?>(json['dataVenda']),
      notas: serializer.fromJson<String?>(json['notas']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'numeroSet': serializer.toJson<int>(numeroSet),
      'temaId': serializer.toJson<int>(temaId),
      'descricao': serializer.toJson<String>(descricao),
      'ano': serializer.toJson<int?>(ano),
      'valorSet': serializer.toJson<double>(valorSet),
      'valorComprado': serializer.toJson<double>(valorComprado),
      'dataCompra': serializer.toJson<DateTime?>(dataCompra),
      'quantidade': serializer.toJson<int>(quantidade),
      'vendido': serializer.toJson<bool>(vendido),
      'valorVenda': serializer.toJson<double?>(valorVenda),
      'dataVenda': serializer.toJson<DateTime?>(dataVenda),
      'notas': serializer.toJson<String?>(notas),
    };
  }

  SetEntry copyWith(
          {int? id,
          int? numeroSet,
          int? temaId,
          String? descricao,
          Value<int?> ano = const Value.absent(),
          double? valorSet,
          double? valorComprado,
          Value<DateTime?> dataCompra = const Value.absent(),
          int? quantidade,
          bool? vendido,
          Value<double?> valorVenda = const Value.absent(),
          Value<DateTime?> dataVenda = const Value.absent(),
          Value<String?> notas = const Value.absent()}) =>
      SetEntry(
        id: id ?? this.id,
        numeroSet: numeroSet ?? this.numeroSet,
        temaId: temaId ?? this.temaId,
        descricao: descricao ?? this.descricao,
        ano: ano.present ? ano.value : this.ano,
        valorSet: valorSet ?? this.valorSet,
        valorComprado: valorComprado ?? this.valorComprado,
        dataCompra: dataCompra.present ? dataCompra.value : this.dataCompra,
        quantidade: quantidade ?? this.quantidade,
        vendido: vendido ?? this.vendido,
        valorVenda: valorVenda.present ? valorVenda.value : this.valorVenda,
        dataVenda: dataVenda.present ? dataVenda.value : this.dataVenda,
        notas: notas.present ? notas.value : this.notas,
      );
  SetEntry copyWithCompanion(SetEntriesCompanion data) {
    return SetEntry(
      id: data.id.present ? data.id.value : this.id,
      numeroSet: data.numeroSet.present ? data.numeroSet.value : this.numeroSet,
      temaId: data.temaId.present ? data.temaId.value : this.temaId,
      descricao: data.descricao.present ? data.descricao.value : this.descricao,
      ano: data.ano.present ? data.ano.value : this.ano,
      valorSet: data.valorSet.present ? data.valorSet.value : this.valorSet,
      valorComprado: data.valorComprado.present
          ? data.valorComprado.value
          : this.valorComprado,
      dataCompra:
          data.dataCompra.present ? data.dataCompra.value : this.dataCompra,
      quantidade:
          data.quantidade.present ? data.quantidade.value : this.quantidade,
      vendido: data.vendido.present ? data.vendido.value : this.vendido,
      valorVenda:
          data.valorVenda.present ? data.valorVenda.value : this.valorVenda,
      dataVenda: data.dataVenda.present ? data.dataVenda.value : this.dataVenda,
      notas: data.notas.present ? data.notas.value : this.notas,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SetEntry(')
          ..write('id: $id, ')
          ..write('numeroSet: $numeroSet, ')
          ..write('temaId: $temaId, ')
          ..write('descricao: $descricao, ')
          ..write('ano: $ano, ')
          ..write('valorSet: $valorSet, ')
          ..write('valorComprado: $valorComprado, ')
          ..write('dataCompra: $dataCompra, ')
          ..write('quantidade: $quantidade, ')
          ..write('vendido: $vendido, ')
          ..write('valorVenda: $valorVenda, ')
          ..write('dataVenda: $dataVenda, ')
          ..write('notas: $notas')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      numeroSet,
      temaId,
      descricao,
      ano,
      valorSet,
      valorComprado,
      dataCompra,
      quantidade,
      vendido,
      valorVenda,
      dataVenda,
      notas);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SetEntry &&
          other.id == this.id &&
          other.numeroSet == this.numeroSet &&
          other.temaId == this.temaId &&
          other.descricao == this.descricao &&
          other.ano == this.ano &&
          other.valorSet == this.valorSet &&
          other.valorComprado == this.valorComprado &&
          other.dataCompra == this.dataCompra &&
          other.quantidade == this.quantidade &&
          other.vendido == this.vendido &&
          other.valorVenda == this.valorVenda &&
          other.dataVenda == this.dataVenda &&
          other.notas == this.notas);
}

class SetEntriesCompanion extends UpdateCompanion<SetEntry> {
  final Value<int> id;
  final Value<int> numeroSet;
  final Value<int> temaId;
  final Value<String> descricao;
  final Value<int?> ano;
  final Value<double> valorSet;
  final Value<double> valorComprado;
  final Value<DateTime?> dataCompra;
  final Value<int> quantidade;
  final Value<bool> vendido;
  final Value<double?> valorVenda;
  final Value<DateTime?> dataVenda;
  final Value<String?> notas;
  const SetEntriesCompanion({
    this.id = const Value.absent(),
    this.numeroSet = const Value.absent(),
    this.temaId = const Value.absent(),
    this.descricao = const Value.absent(),
    this.ano = const Value.absent(),
    this.valorSet = const Value.absent(),
    this.valorComprado = const Value.absent(),
    this.dataCompra = const Value.absent(),
    this.quantidade = const Value.absent(),
    this.vendido = const Value.absent(),
    this.valorVenda = const Value.absent(),
    this.dataVenda = const Value.absent(),
    this.notas = const Value.absent(),
  });
  SetEntriesCompanion.insert({
    this.id = const Value.absent(),
    required int numeroSet,
    required int temaId,
    required String descricao,
    this.ano = const Value.absent(),
    required double valorSet,
    required double valorComprado,
    this.dataCompra = const Value.absent(),
    this.quantidade = const Value.absent(),
    this.vendido = const Value.absent(),
    this.valorVenda = const Value.absent(),
    this.dataVenda = const Value.absent(),
    this.notas = const Value.absent(),
  })  : numeroSet = Value(numeroSet),
        temaId = Value(temaId),
        descricao = Value(descricao),
        valorSet = Value(valorSet),
        valorComprado = Value(valorComprado);
  static Insertable<SetEntry> custom({
    Expression<int>? id,
    Expression<int>? numeroSet,
    Expression<int>? temaId,
    Expression<String>? descricao,
    Expression<int>? ano,
    Expression<double>? valorSet,
    Expression<double>? valorComprado,
    Expression<DateTime>? dataCompra,
    Expression<int>? quantidade,
    Expression<bool>? vendido,
    Expression<double>? valorVenda,
    Expression<DateTime>? dataVenda,
    Expression<String>? notas,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (numeroSet != null) 'numero_set': numeroSet,
      if (temaId != null) 'tema_id': temaId,
      if (descricao != null) 'descricao': descricao,
      if (ano != null) 'ano': ano,
      if (valorSet != null) 'valor_set': valorSet,
      if (valorComprado != null) 'valor_comprado': valorComprado,
      if (dataCompra != null) 'data_compra': dataCompra,
      if (quantidade != null) 'quantidade': quantidade,
      if (vendido != null) 'vendido': vendido,
      if (valorVenda != null) 'valor_venda': valorVenda,
      if (dataVenda != null) 'data_venda': dataVenda,
      if (notas != null) 'notas': notas,
    });
  }

  SetEntriesCompanion copyWith(
      {Value<int>? id,
      Value<int>? numeroSet,
      Value<int>? temaId,
      Value<String>? descricao,
      Value<int?>? ano,
      Value<double>? valorSet,
      Value<double>? valorComprado,
      Value<DateTime?>? dataCompra,
      Value<int>? quantidade,
      Value<bool>? vendido,
      Value<double?>? valorVenda,
      Value<DateTime?>? dataVenda,
      Value<String?>? notas}) {
    return SetEntriesCompanion(
      id: id ?? this.id,
      numeroSet: numeroSet ?? this.numeroSet,
      temaId: temaId ?? this.temaId,
      descricao: descricao ?? this.descricao,
      ano: ano ?? this.ano,
      valorSet: valorSet ?? this.valorSet,
      valorComprado: valorComprado ?? this.valorComprado,
      dataCompra: dataCompra ?? this.dataCompra,
      quantidade: quantidade ?? this.quantidade,
      vendido: vendido ?? this.vendido,
      valorVenda: valorVenda ?? this.valorVenda,
      dataVenda: dataVenda ?? this.dataVenda,
      notas: notas ?? this.notas,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (numeroSet.present) {
      map['numero_set'] = Variable<int>(numeroSet.value);
    }
    if (temaId.present) {
      map['tema_id'] = Variable<int>(temaId.value);
    }
    if (descricao.present) {
      map['descricao'] = Variable<String>(descricao.value);
    }
    if (ano.present) {
      map['ano'] = Variable<int>(ano.value);
    }
    if (valorSet.present) {
      map['valor_set'] = Variable<double>(valorSet.value);
    }
    if (valorComprado.present) {
      map['valor_comprado'] = Variable<double>(valorComprado.value);
    }
    if (dataCompra.present) {
      map['data_compra'] = Variable<DateTime>(dataCompra.value);
    }
    if (quantidade.present) {
      map['quantidade'] = Variable<int>(quantidade.value);
    }
    if (vendido.present) {
      map['vendido'] = Variable<bool>(vendido.value);
    }
    if (valorVenda.present) {
      map['valor_venda'] = Variable<double>(valorVenda.value);
    }
    if (dataVenda.present) {
      map['data_venda'] = Variable<DateTime>(dataVenda.value);
    }
    if (notas.present) {
      map['notas'] = Variable<String>(notas.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SetEntriesCompanion(')
          ..write('id: $id, ')
          ..write('numeroSet: $numeroSet, ')
          ..write('temaId: $temaId, ')
          ..write('descricao: $descricao, ')
          ..write('ano: $ano, ')
          ..write('valorSet: $valorSet, ')
          ..write('valorComprado: $valorComprado, ')
          ..write('dataCompra: $dataCompra, ')
          ..write('quantidade: $quantidade, ')
          ..write('vendido: $vendido, ')
          ..write('valorVenda: $valorVenda, ')
          ..write('dataVenda: $dataVenda, ')
          ..write('notas: $notas')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TemasTable temas = $TemasTable(this);
  late final $SetEntriesTable setEntries = $SetEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [temas, setEntries];
}

typedef $$TemasTableCreateCompanionBuilder = TemasCompanion Function({
  Value<int> id,
  required String nome,
});
typedef $$TemasTableUpdateCompanionBuilder = TemasCompanion Function({
  Value<int> id,
  Value<String> nome,
});

final class $$TemasTableReferences
    extends BaseReferences<_$AppDatabase, $TemasTable, Tema> {
  $$TemasTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SetEntriesTable, List<SetEntry>>
      _setEntriesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.setEntries,
              aliasName: 'temas__id__set_entries__tema_id');

  $$SetEntriesTableProcessedTableManager get setEntriesRefs {
    final manager = $$SetEntriesTableTableManager($_db, $_db.setEntries)
        .filter((f) => f.temaId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_setEntriesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TemasTableFilterComposer extends Composer<_$AppDatabase, $TemasTable> {
  $$TemasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nome => $composableBuilder(
      column: $table.nome, builder: (column) => ColumnFilters(column));

  Expression<bool> setEntriesRefs(
      Expression<bool> Function($$SetEntriesTableFilterComposer f) f) {
    final $$SetEntriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.setEntries,
        getReferencedColumn: (t) => t.temaId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SetEntriesTableFilterComposer(
              $db: $db,
              $table: $db.setEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TemasTableOrderingComposer
    extends Composer<_$AppDatabase, $TemasTable> {
  $$TemasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nome => $composableBuilder(
      column: $table.nome, builder: (column) => ColumnOrderings(column));
}

class $$TemasTableAnnotationComposer
    extends Composer<_$AppDatabase, $TemasTable> {
  $$TemasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  Expression<T> setEntriesRefs<T extends Object>(
      Expression<T> Function($$SetEntriesTableAnnotationComposer a) f) {
    final $$SetEntriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.setEntries,
        getReferencedColumn: (t) => t.temaId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SetEntriesTableAnnotationComposer(
              $db: $db,
              $table: $db.setEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TemasTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TemasTable,
    Tema,
    $$TemasTableFilterComposer,
    $$TemasTableOrderingComposer,
    $$TemasTableAnnotationComposer,
    $$TemasTableCreateCompanionBuilder,
    $$TemasTableUpdateCompanionBuilder,
    (Tema, $$TemasTableReferences),
    Tema,
    PrefetchHooks Function({bool setEntriesRefs})> {
  $$TemasTableTableManager(_$AppDatabase db, $TemasTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TemasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TemasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TemasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> nome = const Value.absent(),
          }) =>
              TemasCompanion(
            id: id,
            nome: nome,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String nome,
          }) =>
              TemasCompanion.insert(
            id: id,
            nome: nome,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$TemasTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({setEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (setEntriesRefs) db.setEntries],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (setEntriesRefs)
                    await $_getPrefetchedData<Tema, $TemasTable, SetEntry>(
                        currentTable: table,
                        referencedTable:
                            $$TemasTableReferences._setEntriesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TemasTableReferences(db, table, p0)
                                .setEntriesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.temaId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$TemasTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TemasTable,
    Tema,
    $$TemasTableFilterComposer,
    $$TemasTableOrderingComposer,
    $$TemasTableAnnotationComposer,
    $$TemasTableCreateCompanionBuilder,
    $$TemasTableUpdateCompanionBuilder,
    (Tema, $$TemasTableReferences),
    Tema,
    PrefetchHooks Function({bool setEntriesRefs})>;
typedef $$SetEntriesTableCreateCompanionBuilder = SetEntriesCompanion Function({
  Value<int> id,
  required int numeroSet,
  required int temaId,
  required String descricao,
  Value<int?> ano,
  required double valorSet,
  required double valorComprado,
  Value<DateTime?> dataCompra,
  Value<int> quantidade,
  Value<bool> vendido,
  Value<double?> valorVenda,
  Value<DateTime?> dataVenda,
  Value<String?> notas,
});
typedef $$SetEntriesTableUpdateCompanionBuilder = SetEntriesCompanion Function({
  Value<int> id,
  Value<int> numeroSet,
  Value<int> temaId,
  Value<String> descricao,
  Value<int?> ano,
  Value<double> valorSet,
  Value<double> valorComprado,
  Value<DateTime?> dataCompra,
  Value<int> quantidade,
  Value<bool> vendido,
  Value<double?> valorVenda,
  Value<DateTime?> dataVenda,
  Value<String?> notas,
});

final class $$SetEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $SetEntriesTable, SetEntry> {
  $$SetEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TemasTable _temaIdTable(_$AppDatabase db) =>
      db.temas.createAlias('set_entries__tema_id__temas__id');

  $$TemasTableProcessedTableManager get temaId {
    final $_column = $_itemColumn<int>('tema_id')!;

    final manager = $$TemasTableTableManager($_db, $_db.temas)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_temaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$SetEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SetEntriesTable> {
  $$SetEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get numeroSet => $composableBuilder(
      column: $table.numeroSet, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get descricao => $composableBuilder(
      column: $table.descricao, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get ano => $composableBuilder(
      column: $table.ano, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get valorSet => $composableBuilder(
      column: $table.valorSet, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get valorComprado => $composableBuilder(
      column: $table.valorComprado, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dataCompra => $composableBuilder(
      column: $table.dataCompra, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get quantidade => $composableBuilder(
      column: $table.quantidade, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get vendido => $composableBuilder(
      column: $table.vendido, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get valorVenda => $composableBuilder(
      column: $table.valorVenda, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dataVenda => $composableBuilder(
      column: $table.dataVenda, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notas => $composableBuilder(
      column: $table.notas, builder: (column) => ColumnFilters(column));

  $$TemasTableFilterComposer get temaId {
    final $$TemasTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.temaId,
        referencedTable: $db.temas,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TemasTableFilterComposer(
              $db: $db,
              $table: $db.temas,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SetEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SetEntriesTable> {
  $$SetEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get numeroSet => $composableBuilder(
      column: $table.numeroSet, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get descricao => $composableBuilder(
      column: $table.descricao, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get ano => $composableBuilder(
      column: $table.ano, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get valorSet => $composableBuilder(
      column: $table.valorSet, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get valorComprado => $composableBuilder(
      column: $table.valorComprado,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dataCompra => $composableBuilder(
      column: $table.dataCompra, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get quantidade => $composableBuilder(
      column: $table.quantidade, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get vendido => $composableBuilder(
      column: $table.vendido, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get valorVenda => $composableBuilder(
      column: $table.valorVenda, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dataVenda => $composableBuilder(
      column: $table.dataVenda, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notas => $composableBuilder(
      column: $table.notas, builder: (column) => ColumnOrderings(column));

  $$TemasTableOrderingComposer get temaId {
    final $$TemasTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.temaId,
        referencedTable: $db.temas,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TemasTableOrderingComposer(
              $db: $db,
              $table: $db.temas,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SetEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SetEntriesTable> {
  $$SetEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get numeroSet =>
      $composableBuilder(column: $table.numeroSet, builder: (column) => column);

  GeneratedColumn<String> get descricao =>
      $composableBuilder(column: $table.descricao, builder: (column) => column);

  GeneratedColumn<int> get ano =>
      $composableBuilder(column: $table.ano, builder: (column) => column);

  GeneratedColumn<double> get valorSet =>
      $composableBuilder(column: $table.valorSet, builder: (column) => column);

  GeneratedColumn<double> get valorComprado => $composableBuilder(
      column: $table.valorComprado, builder: (column) => column);

  GeneratedColumn<DateTime> get dataCompra => $composableBuilder(
      column: $table.dataCompra, builder: (column) => column);

  GeneratedColumn<int> get quantidade => $composableBuilder(
      column: $table.quantidade, builder: (column) => column);

  GeneratedColumn<bool> get vendido =>
      $composableBuilder(column: $table.vendido, builder: (column) => column);

  GeneratedColumn<double> get valorVenda => $composableBuilder(
      column: $table.valorVenda, builder: (column) => column);

  GeneratedColumn<DateTime> get dataVenda =>
      $composableBuilder(column: $table.dataVenda, builder: (column) => column);

  GeneratedColumn<String> get notas =>
      $composableBuilder(column: $table.notas, builder: (column) => column);

  $$TemasTableAnnotationComposer get temaId {
    final $$TemasTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.temaId,
        referencedTable: $db.temas,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TemasTableAnnotationComposer(
              $db: $db,
              $table: $db.temas,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SetEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SetEntriesTable,
    SetEntry,
    $$SetEntriesTableFilterComposer,
    $$SetEntriesTableOrderingComposer,
    $$SetEntriesTableAnnotationComposer,
    $$SetEntriesTableCreateCompanionBuilder,
    $$SetEntriesTableUpdateCompanionBuilder,
    (SetEntry, $$SetEntriesTableReferences),
    SetEntry,
    PrefetchHooks Function({bool temaId})> {
  $$SetEntriesTableTableManager(_$AppDatabase db, $SetEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SetEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SetEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SetEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> numeroSet = const Value.absent(),
            Value<int> temaId = const Value.absent(),
            Value<String> descricao = const Value.absent(),
            Value<int?> ano = const Value.absent(),
            Value<double> valorSet = const Value.absent(),
            Value<double> valorComprado = const Value.absent(),
            Value<DateTime?> dataCompra = const Value.absent(),
            Value<int> quantidade = const Value.absent(),
            Value<bool> vendido = const Value.absent(),
            Value<double?> valorVenda = const Value.absent(),
            Value<DateTime?> dataVenda = const Value.absent(),
            Value<String?> notas = const Value.absent(),
          }) =>
              SetEntriesCompanion(
            id: id,
            numeroSet: numeroSet,
            temaId: temaId,
            descricao: descricao,
            ano: ano,
            valorSet: valorSet,
            valorComprado: valorComprado,
            dataCompra: dataCompra,
            quantidade: quantidade,
            vendido: vendido,
            valorVenda: valorVenda,
            dataVenda: dataVenda,
            notas: notas,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int numeroSet,
            required int temaId,
            required String descricao,
            Value<int?> ano = const Value.absent(),
            required double valorSet,
            required double valorComprado,
            Value<DateTime?> dataCompra = const Value.absent(),
            Value<int> quantidade = const Value.absent(),
            Value<bool> vendido = const Value.absent(),
            Value<double?> valorVenda = const Value.absent(),
            Value<DateTime?> dataVenda = const Value.absent(),
            Value<String?> notas = const Value.absent(),
          }) =>
              SetEntriesCompanion.insert(
            id: id,
            numeroSet: numeroSet,
            temaId: temaId,
            descricao: descricao,
            ano: ano,
            valorSet: valorSet,
            valorComprado: valorComprado,
            dataCompra: dataCompra,
            quantidade: quantidade,
            vendido: vendido,
            valorVenda: valorVenda,
            dataVenda: dataVenda,
            notas: notas,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$SetEntriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({temaId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (temaId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.temaId,
                    referencedTable:
                        $$SetEntriesTableReferences._temaIdTable(db),
                    referencedColumn:
                        $$SetEntriesTableReferences._temaIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$SetEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SetEntriesTable,
    SetEntry,
    $$SetEntriesTableFilterComposer,
    $$SetEntriesTableOrderingComposer,
    $$SetEntriesTableAnnotationComposer,
    $$SetEntriesTableCreateCompanionBuilder,
    $$SetEntriesTableUpdateCompanionBuilder,
    (SetEntry, $$SetEntriesTableReferences),
    SetEntry,
    PrefetchHooks Function({bool temaId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TemasTableTableManager get temas =>
      $$TemasTableTableManager(_db, _db.temas);
  $$SetEntriesTableTableManager get setEntries =>
      $$SetEntriesTableTableManager(_db, _db.setEntries);
}
