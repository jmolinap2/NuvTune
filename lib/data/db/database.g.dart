// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $FavoritesTable extends Favorites
    with TableInfo<$FavoritesTable, Favorite> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _songIdMeta = const VerificationMeta('songId');
  @override
  late final GeneratedColumn<int> songId = GeneratedColumn<int>(
    'song_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [songId, addedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorites';
  @override
  VerificationContext validateIntegrity(
    Insertable<Favorite> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('song_id')) {
      context.handle(
        _songIdMeta,
        songId.isAcceptableOrUnknown(data['song_id']!, _songIdMeta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {songId};
  @override
  Favorite map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Favorite(
      songId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}song_id'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $FavoritesTable createAlias(String alias) {
    return $FavoritesTable(attachedDatabase, alias);
  }
}

class Favorite extends DataClass implements Insertable<Favorite> {
  final int songId;
  final DateTime addedAt;
  const Favorite({required this.songId, required this.addedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['song_id'] = Variable<int>(songId);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  FavoritesCompanion toCompanion(bool nullToAbsent) {
    return FavoritesCompanion(songId: Value(songId), addedAt: Value(addedAt));
  }

  factory Favorite.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Favorite(
      songId: serializer.fromJson<int>(json['songId']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'songId': serializer.toJson<int>(songId),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  Favorite copyWith({int? songId, DateTime? addedAt}) =>
      Favorite(songId: songId ?? this.songId, addedAt: addedAt ?? this.addedAt);
  Favorite copyWithCompanion(FavoritesCompanion data) {
    return Favorite(
      songId: data.songId.present ? data.songId.value : this.songId,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Favorite(')
          ..write('songId: $songId, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(songId, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Favorite &&
          other.songId == this.songId &&
          other.addedAt == this.addedAt);
}

class FavoritesCompanion extends UpdateCompanion<Favorite> {
  final Value<int> songId;
  final Value<DateTime> addedAt;
  const FavoritesCompanion({
    this.songId = const Value.absent(),
    this.addedAt = const Value.absent(),
  });
  FavoritesCompanion.insert({
    this.songId = const Value.absent(),
    this.addedAt = const Value.absent(),
  });
  static Insertable<Favorite> custom({
    Expression<int>? songId,
    Expression<DateTime>? addedAt,
  }) {
    return RawValuesInsertable({
      if (songId != null) 'song_id': songId,
      if (addedAt != null) 'added_at': addedAt,
    });
  }

  FavoritesCompanion copyWith({Value<int>? songId, Value<DateTime>? addedAt}) {
    return FavoritesCompanion(
      songId: songId ?? this.songId,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (songId.present) {
      map['song_id'] = Variable<int>(songId.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoritesCompanion(')
          ..write('songId: $songId, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }
}

class $PlaylistsTable extends Playlists
    with TableInfo<$PlaylistsTable, Playlist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistsTable(this.attachedDatabase, [this._alias]);
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
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coverPathMeta = const VerificationMeta(
    'coverPath',
  );
  @override
  late final GeneratedColumn<String> coverPath = GeneratedColumn<String>(
    'cover_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _giftModeMeta = const VerificationMeta(
    'giftMode',
  );
  @override
  late final GeneratedColumn<bool> giftMode = GeneratedColumn<bool>(
    'gift_mode',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("gift_mode" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _dedicationMeta = const VerificationMeta(
    'dedication',
  );
  @override
  late final GeneratedColumn<String> dedication = GeneratedColumn<String>(
    'dedication',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _giftFromMeta = const VerificationMeta(
    'giftFrom',
  );
  @override
  late final GeneratedColumn<String> giftFrom = GeneratedColumn<String>(
    'gift_from',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _giftToMeta = const VerificationMeta('giftTo');
  @override
  late final GeneratedColumn<String> giftTo = GeneratedColumn<String>(
    'gift_to',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _giftAccentIdMeta = const VerificationMeta(
    'giftAccentId',
  );
  @override
  late final GeneratedColumn<String> giftAccentId = GeneratedColumn<String>(
    'gift_accent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _giftIdMeta = const VerificationMeta('giftId');
  @override
  late final GeneratedColumn<String> giftId = GeneratedColumn<String>(
    'gift_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    coverPath,
    createdAt,
    updatedAt,
    giftMode,
    dedication,
    giftFrom,
    giftTo,
    giftAccentId,
    giftId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlists';
  @override
  VerificationContext validateIntegrity(
    Insertable<Playlist> instance, {
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
    if (data.containsKey('cover_path')) {
      context.handle(
        _coverPathMeta,
        coverPath.isAcceptableOrUnknown(data['cover_path']!, _coverPathMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('gift_mode')) {
      context.handle(
        _giftModeMeta,
        giftMode.isAcceptableOrUnknown(data['gift_mode']!, _giftModeMeta),
      );
    }
    if (data.containsKey('dedication')) {
      context.handle(
        _dedicationMeta,
        dedication.isAcceptableOrUnknown(data['dedication']!, _dedicationMeta),
      );
    }
    if (data.containsKey('gift_from')) {
      context.handle(
        _giftFromMeta,
        giftFrom.isAcceptableOrUnknown(data['gift_from']!, _giftFromMeta),
      );
    }
    if (data.containsKey('gift_to')) {
      context.handle(
        _giftToMeta,
        giftTo.isAcceptableOrUnknown(data['gift_to']!, _giftToMeta),
      );
    }
    if (data.containsKey('gift_accent_id')) {
      context.handle(
        _giftAccentIdMeta,
        giftAccentId.isAcceptableOrUnknown(
          data['gift_accent_id']!,
          _giftAccentIdMeta,
        ),
      );
    }
    if (data.containsKey('gift_id')) {
      context.handle(
        _giftIdMeta,
        giftId.isAcceptableOrUnknown(data['gift_id']!, _giftIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Playlist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Playlist(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      coverPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_path'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      giftMode: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}gift_mode'],
      )!,
      dedication: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dedication'],
      ),
      giftFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gift_from'],
      ),
      giftTo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gift_to'],
      ),
      giftAccentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gift_accent_id'],
      ),
      giftId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gift_id'],
      ),
    );
  }

  @override
  $PlaylistsTable createAlias(String alias) {
    return $PlaylistsTable(attachedDatabase, alias);
  }
}

class Playlist extends DataClass implements Insertable<Playlist> {
  final int id;
  final String name;

  /// Portada elegida para la lista, guardada dentro de la aplicacion.
  final String? coverPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Modo regalo: presenta la lista con dedicatoria antes de reproducir.
  final bool giftMode;

  /// Dedicatoria mostrada en la portada del modo regalo.
  final String? dedication;

  /// "De" y "Para" del regalo (opcional; si estan vacios no se muestran).
  final String? giftFrom;
  final String? giftTo;

  /// Identidad cromatica elegida para el regalo (uno de AccentIdentity.id).
  final String? giftAccentId;

  /// Identificador estable del paquete recibido. Evita importar dos veces el
  /// mismo regalo aunque Android entregue otra URI o el archivo cambie de
  /// nombre al compartirlo.
  final String? giftId;
  const Playlist({
    required this.id,
    required this.name,
    this.coverPath,
    required this.createdAt,
    required this.updatedAt,
    required this.giftMode,
    this.dedication,
    this.giftFrom,
    this.giftTo,
    this.giftAccentId,
    this.giftId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || coverPath != null) {
      map['cover_path'] = Variable<String>(coverPath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['gift_mode'] = Variable<bool>(giftMode);
    if (!nullToAbsent || dedication != null) {
      map['dedication'] = Variable<String>(dedication);
    }
    if (!nullToAbsent || giftFrom != null) {
      map['gift_from'] = Variable<String>(giftFrom);
    }
    if (!nullToAbsent || giftTo != null) {
      map['gift_to'] = Variable<String>(giftTo);
    }
    if (!nullToAbsent || giftAccentId != null) {
      map['gift_accent_id'] = Variable<String>(giftAccentId);
    }
    if (!nullToAbsent || giftId != null) {
      map['gift_id'] = Variable<String>(giftId);
    }
    return map;
  }

  PlaylistsCompanion toCompanion(bool nullToAbsent) {
    return PlaylistsCompanion(
      id: Value(id),
      name: Value(name),
      coverPath: coverPath == null && nullToAbsent
          ? const Value.absent()
          : Value(coverPath),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      giftMode: Value(giftMode),
      dedication: dedication == null && nullToAbsent
          ? const Value.absent()
          : Value(dedication),
      giftFrom: giftFrom == null && nullToAbsent
          ? const Value.absent()
          : Value(giftFrom),
      giftTo: giftTo == null && nullToAbsent
          ? const Value.absent()
          : Value(giftTo),
      giftAccentId: giftAccentId == null && nullToAbsent
          ? const Value.absent()
          : Value(giftAccentId),
      giftId: giftId == null && nullToAbsent
          ? const Value.absent()
          : Value(giftId),
    );
  }

  factory Playlist.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Playlist(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      coverPath: serializer.fromJson<String?>(json['coverPath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      giftMode: serializer.fromJson<bool>(json['giftMode']),
      dedication: serializer.fromJson<String?>(json['dedication']),
      giftFrom: serializer.fromJson<String?>(json['giftFrom']),
      giftTo: serializer.fromJson<String?>(json['giftTo']),
      giftAccentId: serializer.fromJson<String?>(json['giftAccentId']),
      giftId: serializer.fromJson<String?>(json['giftId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'coverPath': serializer.toJson<String?>(coverPath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'giftMode': serializer.toJson<bool>(giftMode),
      'dedication': serializer.toJson<String?>(dedication),
      'giftFrom': serializer.toJson<String?>(giftFrom),
      'giftTo': serializer.toJson<String?>(giftTo),
      'giftAccentId': serializer.toJson<String?>(giftAccentId),
      'giftId': serializer.toJson<String?>(giftId),
    };
  }

  Playlist copyWith({
    int? id,
    String? name,
    Value<String?> coverPath = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? giftMode,
    Value<String?> dedication = const Value.absent(),
    Value<String?> giftFrom = const Value.absent(),
    Value<String?> giftTo = const Value.absent(),
    Value<String?> giftAccentId = const Value.absent(),
    Value<String?> giftId = const Value.absent(),
  }) => Playlist(
    id: id ?? this.id,
    name: name ?? this.name,
    coverPath: coverPath.present ? coverPath.value : this.coverPath,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    giftMode: giftMode ?? this.giftMode,
    dedication: dedication.present ? dedication.value : this.dedication,
    giftFrom: giftFrom.present ? giftFrom.value : this.giftFrom,
    giftTo: giftTo.present ? giftTo.value : this.giftTo,
    giftAccentId: giftAccentId.present ? giftAccentId.value : this.giftAccentId,
    giftId: giftId.present ? giftId.value : this.giftId,
  );
  Playlist copyWithCompanion(PlaylistsCompanion data) {
    return Playlist(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      coverPath: data.coverPath.present ? data.coverPath.value : this.coverPath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      giftMode: data.giftMode.present ? data.giftMode.value : this.giftMode,
      dedication: data.dedication.present
          ? data.dedication.value
          : this.dedication,
      giftFrom: data.giftFrom.present ? data.giftFrom.value : this.giftFrom,
      giftTo: data.giftTo.present ? data.giftTo.value : this.giftTo,
      giftAccentId: data.giftAccentId.present
          ? data.giftAccentId.value
          : this.giftAccentId,
      giftId: data.giftId.present ? data.giftId.value : this.giftId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Playlist(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('coverPath: $coverPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('giftMode: $giftMode, ')
          ..write('dedication: $dedication, ')
          ..write('giftFrom: $giftFrom, ')
          ..write('giftTo: $giftTo, ')
          ..write('giftAccentId: $giftAccentId, ')
          ..write('giftId: $giftId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    coverPath,
    createdAt,
    updatedAt,
    giftMode,
    dedication,
    giftFrom,
    giftTo,
    giftAccentId,
    giftId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Playlist &&
          other.id == this.id &&
          other.name == this.name &&
          other.coverPath == this.coverPath &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.giftMode == this.giftMode &&
          other.dedication == this.dedication &&
          other.giftFrom == this.giftFrom &&
          other.giftTo == this.giftTo &&
          other.giftAccentId == this.giftAccentId &&
          other.giftId == this.giftId);
}

class PlaylistsCompanion extends UpdateCompanion<Playlist> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> coverPath;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> giftMode;
  final Value<String?> dedication;
  final Value<String?> giftFrom;
  final Value<String?> giftTo;
  final Value<String?> giftAccentId;
  final Value<String?> giftId;
  const PlaylistsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.coverPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.giftMode = const Value.absent(),
    this.dedication = const Value.absent(),
    this.giftFrom = const Value.absent(),
    this.giftTo = const Value.absent(),
    this.giftAccentId = const Value.absent(),
    this.giftId = const Value.absent(),
  });
  PlaylistsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.coverPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.giftMode = const Value.absent(),
    this.dedication = const Value.absent(),
    this.giftFrom = const Value.absent(),
    this.giftTo = const Value.absent(),
    this.giftAccentId = const Value.absent(),
    this.giftId = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Playlist> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? coverPath,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? giftMode,
    Expression<String>? dedication,
    Expression<String>? giftFrom,
    Expression<String>? giftTo,
    Expression<String>? giftAccentId,
    Expression<String>? giftId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (coverPath != null) 'cover_path': coverPath,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (giftMode != null) 'gift_mode': giftMode,
      if (dedication != null) 'dedication': dedication,
      if (giftFrom != null) 'gift_from': giftFrom,
      if (giftTo != null) 'gift_to': giftTo,
      if (giftAccentId != null) 'gift_accent_id': giftAccentId,
      if (giftId != null) 'gift_id': giftId,
    });
  }

  PlaylistsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? coverPath,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? giftMode,
    Value<String?>? dedication,
    Value<String?>? giftFrom,
    Value<String?>? giftTo,
    Value<String?>? giftAccentId,
    Value<String?>? giftId,
  }) {
    return PlaylistsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      coverPath: coverPath ?? this.coverPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      giftMode: giftMode ?? this.giftMode,
      dedication: dedication ?? this.dedication,
      giftFrom: giftFrom ?? this.giftFrom,
      giftTo: giftTo ?? this.giftTo,
      giftAccentId: giftAccentId ?? this.giftAccentId,
      giftId: giftId ?? this.giftId,
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
    if (coverPath.present) {
      map['cover_path'] = Variable<String>(coverPath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (giftMode.present) {
      map['gift_mode'] = Variable<bool>(giftMode.value);
    }
    if (dedication.present) {
      map['dedication'] = Variable<String>(dedication.value);
    }
    if (giftFrom.present) {
      map['gift_from'] = Variable<String>(giftFrom.value);
    }
    if (giftTo.present) {
      map['gift_to'] = Variable<String>(giftTo.value);
    }
    if (giftAccentId.present) {
      map['gift_accent_id'] = Variable<String>(giftAccentId.value);
    }
    if (giftId.present) {
      map['gift_id'] = Variable<String>(giftId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('coverPath: $coverPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('giftMode: $giftMode, ')
          ..write('dedication: $dedication, ')
          ..write('giftFrom: $giftFrom, ')
          ..write('giftTo: $giftTo, ')
          ..write('giftAccentId: $giftAccentId, ')
          ..write('giftId: $giftId')
          ..write(')'))
        .toString();
  }
}

class $PlaylistEntriesTable extends PlaylistEntries
    with TableInfo<$PlaylistEntriesTable, PlaylistEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _playlistIdMeta = const VerificationMeta(
    'playlistId',
  );
  @override
  late final GeneratedColumn<int> playlistId = GeneratedColumn<int>(
    'playlist_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES playlists (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _songIdMeta = const VerificationMeta('songId');
  @override
  late final GeneratedColumn<int> songId = GeneratedColumn<int>(
    'song_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [playlistId, songId, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlist_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaylistEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('playlist_id')) {
      context.handle(
        _playlistIdMeta,
        playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('song_id')) {
      context.handle(
        _songIdMeta,
        songId.isAcceptableOrUnknown(data['song_id']!, _songIdMeta),
      );
    } else if (isInserting) {
      context.missing(_songIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {playlistId, position};
  @override
  PlaylistEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaylistEntry(
      playlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}playlist_id'],
      )!,
      songId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}song_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $PlaylistEntriesTable createAlias(String alias) {
    return $PlaylistEntriesTable(attachedDatabase, alias);
  }
}

class PlaylistEntry extends DataClass implements Insertable<PlaylistEntry> {
  final int playlistId;
  final int songId;
  final int position;
  const PlaylistEntry({
    required this.playlistId,
    required this.songId,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['playlist_id'] = Variable<int>(playlistId);
    map['song_id'] = Variable<int>(songId);
    map['position'] = Variable<int>(position);
    return map;
  }

  PlaylistEntriesCompanion toCompanion(bool nullToAbsent) {
    return PlaylistEntriesCompanion(
      playlistId: Value(playlistId),
      songId: Value(songId),
      position: Value(position),
    );
  }

  factory PlaylistEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaylistEntry(
      playlistId: serializer.fromJson<int>(json['playlistId']),
      songId: serializer.fromJson<int>(json['songId']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'playlistId': serializer.toJson<int>(playlistId),
      'songId': serializer.toJson<int>(songId),
      'position': serializer.toJson<int>(position),
    };
  }

  PlaylistEntry copyWith({int? playlistId, int? songId, int? position}) =>
      PlaylistEntry(
        playlistId: playlistId ?? this.playlistId,
        songId: songId ?? this.songId,
        position: position ?? this.position,
      );
  PlaylistEntry copyWithCompanion(PlaylistEntriesCompanion data) {
    return PlaylistEntry(
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      songId: data.songId.present ? data.songId.value : this.songId,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistEntry(')
          ..write('playlistId: $playlistId, ')
          ..write('songId: $songId, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(playlistId, songId, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistEntry &&
          other.playlistId == this.playlistId &&
          other.songId == this.songId &&
          other.position == this.position);
}

class PlaylistEntriesCompanion extends UpdateCompanion<PlaylistEntry> {
  final Value<int> playlistId;
  final Value<int> songId;
  final Value<int> position;
  final Value<int> rowid;
  const PlaylistEntriesCompanion({
    this.playlistId = const Value.absent(),
    this.songId = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaylistEntriesCompanion.insert({
    required int playlistId,
    required int songId,
    required int position,
    this.rowid = const Value.absent(),
  }) : playlistId = Value(playlistId),
       songId = Value(songId),
       position = Value(position);
  static Insertable<PlaylistEntry> custom({
    Expression<int>? playlistId,
    Expression<int>? songId,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (playlistId != null) 'playlist_id': playlistId,
      if (songId != null) 'song_id': songId,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaylistEntriesCompanion copyWith({
    Value<int>? playlistId,
    Value<int>? songId,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return PlaylistEntriesCompanion(
      playlistId: playlistId ?? this.playlistId,
      songId: songId ?? this.songId,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (playlistId.present) {
      map['playlist_id'] = Variable<int>(playlistId.value);
    }
    if (songId.present) {
      map['song_id'] = Variable<int>(songId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistEntriesCompanion(')
          ..write('playlistId: $playlistId, ')
          ..write('songId: $songId, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlayHistoryTable extends PlayHistory
    with TableInfo<$PlayHistoryTable, PlayHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayHistoryTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _songIdMeta = const VerificationMeta('songId');
  @override
  late final GeneratedColumn<int> songId = GeneratedColumn<int>(
    'song_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playedAtMeta = const VerificationMeta(
    'playedAt',
  );
  @override
  late final GeneratedColumn<DateTime> playedAt = GeneratedColumn<DateTime>(
    'played_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, songId, playedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'play_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlayHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('song_id')) {
      context.handle(
        _songIdMeta,
        songId.isAcceptableOrUnknown(data['song_id']!, _songIdMeta),
      );
    } else if (isInserting) {
      context.missing(_songIdMeta);
    }
    if (data.containsKey('played_at')) {
      context.handle(
        _playedAtMeta,
        playedAt.isAcceptableOrUnknown(data['played_at']!, _playedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlayHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlayHistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      songId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}song_id'],
      )!,
      playedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}played_at'],
      )!,
    );
  }

  @override
  $PlayHistoryTable createAlias(String alias) {
    return $PlayHistoryTable(attachedDatabase, alias);
  }
}

class PlayHistoryData extends DataClass implements Insertable<PlayHistoryData> {
  final int id;
  final int songId;
  final DateTime playedAt;
  const PlayHistoryData({
    required this.id,
    required this.songId,
    required this.playedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['song_id'] = Variable<int>(songId);
    map['played_at'] = Variable<DateTime>(playedAt);
    return map;
  }

  PlayHistoryCompanion toCompanion(bool nullToAbsent) {
    return PlayHistoryCompanion(
      id: Value(id),
      songId: Value(songId),
      playedAt: Value(playedAt),
    );
  }

  factory PlayHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlayHistoryData(
      id: serializer.fromJson<int>(json['id']),
      songId: serializer.fromJson<int>(json['songId']),
      playedAt: serializer.fromJson<DateTime>(json['playedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'songId': serializer.toJson<int>(songId),
      'playedAt': serializer.toJson<DateTime>(playedAt),
    };
  }

  PlayHistoryData copyWith({int? id, int? songId, DateTime? playedAt}) =>
      PlayHistoryData(
        id: id ?? this.id,
        songId: songId ?? this.songId,
        playedAt: playedAt ?? this.playedAt,
      );
  PlayHistoryData copyWithCompanion(PlayHistoryCompanion data) {
    return PlayHistoryData(
      id: data.id.present ? data.id.value : this.id,
      songId: data.songId.present ? data.songId.value : this.songId,
      playedAt: data.playedAt.present ? data.playedAt.value : this.playedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlayHistoryData(')
          ..write('id: $id, ')
          ..write('songId: $songId, ')
          ..write('playedAt: $playedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, songId, playedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayHistoryData &&
          other.id == this.id &&
          other.songId == this.songId &&
          other.playedAt == this.playedAt);
}

class PlayHistoryCompanion extends UpdateCompanion<PlayHistoryData> {
  final Value<int> id;
  final Value<int> songId;
  final Value<DateTime> playedAt;
  const PlayHistoryCompanion({
    this.id = const Value.absent(),
    this.songId = const Value.absent(),
    this.playedAt = const Value.absent(),
  });
  PlayHistoryCompanion.insert({
    this.id = const Value.absent(),
    required int songId,
    this.playedAt = const Value.absent(),
  }) : songId = Value(songId);
  static Insertable<PlayHistoryData> custom({
    Expression<int>? id,
    Expression<int>? songId,
    Expression<DateTime>? playedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (songId != null) 'song_id': songId,
      if (playedAt != null) 'played_at': playedAt,
    });
  }

  PlayHistoryCompanion copyWith({
    Value<int>? id,
    Value<int>? songId,
    Value<DateTime>? playedAt,
  }) {
    return PlayHistoryCompanion(
      id: id ?? this.id,
      songId: songId ?? this.songId,
      playedAt: playedAt ?? this.playedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (songId.present) {
      map['song_id'] = Variable<int>(songId.value);
    }
    if (playedAt.present) {
      map['played_at'] = Variable<DateTime>(playedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayHistoryCompanion(')
          ..write('id: $id, ')
          ..write('songId: $songId, ')
          ..write('playedAt: $playedAt')
          ..write(')'))
        .toString();
  }
}

class $PlayCountsTable extends PlayCounts
    with TableInfo<$PlayCountsTable, PlayCount> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayCountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _songIdMeta = const VerificationMeta('songId');
  @override
  late final GeneratedColumn<int> songId = GeneratedColumn<int>(
    'song_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _countMeta = const VerificationMeta('count');
  @override
  late final GeneratedColumn<int> count = GeneratedColumn<int>(
    'count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastPlayedAtMeta = const VerificationMeta(
    'lastPlayedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPlayedAt = GeneratedColumn<DateTime>(
    'last_played_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [songId, count, lastPlayedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'play_counts';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlayCount> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('song_id')) {
      context.handle(
        _songIdMeta,
        songId.isAcceptableOrUnknown(data['song_id']!, _songIdMeta),
      );
    }
    if (data.containsKey('count')) {
      context.handle(
        _countMeta,
        count.isAcceptableOrUnknown(data['count']!, _countMeta),
      );
    }
    if (data.containsKey('last_played_at')) {
      context.handle(
        _lastPlayedAtMeta,
        lastPlayedAt.isAcceptableOrUnknown(
          data['last_played_at']!,
          _lastPlayedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {songId};
  @override
  PlayCount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlayCount(
      songId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}song_id'],
      )!,
      count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}count'],
      )!,
      lastPlayedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_played_at'],
      ),
    );
  }

  @override
  $PlayCountsTable createAlias(String alias) {
    return $PlayCountsTable(attachedDatabase, alias);
  }
}

class PlayCount extends DataClass implements Insertable<PlayCount> {
  final int songId;
  final int count;
  final DateTime? lastPlayedAt;
  const PlayCount({
    required this.songId,
    required this.count,
    this.lastPlayedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['song_id'] = Variable<int>(songId);
    map['count'] = Variable<int>(count);
    if (!nullToAbsent || lastPlayedAt != null) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt);
    }
    return map;
  }

  PlayCountsCompanion toCompanion(bool nullToAbsent) {
    return PlayCountsCompanion(
      songId: Value(songId),
      count: Value(count),
      lastPlayedAt: lastPlayedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPlayedAt),
    );
  }

  factory PlayCount.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlayCount(
      songId: serializer.fromJson<int>(json['songId']),
      count: serializer.fromJson<int>(json['count']),
      lastPlayedAt: serializer.fromJson<DateTime?>(json['lastPlayedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'songId': serializer.toJson<int>(songId),
      'count': serializer.toJson<int>(count),
      'lastPlayedAt': serializer.toJson<DateTime?>(lastPlayedAt),
    };
  }

  PlayCount copyWith({
    int? songId,
    int? count,
    Value<DateTime?> lastPlayedAt = const Value.absent(),
  }) => PlayCount(
    songId: songId ?? this.songId,
    count: count ?? this.count,
    lastPlayedAt: lastPlayedAt.present ? lastPlayedAt.value : this.lastPlayedAt,
  );
  PlayCount copyWithCompanion(PlayCountsCompanion data) {
    return PlayCount(
      songId: data.songId.present ? data.songId.value : this.songId,
      count: data.count.present ? data.count.value : this.count,
      lastPlayedAt: data.lastPlayedAt.present
          ? data.lastPlayedAt.value
          : this.lastPlayedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlayCount(')
          ..write('songId: $songId, ')
          ..write('count: $count, ')
          ..write('lastPlayedAt: $lastPlayedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(songId, count, lastPlayedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayCount &&
          other.songId == this.songId &&
          other.count == this.count &&
          other.lastPlayedAt == this.lastPlayedAt);
}

class PlayCountsCompanion extends UpdateCompanion<PlayCount> {
  final Value<int> songId;
  final Value<int> count;
  final Value<DateTime?> lastPlayedAt;
  const PlayCountsCompanion({
    this.songId = const Value.absent(),
    this.count = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
  });
  PlayCountsCompanion.insert({
    this.songId = const Value.absent(),
    this.count = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
  });
  static Insertable<PlayCount> custom({
    Expression<int>? songId,
    Expression<int>? count,
    Expression<DateTime>? lastPlayedAt,
  }) {
    return RawValuesInsertable({
      if (songId != null) 'song_id': songId,
      if (count != null) 'count': count,
      if (lastPlayedAt != null) 'last_played_at': lastPlayedAt,
    });
  }

  PlayCountsCompanion copyWith({
    Value<int>? songId,
    Value<int>? count,
    Value<DateTime?>? lastPlayedAt,
  }) {
    return PlayCountsCompanion(
      songId: songId ?? this.songId,
      count: count ?? this.count,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (songId.present) {
      map['song_id'] = Variable<int>(songId.value);
    }
    if (count.present) {
      map['count'] = Variable<int>(count.value);
    }
    if (lastPlayedAt.present) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayCountsCompanion(')
          ..write('songId: $songId, ')
          ..write('count: $count, ')
          ..write('lastPlayedAt: $lastPlayedAt')
          ..write(')'))
        .toString();
  }
}

class $QueueEntriesTable extends QueueEntries
    with TableInfo<$QueueEntriesTable, QueueEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QueueEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _songIdMeta = const VerificationMeta('songId');
  @override
  late final GeneratedColumn<int> songId = GeneratedColumn<int>(
    'song_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [position, songId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'queue_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<QueueEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('song_id')) {
      context.handle(
        _songIdMeta,
        songId.isAcceptableOrUnknown(data['song_id']!, _songIdMeta),
      );
    } else if (isInserting) {
      context.missing(_songIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {position};
  @override
  QueueEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QueueEntry(
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      songId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}song_id'],
      )!,
    );
  }

  @override
  $QueueEntriesTable createAlias(String alias) {
    return $QueueEntriesTable(attachedDatabase, alias);
  }
}

class QueueEntry extends DataClass implements Insertable<QueueEntry> {
  final int position;
  final int songId;
  const QueueEntry({required this.position, required this.songId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['position'] = Variable<int>(position);
    map['song_id'] = Variable<int>(songId);
    return map;
  }

  QueueEntriesCompanion toCompanion(bool nullToAbsent) {
    return QueueEntriesCompanion(
      position: Value(position),
      songId: Value(songId),
    );
  }

  factory QueueEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QueueEntry(
      position: serializer.fromJson<int>(json['position']),
      songId: serializer.fromJson<int>(json['songId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'position': serializer.toJson<int>(position),
      'songId': serializer.toJson<int>(songId),
    };
  }

  QueueEntry copyWith({int? position, int? songId}) => QueueEntry(
    position: position ?? this.position,
    songId: songId ?? this.songId,
  );
  QueueEntry copyWithCompanion(QueueEntriesCompanion data) {
    return QueueEntry(
      position: data.position.present ? data.position.value : this.position,
      songId: data.songId.present ? data.songId.value : this.songId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QueueEntry(')
          ..write('position: $position, ')
          ..write('songId: $songId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(position, songId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QueueEntry &&
          other.position == this.position &&
          other.songId == this.songId);
}

class QueueEntriesCompanion extends UpdateCompanion<QueueEntry> {
  final Value<int> position;
  final Value<int> songId;
  const QueueEntriesCompanion({
    this.position = const Value.absent(),
    this.songId = const Value.absent(),
  });
  QueueEntriesCompanion.insert({
    this.position = const Value.absent(),
    required int songId,
  }) : songId = Value(songId);
  static Insertable<QueueEntry> custom({
    Expression<int>? position,
    Expression<int>? songId,
  }) {
    return RawValuesInsertable({
      if (position != null) 'position': position,
      if (songId != null) 'song_id': songId,
    });
  }

  QueueEntriesCompanion copyWith({Value<int>? position, Value<int>? songId}) {
    return QueueEntriesCompanion(
      position: position ?? this.position,
      songId: songId ?? this.songId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (songId.present) {
      map['song_id'] = Variable<int>(songId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QueueEntriesCompanion(')
          ..write('position: $position, ')
          ..write('songId: $songId')
          ..write(')'))
        .toString();
  }
}

class $QueueStateTable extends QueueState
    with TableInfo<$QueueStateTable, QueueStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QueueStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _currentIndexMeta = const VerificationMeta(
    'currentIndex',
  );
  @override
  late final GeneratedColumn<int> currentIndex = GeneratedColumn<int>(
    'current_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(-1),
  );
  static const VerificationMeta _positionMsMeta = const VerificationMeta(
    'positionMs',
  );
  @override
  late final GeneratedColumn<int> positionMs = GeneratedColumn<int>(
    'position_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _repeatModeMeta = const VerificationMeta(
    'repeatMode',
  );
  @override
  late final GeneratedColumn<int> repeatMode = GeneratedColumn<int>(
    'repeat_mode',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _shuffleEnabledMeta = const VerificationMeta(
    'shuffleEnabled',
  );
  @override
  late final GeneratedColumn<bool> shuffleEnabled = GeneratedColumn<bool>(
    'shuffle_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("shuffle_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    currentIndex,
    positionMs,
    repeatMode,
    shuffleEnabled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'queue_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<QueueStateData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('current_index')) {
      context.handle(
        _currentIndexMeta,
        currentIndex.isAcceptableOrUnknown(
          data['current_index']!,
          _currentIndexMeta,
        ),
      );
    }
    if (data.containsKey('position_ms')) {
      context.handle(
        _positionMsMeta,
        positionMs.isAcceptableOrUnknown(data['position_ms']!, _positionMsMeta),
      );
    }
    if (data.containsKey('repeat_mode')) {
      context.handle(
        _repeatModeMeta,
        repeatMode.isAcceptableOrUnknown(data['repeat_mode']!, _repeatModeMeta),
      );
    }
    if (data.containsKey('shuffle_enabled')) {
      context.handle(
        _shuffleEnabledMeta,
        shuffleEnabled.isAcceptableOrUnknown(
          data['shuffle_enabled']!,
          _shuffleEnabledMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QueueStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QueueStateData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      currentIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_index'],
      )!,
      positionMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position_ms'],
      )!,
      repeatMode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repeat_mode'],
      )!,
      shuffleEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}shuffle_enabled'],
      )!,
    );
  }

  @override
  $QueueStateTable createAlias(String alias) {
    return $QueueStateTable(attachedDatabase, alias);
  }
}

class QueueStateData extends DataClass implements Insertable<QueueStateData> {
  final int id;
  final int currentIndex;
  final int positionMs;

  /// Indice de [RepeatMode] del contrato con el motor.
  final int repeatMode;
  final bool shuffleEnabled;
  const QueueStateData({
    required this.id,
    required this.currentIndex,
    required this.positionMs,
    required this.repeatMode,
    required this.shuffleEnabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['current_index'] = Variable<int>(currentIndex);
    map['position_ms'] = Variable<int>(positionMs);
    map['repeat_mode'] = Variable<int>(repeatMode);
    map['shuffle_enabled'] = Variable<bool>(shuffleEnabled);
    return map;
  }

  QueueStateCompanion toCompanion(bool nullToAbsent) {
    return QueueStateCompanion(
      id: Value(id),
      currentIndex: Value(currentIndex),
      positionMs: Value(positionMs),
      repeatMode: Value(repeatMode),
      shuffleEnabled: Value(shuffleEnabled),
    );
  }

  factory QueueStateData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QueueStateData(
      id: serializer.fromJson<int>(json['id']),
      currentIndex: serializer.fromJson<int>(json['currentIndex']),
      positionMs: serializer.fromJson<int>(json['positionMs']),
      repeatMode: serializer.fromJson<int>(json['repeatMode']),
      shuffleEnabled: serializer.fromJson<bool>(json['shuffleEnabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'currentIndex': serializer.toJson<int>(currentIndex),
      'positionMs': serializer.toJson<int>(positionMs),
      'repeatMode': serializer.toJson<int>(repeatMode),
      'shuffleEnabled': serializer.toJson<bool>(shuffleEnabled),
    };
  }

  QueueStateData copyWith({
    int? id,
    int? currentIndex,
    int? positionMs,
    int? repeatMode,
    bool? shuffleEnabled,
  }) => QueueStateData(
    id: id ?? this.id,
    currentIndex: currentIndex ?? this.currentIndex,
    positionMs: positionMs ?? this.positionMs,
    repeatMode: repeatMode ?? this.repeatMode,
    shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
  );
  QueueStateData copyWithCompanion(QueueStateCompanion data) {
    return QueueStateData(
      id: data.id.present ? data.id.value : this.id,
      currentIndex: data.currentIndex.present
          ? data.currentIndex.value
          : this.currentIndex,
      positionMs: data.positionMs.present
          ? data.positionMs.value
          : this.positionMs,
      repeatMode: data.repeatMode.present
          ? data.repeatMode.value
          : this.repeatMode,
      shuffleEnabled: data.shuffleEnabled.present
          ? data.shuffleEnabled.value
          : this.shuffleEnabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QueueStateData(')
          ..write('id: $id, ')
          ..write('currentIndex: $currentIndex, ')
          ..write('positionMs: $positionMs, ')
          ..write('repeatMode: $repeatMode, ')
          ..write('shuffleEnabled: $shuffleEnabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, currentIndex, positionMs, repeatMode, shuffleEnabled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QueueStateData &&
          other.id == this.id &&
          other.currentIndex == this.currentIndex &&
          other.positionMs == this.positionMs &&
          other.repeatMode == this.repeatMode &&
          other.shuffleEnabled == this.shuffleEnabled);
}

class QueueStateCompanion extends UpdateCompanion<QueueStateData> {
  final Value<int> id;
  final Value<int> currentIndex;
  final Value<int> positionMs;
  final Value<int> repeatMode;
  final Value<bool> shuffleEnabled;
  const QueueStateCompanion({
    this.id = const Value.absent(),
    this.currentIndex = const Value.absent(),
    this.positionMs = const Value.absent(),
    this.repeatMode = const Value.absent(),
    this.shuffleEnabled = const Value.absent(),
  });
  QueueStateCompanion.insert({
    this.id = const Value.absent(),
    this.currentIndex = const Value.absent(),
    this.positionMs = const Value.absent(),
    this.repeatMode = const Value.absent(),
    this.shuffleEnabled = const Value.absent(),
  });
  static Insertable<QueueStateData> custom({
    Expression<int>? id,
    Expression<int>? currentIndex,
    Expression<int>? positionMs,
    Expression<int>? repeatMode,
    Expression<bool>? shuffleEnabled,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (currentIndex != null) 'current_index': currentIndex,
      if (positionMs != null) 'position_ms': positionMs,
      if (repeatMode != null) 'repeat_mode': repeatMode,
      if (shuffleEnabled != null) 'shuffle_enabled': shuffleEnabled,
    });
  }

  QueueStateCompanion copyWith({
    Value<int>? id,
    Value<int>? currentIndex,
    Value<int>? positionMs,
    Value<int>? repeatMode,
    Value<bool>? shuffleEnabled,
  }) {
    return QueueStateCompanion(
      id: id ?? this.id,
      currentIndex: currentIndex ?? this.currentIndex,
      positionMs: positionMs ?? this.positionMs,
      repeatMode: repeatMode ?? this.repeatMode,
      shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (currentIndex.present) {
      map['current_index'] = Variable<int>(currentIndex.value);
    }
    if (positionMs.present) {
      map['position_ms'] = Variable<int>(positionMs.value);
    }
    if (repeatMode.present) {
      map['repeat_mode'] = Variable<int>(repeatMode.value);
    }
    if (shuffleEnabled.present) {
      map['shuffle_enabled'] = Variable<bool>(shuffleEnabled.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QueueStateCompanion(')
          ..write('id: $id, ')
          ..write('currentIndex: $currentIndex, ')
          ..write('positionMs: $positionMs, ')
          ..write('repeatMode: $repeatMode, ')
          ..write('shuffleEnabled: $shuffleEnabled')
          ..write(')'))
        .toString();
  }
}

class $ExcludedFoldersTable extends ExcludedFolders
    with TableInfo<$ExcludedFoldersTable, ExcludedFolder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExcludedFoldersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [path];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'excluded_folders';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExcludedFolder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {path};
  @override
  ExcludedFolder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExcludedFolder(
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
    );
  }

  @override
  $ExcludedFoldersTable createAlias(String alias) {
    return $ExcludedFoldersTable(attachedDatabase, alias);
  }
}

class ExcludedFolder extends DataClass implements Insertable<ExcludedFolder> {
  final String path;
  const ExcludedFolder({required this.path});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['path'] = Variable<String>(path);
    return map;
  }

  ExcludedFoldersCompanion toCompanion(bool nullToAbsent) {
    return ExcludedFoldersCompanion(path: Value(path));
  }

  factory ExcludedFolder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExcludedFolder(path: serializer.fromJson<String>(json['path']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'path': serializer.toJson<String>(path)};
  }

  ExcludedFolder copyWith({String? path}) =>
      ExcludedFolder(path: path ?? this.path);
  ExcludedFolder copyWithCompanion(ExcludedFoldersCompanion data) {
    return ExcludedFolder(
      path: data.path.present ? data.path.value : this.path,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExcludedFolder(')
          ..write('path: $path')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => path.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExcludedFolder && other.path == this.path);
}

class ExcludedFoldersCompanion extends UpdateCompanion<ExcludedFolder> {
  final Value<String> path;
  final Value<int> rowid;
  const ExcludedFoldersCompanion({
    this.path = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExcludedFoldersCompanion.insert({
    required String path,
    this.rowid = const Value.absent(),
  }) : path = Value(path);
  static Insertable<ExcludedFolder> custom({
    Expression<String>? path,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (path != null) 'path': path,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExcludedFoldersCompanion copyWith({Value<String>? path, Value<int>? rowid}) {
    return ExcludedFoldersCompanion(
      path: path ?? this.path,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExcludedFoldersCompanion(')
          ..write('path: $path, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SourceFoldersTable extends SourceFolders
    with TableInfo<$SourceFoldersTable, SourceFolder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SourceFoldersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uriMeta = const VerificationMeta('uri');
  @override
  late final GeneratedColumn<String> uri = GeneratedColumn<String>(
    'uri',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayPathMeta = const VerificationMeta(
    'displayPath',
  );
  @override
  late final GeneratedColumn<String> displayPath = GeneratedColumn<String>(
    'display_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [uri, displayPath];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'source_folders';
  @override
  VerificationContext validateIntegrity(
    Insertable<SourceFolder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uri')) {
      context.handle(
        _uriMeta,
        uri.isAcceptableOrUnknown(data['uri']!, _uriMeta),
      );
    } else if (isInserting) {
      context.missing(_uriMeta);
    }
    if (data.containsKey('display_path')) {
      context.handle(
        _displayPathMeta,
        displayPath.isAcceptableOrUnknown(
          data['display_path']!,
          _displayPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayPathMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uri};
  @override
  SourceFolder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SourceFolder(
      uri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uri'],
      )!,
      displayPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_path'],
      )!,
    );
  }

  @override
  $SourceFoldersTable createAlias(String alias) {
    return $SourceFoldersTable(attachedDatabase, alias);
  }
}

class SourceFolder extends DataClass implements Insertable<SourceFolder> {
  final String uri;
  final String displayPath;
  const SourceFolder({required this.uri, required this.displayPath});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uri'] = Variable<String>(uri);
    map['display_path'] = Variable<String>(displayPath);
    return map;
  }

  SourceFoldersCompanion toCompanion(bool nullToAbsent) {
    return SourceFoldersCompanion(
      uri: Value(uri),
      displayPath: Value(displayPath),
    );
  }

  factory SourceFolder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SourceFolder(
      uri: serializer.fromJson<String>(json['uri']),
      displayPath: serializer.fromJson<String>(json['displayPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uri': serializer.toJson<String>(uri),
      'displayPath': serializer.toJson<String>(displayPath),
    };
  }

  SourceFolder copyWith({String? uri, String? displayPath}) => SourceFolder(
    uri: uri ?? this.uri,
    displayPath: displayPath ?? this.displayPath,
  );
  SourceFolder copyWithCompanion(SourceFoldersCompanion data) {
    return SourceFolder(
      uri: data.uri.present ? data.uri.value : this.uri,
      displayPath: data.displayPath.present
          ? data.displayPath.value
          : this.displayPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SourceFolder(')
          ..write('uri: $uri, ')
          ..write('displayPath: $displayPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(uri, displayPath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SourceFolder &&
          other.uri == this.uri &&
          other.displayPath == this.displayPath);
}

class SourceFoldersCompanion extends UpdateCompanion<SourceFolder> {
  final Value<String> uri;
  final Value<String> displayPath;
  final Value<int> rowid;
  const SourceFoldersCompanion({
    this.uri = const Value.absent(),
    this.displayPath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SourceFoldersCompanion.insert({
    required String uri,
    required String displayPath,
    this.rowid = const Value.absent(),
  }) : uri = Value(uri),
       displayPath = Value(displayPath);
  static Insertable<SourceFolder> custom({
    Expression<String>? uri,
    Expression<String>? displayPath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uri != null) 'uri': uri,
      if (displayPath != null) 'display_path': displayPath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SourceFoldersCompanion copyWith({
    Value<String>? uri,
    Value<String>? displayPath,
    Value<int>? rowid,
  }) {
    return SourceFoldersCompanion(
      uri: uri ?? this.uri,
      displayPath: displayPath ?? this.displayPath,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uri.present) {
      map['uri'] = Variable<String>(uri.value);
    }
    if (displayPath.present) {
      map['display_path'] = Variable<String>(displayPath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SourceFoldersCompanion(')
          ..write('uri: $uri, ')
          ..write('displayPath: $displayPath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomCoversTable extends CustomCovers
    with TableInfo<$CustomCoversTable, CustomCover> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomCoversTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _targetMeta = const VerificationMeta('target');
  @override
  late final GeneratedColumn<String> target = GeneratedColumn<String>(
    'target',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [target, imagePath, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_covers';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomCover> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('target')) {
      context.handle(
        _targetMeta,
        target.isAcceptableOrUnknown(data['target']!, _targetMeta),
      );
    } else if (isInserting) {
      context.missing(_targetMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    } else if (isInserting) {
      context.missing(_imagePathMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {target};
  @override
  CustomCover map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomCover(
      target: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CustomCoversTable createAlias(String alias) {
    return $CustomCoversTable(attachedDatabase, alias);
  }
}

class CustomCover extends DataClass implements Insertable<CustomCover> {
  /// `song:<id>` o `album:<id>`.
  final String target;
  final String imagePath;
  final DateTime updatedAt;
  const CustomCover({
    required this.target,
    required this.imagePath,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['target'] = Variable<String>(target);
    map['image_path'] = Variable<String>(imagePath);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CustomCoversCompanion toCompanion(bool nullToAbsent) {
    return CustomCoversCompanion(
      target: Value(target),
      imagePath: Value(imagePath),
      updatedAt: Value(updatedAt),
    );
  }

  factory CustomCover.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomCover(
      target: serializer.fromJson<String>(json['target']),
      imagePath: serializer.fromJson<String>(json['imagePath']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'target': serializer.toJson<String>(target),
      'imagePath': serializer.toJson<String>(imagePath),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CustomCover copyWith({
    String? target,
    String? imagePath,
    DateTime? updatedAt,
  }) => CustomCover(
    target: target ?? this.target,
    imagePath: imagePath ?? this.imagePath,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CustomCover copyWithCompanion(CustomCoversCompanion data) {
    return CustomCover(
      target: data.target.present ? data.target.value : this.target,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomCover(')
          ..write('target: $target, ')
          ..write('imagePath: $imagePath, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(target, imagePath, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomCover &&
          other.target == this.target &&
          other.imagePath == this.imagePath &&
          other.updatedAt == this.updatedAt);
}

class CustomCoversCompanion extends UpdateCompanion<CustomCover> {
  final Value<String> target;
  final Value<String> imagePath;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CustomCoversCompanion({
    this.target = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomCoversCompanion.insert({
    required String target,
    required String imagePath,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : target = Value(target),
       imagePath = Value(imagePath);
  static Insertable<CustomCover> custom({
    Expression<String>? target,
    Expression<String>? imagePath,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (target != null) 'target': target,
      if (imagePath != null) 'image_path': imagePath,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomCoversCompanion copyWith({
    Value<String>? target,
    Value<String>? imagePath,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CustomCoversCompanion(
      target: target ?? this.target,
      imagePath: imagePath ?? this.imagePath,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (target.present) {
      map['target'] = Variable<String>(target.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomCoversCompanion(')
          ..write('target: $target, ')
          ..write('imagePath: $imagePath, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EqualizerPresetsTableTable extends EqualizerPresetsTable
    with TableInfo<$EqualizerPresetsTableTable, EqualizerPreset> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EqualizerPresetsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bandCountMeta = const VerificationMeta(
    'bandCount',
  );
  @override
  late final GeneratedColumn<int> bandCount = GeneratedColumn<int>(
    'band_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gainsJsonMeta = const VerificationMeta(
    'gainsJson',
  );
  @override
  late final GeneratedColumn<String> gainsJson = GeneratedColumn<String>(
    'gains_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _preampDbMeta = const VerificationMeta(
    'preampDb',
  );
  @override
  late final GeneratedColumn<double> preampDb = GeneratedColumn<double>(
    'preamp_db',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [name, bandCount, gainsJson, preampDb];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'equalizer_presets';
  @override
  VerificationContext validateIntegrity(
    Insertable<EqualizerPreset> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('band_count')) {
      context.handle(
        _bandCountMeta,
        bandCount.isAcceptableOrUnknown(data['band_count']!, _bandCountMeta),
      );
    } else if (isInserting) {
      context.missing(_bandCountMeta);
    }
    if (data.containsKey('gains_json')) {
      context.handle(
        _gainsJsonMeta,
        gainsJson.isAcceptableOrUnknown(data['gains_json']!, _gainsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_gainsJsonMeta);
    }
    if (data.containsKey('preamp_db')) {
      context.handle(
        _preampDbMeta,
        preampDb.isAcceptableOrUnknown(data['preamp_db']!, _preampDbMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {name};
  @override
  EqualizerPreset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EqualizerPreset(
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      bandCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}band_count'],
      )!,
      gainsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gains_json'],
      )!,
      preampDb: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}preamp_db'],
      )!,
    );
  }

  @override
  $EqualizerPresetsTableTable createAlias(String alias) {
    return $EqualizerPresetsTableTable(attachedDatabase, alias);
  }
}

class EqualizerPreset extends DataClass implements Insertable<EqualizerPreset> {
  final String name;
  final int bandCount;

  /// Ganancias en dB codificadas como JSON.
  final String gainsJson;
  final double preampDb;
  const EqualizerPreset({
    required this.name,
    required this.bandCount,
    required this.gainsJson,
    required this.preampDb,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    map['band_count'] = Variable<int>(bandCount);
    map['gains_json'] = Variable<String>(gainsJson);
    map['preamp_db'] = Variable<double>(preampDb);
    return map;
  }

  EqualizerPresetsTableCompanion toCompanion(bool nullToAbsent) {
    return EqualizerPresetsTableCompanion(
      name: Value(name),
      bandCount: Value(bandCount),
      gainsJson: Value(gainsJson),
      preampDb: Value(preampDb),
    );
  }

  factory EqualizerPreset.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EqualizerPreset(
      name: serializer.fromJson<String>(json['name']),
      bandCount: serializer.fromJson<int>(json['bandCount']),
      gainsJson: serializer.fromJson<String>(json['gainsJson']),
      preampDb: serializer.fromJson<double>(json['preampDb']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'bandCount': serializer.toJson<int>(bandCount),
      'gainsJson': serializer.toJson<String>(gainsJson),
      'preampDb': serializer.toJson<double>(preampDb),
    };
  }

  EqualizerPreset copyWith({
    String? name,
    int? bandCount,
    String? gainsJson,
    double? preampDb,
  }) => EqualizerPreset(
    name: name ?? this.name,
    bandCount: bandCount ?? this.bandCount,
    gainsJson: gainsJson ?? this.gainsJson,
    preampDb: preampDb ?? this.preampDb,
  );
  EqualizerPreset copyWithCompanion(EqualizerPresetsTableCompanion data) {
    return EqualizerPreset(
      name: data.name.present ? data.name.value : this.name,
      bandCount: data.bandCount.present ? data.bandCount.value : this.bandCount,
      gainsJson: data.gainsJson.present ? data.gainsJson.value : this.gainsJson,
      preampDb: data.preampDb.present ? data.preampDb.value : this.preampDb,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EqualizerPreset(')
          ..write('name: $name, ')
          ..write('bandCount: $bandCount, ')
          ..write('gainsJson: $gainsJson, ')
          ..write('preampDb: $preampDb')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(name, bandCount, gainsJson, preampDb);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EqualizerPreset &&
          other.name == this.name &&
          other.bandCount == this.bandCount &&
          other.gainsJson == this.gainsJson &&
          other.preampDb == this.preampDb);
}

class EqualizerPresetsTableCompanion extends UpdateCompanion<EqualizerPreset> {
  final Value<String> name;
  final Value<int> bandCount;
  final Value<String> gainsJson;
  final Value<double> preampDb;
  final Value<int> rowid;
  const EqualizerPresetsTableCompanion({
    this.name = const Value.absent(),
    this.bandCount = const Value.absent(),
    this.gainsJson = const Value.absent(),
    this.preampDb = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EqualizerPresetsTableCompanion.insert({
    required String name,
    required int bandCount,
    required String gainsJson,
    this.preampDb = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       bandCount = Value(bandCount),
       gainsJson = Value(gainsJson);
  static Insertable<EqualizerPreset> custom({
    Expression<String>? name,
    Expression<int>? bandCount,
    Expression<String>? gainsJson,
    Expression<double>? preampDb,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (bandCount != null) 'band_count': bandCount,
      if (gainsJson != null) 'gains_json': gainsJson,
      if (preampDb != null) 'preamp_db': preampDb,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EqualizerPresetsTableCompanion copyWith({
    Value<String>? name,
    Value<int>? bandCount,
    Value<String>? gainsJson,
    Value<double>? preampDb,
    Value<int>? rowid,
  }) {
    return EqualizerPresetsTableCompanion(
      name: name ?? this.name,
      bandCount: bandCount ?? this.bandCount,
      gainsJson: gainsJson ?? this.gainsJson,
      preampDb: preampDb ?? this.preampDb,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (bandCount.present) {
      map['band_count'] = Variable<int>(bandCount.value);
    }
    if (gainsJson.present) {
      map['gains_json'] = Variable<String>(gainsJson.value);
    }
    if (preampDb.present) {
      map['preamp_db'] = Variable<double>(preampDb.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EqualizerPresetsTableCompanion(')
          ..write('name: $name, ')
          ..write('bandCount: $bandCount, ')
          ..write('gainsJson: $gainsJson, ')
          ..write('preampDb: $preampDb, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EqualizerStateTable extends EqualizerState
    with TableInfo<$EqualizerStateTable, EqualizerStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EqualizerStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _bandCountMeta = const VerificationMeta(
    'bandCount',
  );
  @override
  late final GeneratedColumn<int> bandCount = GeneratedColumn<int>(
    'band_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(10),
  );
  static const VerificationMeta _gainsJsonMeta = const VerificationMeta(
    'gainsJson',
  );
  @override
  late final GeneratedColumn<String> gainsJson = GeneratedColumn<String>(
    'gains_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[0,0,0,0,0,0,0,0,0,0]'),
  );
  static const VerificationMeta _preampDbMeta = const VerificationMeta(
    'preampDb',
  );
  @override
  late final GeneratedColumn<double> preampDb = GeneratedColumn<double>(
    'preamp_db',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _autoPreventClippingMeta =
      const VerificationMeta('autoPreventClipping');
  @override
  late final GeneratedColumn<bool> autoPreventClipping = GeneratedColumn<bool>(
    'auto_prevent_clipping',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_prevent_clipping" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _monoOutputMeta = const VerificationMeta(
    'monoOutput',
  );
  @override
  late final GeneratedColumn<bool> monoOutput = GeneratedColumn<bool>(
    'mono_output',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("mono_output" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _presetNameMeta = const VerificationMeta(
    'presetName',
  );
  @override
  late final GeneratedColumn<String> presetName = GeneratedColumn<String>(
    'preset_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Plano'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    enabled,
    bandCount,
    gainsJson,
    preampDb,
    autoPreventClipping,
    balance,
    monoOutput,
    presetName,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'equalizer_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<EqualizerStateData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('band_count')) {
      context.handle(
        _bandCountMeta,
        bandCount.isAcceptableOrUnknown(data['band_count']!, _bandCountMeta),
      );
    }
    if (data.containsKey('gains_json')) {
      context.handle(
        _gainsJsonMeta,
        gainsJson.isAcceptableOrUnknown(data['gains_json']!, _gainsJsonMeta),
      );
    }
    if (data.containsKey('preamp_db')) {
      context.handle(
        _preampDbMeta,
        preampDb.isAcceptableOrUnknown(data['preamp_db']!, _preampDbMeta),
      );
    }
    if (data.containsKey('auto_prevent_clipping')) {
      context.handle(
        _autoPreventClippingMeta,
        autoPreventClipping.isAcceptableOrUnknown(
          data['auto_prevent_clipping']!,
          _autoPreventClippingMeta,
        ),
      );
    }
    if (data.containsKey('balance')) {
      context.handle(
        _balanceMeta,
        balance.isAcceptableOrUnknown(data['balance']!, _balanceMeta),
      );
    }
    if (data.containsKey('mono_output')) {
      context.handle(
        _monoOutputMeta,
        monoOutput.isAcceptableOrUnknown(data['mono_output']!, _monoOutputMeta),
      );
    }
    if (data.containsKey('preset_name')) {
      context.handle(
        _presetNameMeta,
        presetName.isAcceptableOrUnknown(data['preset_name']!, _presetNameMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EqualizerStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EqualizerStateData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      bandCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}band_count'],
      )!,
      gainsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gains_json'],
      )!,
      preampDb: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}preamp_db'],
      )!,
      autoPreventClipping: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_prevent_clipping'],
      )!,
      balance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}balance'],
      )!,
      monoOutput: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}mono_output'],
      )!,
      presetName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preset_name'],
      )!,
    );
  }

  @override
  $EqualizerStateTable createAlias(String alias) {
    return $EqualizerStateTable(attachedDatabase, alias);
  }
}

class EqualizerStateData extends DataClass
    implements Insertable<EqualizerStateData> {
  final int id;
  final bool enabled;
  final int bandCount;
  final String gainsJson;
  final double preampDb;
  final bool autoPreventClipping;
  final double balance;
  final bool monoOutput;
  final String presetName;
  const EqualizerStateData({
    required this.id,
    required this.enabled,
    required this.bandCount,
    required this.gainsJson,
    required this.preampDb,
    required this.autoPreventClipping,
    required this.balance,
    required this.monoOutput,
    required this.presetName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['enabled'] = Variable<bool>(enabled);
    map['band_count'] = Variable<int>(bandCount);
    map['gains_json'] = Variable<String>(gainsJson);
    map['preamp_db'] = Variable<double>(preampDb);
    map['auto_prevent_clipping'] = Variable<bool>(autoPreventClipping);
    map['balance'] = Variable<double>(balance);
    map['mono_output'] = Variable<bool>(monoOutput);
    map['preset_name'] = Variable<String>(presetName);
    return map;
  }

  EqualizerStateCompanion toCompanion(bool nullToAbsent) {
    return EqualizerStateCompanion(
      id: Value(id),
      enabled: Value(enabled),
      bandCount: Value(bandCount),
      gainsJson: Value(gainsJson),
      preampDb: Value(preampDb),
      autoPreventClipping: Value(autoPreventClipping),
      balance: Value(balance),
      monoOutput: Value(monoOutput),
      presetName: Value(presetName),
    );
  }

  factory EqualizerStateData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EqualizerStateData(
      id: serializer.fromJson<int>(json['id']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      bandCount: serializer.fromJson<int>(json['bandCount']),
      gainsJson: serializer.fromJson<String>(json['gainsJson']),
      preampDb: serializer.fromJson<double>(json['preampDb']),
      autoPreventClipping: serializer.fromJson<bool>(
        json['autoPreventClipping'],
      ),
      balance: serializer.fromJson<double>(json['balance']),
      monoOutput: serializer.fromJson<bool>(json['monoOutput']),
      presetName: serializer.fromJson<String>(json['presetName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'enabled': serializer.toJson<bool>(enabled),
      'bandCount': serializer.toJson<int>(bandCount),
      'gainsJson': serializer.toJson<String>(gainsJson),
      'preampDb': serializer.toJson<double>(preampDb),
      'autoPreventClipping': serializer.toJson<bool>(autoPreventClipping),
      'balance': serializer.toJson<double>(balance),
      'monoOutput': serializer.toJson<bool>(monoOutput),
      'presetName': serializer.toJson<String>(presetName),
    };
  }

  EqualizerStateData copyWith({
    int? id,
    bool? enabled,
    int? bandCount,
    String? gainsJson,
    double? preampDb,
    bool? autoPreventClipping,
    double? balance,
    bool? monoOutput,
    String? presetName,
  }) => EqualizerStateData(
    id: id ?? this.id,
    enabled: enabled ?? this.enabled,
    bandCount: bandCount ?? this.bandCount,
    gainsJson: gainsJson ?? this.gainsJson,
    preampDb: preampDb ?? this.preampDb,
    autoPreventClipping: autoPreventClipping ?? this.autoPreventClipping,
    balance: balance ?? this.balance,
    monoOutput: monoOutput ?? this.monoOutput,
    presetName: presetName ?? this.presetName,
  );
  EqualizerStateData copyWithCompanion(EqualizerStateCompanion data) {
    return EqualizerStateData(
      id: data.id.present ? data.id.value : this.id,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      bandCount: data.bandCount.present ? data.bandCount.value : this.bandCount,
      gainsJson: data.gainsJson.present ? data.gainsJson.value : this.gainsJson,
      preampDb: data.preampDb.present ? data.preampDb.value : this.preampDb,
      autoPreventClipping: data.autoPreventClipping.present
          ? data.autoPreventClipping.value
          : this.autoPreventClipping,
      balance: data.balance.present ? data.balance.value : this.balance,
      monoOutput: data.monoOutput.present
          ? data.monoOutput.value
          : this.monoOutput,
      presetName: data.presetName.present
          ? data.presetName.value
          : this.presetName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EqualizerStateData(')
          ..write('id: $id, ')
          ..write('enabled: $enabled, ')
          ..write('bandCount: $bandCount, ')
          ..write('gainsJson: $gainsJson, ')
          ..write('preampDb: $preampDb, ')
          ..write('autoPreventClipping: $autoPreventClipping, ')
          ..write('balance: $balance, ')
          ..write('monoOutput: $monoOutput, ')
          ..write('presetName: $presetName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    enabled,
    bandCount,
    gainsJson,
    preampDb,
    autoPreventClipping,
    balance,
    monoOutput,
    presetName,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EqualizerStateData &&
          other.id == this.id &&
          other.enabled == this.enabled &&
          other.bandCount == this.bandCount &&
          other.gainsJson == this.gainsJson &&
          other.preampDb == this.preampDb &&
          other.autoPreventClipping == this.autoPreventClipping &&
          other.balance == this.balance &&
          other.monoOutput == this.monoOutput &&
          other.presetName == this.presetName);
}

class EqualizerStateCompanion extends UpdateCompanion<EqualizerStateData> {
  final Value<int> id;
  final Value<bool> enabled;
  final Value<int> bandCount;
  final Value<String> gainsJson;
  final Value<double> preampDb;
  final Value<bool> autoPreventClipping;
  final Value<double> balance;
  final Value<bool> monoOutput;
  final Value<String> presetName;
  const EqualizerStateCompanion({
    this.id = const Value.absent(),
    this.enabled = const Value.absent(),
    this.bandCount = const Value.absent(),
    this.gainsJson = const Value.absent(),
    this.preampDb = const Value.absent(),
    this.autoPreventClipping = const Value.absent(),
    this.balance = const Value.absent(),
    this.monoOutput = const Value.absent(),
    this.presetName = const Value.absent(),
  });
  EqualizerStateCompanion.insert({
    this.id = const Value.absent(),
    this.enabled = const Value.absent(),
    this.bandCount = const Value.absent(),
    this.gainsJson = const Value.absent(),
    this.preampDb = const Value.absent(),
    this.autoPreventClipping = const Value.absent(),
    this.balance = const Value.absent(),
    this.monoOutput = const Value.absent(),
    this.presetName = const Value.absent(),
  });
  static Insertable<EqualizerStateData> custom({
    Expression<int>? id,
    Expression<bool>? enabled,
    Expression<int>? bandCount,
    Expression<String>? gainsJson,
    Expression<double>? preampDb,
    Expression<bool>? autoPreventClipping,
    Expression<double>? balance,
    Expression<bool>? monoOutput,
    Expression<String>? presetName,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (enabled != null) 'enabled': enabled,
      if (bandCount != null) 'band_count': bandCount,
      if (gainsJson != null) 'gains_json': gainsJson,
      if (preampDb != null) 'preamp_db': preampDb,
      if (autoPreventClipping != null)
        'auto_prevent_clipping': autoPreventClipping,
      if (balance != null) 'balance': balance,
      if (monoOutput != null) 'mono_output': monoOutput,
      if (presetName != null) 'preset_name': presetName,
    });
  }

  EqualizerStateCompanion copyWith({
    Value<int>? id,
    Value<bool>? enabled,
    Value<int>? bandCount,
    Value<String>? gainsJson,
    Value<double>? preampDb,
    Value<bool>? autoPreventClipping,
    Value<double>? balance,
    Value<bool>? monoOutput,
    Value<String>? presetName,
  }) {
    return EqualizerStateCompanion(
      id: id ?? this.id,
      enabled: enabled ?? this.enabled,
      bandCount: bandCount ?? this.bandCount,
      gainsJson: gainsJson ?? this.gainsJson,
      preampDb: preampDb ?? this.preampDb,
      autoPreventClipping: autoPreventClipping ?? this.autoPreventClipping,
      balance: balance ?? this.balance,
      monoOutput: monoOutput ?? this.monoOutput,
      presetName: presetName ?? this.presetName,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (bandCount.present) {
      map['band_count'] = Variable<int>(bandCount.value);
    }
    if (gainsJson.present) {
      map['gains_json'] = Variable<String>(gainsJson.value);
    }
    if (preampDb.present) {
      map['preamp_db'] = Variable<double>(preampDb.value);
    }
    if (autoPreventClipping.present) {
      map['auto_prevent_clipping'] = Variable<bool>(autoPreventClipping.value);
    }
    if (balance.present) {
      map['balance'] = Variable<double>(balance.value);
    }
    if (monoOutput.present) {
      map['mono_output'] = Variable<bool>(monoOutput.value);
    }
    if (presetName.present) {
      map['preset_name'] = Variable<String>(presetName.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EqualizerStateCompanion(')
          ..write('id: $id, ')
          ..write('enabled: $enabled, ')
          ..write('bandCount: $bandCount, ')
          ..write('gainsJson: $gainsJson, ')
          ..write('preampDb: $preampDb, ')
          ..write('autoPreventClipping: $autoPreventClipping, ')
          ..write('balance: $balance, ')
          ..write('monoOutput: $monoOutput, ')
          ..write('presetName: $presetName')
          ..write(')'))
        .toString();
  }
}

class $EnhancementStateTable extends EnhancementState
    with TableInfo<$EnhancementStateTable, EnhancementStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EnhancementStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _profileIndexMeta = const VerificationMeta(
    'profileIndex',
  );
  @override
  late final GeneratedColumn<int> profileIndex = GeneratedColumn<int>(
    'profile_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _detailIndexMeta = const VerificationMeta(
    'detailIndex',
  );
  @override
  late final GeneratedColumn<int> detailIndex = GeneratedColumn<int>(
    'detail_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _multibandStrengthMeta = const VerificationMeta(
    'multibandStrength',
  );
  @override
  late final GeneratedColumn<double> multibandStrength =
      GeneratedColumn<double>(
        'multiband_strength',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _normalizationIndexMeta =
      const VerificationMeta('normalizationIndex');
  @override
  late final GeneratedColumn<int> normalizationIndex = GeneratedColumn<int>(
    'normalization_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _targetLevelDbMeta = const VerificationMeta(
    'targetLevelDb',
  );
  @override
  late final GeneratedColumn<double> targetLevelDb = GeneratedColumn<double>(
    'target_level_db',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(-14),
  );
  static const VerificationMeta _stereoExpansionEnabledMeta =
      const VerificationMeta('stereoExpansionEnabled');
  @override
  late final GeneratedColumn<bool> stereoExpansionEnabled =
      GeneratedColumn<bool>(
        'stereo_expansion_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("stereo_expansion_enabled" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _stereoWidthMeta = const VerificationMeta(
    'stereoWidth',
  );
  @override
  late final GeneratedColumn<double> stereoWidth = GeneratedColumn<double>(
    'stereo_width',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    enabled,
    profileIndex,
    detailIndex,
    multibandStrength,
    normalizationIndex,
    targetLevelDb,
    stereoExpansionEnabled,
    stereoWidth,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'enhancement_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<EnhancementStateData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('profile_index')) {
      context.handle(
        _profileIndexMeta,
        profileIndex.isAcceptableOrUnknown(
          data['profile_index']!,
          _profileIndexMeta,
        ),
      );
    }
    if (data.containsKey('detail_index')) {
      context.handle(
        _detailIndexMeta,
        detailIndex.isAcceptableOrUnknown(
          data['detail_index']!,
          _detailIndexMeta,
        ),
      );
    }
    if (data.containsKey('multiband_strength')) {
      context.handle(
        _multibandStrengthMeta,
        multibandStrength.isAcceptableOrUnknown(
          data['multiband_strength']!,
          _multibandStrengthMeta,
        ),
      );
    }
    if (data.containsKey('normalization_index')) {
      context.handle(
        _normalizationIndexMeta,
        normalizationIndex.isAcceptableOrUnknown(
          data['normalization_index']!,
          _normalizationIndexMeta,
        ),
      );
    }
    if (data.containsKey('target_level_db')) {
      context.handle(
        _targetLevelDbMeta,
        targetLevelDb.isAcceptableOrUnknown(
          data['target_level_db']!,
          _targetLevelDbMeta,
        ),
      );
    }
    if (data.containsKey('stereo_expansion_enabled')) {
      context.handle(
        _stereoExpansionEnabledMeta,
        stereoExpansionEnabled.isAcceptableOrUnknown(
          data['stereo_expansion_enabled']!,
          _stereoExpansionEnabledMeta,
        ),
      );
    }
    if (data.containsKey('stereo_width')) {
      context.handle(
        _stereoWidthMeta,
        stereoWidth.isAcceptableOrUnknown(
          data['stereo_width']!,
          _stereoWidthMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EnhancementStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EnhancementStateData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      profileIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_index'],
      )!,
      detailIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}detail_index'],
      )!,
      multibandStrength: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}multiband_strength'],
      )!,
      normalizationIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}normalization_index'],
      )!,
      targetLevelDb: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_level_db'],
      )!,
      stereoExpansionEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}stereo_expansion_enabled'],
      )!,
      stereoWidth: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stereo_width'],
      )!,
    );
  }

  @override
  $EnhancementStateTable createAlias(String alias) {
    return $EnhancementStateTable(attachedDatabase, alias);
  }
}

class EnhancementStateData extends DataClass
    implements Insertable<EnhancementStateData> {
  final int id;
  final bool enabled;

  /// Indice de `EnhancementProfile` del contrato con el motor.
  final int profileIndex;

  /// Indice de `DetailLevel`.
  final int detailIndex;
  final double multibandStrength;

  /// Indice de `NormalizationMode`.
  final int normalizationIndex;
  final double targetLevelDb;
  final bool stereoExpansionEnabled;
  final double stereoWidth;
  const EnhancementStateData({
    required this.id,
    required this.enabled,
    required this.profileIndex,
    required this.detailIndex,
    required this.multibandStrength,
    required this.normalizationIndex,
    required this.targetLevelDb,
    required this.stereoExpansionEnabled,
    required this.stereoWidth,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['enabled'] = Variable<bool>(enabled);
    map['profile_index'] = Variable<int>(profileIndex);
    map['detail_index'] = Variable<int>(detailIndex);
    map['multiband_strength'] = Variable<double>(multibandStrength);
    map['normalization_index'] = Variable<int>(normalizationIndex);
    map['target_level_db'] = Variable<double>(targetLevelDb);
    map['stereo_expansion_enabled'] = Variable<bool>(stereoExpansionEnabled);
    map['stereo_width'] = Variable<double>(stereoWidth);
    return map;
  }

  EnhancementStateCompanion toCompanion(bool nullToAbsent) {
    return EnhancementStateCompanion(
      id: Value(id),
      enabled: Value(enabled),
      profileIndex: Value(profileIndex),
      detailIndex: Value(detailIndex),
      multibandStrength: Value(multibandStrength),
      normalizationIndex: Value(normalizationIndex),
      targetLevelDb: Value(targetLevelDb),
      stereoExpansionEnabled: Value(stereoExpansionEnabled),
      stereoWidth: Value(stereoWidth),
    );
  }

  factory EnhancementStateData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EnhancementStateData(
      id: serializer.fromJson<int>(json['id']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      profileIndex: serializer.fromJson<int>(json['profileIndex']),
      detailIndex: serializer.fromJson<int>(json['detailIndex']),
      multibandStrength: serializer.fromJson<double>(json['multibandStrength']),
      normalizationIndex: serializer.fromJson<int>(json['normalizationIndex']),
      targetLevelDb: serializer.fromJson<double>(json['targetLevelDb']),
      stereoExpansionEnabled: serializer.fromJson<bool>(
        json['stereoExpansionEnabled'],
      ),
      stereoWidth: serializer.fromJson<double>(json['stereoWidth']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'enabled': serializer.toJson<bool>(enabled),
      'profileIndex': serializer.toJson<int>(profileIndex),
      'detailIndex': serializer.toJson<int>(detailIndex),
      'multibandStrength': serializer.toJson<double>(multibandStrength),
      'normalizationIndex': serializer.toJson<int>(normalizationIndex),
      'targetLevelDb': serializer.toJson<double>(targetLevelDb),
      'stereoExpansionEnabled': serializer.toJson<bool>(stereoExpansionEnabled),
      'stereoWidth': serializer.toJson<double>(stereoWidth),
    };
  }

  EnhancementStateData copyWith({
    int? id,
    bool? enabled,
    int? profileIndex,
    int? detailIndex,
    double? multibandStrength,
    int? normalizationIndex,
    double? targetLevelDb,
    bool? stereoExpansionEnabled,
    double? stereoWidth,
  }) => EnhancementStateData(
    id: id ?? this.id,
    enabled: enabled ?? this.enabled,
    profileIndex: profileIndex ?? this.profileIndex,
    detailIndex: detailIndex ?? this.detailIndex,
    multibandStrength: multibandStrength ?? this.multibandStrength,
    normalizationIndex: normalizationIndex ?? this.normalizationIndex,
    targetLevelDb: targetLevelDb ?? this.targetLevelDb,
    stereoExpansionEnabled:
        stereoExpansionEnabled ?? this.stereoExpansionEnabled,
    stereoWidth: stereoWidth ?? this.stereoWidth,
  );
  EnhancementStateData copyWithCompanion(EnhancementStateCompanion data) {
    return EnhancementStateData(
      id: data.id.present ? data.id.value : this.id,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      profileIndex: data.profileIndex.present
          ? data.profileIndex.value
          : this.profileIndex,
      detailIndex: data.detailIndex.present
          ? data.detailIndex.value
          : this.detailIndex,
      multibandStrength: data.multibandStrength.present
          ? data.multibandStrength.value
          : this.multibandStrength,
      normalizationIndex: data.normalizationIndex.present
          ? data.normalizationIndex.value
          : this.normalizationIndex,
      targetLevelDb: data.targetLevelDb.present
          ? data.targetLevelDb.value
          : this.targetLevelDb,
      stereoExpansionEnabled: data.stereoExpansionEnabled.present
          ? data.stereoExpansionEnabled.value
          : this.stereoExpansionEnabled,
      stereoWidth: data.stereoWidth.present
          ? data.stereoWidth.value
          : this.stereoWidth,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EnhancementStateData(')
          ..write('id: $id, ')
          ..write('enabled: $enabled, ')
          ..write('profileIndex: $profileIndex, ')
          ..write('detailIndex: $detailIndex, ')
          ..write('multibandStrength: $multibandStrength, ')
          ..write('normalizationIndex: $normalizationIndex, ')
          ..write('targetLevelDb: $targetLevelDb, ')
          ..write('stereoExpansionEnabled: $stereoExpansionEnabled, ')
          ..write('stereoWidth: $stereoWidth')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    enabled,
    profileIndex,
    detailIndex,
    multibandStrength,
    normalizationIndex,
    targetLevelDb,
    stereoExpansionEnabled,
    stereoWidth,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EnhancementStateData &&
          other.id == this.id &&
          other.enabled == this.enabled &&
          other.profileIndex == this.profileIndex &&
          other.detailIndex == this.detailIndex &&
          other.multibandStrength == this.multibandStrength &&
          other.normalizationIndex == this.normalizationIndex &&
          other.targetLevelDb == this.targetLevelDb &&
          other.stereoExpansionEnabled == this.stereoExpansionEnabled &&
          other.stereoWidth == this.stereoWidth);
}

class EnhancementStateCompanion extends UpdateCompanion<EnhancementStateData> {
  final Value<int> id;
  final Value<bool> enabled;
  final Value<int> profileIndex;
  final Value<int> detailIndex;
  final Value<double> multibandStrength;
  final Value<int> normalizationIndex;
  final Value<double> targetLevelDb;
  final Value<bool> stereoExpansionEnabled;
  final Value<double> stereoWidth;
  const EnhancementStateCompanion({
    this.id = const Value.absent(),
    this.enabled = const Value.absent(),
    this.profileIndex = const Value.absent(),
    this.detailIndex = const Value.absent(),
    this.multibandStrength = const Value.absent(),
    this.normalizationIndex = const Value.absent(),
    this.targetLevelDb = const Value.absent(),
    this.stereoExpansionEnabled = const Value.absent(),
    this.stereoWidth = const Value.absent(),
  });
  EnhancementStateCompanion.insert({
    this.id = const Value.absent(),
    this.enabled = const Value.absent(),
    this.profileIndex = const Value.absent(),
    this.detailIndex = const Value.absent(),
    this.multibandStrength = const Value.absent(),
    this.normalizationIndex = const Value.absent(),
    this.targetLevelDb = const Value.absent(),
    this.stereoExpansionEnabled = const Value.absent(),
    this.stereoWidth = const Value.absent(),
  });
  static Insertable<EnhancementStateData> custom({
    Expression<int>? id,
    Expression<bool>? enabled,
    Expression<int>? profileIndex,
    Expression<int>? detailIndex,
    Expression<double>? multibandStrength,
    Expression<int>? normalizationIndex,
    Expression<double>? targetLevelDb,
    Expression<bool>? stereoExpansionEnabled,
    Expression<double>? stereoWidth,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (enabled != null) 'enabled': enabled,
      if (profileIndex != null) 'profile_index': profileIndex,
      if (detailIndex != null) 'detail_index': detailIndex,
      if (multibandStrength != null) 'multiband_strength': multibandStrength,
      if (normalizationIndex != null) 'normalization_index': normalizationIndex,
      if (targetLevelDb != null) 'target_level_db': targetLevelDb,
      if (stereoExpansionEnabled != null)
        'stereo_expansion_enabled': stereoExpansionEnabled,
      if (stereoWidth != null) 'stereo_width': stereoWidth,
    });
  }

  EnhancementStateCompanion copyWith({
    Value<int>? id,
    Value<bool>? enabled,
    Value<int>? profileIndex,
    Value<int>? detailIndex,
    Value<double>? multibandStrength,
    Value<int>? normalizationIndex,
    Value<double>? targetLevelDb,
    Value<bool>? stereoExpansionEnabled,
    Value<double>? stereoWidth,
  }) {
    return EnhancementStateCompanion(
      id: id ?? this.id,
      enabled: enabled ?? this.enabled,
      profileIndex: profileIndex ?? this.profileIndex,
      detailIndex: detailIndex ?? this.detailIndex,
      multibandStrength: multibandStrength ?? this.multibandStrength,
      normalizationIndex: normalizationIndex ?? this.normalizationIndex,
      targetLevelDb: targetLevelDb ?? this.targetLevelDb,
      stereoExpansionEnabled:
          stereoExpansionEnabled ?? this.stereoExpansionEnabled,
      stereoWidth: stereoWidth ?? this.stereoWidth,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (profileIndex.present) {
      map['profile_index'] = Variable<int>(profileIndex.value);
    }
    if (detailIndex.present) {
      map['detail_index'] = Variable<int>(detailIndex.value);
    }
    if (multibandStrength.present) {
      map['multiband_strength'] = Variable<double>(multibandStrength.value);
    }
    if (normalizationIndex.present) {
      map['normalization_index'] = Variable<int>(normalizationIndex.value);
    }
    if (targetLevelDb.present) {
      map['target_level_db'] = Variable<double>(targetLevelDb.value);
    }
    if (stereoExpansionEnabled.present) {
      map['stereo_expansion_enabled'] = Variable<bool>(
        stereoExpansionEnabled.value,
      );
    }
    if (stereoWidth.present) {
      map['stereo_width'] = Variable<double>(stereoWidth.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EnhancementStateCompanion(')
          ..write('id: $id, ')
          ..write('enabled: $enabled, ')
          ..write('profileIndex: $profileIndex, ')
          ..write('detailIndex: $detailIndex, ')
          ..write('multibandStrength: $multibandStrength, ')
          ..write('normalizationIndex: $normalizationIndex, ')
          ..write('targetLevelDb: $targetLevelDb, ')
          ..write('stereoExpansionEnabled: $stereoExpansionEnabled, ')
          ..write('stereoWidth: $stereoWidth')
          ..write(')'))
        .toString();
  }
}

class $OutputProfilesTable extends OutputProfiles
    with TableInfo<$OutputProfilesTable, OutputProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutputProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _outputIndexMeta = const VerificationMeta(
    'outputIndex',
  );
  @override
  late final GeneratedColumn<int> outputIndex = GeneratedColumn<int>(
    'output_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bandCountMeta = const VerificationMeta(
    'bandCount',
  );
  @override
  late final GeneratedColumn<int> bandCount = GeneratedColumn<int>(
    'band_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(10),
  );
  static const VerificationMeta _gainsJsonMeta = const VerificationMeta(
    'gainsJson',
  );
  @override
  late final GeneratedColumn<String> gainsJson = GeneratedColumn<String>(
    'gains_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[0,0,0,0,0,0,0,0,0,0]'),
  );
  static const VerificationMeta _presetNameMeta = const VerificationMeta(
    'presetName',
  );
  @override
  late final GeneratedColumn<String> presetName = GeneratedColumn<String>(
    'preset_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Plano'),
  );
  static const VerificationMeta _preampDbMeta = const VerificationMeta(
    'preampDb',
  );
  @override
  late final GeneratedColumn<double> preampDb = GeneratedColumn<double>(
    'preamp_db',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _profileIndexMeta = const VerificationMeta(
    'profileIndex',
  );
  @override
  late final GeneratedColumn<int> profileIndex = GeneratedColumn<int>(
    'profile_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _enhancementEnabledMeta =
      const VerificationMeta('enhancementEnabled');
  @override
  late final GeneratedColumn<bool> enhancementEnabled = GeneratedColumn<bool>(
    'enhancement_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enhancement_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    outputIndex,
    bandCount,
    gainsJson,
    presetName,
    preampDb,
    profileIndex,
    enhancementEnabled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'output_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutputProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('output_index')) {
      context.handle(
        _outputIndexMeta,
        outputIndex.isAcceptableOrUnknown(
          data['output_index']!,
          _outputIndexMeta,
        ),
      );
    }
    if (data.containsKey('band_count')) {
      context.handle(
        _bandCountMeta,
        bandCount.isAcceptableOrUnknown(data['band_count']!, _bandCountMeta),
      );
    }
    if (data.containsKey('gains_json')) {
      context.handle(
        _gainsJsonMeta,
        gainsJson.isAcceptableOrUnknown(data['gains_json']!, _gainsJsonMeta),
      );
    }
    if (data.containsKey('preset_name')) {
      context.handle(
        _presetNameMeta,
        presetName.isAcceptableOrUnknown(data['preset_name']!, _presetNameMeta),
      );
    }
    if (data.containsKey('preamp_db')) {
      context.handle(
        _preampDbMeta,
        preampDb.isAcceptableOrUnknown(data['preamp_db']!, _preampDbMeta),
      );
    }
    if (data.containsKey('profile_index')) {
      context.handle(
        _profileIndexMeta,
        profileIndex.isAcceptableOrUnknown(
          data['profile_index']!,
          _profileIndexMeta,
        ),
      );
    }
    if (data.containsKey('enhancement_enabled')) {
      context.handle(
        _enhancementEnabledMeta,
        enhancementEnabled.isAcceptableOrUnknown(
          data['enhancement_enabled']!,
          _enhancementEnabledMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {outputIndex};
  @override
  OutputProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutputProfile(
      outputIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}output_index'],
      )!,
      bandCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}band_count'],
      )!,
      gainsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gains_json'],
      )!,
      presetName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preset_name'],
      )!,
      preampDb: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}preamp_db'],
      )!,
      profileIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_index'],
      )!,
      enhancementEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enhancement_enabled'],
      )!,
    );
  }

  @override
  $OutputProfilesTable createAlias(String alias) {
    return $OutputProfilesTable(attachedDatabase, alias);
  }
}

class OutputProfile extends DataClass implements Insertable<OutputProfile> {
  final int outputIndex;

  /// Curva del ecualizador guardada para esta salida.
  final int bandCount;
  final String gainsJson;
  final String presetName;
  final double preampDb;

  /// Perfil de mejora asociado a esta salida.
  final int profileIndex;
  final bool enhancementEnabled;
  const OutputProfile({
    required this.outputIndex,
    required this.bandCount,
    required this.gainsJson,
    required this.presetName,
    required this.preampDb,
    required this.profileIndex,
    required this.enhancementEnabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['output_index'] = Variable<int>(outputIndex);
    map['band_count'] = Variable<int>(bandCount);
    map['gains_json'] = Variable<String>(gainsJson);
    map['preset_name'] = Variable<String>(presetName);
    map['preamp_db'] = Variable<double>(preampDb);
    map['profile_index'] = Variable<int>(profileIndex);
    map['enhancement_enabled'] = Variable<bool>(enhancementEnabled);
    return map;
  }

  OutputProfilesCompanion toCompanion(bool nullToAbsent) {
    return OutputProfilesCompanion(
      outputIndex: Value(outputIndex),
      bandCount: Value(bandCount),
      gainsJson: Value(gainsJson),
      presetName: Value(presetName),
      preampDb: Value(preampDb),
      profileIndex: Value(profileIndex),
      enhancementEnabled: Value(enhancementEnabled),
    );
  }

  factory OutputProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutputProfile(
      outputIndex: serializer.fromJson<int>(json['outputIndex']),
      bandCount: serializer.fromJson<int>(json['bandCount']),
      gainsJson: serializer.fromJson<String>(json['gainsJson']),
      presetName: serializer.fromJson<String>(json['presetName']),
      preampDb: serializer.fromJson<double>(json['preampDb']),
      profileIndex: serializer.fromJson<int>(json['profileIndex']),
      enhancementEnabled: serializer.fromJson<bool>(json['enhancementEnabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'outputIndex': serializer.toJson<int>(outputIndex),
      'bandCount': serializer.toJson<int>(bandCount),
      'gainsJson': serializer.toJson<String>(gainsJson),
      'presetName': serializer.toJson<String>(presetName),
      'preampDb': serializer.toJson<double>(preampDb),
      'profileIndex': serializer.toJson<int>(profileIndex),
      'enhancementEnabled': serializer.toJson<bool>(enhancementEnabled),
    };
  }

  OutputProfile copyWith({
    int? outputIndex,
    int? bandCount,
    String? gainsJson,
    String? presetName,
    double? preampDb,
    int? profileIndex,
    bool? enhancementEnabled,
  }) => OutputProfile(
    outputIndex: outputIndex ?? this.outputIndex,
    bandCount: bandCount ?? this.bandCount,
    gainsJson: gainsJson ?? this.gainsJson,
    presetName: presetName ?? this.presetName,
    preampDb: preampDb ?? this.preampDb,
    profileIndex: profileIndex ?? this.profileIndex,
    enhancementEnabled: enhancementEnabled ?? this.enhancementEnabled,
  );
  OutputProfile copyWithCompanion(OutputProfilesCompanion data) {
    return OutputProfile(
      outputIndex: data.outputIndex.present
          ? data.outputIndex.value
          : this.outputIndex,
      bandCount: data.bandCount.present ? data.bandCount.value : this.bandCount,
      gainsJson: data.gainsJson.present ? data.gainsJson.value : this.gainsJson,
      presetName: data.presetName.present
          ? data.presetName.value
          : this.presetName,
      preampDb: data.preampDb.present ? data.preampDb.value : this.preampDb,
      profileIndex: data.profileIndex.present
          ? data.profileIndex.value
          : this.profileIndex,
      enhancementEnabled: data.enhancementEnabled.present
          ? data.enhancementEnabled.value
          : this.enhancementEnabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutputProfile(')
          ..write('outputIndex: $outputIndex, ')
          ..write('bandCount: $bandCount, ')
          ..write('gainsJson: $gainsJson, ')
          ..write('presetName: $presetName, ')
          ..write('preampDb: $preampDb, ')
          ..write('profileIndex: $profileIndex, ')
          ..write('enhancementEnabled: $enhancementEnabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    outputIndex,
    bandCount,
    gainsJson,
    presetName,
    preampDb,
    profileIndex,
    enhancementEnabled,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutputProfile &&
          other.outputIndex == this.outputIndex &&
          other.bandCount == this.bandCount &&
          other.gainsJson == this.gainsJson &&
          other.presetName == this.presetName &&
          other.preampDb == this.preampDb &&
          other.profileIndex == this.profileIndex &&
          other.enhancementEnabled == this.enhancementEnabled);
}

class OutputProfilesCompanion extends UpdateCompanion<OutputProfile> {
  final Value<int> outputIndex;
  final Value<int> bandCount;
  final Value<String> gainsJson;
  final Value<String> presetName;
  final Value<double> preampDb;
  final Value<int> profileIndex;
  final Value<bool> enhancementEnabled;
  const OutputProfilesCompanion({
    this.outputIndex = const Value.absent(),
    this.bandCount = const Value.absent(),
    this.gainsJson = const Value.absent(),
    this.presetName = const Value.absent(),
    this.preampDb = const Value.absent(),
    this.profileIndex = const Value.absent(),
    this.enhancementEnabled = const Value.absent(),
  });
  OutputProfilesCompanion.insert({
    this.outputIndex = const Value.absent(),
    this.bandCount = const Value.absent(),
    this.gainsJson = const Value.absent(),
    this.presetName = const Value.absent(),
    this.preampDb = const Value.absent(),
    this.profileIndex = const Value.absent(),
    this.enhancementEnabled = const Value.absent(),
  });
  static Insertable<OutputProfile> custom({
    Expression<int>? outputIndex,
    Expression<int>? bandCount,
    Expression<String>? gainsJson,
    Expression<String>? presetName,
    Expression<double>? preampDb,
    Expression<int>? profileIndex,
    Expression<bool>? enhancementEnabled,
  }) {
    return RawValuesInsertable({
      if (outputIndex != null) 'output_index': outputIndex,
      if (bandCount != null) 'band_count': bandCount,
      if (gainsJson != null) 'gains_json': gainsJson,
      if (presetName != null) 'preset_name': presetName,
      if (preampDb != null) 'preamp_db': preampDb,
      if (profileIndex != null) 'profile_index': profileIndex,
      if (enhancementEnabled != null) 'enhancement_enabled': enhancementEnabled,
    });
  }

  OutputProfilesCompanion copyWith({
    Value<int>? outputIndex,
    Value<int>? bandCount,
    Value<String>? gainsJson,
    Value<String>? presetName,
    Value<double>? preampDb,
    Value<int>? profileIndex,
    Value<bool>? enhancementEnabled,
  }) {
    return OutputProfilesCompanion(
      outputIndex: outputIndex ?? this.outputIndex,
      bandCount: bandCount ?? this.bandCount,
      gainsJson: gainsJson ?? this.gainsJson,
      presetName: presetName ?? this.presetName,
      preampDb: preampDb ?? this.preampDb,
      profileIndex: profileIndex ?? this.profileIndex,
      enhancementEnabled: enhancementEnabled ?? this.enhancementEnabled,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (outputIndex.present) {
      map['output_index'] = Variable<int>(outputIndex.value);
    }
    if (bandCount.present) {
      map['band_count'] = Variable<int>(bandCount.value);
    }
    if (gainsJson.present) {
      map['gains_json'] = Variable<String>(gainsJson.value);
    }
    if (presetName.present) {
      map['preset_name'] = Variable<String>(presetName.value);
    }
    if (preampDb.present) {
      map['preamp_db'] = Variable<double>(preampDb.value);
    }
    if (profileIndex.present) {
      map['profile_index'] = Variable<int>(profileIndex.value);
    }
    if (enhancementEnabled.present) {
      map['enhancement_enabled'] = Variable<bool>(enhancementEnabled.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutputProfilesCompanion(')
          ..write('outputIndex: $outputIndex, ')
          ..write('bandCount: $bandCount, ')
          ..write('gainsJson: $gainsJson, ')
          ..write('presetName: $presetName, ')
          ..write('preampDb: $preampDb, ')
          ..write('profileIndex: $profileIndex, ')
          ..write('enhancementEnabled: $enhancementEnabled')
          ..write(')'))
        .toString();
  }
}

class $LoudnessAnalysesTable extends LoudnessAnalyses
    with TableInfo<$LoudnessAnalysesTable, LoudnessAnalyse> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LoudnessAnalysesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _songIdMeta = const VerificationMeta('songId');
  @override
  late final GeneratedColumn<int> songId = GeneratedColumn<int>(
    'song_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gainDbMeta = const VerificationMeta('gainDb');
  @override
  late final GeneratedColumn<double> gainDb = GeneratedColumn<double>(
    'gain_db',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _peakMeta = const VerificationMeta('peak');
  @override
  late final GeneratedColumn<double> peak = GeneratedColumn<double>(
    'peak',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _analyzedAtMeta = const VerificationMeta(
    'analyzedAt',
  );
  @override
  late final GeneratedColumn<DateTime> analyzedAt = GeneratedColumn<DateTime>(
    'analyzed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [songId, gainDb, peak, analyzedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'loudness_analyses';
  @override
  VerificationContext validateIntegrity(
    Insertable<LoudnessAnalyse> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('song_id')) {
      context.handle(
        _songIdMeta,
        songId.isAcceptableOrUnknown(data['song_id']!, _songIdMeta),
      );
    }
    if (data.containsKey('gain_db')) {
      context.handle(
        _gainDbMeta,
        gainDb.isAcceptableOrUnknown(data['gain_db']!, _gainDbMeta),
      );
    } else if (isInserting) {
      context.missing(_gainDbMeta);
    }
    if (data.containsKey('peak')) {
      context.handle(
        _peakMeta,
        peak.isAcceptableOrUnknown(data['peak']!, _peakMeta),
      );
    } else if (isInserting) {
      context.missing(_peakMeta);
    }
    if (data.containsKey('analyzed_at')) {
      context.handle(
        _analyzedAtMeta,
        analyzedAt.isAcceptableOrUnknown(data['analyzed_at']!, _analyzedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {songId};
  @override
  LoudnessAnalyse map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LoudnessAnalyse(
      songId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}song_id'],
      )!,
      gainDb: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}gain_db'],
      )!,
      peak: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}peak'],
      )!,
      analyzedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}analyzed_at'],
      )!,
    );
  }

  @override
  $LoudnessAnalysesTable createAlias(String alias) {
    return $LoudnessAnalysesTable(attachedDatabase, alias);
  }
}

class LoudnessAnalyse extends DataClass implements Insertable<LoudnessAnalyse> {
  final int songId;
  final double gainDb;
  final double peak;
  final DateTime analyzedAt;
  const LoudnessAnalyse({
    required this.songId,
    required this.gainDb,
    required this.peak,
    required this.analyzedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['song_id'] = Variable<int>(songId);
    map['gain_db'] = Variable<double>(gainDb);
    map['peak'] = Variable<double>(peak);
    map['analyzed_at'] = Variable<DateTime>(analyzedAt);
    return map;
  }

  LoudnessAnalysesCompanion toCompanion(bool nullToAbsent) {
    return LoudnessAnalysesCompanion(
      songId: Value(songId),
      gainDb: Value(gainDb),
      peak: Value(peak),
      analyzedAt: Value(analyzedAt),
    );
  }

  factory LoudnessAnalyse.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LoudnessAnalyse(
      songId: serializer.fromJson<int>(json['songId']),
      gainDb: serializer.fromJson<double>(json['gainDb']),
      peak: serializer.fromJson<double>(json['peak']),
      analyzedAt: serializer.fromJson<DateTime>(json['analyzedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'songId': serializer.toJson<int>(songId),
      'gainDb': serializer.toJson<double>(gainDb),
      'peak': serializer.toJson<double>(peak),
      'analyzedAt': serializer.toJson<DateTime>(analyzedAt),
    };
  }

  LoudnessAnalyse copyWith({
    int? songId,
    double? gainDb,
    double? peak,
    DateTime? analyzedAt,
  }) => LoudnessAnalyse(
    songId: songId ?? this.songId,
    gainDb: gainDb ?? this.gainDb,
    peak: peak ?? this.peak,
    analyzedAt: analyzedAt ?? this.analyzedAt,
  );
  LoudnessAnalyse copyWithCompanion(LoudnessAnalysesCompanion data) {
    return LoudnessAnalyse(
      songId: data.songId.present ? data.songId.value : this.songId,
      gainDb: data.gainDb.present ? data.gainDb.value : this.gainDb,
      peak: data.peak.present ? data.peak.value : this.peak,
      analyzedAt: data.analyzedAt.present
          ? data.analyzedAt.value
          : this.analyzedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LoudnessAnalyse(')
          ..write('songId: $songId, ')
          ..write('gainDb: $gainDb, ')
          ..write('peak: $peak, ')
          ..write('analyzedAt: $analyzedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(songId, gainDb, peak, analyzedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LoudnessAnalyse &&
          other.songId == this.songId &&
          other.gainDb == this.gainDb &&
          other.peak == this.peak &&
          other.analyzedAt == this.analyzedAt);
}

class LoudnessAnalysesCompanion extends UpdateCompanion<LoudnessAnalyse> {
  final Value<int> songId;
  final Value<double> gainDb;
  final Value<double> peak;
  final Value<DateTime> analyzedAt;
  const LoudnessAnalysesCompanion({
    this.songId = const Value.absent(),
    this.gainDb = const Value.absent(),
    this.peak = const Value.absent(),
    this.analyzedAt = const Value.absent(),
  });
  LoudnessAnalysesCompanion.insert({
    this.songId = const Value.absent(),
    required double gainDb,
    required double peak,
    this.analyzedAt = const Value.absent(),
  }) : gainDb = Value(gainDb),
       peak = Value(peak);
  static Insertable<LoudnessAnalyse> custom({
    Expression<int>? songId,
    Expression<double>? gainDb,
    Expression<double>? peak,
    Expression<DateTime>? analyzedAt,
  }) {
    return RawValuesInsertable({
      if (songId != null) 'song_id': songId,
      if (gainDb != null) 'gain_db': gainDb,
      if (peak != null) 'peak': peak,
      if (analyzedAt != null) 'analyzed_at': analyzedAt,
    });
  }

  LoudnessAnalysesCompanion copyWith({
    Value<int>? songId,
    Value<double>? gainDb,
    Value<double>? peak,
    Value<DateTime>? analyzedAt,
  }) {
    return LoudnessAnalysesCompanion(
      songId: songId ?? this.songId,
      gainDb: gainDb ?? this.gainDb,
      peak: peak ?? this.peak,
      analyzedAt: analyzedAt ?? this.analyzedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (songId.present) {
      map['song_id'] = Variable<int>(songId.value);
    }
    if (gainDb.present) {
      map['gain_db'] = Variable<double>(gainDb.value);
    }
    if (peak.present) {
      map['peak'] = Variable<double>(peak.value);
    }
    if (analyzedAt.present) {
      map['analyzed_at'] = Variable<DateTime>(analyzedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LoudnessAnalysesCompanion(')
          ..write('songId: $songId, ')
          ..write('gainDb: $gainDb, ')
          ..write('peak: $peak, ')
          ..write('analyzedAt: $analyzedAt')
          ..write(')'))
        .toString();
  }
}

class $SavedRadiosTable extends SavedRadios
    with TableInfo<$SavedRadiosTable, SavedRadio> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedRadiosTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, url, addedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_radios';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedRadio> instance, {
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
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavedRadio map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedRadio(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $SavedRadiosTable createAlias(String alias) {
    return $SavedRadiosTable(attachedDatabase, alias);
  }
}

class SavedRadio extends DataClass implements Insertable<SavedRadio> {
  final int id;
  final String name;
  final String url;
  final DateTime addedAt;
  const SavedRadio({
    required this.id,
    required this.name,
    required this.url,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['url'] = Variable<String>(url);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  SavedRadiosCompanion toCompanion(bool nullToAbsent) {
    return SavedRadiosCompanion(
      id: Value(id),
      name: Value(name),
      url: Value(url),
      addedAt: Value(addedAt),
    );
  }

  factory SavedRadio.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedRadio(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      url: serializer.fromJson<String>(json['url']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'url': serializer.toJson<String>(url),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  SavedRadio copyWith({
    int? id,
    String? name,
    String? url,
    DateTime? addedAt,
  }) => SavedRadio(
    id: id ?? this.id,
    name: name ?? this.name,
    url: url ?? this.url,
    addedAt: addedAt ?? this.addedAt,
  );
  SavedRadio copyWithCompanion(SavedRadiosCompanion data) {
    return SavedRadio(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      url: data.url.present ? data.url.value : this.url,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedRadio(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('url: $url, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, url, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedRadio &&
          other.id == this.id &&
          other.name == this.name &&
          other.url == this.url &&
          other.addedAt == this.addedAt);
}

class SavedRadiosCompanion extends UpdateCompanion<SavedRadio> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> url;
  final Value<DateTime> addedAt;
  const SavedRadiosCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.url = const Value.absent(),
    this.addedAt = const Value.absent(),
  });
  SavedRadiosCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String url,
    this.addedAt = const Value.absent(),
  }) : name = Value(name),
       url = Value(url);
  static Insertable<SavedRadio> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? url,
    Expression<DateTime>? addedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (url != null) 'url': url,
      if (addedAt != null) 'added_at': addedAt,
    });
  }

  SavedRadiosCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? url,
    Value<DateTime>? addedAt,
  }) {
    return SavedRadiosCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      addedAt: addedAt ?? this.addedAt,
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
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedRadiosCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('url: $url, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }
}

class $LyricsOverridesTable extends LyricsOverrides
    with TableInfo<$LyricsOverridesTable, LyricsOverride> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LyricsOverridesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _songIdMeta = const VerificationMeta('songId');
  @override
  late final GeneratedColumn<int> songId = GeneratedColumn<int>(
    'song_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _offsetMsMeta = const VerificationMeta(
    'offsetMs',
  );
  @override
  late final GeneratedColumn<int> offsetMs = GeneratedColumn<int>(
    'offset_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _synchronizedMeta = const VerificationMeta(
    'synchronized',
  );
  @override
  late final GeneratedColumn<bool> synchronized = GeneratedColumn<bool>(
    'synchronized',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synchronized" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    songId,
    content,
    offsetMs,
    synchronized,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lyrics_overrides';
  @override
  VerificationContext validateIntegrity(
    Insertable<LyricsOverride> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('song_id')) {
      context.handle(
        _songIdMeta,
        songId.isAcceptableOrUnknown(data['song_id']!, _songIdMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('offset_ms')) {
      context.handle(
        _offsetMsMeta,
        offsetMs.isAcceptableOrUnknown(data['offset_ms']!, _offsetMsMeta),
      );
    }
    if (data.containsKey('synchronized')) {
      context.handle(
        _synchronizedMeta,
        synchronized.isAcceptableOrUnknown(
          data['synchronized']!,
          _synchronizedMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {songId};
  @override
  LyricsOverride map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LyricsOverride(
      songId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}song_id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      offsetMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}offset_ms'],
      )!,
      synchronized: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synchronized'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LyricsOverridesTable createAlias(String alias) {
    return $LyricsOverridesTable(attachedDatabase, alias);
  }
}

class LyricsOverride extends DataClass implements Insertable<LyricsOverride> {
  final int songId;
  final String content;
  final int offsetMs;
  final bool synchronized;
  final DateTime updatedAt;
  const LyricsOverride({
    required this.songId,
    required this.content,
    required this.offsetMs,
    required this.synchronized,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['song_id'] = Variable<int>(songId);
    map['content'] = Variable<String>(content);
    map['offset_ms'] = Variable<int>(offsetMs);
    map['synchronized'] = Variable<bool>(synchronized);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LyricsOverridesCompanion toCompanion(bool nullToAbsent) {
    return LyricsOverridesCompanion(
      songId: Value(songId),
      content: Value(content),
      offsetMs: Value(offsetMs),
      synchronized: Value(synchronized),
      updatedAt: Value(updatedAt),
    );
  }

  factory LyricsOverride.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LyricsOverride(
      songId: serializer.fromJson<int>(json['songId']),
      content: serializer.fromJson<String>(json['content']),
      offsetMs: serializer.fromJson<int>(json['offsetMs']),
      synchronized: serializer.fromJson<bool>(json['synchronized']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'songId': serializer.toJson<int>(songId),
      'content': serializer.toJson<String>(content),
      'offsetMs': serializer.toJson<int>(offsetMs),
      'synchronized': serializer.toJson<bool>(synchronized),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LyricsOverride copyWith({
    int? songId,
    String? content,
    int? offsetMs,
    bool? synchronized,
    DateTime? updatedAt,
  }) => LyricsOverride(
    songId: songId ?? this.songId,
    content: content ?? this.content,
    offsetMs: offsetMs ?? this.offsetMs,
    synchronized: synchronized ?? this.synchronized,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LyricsOverride copyWithCompanion(LyricsOverridesCompanion data) {
    return LyricsOverride(
      songId: data.songId.present ? data.songId.value : this.songId,
      content: data.content.present ? data.content.value : this.content,
      offsetMs: data.offsetMs.present ? data.offsetMs.value : this.offsetMs,
      synchronized: data.synchronized.present
          ? data.synchronized.value
          : this.synchronized,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LyricsOverride(')
          ..write('songId: $songId, ')
          ..write('content: $content, ')
          ..write('offsetMs: $offsetMs, ')
          ..write('synchronized: $synchronized, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(songId, content, offsetMs, synchronized, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LyricsOverride &&
          other.songId == this.songId &&
          other.content == this.content &&
          other.offsetMs == this.offsetMs &&
          other.synchronized == this.synchronized &&
          other.updatedAt == this.updatedAt);
}

class LyricsOverridesCompanion extends UpdateCompanion<LyricsOverride> {
  final Value<int> songId;
  final Value<String> content;
  final Value<int> offsetMs;
  final Value<bool> synchronized;
  final Value<DateTime> updatedAt;
  const LyricsOverridesCompanion({
    this.songId = const Value.absent(),
    this.content = const Value.absent(),
    this.offsetMs = const Value.absent(),
    this.synchronized = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LyricsOverridesCompanion.insert({
    this.songId = const Value.absent(),
    required String content,
    this.offsetMs = const Value.absent(),
    this.synchronized = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : content = Value(content);
  static Insertable<LyricsOverride> custom({
    Expression<int>? songId,
    Expression<String>? content,
    Expression<int>? offsetMs,
    Expression<bool>? synchronized,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (songId != null) 'song_id': songId,
      if (content != null) 'content': content,
      if (offsetMs != null) 'offset_ms': offsetMs,
      if (synchronized != null) 'synchronized': synchronized,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LyricsOverridesCompanion copyWith({
    Value<int>? songId,
    Value<String>? content,
    Value<int>? offsetMs,
    Value<bool>? synchronized,
    Value<DateTime>? updatedAt,
  }) {
    return LyricsOverridesCompanion(
      songId: songId ?? this.songId,
      content: content ?? this.content,
      offsetMs: offsetMs ?? this.offsetMs,
      synchronized: synchronized ?? this.synchronized,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (songId.present) {
      map['song_id'] = Variable<int>(songId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (offsetMs.present) {
      map['offset_ms'] = Variable<int>(offsetMs.value);
    }
    if (synchronized.present) {
      map['synchronized'] = Variable<bool>(synchronized.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LyricsOverridesCompanion(')
          ..write('songId: $songId, ')
          ..write('content: $content, ')
          ..write('offsetMs: $offsetMs, ')
          ..write('synchronized: $synchronized, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _scanOnStartMeta = const VerificationMeta(
    'scanOnStart',
  );
  @override
  late final GeneratedColumn<bool> scanOnStart = GeneratedColumn<bool>(
    'scan_on_start',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("scan_on_start" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _lastScanAtMeta = const VerificationMeta(
    'lastScanAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastScanAt = GeneratedColumn<DateTime>(
    'last_scan_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _useDynamicColorMeta = const VerificationMeta(
    'useDynamicColor',
  );
  @override
  late final GeneratedColumn<bool> useDynamicColor = GeneratedColumn<bool>(
    'use_dynamic_color',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("use_dynamic_color" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _pureBlackBackgroundMeta =
      const VerificationMeta('pureBlackBackground');
  @override
  late final GeneratedColumn<bool> pureBlackBackground = GeneratedColumn<bool>(
    'pure_black_background',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pure_black_background" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _accentIdMeta = const VerificationMeta(
    'accentId',
  );
  @override
  late final GeneratedColumn<String> accentId = GeneratedColumn<String>(
    'accent_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('nebula'),
  );
  static const VerificationMeta _backgroundDepthMeta = const VerificationMeta(
    'backgroundDepth',
  );
  @override
  late final GeneratedColumn<String> backgroundDepth = GeneratedColumn<String>(
    'background_depth',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('night'),
  );
  static const VerificationMeta _glassIntensityMeta = const VerificationMeta(
    'glassIntensity',
  );
  @override
  late final GeneratedColumn<String> glassIntensity = GeneratedColumn<String>(
    'glass_intensity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('medium'),
  );
  static const VerificationMeta _restoreQueueOnStartMeta =
      const VerificationMeta('restoreQueueOnStart');
  @override
  late final GeneratedColumn<bool> restoreQueueOnStart = GeneratedColumn<bool>(
    'restore_queue_on_start',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("restore_queue_on_start" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _gaplessEnabledMeta = const VerificationMeta(
    'gaplessEnabled',
  );
  @override
  late final GeneratedColumn<bool> gaplessEnabled = GeneratedColumn<bool>(
    'gapless_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("gapless_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _crossfadeSecondsMeta = const VerificationMeta(
    'crossfadeSeconds',
  );
  @override
  late final GeneratedColumn<int> crossfadeSeconds = GeneratedColumn<int>(
    'crossfade_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _fadeOnPauseMeta = const VerificationMeta(
    'fadeOnPause',
  );
  @override
  late final GeneratedColumn<bool> fadeOnPause = GeneratedColumn<bool>(
    'fade_on_pause',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("fade_on_pause" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _fadeOnPauseMsMeta = const VerificationMeta(
    'fadeOnPauseMs',
  );
  @override
  late final GeneratedColumn<int> fadeOnPauseMs = GeneratedColumn<int>(
    'fade_on_pause_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(250),
  );
  static const VerificationMeta _directModeMeta = const VerificationMeta(
    'directMode',
  );
  @override
  late final GeneratedColumn<bool> directMode = GeneratedColumn<bool>(
    'direct_mode',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("direct_mode" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _allowOffloadMeta = const VerificationMeta(
    'allowOffload',
  );
  @override
  late final GeneratedColumn<bool> allowOffload = GeneratedColumn<bool>(
    'allow_offload',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("allow_offload" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _playbackSpeedMeta = const VerificationMeta(
    'playbackSpeed',
  );
  @override
  late final GeneratedColumn<double> playbackSpeed = GeneratedColumn<double>(
    'playback_speed',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _playbackPitchMeta = const VerificationMeta(
    'playbackPitch',
  );
  @override
  late final GeneratedColumn<double> playbackPitch = GeneratedColumn<double>(
    'playback_pitch',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _embedCoverInFileMeta = const VerificationMeta(
    'embedCoverInFile',
  );
  @override
  late final GeneratedColumn<bool> embedCoverInFile = GeneratedColumn<bool>(
    'embed_cover_in_file',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("embed_cover_in_file" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _widgetEnabledMeta = const VerificationMeta(
    'widgetEnabled',
  );
  @override
  late final GeneratedColumn<bool> widgetEnabled = GeneratedColumn<bool>(
    'widget_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("widget_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _widgetStyleMeta = const VerificationMeta(
    'widgetStyle',
  );
  @override
  late final GeneratedColumn<int> widgetStyle = GeneratedColumn<int>(
    'widget_style',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _widgetThemeMeta = const VerificationMeta(
    'widgetTheme',
  );
  @override
  late final GeneratedColumn<int> widgetTheme = GeneratedColumn<int>(
    'widget_theme',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _widgetSizeMeta = const VerificationMeta(
    'widgetSize',
  );
  @override
  late final GeneratedColumn<int> widgetSize = GeneratedColumn<int>(
    'widget_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _widgetAccentColorMeta = const VerificationMeta(
    'widgetAccentColor',
  );
  @override
  late final GeneratedColumn<int> widgetAccentColor = GeneratedColumn<int>(
    'widget_accent_color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0xFFB14BFF),
  );
  static const VerificationMeta _widgetOpacityMeta = const VerificationMeta(
    'widgetOpacity',
  );
  @override
  late final GeneratedColumn<double> widgetOpacity = GeneratedColumn<double>(
    'widget_opacity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.92),
  );
  static const VerificationMeta _widgetShowCoverMeta = const VerificationMeta(
    'widgetShowCover',
  );
  @override
  late final GeneratedColumn<bool> widgetShowCover = GeneratedColumn<bool>(
    'widget_show_cover',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("widget_show_cover" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _widgetShowTitleMeta = const VerificationMeta(
    'widgetShowTitle',
  );
  @override
  late final GeneratedColumn<bool> widgetShowTitle = GeneratedColumn<bool>(
    'widget_show_title',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("widget_show_title" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _widgetShowArtistMeta = const VerificationMeta(
    'widgetShowArtist',
  );
  @override
  late final GeneratedColumn<bool> widgetShowArtist = GeneratedColumn<bool>(
    'widget_show_artist',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("widget_show_artist" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _widgetShowControlsMeta =
      const VerificationMeta('widgetShowControls');
  @override
  late final GeneratedColumn<bool> widgetShowControls = GeneratedColumn<bool>(
    'widget_show_controls',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("widget_show_controls" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _widgetShowProgressMeta =
      const VerificationMeta('widgetShowProgress');
  @override
  late final GeneratedColumn<bool> widgetShowProgress = GeneratedColumn<bool>(
    'widget_show_progress',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("widget_show_progress" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _widgetShowDurationMeta =
      const VerificationMeta('widgetShowDuration');
  @override
  late final GeneratedColumn<bool> widgetShowDuration = GeneratedColumn<bool>(
    'widget_show_duration',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("widget_show_duration" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _widgetShowNextInQueueMeta =
      const VerificationMeta('widgetShowNextInQueue');
  @override
  late final GeneratedColumn<bool> widgetShowNextInQueue =
      GeneratedColumn<bool>(
        'widget_show_next_in_queue',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("widget_show_next_in_queue" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _widgetOpenOnTapMeta = const VerificationMeta(
    'widgetOpenOnTap',
  );
  @override
  late final GeneratedColumn<bool> widgetOpenOnTap = GeneratedColumn<bool>(
    'widget_open_on_tap',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("widget_open_on_tap" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _widgetPauseOnDisconnectMeta =
      const VerificationMeta('widgetPauseOnDisconnect');
  @override
  late final GeneratedColumn<bool> widgetPauseOnDisconnect =
      GeneratedColumn<bool>(
        'widget_pause_on_disconnect',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("widget_pause_on_disconnect" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _widgetResumeOnConnectMeta =
      const VerificationMeta('widgetResumeOnConnect');
  @override
  late final GeneratedColumn<bool> widgetResumeOnConnect =
      GeneratedColumn<bool>(
        'widget_resume_on_connect',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("widget_resume_on_connect" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _sleepTimerMinutesMeta = const VerificationMeta(
    'sleepTimerMinutes',
  );
  @override
  late final GeneratedColumn<int> sleepTimerMinutes = GeneratedColumn<int>(
    'sleep_timer_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(30),
  );
  static const VerificationMeta _sleepTimerFinishTrackMeta =
      const VerificationMeta('sleepTimerFinishTrack');
  @override
  late final GeneratedColumn<bool> sleepTimerFinishTrack =
      GeneratedColumn<bool>(
        'sleep_timer_finish_track',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("sleep_timer_finish_track" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _homeSectionsJsonMeta = const VerificationMeta(
    'homeSectionsJson',
  );
  @override
  late final GeneratedColumn<String> homeSectionsJson = GeneratedColumn<String>(
    'home_sections_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(
      '["continue","favorites","recentlyPlayed","recentAlbums","mostPlayed","featuredPlaylists"]',
    ),
  );
  static const VerificationMeta _librarySortJsonMeta = const VerificationMeta(
    'librarySortJson',
  );
  @override
  late final GeneratedColumn<String> librarySortJson = GeneratedColumn<String>(
    'library_sort_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _videoBackgroundEnabledMeta =
      const VerificationMeta('videoBackgroundEnabled');
  @override
  late final GeneratedColumn<bool> videoBackgroundEnabled =
      GeneratedColumn<bool>(
        'video_background_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("video_background_enabled" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _playerVisualizerStyleMeta =
      const VerificationMeta('playerVisualizerStyle');
  @override
  late final GeneratedColumn<int> playerVisualizerStyle = GeneratedColumn<int>(
    'player_visualizer_style',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _playerVisualSceneMeta = const VerificationMeta(
    'playerVisualScene',
  );
  @override
  late final GeneratedColumn<int> playerVisualScene = GeneratedColumn<int>(
    'player_visual_scene',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _playerSceneAspectRatioMeta =
      const VerificationMeta('playerSceneAspectRatio');
  @override
  late final GeneratedColumn<int> playerSceneAspectRatio = GeneratedColumn<int>(
    'player_scene_aspect_ratio',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _playerControlPresetMeta =
      const VerificationMeta('playerControlPreset');
  @override
  late final GeneratedColumn<String> playerControlPreset =
      GeneratedColumn<String>(
        'player_control_preset',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('complete'),
      );
  static const VerificationMeta _playerControlLayoutJsonMeta =
      const VerificationMeta('playerControlLayoutJson');
  @override
  late final GeneratedColumn<String>
  playerControlLayoutJson = GeneratedColumn<String>(
    'player_control_layout_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(
      '{"primary":["shuffle","previous","playPause","next","repeat"],'
      '"secondary":["favorite","seekBackward","seekForward","queue","sleepTimer"]}',
    ),
  );
  static const VerificationMeta _playerControlHandednessMeta =
      const VerificationMeta('playerControlHandedness');
  @override
  late final GeneratedColumn<String> playerControlHandedness =
      GeneratedColumn<String>(
        'player_control_handedness',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('right'),
      );
  static const VerificationMeta _playerDensityMeta = const VerificationMeta(
    'playerDensity',
  );
  @override
  late final GeneratedColumn<String> playerDensity = GeneratedColumn<String>(
    'player_density',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('normal'),
  );
  static const VerificationMeta _playerGestureDoubleTapMeta =
      const VerificationMeta('playerGestureDoubleTap');
  @override
  late final GeneratedColumn<bool> playerGestureDoubleTap =
      GeneratedColumn<bool>(
        'player_gesture_double_tap',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("player_gesture_double_tap" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _playerGestureSwipeTrackMeta =
      const VerificationMeta('playerGestureSwipeTrack');
  @override
  late final GeneratedColumn<bool> playerGestureSwipeTrack =
      GeneratedColumn<bool>(
        'player_gesture_swipe_track',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("player_gesture_swipe_track" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _playerGestureSwipeVolumeMeta =
      const VerificationMeta('playerGestureSwipeVolume');
  @override
  late final GeneratedColumn<bool> playerGestureSwipeVolume =
      GeneratedColumn<bool>(
        'player_gesture_swipe_volume',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("player_gesture_swipe_volume" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _playerGestureSwipeDismissMeta =
      const VerificationMeta('playerGestureSwipeDismiss');
  @override
  late final GeneratedColumn<bool> playerGestureSwipeDismiss =
      GeneratedColumn<bool>(
        'player_gesture_swipe_dismiss',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("player_gesture_swipe_dismiss" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scanOnStart,
    lastScanAt,
    useDynamicColor,
    pureBlackBackground,
    accentId,
    backgroundDepth,
    glassIntensity,
    restoreQueueOnStart,
    gaplessEnabled,
    crossfadeSeconds,
    fadeOnPause,
    fadeOnPauseMs,
    directMode,
    allowOffload,
    playbackSpeed,
    playbackPitch,
    embedCoverInFile,
    widgetEnabled,
    widgetStyle,
    widgetTheme,
    widgetSize,
    widgetAccentColor,
    widgetOpacity,
    widgetShowCover,
    widgetShowTitle,
    widgetShowArtist,
    widgetShowControls,
    widgetShowProgress,
    widgetShowDuration,
    widgetShowNextInQueue,
    widgetOpenOnTap,
    widgetPauseOnDisconnect,
    widgetResumeOnConnect,
    sleepTimerMinutes,
    sleepTimerFinishTrack,
    homeSectionsJson,
    librarySortJson,
    videoBackgroundEnabled,
    playerVisualizerStyle,
    playerVisualScene,
    playerSceneAspectRatio,
    playerControlPreset,
    playerControlLayoutJson,
    playerControlHandedness,
    playerDensity,
    playerGestureDoubleTap,
    playerGestureSwipeTrack,
    playerGestureSwipeVolume,
    playerGestureSwipeDismiss,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('scan_on_start')) {
      context.handle(
        _scanOnStartMeta,
        scanOnStart.isAcceptableOrUnknown(
          data['scan_on_start']!,
          _scanOnStartMeta,
        ),
      );
    }
    if (data.containsKey('last_scan_at')) {
      context.handle(
        _lastScanAtMeta,
        lastScanAt.isAcceptableOrUnknown(
          data['last_scan_at']!,
          _lastScanAtMeta,
        ),
      );
    }
    if (data.containsKey('use_dynamic_color')) {
      context.handle(
        _useDynamicColorMeta,
        useDynamicColor.isAcceptableOrUnknown(
          data['use_dynamic_color']!,
          _useDynamicColorMeta,
        ),
      );
    }
    if (data.containsKey('pure_black_background')) {
      context.handle(
        _pureBlackBackgroundMeta,
        pureBlackBackground.isAcceptableOrUnknown(
          data['pure_black_background']!,
          _pureBlackBackgroundMeta,
        ),
      );
    }
    if (data.containsKey('accent_id')) {
      context.handle(
        _accentIdMeta,
        accentId.isAcceptableOrUnknown(data['accent_id']!, _accentIdMeta),
      );
    }
    if (data.containsKey('background_depth')) {
      context.handle(
        _backgroundDepthMeta,
        backgroundDepth.isAcceptableOrUnknown(
          data['background_depth']!,
          _backgroundDepthMeta,
        ),
      );
    }
    if (data.containsKey('glass_intensity')) {
      context.handle(
        _glassIntensityMeta,
        glassIntensity.isAcceptableOrUnknown(
          data['glass_intensity']!,
          _glassIntensityMeta,
        ),
      );
    }
    if (data.containsKey('restore_queue_on_start')) {
      context.handle(
        _restoreQueueOnStartMeta,
        restoreQueueOnStart.isAcceptableOrUnknown(
          data['restore_queue_on_start']!,
          _restoreQueueOnStartMeta,
        ),
      );
    }
    if (data.containsKey('gapless_enabled')) {
      context.handle(
        _gaplessEnabledMeta,
        gaplessEnabled.isAcceptableOrUnknown(
          data['gapless_enabled']!,
          _gaplessEnabledMeta,
        ),
      );
    }
    if (data.containsKey('crossfade_seconds')) {
      context.handle(
        _crossfadeSecondsMeta,
        crossfadeSeconds.isAcceptableOrUnknown(
          data['crossfade_seconds']!,
          _crossfadeSecondsMeta,
        ),
      );
    }
    if (data.containsKey('fade_on_pause')) {
      context.handle(
        _fadeOnPauseMeta,
        fadeOnPause.isAcceptableOrUnknown(
          data['fade_on_pause']!,
          _fadeOnPauseMeta,
        ),
      );
    }
    if (data.containsKey('fade_on_pause_ms')) {
      context.handle(
        _fadeOnPauseMsMeta,
        fadeOnPauseMs.isAcceptableOrUnknown(
          data['fade_on_pause_ms']!,
          _fadeOnPauseMsMeta,
        ),
      );
    }
    if (data.containsKey('direct_mode')) {
      context.handle(
        _directModeMeta,
        directMode.isAcceptableOrUnknown(data['direct_mode']!, _directModeMeta),
      );
    }
    if (data.containsKey('allow_offload')) {
      context.handle(
        _allowOffloadMeta,
        allowOffload.isAcceptableOrUnknown(
          data['allow_offload']!,
          _allowOffloadMeta,
        ),
      );
    }
    if (data.containsKey('playback_speed')) {
      context.handle(
        _playbackSpeedMeta,
        playbackSpeed.isAcceptableOrUnknown(
          data['playback_speed']!,
          _playbackSpeedMeta,
        ),
      );
    }
    if (data.containsKey('playback_pitch')) {
      context.handle(
        _playbackPitchMeta,
        playbackPitch.isAcceptableOrUnknown(
          data['playback_pitch']!,
          _playbackPitchMeta,
        ),
      );
    }
    if (data.containsKey('embed_cover_in_file')) {
      context.handle(
        _embedCoverInFileMeta,
        embedCoverInFile.isAcceptableOrUnknown(
          data['embed_cover_in_file']!,
          _embedCoverInFileMeta,
        ),
      );
    }
    if (data.containsKey('widget_enabled')) {
      context.handle(
        _widgetEnabledMeta,
        widgetEnabled.isAcceptableOrUnknown(
          data['widget_enabled']!,
          _widgetEnabledMeta,
        ),
      );
    }
    if (data.containsKey('widget_style')) {
      context.handle(
        _widgetStyleMeta,
        widgetStyle.isAcceptableOrUnknown(
          data['widget_style']!,
          _widgetStyleMeta,
        ),
      );
    }
    if (data.containsKey('widget_theme')) {
      context.handle(
        _widgetThemeMeta,
        widgetTheme.isAcceptableOrUnknown(
          data['widget_theme']!,
          _widgetThemeMeta,
        ),
      );
    }
    if (data.containsKey('widget_size')) {
      context.handle(
        _widgetSizeMeta,
        widgetSize.isAcceptableOrUnknown(data['widget_size']!, _widgetSizeMeta),
      );
    }
    if (data.containsKey('widget_accent_color')) {
      context.handle(
        _widgetAccentColorMeta,
        widgetAccentColor.isAcceptableOrUnknown(
          data['widget_accent_color']!,
          _widgetAccentColorMeta,
        ),
      );
    }
    if (data.containsKey('widget_opacity')) {
      context.handle(
        _widgetOpacityMeta,
        widgetOpacity.isAcceptableOrUnknown(
          data['widget_opacity']!,
          _widgetOpacityMeta,
        ),
      );
    }
    if (data.containsKey('widget_show_cover')) {
      context.handle(
        _widgetShowCoverMeta,
        widgetShowCover.isAcceptableOrUnknown(
          data['widget_show_cover']!,
          _widgetShowCoverMeta,
        ),
      );
    }
    if (data.containsKey('widget_show_title')) {
      context.handle(
        _widgetShowTitleMeta,
        widgetShowTitle.isAcceptableOrUnknown(
          data['widget_show_title']!,
          _widgetShowTitleMeta,
        ),
      );
    }
    if (data.containsKey('widget_show_artist')) {
      context.handle(
        _widgetShowArtistMeta,
        widgetShowArtist.isAcceptableOrUnknown(
          data['widget_show_artist']!,
          _widgetShowArtistMeta,
        ),
      );
    }
    if (data.containsKey('widget_show_controls')) {
      context.handle(
        _widgetShowControlsMeta,
        widgetShowControls.isAcceptableOrUnknown(
          data['widget_show_controls']!,
          _widgetShowControlsMeta,
        ),
      );
    }
    if (data.containsKey('widget_show_progress')) {
      context.handle(
        _widgetShowProgressMeta,
        widgetShowProgress.isAcceptableOrUnknown(
          data['widget_show_progress']!,
          _widgetShowProgressMeta,
        ),
      );
    }
    if (data.containsKey('widget_show_duration')) {
      context.handle(
        _widgetShowDurationMeta,
        widgetShowDuration.isAcceptableOrUnknown(
          data['widget_show_duration']!,
          _widgetShowDurationMeta,
        ),
      );
    }
    if (data.containsKey('widget_show_next_in_queue')) {
      context.handle(
        _widgetShowNextInQueueMeta,
        widgetShowNextInQueue.isAcceptableOrUnknown(
          data['widget_show_next_in_queue']!,
          _widgetShowNextInQueueMeta,
        ),
      );
    }
    if (data.containsKey('widget_open_on_tap')) {
      context.handle(
        _widgetOpenOnTapMeta,
        widgetOpenOnTap.isAcceptableOrUnknown(
          data['widget_open_on_tap']!,
          _widgetOpenOnTapMeta,
        ),
      );
    }
    if (data.containsKey('widget_pause_on_disconnect')) {
      context.handle(
        _widgetPauseOnDisconnectMeta,
        widgetPauseOnDisconnect.isAcceptableOrUnknown(
          data['widget_pause_on_disconnect']!,
          _widgetPauseOnDisconnectMeta,
        ),
      );
    }
    if (data.containsKey('widget_resume_on_connect')) {
      context.handle(
        _widgetResumeOnConnectMeta,
        widgetResumeOnConnect.isAcceptableOrUnknown(
          data['widget_resume_on_connect']!,
          _widgetResumeOnConnectMeta,
        ),
      );
    }
    if (data.containsKey('sleep_timer_minutes')) {
      context.handle(
        _sleepTimerMinutesMeta,
        sleepTimerMinutes.isAcceptableOrUnknown(
          data['sleep_timer_minutes']!,
          _sleepTimerMinutesMeta,
        ),
      );
    }
    if (data.containsKey('sleep_timer_finish_track')) {
      context.handle(
        _sleepTimerFinishTrackMeta,
        sleepTimerFinishTrack.isAcceptableOrUnknown(
          data['sleep_timer_finish_track']!,
          _sleepTimerFinishTrackMeta,
        ),
      );
    }
    if (data.containsKey('home_sections_json')) {
      context.handle(
        _homeSectionsJsonMeta,
        homeSectionsJson.isAcceptableOrUnknown(
          data['home_sections_json']!,
          _homeSectionsJsonMeta,
        ),
      );
    }
    if (data.containsKey('library_sort_json')) {
      context.handle(
        _librarySortJsonMeta,
        librarySortJson.isAcceptableOrUnknown(
          data['library_sort_json']!,
          _librarySortJsonMeta,
        ),
      );
    }
    if (data.containsKey('video_background_enabled')) {
      context.handle(
        _videoBackgroundEnabledMeta,
        videoBackgroundEnabled.isAcceptableOrUnknown(
          data['video_background_enabled']!,
          _videoBackgroundEnabledMeta,
        ),
      );
    }
    if (data.containsKey('player_visualizer_style')) {
      context.handle(
        _playerVisualizerStyleMeta,
        playerVisualizerStyle.isAcceptableOrUnknown(
          data['player_visualizer_style']!,
          _playerVisualizerStyleMeta,
        ),
      );
    }
    if (data.containsKey('player_visual_scene')) {
      context.handle(
        _playerVisualSceneMeta,
        playerVisualScene.isAcceptableOrUnknown(
          data['player_visual_scene']!,
          _playerVisualSceneMeta,
        ),
      );
    }
    if (data.containsKey('player_scene_aspect_ratio')) {
      context.handle(
        _playerSceneAspectRatioMeta,
        playerSceneAspectRatio.isAcceptableOrUnknown(
          data['player_scene_aspect_ratio']!,
          _playerSceneAspectRatioMeta,
        ),
      );
    }
    if (data.containsKey('player_control_preset')) {
      context.handle(
        _playerControlPresetMeta,
        playerControlPreset.isAcceptableOrUnknown(
          data['player_control_preset']!,
          _playerControlPresetMeta,
        ),
      );
    }
    if (data.containsKey('player_control_layout_json')) {
      context.handle(
        _playerControlLayoutJsonMeta,
        playerControlLayoutJson.isAcceptableOrUnknown(
          data['player_control_layout_json']!,
          _playerControlLayoutJsonMeta,
        ),
      );
    }
    if (data.containsKey('player_control_handedness')) {
      context.handle(
        _playerControlHandednessMeta,
        playerControlHandedness.isAcceptableOrUnknown(
          data['player_control_handedness']!,
          _playerControlHandednessMeta,
        ),
      );
    }
    if (data.containsKey('player_density')) {
      context.handle(
        _playerDensityMeta,
        playerDensity.isAcceptableOrUnknown(
          data['player_density']!,
          _playerDensityMeta,
        ),
      );
    }
    if (data.containsKey('player_gesture_double_tap')) {
      context.handle(
        _playerGestureDoubleTapMeta,
        playerGestureDoubleTap.isAcceptableOrUnknown(
          data['player_gesture_double_tap']!,
          _playerGestureDoubleTapMeta,
        ),
      );
    }
    if (data.containsKey('player_gesture_swipe_track')) {
      context.handle(
        _playerGestureSwipeTrackMeta,
        playerGestureSwipeTrack.isAcceptableOrUnknown(
          data['player_gesture_swipe_track']!,
          _playerGestureSwipeTrackMeta,
        ),
      );
    }
    if (data.containsKey('player_gesture_swipe_volume')) {
      context.handle(
        _playerGestureSwipeVolumeMeta,
        playerGestureSwipeVolume.isAcceptableOrUnknown(
          data['player_gesture_swipe_volume']!,
          _playerGestureSwipeVolumeMeta,
        ),
      );
    }
    if (data.containsKey('player_gesture_swipe_dismiss')) {
      context.handle(
        _playerGestureSwipeDismissMeta,
        playerGestureSwipeDismiss.isAcceptableOrUnknown(
          data['player_gesture_swipe_dismiss']!,
          _playerGestureSwipeDismissMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      scanOnStart: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}scan_on_start'],
      )!,
      lastScanAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_scan_at'],
      ),
      useDynamicColor: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}use_dynamic_color'],
      )!,
      pureBlackBackground: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pure_black_background'],
      )!,
      accentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}accent_id'],
      )!,
      backgroundDepth: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}background_depth'],
      )!,
      glassIntensity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}glass_intensity'],
      )!,
      restoreQueueOnStart: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}restore_queue_on_start'],
      )!,
      gaplessEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}gapless_enabled'],
      )!,
      crossfadeSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}crossfade_seconds'],
      )!,
      fadeOnPause: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}fade_on_pause'],
      )!,
      fadeOnPauseMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fade_on_pause_ms'],
      )!,
      directMode: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}direct_mode'],
      )!,
      allowOffload: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}allow_offload'],
      )!,
      playbackSpeed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}playback_speed'],
      )!,
      playbackPitch: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}playback_pitch'],
      )!,
      embedCoverInFile: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}embed_cover_in_file'],
      )!,
      widgetEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}widget_enabled'],
      )!,
      widgetStyle: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}widget_style'],
      )!,
      widgetTheme: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}widget_theme'],
      )!,
      widgetSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}widget_size'],
      )!,
      widgetAccentColor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}widget_accent_color'],
      )!,
      widgetOpacity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}widget_opacity'],
      )!,
      widgetShowCover: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}widget_show_cover'],
      )!,
      widgetShowTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}widget_show_title'],
      )!,
      widgetShowArtist: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}widget_show_artist'],
      )!,
      widgetShowControls: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}widget_show_controls'],
      )!,
      widgetShowProgress: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}widget_show_progress'],
      )!,
      widgetShowDuration: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}widget_show_duration'],
      )!,
      widgetShowNextInQueue: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}widget_show_next_in_queue'],
      )!,
      widgetOpenOnTap: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}widget_open_on_tap'],
      )!,
      widgetPauseOnDisconnect: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}widget_pause_on_disconnect'],
      )!,
      widgetResumeOnConnect: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}widget_resume_on_connect'],
      )!,
      sleepTimerMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sleep_timer_minutes'],
      )!,
      sleepTimerFinishTrack: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sleep_timer_finish_track'],
      )!,
      homeSectionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}home_sections_json'],
      )!,
      librarySortJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}library_sort_json'],
      )!,
      videoBackgroundEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}video_background_enabled'],
      )!,
      playerVisualizerStyle: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}player_visualizer_style'],
      )!,
      playerVisualScene: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}player_visual_scene'],
      )!,
      playerSceneAspectRatio: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}player_scene_aspect_ratio'],
      )!,
      playerControlPreset: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}player_control_preset'],
      )!,
      playerControlLayoutJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}player_control_layout_json'],
      )!,
      playerControlHandedness: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}player_control_handedness'],
      )!,
      playerDensity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}player_density'],
      )!,
      playerGestureDoubleTap: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}player_gesture_double_tap'],
      )!,
      playerGestureSwipeTrack: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}player_gesture_swipe_track'],
      )!,
      playerGestureSwipeVolume: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}player_gesture_swipe_volume'],
      )!,
      playerGestureSwipeDismiss: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}player_gesture_swipe_dismiss'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final int id;
  final bool scanOnStart;
  final DateTime? lastScanAt;
  final bool useDynamicColor;
  final bool pureBlackBackground;

  /// Identidad cromatica elegida (`AccentIdentity.id`).
  final String accentId;

  /// Profundidad del fondo (`BackgroundDepth.id`).
  final String backgroundDepth;

  /// Intensidad del efecto de vidrio (`GlassIntensity.id`).
  final String glassIntensity;
  final bool restoreQueueOnStart;
  final bool gaplessEnabled;
  final int crossfadeSeconds;
  final bool fadeOnPause;
  final int fadeOnPauseMs;
  final bool directMode;
  final bool allowOffload;
  final double playbackSpeed;
  final double playbackPitch;
  final bool embedCoverInFile;
  final bool widgetEnabled;
  final int widgetStyle;
  final int widgetTheme;
  final int widgetSize;
  final int widgetAccentColor;
  final double widgetOpacity;
  final bool widgetShowCover;
  final bool widgetShowTitle;
  final bool widgetShowArtist;
  final bool widgetShowControls;
  final bool widgetShowProgress;
  final bool widgetShowDuration;
  final bool widgetShowNextInQueue;
  final bool widgetOpenOnTap;
  final bool widgetPauseOnDisconnect;
  final bool widgetResumeOnConnect;
  final int sleepTimerMinutes;
  final bool sleepTimerFinishTrack;

  /// Secciones activas de la pantalla Inicio, en orden, codificadas como JSON.
  final String homeSectionsJson;

  /// Orden y filtro recordados por seccion de la biblioteca
  /// (requerimiento 4.1), codificados como JSON.
  final String librarySortJson;

  /// Fondo de video musical en la pantalla del reproductor.
  /// Requiere Wi-Fi (nunca datos moviles) para no gastar el plan del usuario.
  final bool videoBackgroundEnabled;

  /// Estilo del visualizador reactivo del reproductor.
  /// Cero es automatico; los demas valores siguen VisualizerStyle.values.
  final int playerVisualizerStyle;

  /// Escenario principal del reproductor. Los índices corresponden a
  /// PlayerVisualScene; cero es Video y usa Portada si no hay un video
  /// disponible mediante Wi-Fi.
  final int playerVisualScene;

  /// Relación de aspecto del contenedor de la escena visual en pantalla
  /// completa. Los índices corresponden a PlayerSceneAspectRatio; cero es
  /// pantalla completa (9:16, comportamiento previo a esta columna).
  final int playerSceneAspectRatio;
  final String playerControlPreset;
  final String playerControlLayoutJson;
  final String playerControlHandedness;

  /// Cuanto aire deja el reproductor: 'compact', 'normal' o 'spacious'. Ver
  /// [PlayerDensity]. No guarda medidas en pixeles a proposito: el reparto de
  /// altura lo recalcula el reproductor con la pantalla real, asi que una
  /// preferencia hecha en un telefono no puede dejar los controles fuera de
  /// pantalla en otro.
  final String playerDensity;
  final bool playerGestureDoubleTap;
  final bool playerGestureSwipeTrack;
  final bool playerGestureSwipeVolume;
  final bool playerGestureSwipeDismiss;
  const AppSetting({
    required this.id,
    required this.scanOnStart,
    this.lastScanAt,
    required this.useDynamicColor,
    required this.pureBlackBackground,
    required this.accentId,
    required this.backgroundDepth,
    required this.glassIntensity,
    required this.restoreQueueOnStart,
    required this.gaplessEnabled,
    required this.crossfadeSeconds,
    required this.fadeOnPause,
    required this.fadeOnPauseMs,
    required this.directMode,
    required this.allowOffload,
    required this.playbackSpeed,
    required this.playbackPitch,
    required this.embedCoverInFile,
    required this.widgetEnabled,
    required this.widgetStyle,
    required this.widgetTheme,
    required this.widgetSize,
    required this.widgetAccentColor,
    required this.widgetOpacity,
    required this.widgetShowCover,
    required this.widgetShowTitle,
    required this.widgetShowArtist,
    required this.widgetShowControls,
    required this.widgetShowProgress,
    required this.widgetShowDuration,
    required this.widgetShowNextInQueue,
    required this.widgetOpenOnTap,
    required this.widgetPauseOnDisconnect,
    required this.widgetResumeOnConnect,
    required this.sleepTimerMinutes,
    required this.sleepTimerFinishTrack,
    required this.homeSectionsJson,
    required this.librarySortJson,
    required this.videoBackgroundEnabled,
    required this.playerVisualizerStyle,
    required this.playerVisualScene,
    required this.playerSceneAspectRatio,
    required this.playerControlPreset,
    required this.playerControlLayoutJson,
    required this.playerControlHandedness,
    required this.playerDensity,
    required this.playerGestureDoubleTap,
    required this.playerGestureSwipeTrack,
    required this.playerGestureSwipeVolume,
    required this.playerGestureSwipeDismiss,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['scan_on_start'] = Variable<bool>(scanOnStart);
    if (!nullToAbsent || lastScanAt != null) {
      map['last_scan_at'] = Variable<DateTime>(lastScanAt);
    }
    map['use_dynamic_color'] = Variable<bool>(useDynamicColor);
    map['pure_black_background'] = Variable<bool>(pureBlackBackground);
    map['accent_id'] = Variable<String>(accentId);
    map['background_depth'] = Variable<String>(backgroundDepth);
    map['glass_intensity'] = Variable<String>(glassIntensity);
    map['restore_queue_on_start'] = Variable<bool>(restoreQueueOnStart);
    map['gapless_enabled'] = Variable<bool>(gaplessEnabled);
    map['crossfade_seconds'] = Variable<int>(crossfadeSeconds);
    map['fade_on_pause'] = Variable<bool>(fadeOnPause);
    map['fade_on_pause_ms'] = Variable<int>(fadeOnPauseMs);
    map['direct_mode'] = Variable<bool>(directMode);
    map['allow_offload'] = Variable<bool>(allowOffload);
    map['playback_speed'] = Variable<double>(playbackSpeed);
    map['playback_pitch'] = Variable<double>(playbackPitch);
    map['embed_cover_in_file'] = Variable<bool>(embedCoverInFile);
    map['widget_enabled'] = Variable<bool>(widgetEnabled);
    map['widget_style'] = Variable<int>(widgetStyle);
    map['widget_theme'] = Variable<int>(widgetTheme);
    map['widget_size'] = Variable<int>(widgetSize);
    map['widget_accent_color'] = Variable<int>(widgetAccentColor);
    map['widget_opacity'] = Variable<double>(widgetOpacity);
    map['widget_show_cover'] = Variable<bool>(widgetShowCover);
    map['widget_show_title'] = Variable<bool>(widgetShowTitle);
    map['widget_show_artist'] = Variable<bool>(widgetShowArtist);
    map['widget_show_controls'] = Variable<bool>(widgetShowControls);
    map['widget_show_progress'] = Variable<bool>(widgetShowProgress);
    map['widget_show_duration'] = Variable<bool>(widgetShowDuration);
    map['widget_show_next_in_queue'] = Variable<bool>(widgetShowNextInQueue);
    map['widget_open_on_tap'] = Variable<bool>(widgetOpenOnTap);
    map['widget_pause_on_disconnect'] = Variable<bool>(widgetPauseOnDisconnect);
    map['widget_resume_on_connect'] = Variable<bool>(widgetResumeOnConnect);
    map['sleep_timer_minutes'] = Variable<int>(sleepTimerMinutes);
    map['sleep_timer_finish_track'] = Variable<bool>(sleepTimerFinishTrack);
    map['home_sections_json'] = Variable<String>(homeSectionsJson);
    map['library_sort_json'] = Variable<String>(librarySortJson);
    map['video_background_enabled'] = Variable<bool>(videoBackgroundEnabled);
    map['player_visualizer_style'] = Variable<int>(playerVisualizerStyle);
    map['player_visual_scene'] = Variable<int>(playerVisualScene);
    map['player_scene_aspect_ratio'] = Variable<int>(playerSceneAspectRatio);
    map['player_control_preset'] = Variable<String>(playerControlPreset);
    map['player_control_layout_json'] = Variable<String>(
      playerControlLayoutJson,
    );
    map['player_control_handedness'] = Variable<String>(
      playerControlHandedness,
    );
    map['player_density'] = Variable<String>(playerDensity);
    map['player_gesture_double_tap'] = Variable<bool>(playerGestureDoubleTap);
    map['player_gesture_swipe_track'] = Variable<bool>(playerGestureSwipeTrack);
    map['player_gesture_swipe_volume'] = Variable<bool>(
      playerGestureSwipeVolume,
    );
    map['player_gesture_swipe_dismiss'] = Variable<bool>(
      playerGestureSwipeDismiss,
    );
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      scanOnStart: Value(scanOnStart),
      lastScanAt: lastScanAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastScanAt),
      useDynamicColor: Value(useDynamicColor),
      pureBlackBackground: Value(pureBlackBackground),
      accentId: Value(accentId),
      backgroundDepth: Value(backgroundDepth),
      glassIntensity: Value(glassIntensity),
      restoreQueueOnStart: Value(restoreQueueOnStart),
      gaplessEnabled: Value(gaplessEnabled),
      crossfadeSeconds: Value(crossfadeSeconds),
      fadeOnPause: Value(fadeOnPause),
      fadeOnPauseMs: Value(fadeOnPauseMs),
      directMode: Value(directMode),
      allowOffload: Value(allowOffload),
      playbackSpeed: Value(playbackSpeed),
      playbackPitch: Value(playbackPitch),
      embedCoverInFile: Value(embedCoverInFile),
      widgetEnabled: Value(widgetEnabled),
      widgetStyle: Value(widgetStyle),
      widgetTheme: Value(widgetTheme),
      widgetSize: Value(widgetSize),
      widgetAccentColor: Value(widgetAccentColor),
      widgetOpacity: Value(widgetOpacity),
      widgetShowCover: Value(widgetShowCover),
      widgetShowTitle: Value(widgetShowTitle),
      widgetShowArtist: Value(widgetShowArtist),
      widgetShowControls: Value(widgetShowControls),
      widgetShowProgress: Value(widgetShowProgress),
      widgetShowDuration: Value(widgetShowDuration),
      widgetShowNextInQueue: Value(widgetShowNextInQueue),
      widgetOpenOnTap: Value(widgetOpenOnTap),
      widgetPauseOnDisconnect: Value(widgetPauseOnDisconnect),
      widgetResumeOnConnect: Value(widgetResumeOnConnect),
      sleepTimerMinutes: Value(sleepTimerMinutes),
      sleepTimerFinishTrack: Value(sleepTimerFinishTrack),
      homeSectionsJson: Value(homeSectionsJson),
      librarySortJson: Value(librarySortJson),
      videoBackgroundEnabled: Value(videoBackgroundEnabled),
      playerVisualizerStyle: Value(playerVisualizerStyle),
      playerVisualScene: Value(playerVisualScene),
      playerSceneAspectRatio: Value(playerSceneAspectRatio),
      playerControlPreset: Value(playerControlPreset),
      playerControlLayoutJson: Value(playerControlLayoutJson),
      playerControlHandedness: Value(playerControlHandedness),
      playerDensity: Value(playerDensity),
      playerGestureDoubleTap: Value(playerGestureDoubleTap),
      playerGestureSwipeTrack: Value(playerGestureSwipeTrack),
      playerGestureSwipeVolume: Value(playerGestureSwipeVolume),
      playerGestureSwipeDismiss: Value(playerGestureSwipeDismiss),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      id: serializer.fromJson<int>(json['id']),
      scanOnStart: serializer.fromJson<bool>(json['scanOnStart']),
      lastScanAt: serializer.fromJson<DateTime?>(json['lastScanAt']),
      useDynamicColor: serializer.fromJson<bool>(json['useDynamicColor']),
      pureBlackBackground: serializer.fromJson<bool>(
        json['pureBlackBackground'],
      ),
      accentId: serializer.fromJson<String>(json['accentId']),
      backgroundDepth: serializer.fromJson<String>(json['backgroundDepth']),
      glassIntensity: serializer.fromJson<String>(json['glassIntensity']),
      restoreQueueOnStart: serializer.fromJson<bool>(
        json['restoreQueueOnStart'],
      ),
      gaplessEnabled: serializer.fromJson<bool>(json['gaplessEnabled']),
      crossfadeSeconds: serializer.fromJson<int>(json['crossfadeSeconds']),
      fadeOnPause: serializer.fromJson<bool>(json['fadeOnPause']),
      fadeOnPauseMs: serializer.fromJson<int>(json['fadeOnPauseMs']),
      directMode: serializer.fromJson<bool>(json['directMode']),
      allowOffload: serializer.fromJson<bool>(json['allowOffload']),
      playbackSpeed: serializer.fromJson<double>(json['playbackSpeed']),
      playbackPitch: serializer.fromJson<double>(json['playbackPitch']),
      embedCoverInFile: serializer.fromJson<bool>(json['embedCoverInFile']),
      widgetEnabled: serializer.fromJson<bool>(json['widgetEnabled']),
      widgetStyle: serializer.fromJson<int>(json['widgetStyle']),
      widgetTheme: serializer.fromJson<int>(json['widgetTheme']),
      widgetSize: serializer.fromJson<int>(json['widgetSize']),
      widgetAccentColor: serializer.fromJson<int>(json['widgetAccentColor']),
      widgetOpacity: serializer.fromJson<double>(json['widgetOpacity']),
      widgetShowCover: serializer.fromJson<bool>(json['widgetShowCover']),
      widgetShowTitle: serializer.fromJson<bool>(json['widgetShowTitle']),
      widgetShowArtist: serializer.fromJson<bool>(json['widgetShowArtist']),
      widgetShowControls: serializer.fromJson<bool>(json['widgetShowControls']),
      widgetShowProgress: serializer.fromJson<bool>(json['widgetShowProgress']),
      widgetShowDuration: serializer.fromJson<bool>(json['widgetShowDuration']),
      widgetShowNextInQueue: serializer.fromJson<bool>(
        json['widgetShowNextInQueue'],
      ),
      widgetOpenOnTap: serializer.fromJson<bool>(json['widgetOpenOnTap']),
      widgetPauseOnDisconnect: serializer.fromJson<bool>(
        json['widgetPauseOnDisconnect'],
      ),
      widgetResumeOnConnect: serializer.fromJson<bool>(
        json['widgetResumeOnConnect'],
      ),
      sleepTimerMinutes: serializer.fromJson<int>(json['sleepTimerMinutes']),
      sleepTimerFinishTrack: serializer.fromJson<bool>(
        json['sleepTimerFinishTrack'],
      ),
      homeSectionsJson: serializer.fromJson<String>(json['homeSectionsJson']),
      librarySortJson: serializer.fromJson<String>(json['librarySortJson']),
      videoBackgroundEnabled: serializer.fromJson<bool>(
        json['videoBackgroundEnabled'],
      ),
      playerVisualizerStyle: serializer.fromJson<int>(
        json['playerVisualizerStyle'],
      ),
      playerVisualScene: serializer.fromJson<int>(json['playerVisualScene']),
      playerSceneAspectRatio: serializer.fromJson<int>(
        json['playerSceneAspectRatio'],
      ),
      playerControlPreset: serializer.fromJson<String>(
        json['playerControlPreset'],
      ),
      playerControlLayoutJson: serializer.fromJson<String>(
        json['playerControlLayoutJson'],
      ),
      playerControlHandedness: serializer.fromJson<String>(
        json['playerControlHandedness'],
      ),
      playerDensity: serializer.fromJson<String>(json['playerDensity']),
      playerGestureDoubleTap: serializer.fromJson<bool>(
        json['playerGestureDoubleTap'],
      ),
      playerGestureSwipeTrack: serializer.fromJson<bool>(
        json['playerGestureSwipeTrack'],
      ),
      playerGestureSwipeVolume: serializer.fromJson<bool>(
        json['playerGestureSwipeVolume'],
      ),
      playerGestureSwipeDismiss: serializer.fromJson<bool>(
        json['playerGestureSwipeDismiss'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'scanOnStart': serializer.toJson<bool>(scanOnStart),
      'lastScanAt': serializer.toJson<DateTime?>(lastScanAt),
      'useDynamicColor': serializer.toJson<bool>(useDynamicColor),
      'pureBlackBackground': serializer.toJson<bool>(pureBlackBackground),
      'accentId': serializer.toJson<String>(accentId),
      'backgroundDepth': serializer.toJson<String>(backgroundDepth),
      'glassIntensity': serializer.toJson<String>(glassIntensity),
      'restoreQueueOnStart': serializer.toJson<bool>(restoreQueueOnStart),
      'gaplessEnabled': serializer.toJson<bool>(gaplessEnabled),
      'crossfadeSeconds': serializer.toJson<int>(crossfadeSeconds),
      'fadeOnPause': serializer.toJson<bool>(fadeOnPause),
      'fadeOnPauseMs': serializer.toJson<int>(fadeOnPauseMs),
      'directMode': serializer.toJson<bool>(directMode),
      'allowOffload': serializer.toJson<bool>(allowOffload),
      'playbackSpeed': serializer.toJson<double>(playbackSpeed),
      'playbackPitch': serializer.toJson<double>(playbackPitch),
      'embedCoverInFile': serializer.toJson<bool>(embedCoverInFile),
      'widgetEnabled': serializer.toJson<bool>(widgetEnabled),
      'widgetStyle': serializer.toJson<int>(widgetStyle),
      'widgetTheme': serializer.toJson<int>(widgetTheme),
      'widgetSize': serializer.toJson<int>(widgetSize),
      'widgetAccentColor': serializer.toJson<int>(widgetAccentColor),
      'widgetOpacity': serializer.toJson<double>(widgetOpacity),
      'widgetShowCover': serializer.toJson<bool>(widgetShowCover),
      'widgetShowTitle': serializer.toJson<bool>(widgetShowTitle),
      'widgetShowArtist': serializer.toJson<bool>(widgetShowArtist),
      'widgetShowControls': serializer.toJson<bool>(widgetShowControls),
      'widgetShowProgress': serializer.toJson<bool>(widgetShowProgress),
      'widgetShowDuration': serializer.toJson<bool>(widgetShowDuration),
      'widgetShowNextInQueue': serializer.toJson<bool>(widgetShowNextInQueue),
      'widgetOpenOnTap': serializer.toJson<bool>(widgetOpenOnTap),
      'widgetPauseOnDisconnect': serializer.toJson<bool>(
        widgetPauseOnDisconnect,
      ),
      'widgetResumeOnConnect': serializer.toJson<bool>(widgetResumeOnConnect),
      'sleepTimerMinutes': serializer.toJson<int>(sleepTimerMinutes),
      'sleepTimerFinishTrack': serializer.toJson<bool>(sleepTimerFinishTrack),
      'homeSectionsJson': serializer.toJson<String>(homeSectionsJson),
      'librarySortJson': serializer.toJson<String>(librarySortJson),
      'videoBackgroundEnabled': serializer.toJson<bool>(videoBackgroundEnabled),
      'playerVisualizerStyle': serializer.toJson<int>(playerVisualizerStyle),
      'playerVisualScene': serializer.toJson<int>(playerVisualScene),
      'playerSceneAspectRatio': serializer.toJson<int>(playerSceneAspectRatio),
      'playerControlPreset': serializer.toJson<String>(playerControlPreset),
      'playerControlLayoutJson': serializer.toJson<String>(
        playerControlLayoutJson,
      ),
      'playerControlHandedness': serializer.toJson<String>(
        playerControlHandedness,
      ),
      'playerDensity': serializer.toJson<String>(playerDensity),
      'playerGestureDoubleTap': serializer.toJson<bool>(playerGestureDoubleTap),
      'playerGestureSwipeTrack': serializer.toJson<bool>(
        playerGestureSwipeTrack,
      ),
      'playerGestureSwipeVolume': serializer.toJson<bool>(
        playerGestureSwipeVolume,
      ),
      'playerGestureSwipeDismiss': serializer.toJson<bool>(
        playerGestureSwipeDismiss,
      ),
    };
  }

  AppSetting copyWith({
    int? id,
    bool? scanOnStart,
    Value<DateTime?> lastScanAt = const Value.absent(),
    bool? useDynamicColor,
    bool? pureBlackBackground,
    String? accentId,
    String? backgroundDepth,
    String? glassIntensity,
    bool? restoreQueueOnStart,
    bool? gaplessEnabled,
    int? crossfadeSeconds,
    bool? fadeOnPause,
    int? fadeOnPauseMs,
    bool? directMode,
    bool? allowOffload,
    double? playbackSpeed,
    double? playbackPitch,
    bool? embedCoverInFile,
    bool? widgetEnabled,
    int? widgetStyle,
    int? widgetTheme,
    int? widgetSize,
    int? widgetAccentColor,
    double? widgetOpacity,
    bool? widgetShowCover,
    bool? widgetShowTitle,
    bool? widgetShowArtist,
    bool? widgetShowControls,
    bool? widgetShowProgress,
    bool? widgetShowDuration,
    bool? widgetShowNextInQueue,
    bool? widgetOpenOnTap,
    bool? widgetPauseOnDisconnect,
    bool? widgetResumeOnConnect,
    int? sleepTimerMinutes,
    bool? sleepTimerFinishTrack,
    String? homeSectionsJson,
    String? librarySortJson,
    bool? videoBackgroundEnabled,
    int? playerVisualizerStyle,
    int? playerVisualScene,
    int? playerSceneAspectRatio,
    String? playerControlPreset,
    String? playerControlLayoutJson,
    String? playerControlHandedness,
    String? playerDensity,
    bool? playerGestureDoubleTap,
    bool? playerGestureSwipeTrack,
    bool? playerGestureSwipeVolume,
    bool? playerGestureSwipeDismiss,
  }) => AppSetting(
    id: id ?? this.id,
    scanOnStart: scanOnStart ?? this.scanOnStart,
    lastScanAt: lastScanAt.present ? lastScanAt.value : this.lastScanAt,
    useDynamicColor: useDynamicColor ?? this.useDynamicColor,
    pureBlackBackground: pureBlackBackground ?? this.pureBlackBackground,
    accentId: accentId ?? this.accentId,
    backgroundDepth: backgroundDepth ?? this.backgroundDepth,
    glassIntensity: glassIntensity ?? this.glassIntensity,
    restoreQueueOnStart: restoreQueueOnStart ?? this.restoreQueueOnStart,
    gaplessEnabled: gaplessEnabled ?? this.gaplessEnabled,
    crossfadeSeconds: crossfadeSeconds ?? this.crossfadeSeconds,
    fadeOnPause: fadeOnPause ?? this.fadeOnPause,
    fadeOnPauseMs: fadeOnPauseMs ?? this.fadeOnPauseMs,
    directMode: directMode ?? this.directMode,
    allowOffload: allowOffload ?? this.allowOffload,
    playbackSpeed: playbackSpeed ?? this.playbackSpeed,
    playbackPitch: playbackPitch ?? this.playbackPitch,
    embedCoverInFile: embedCoverInFile ?? this.embedCoverInFile,
    widgetEnabled: widgetEnabled ?? this.widgetEnabled,
    widgetStyle: widgetStyle ?? this.widgetStyle,
    widgetTheme: widgetTheme ?? this.widgetTheme,
    widgetSize: widgetSize ?? this.widgetSize,
    widgetAccentColor: widgetAccentColor ?? this.widgetAccentColor,
    widgetOpacity: widgetOpacity ?? this.widgetOpacity,
    widgetShowCover: widgetShowCover ?? this.widgetShowCover,
    widgetShowTitle: widgetShowTitle ?? this.widgetShowTitle,
    widgetShowArtist: widgetShowArtist ?? this.widgetShowArtist,
    widgetShowControls: widgetShowControls ?? this.widgetShowControls,
    widgetShowProgress: widgetShowProgress ?? this.widgetShowProgress,
    widgetShowDuration: widgetShowDuration ?? this.widgetShowDuration,
    widgetShowNextInQueue: widgetShowNextInQueue ?? this.widgetShowNextInQueue,
    widgetOpenOnTap: widgetOpenOnTap ?? this.widgetOpenOnTap,
    widgetPauseOnDisconnect:
        widgetPauseOnDisconnect ?? this.widgetPauseOnDisconnect,
    widgetResumeOnConnect: widgetResumeOnConnect ?? this.widgetResumeOnConnect,
    sleepTimerMinutes: sleepTimerMinutes ?? this.sleepTimerMinutes,
    sleepTimerFinishTrack: sleepTimerFinishTrack ?? this.sleepTimerFinishTrack,
    homeSectionsJson: homeSectionsJson ?? this.homeSectionsJson,
    librarySortJson: librarySortJson ?? this.librarySortJson,
    videoBackgroundEnabled:
        videoBackgroundEnabled ?? this.videoBackgroundEnabled,
    playerVisualizerStyle: playerVisualizerStyle ?? this.playerVisualizerStyle,
    playerVisualScene: playerVisualScene ?? this.playerVisualScene,
    playerSceneAspectRatio:
        playerSceneAspectRatio ?? this.playerSceneAspectRatio,
    playerControlPreset: playerControlPreset ?? this.playerControlPreset,
    playerControlLayoutJson:
        playerControlLayoutJson ?? this.playerControlLayoutJson,
    playerControlHandedness:
        playerControlHandedness ?? this.playerControlHandedness,
    playerDensity: playerDensity ?? this.playerDensity,
    playerGestureDoubleTap:
        playerGestureDoubleTap ?? this.playerGestureDoubleTap,
    playerGestureSwipeTrack:
        playerGestureSwipeTrack ?? this.playerGestureSwipeTrack,
    playerGestureSwipeVolume:
        playerGestureSwipeVolume ?? this.playerGestureSwipeVolume,
    playerGestureSwipeDismiss:
        playerGestureSwipeDismiss ?? this.playerGestureSwipeDismiss,
  );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      id: data.id.present ? data.id.value : this.id,
      scanOnStart: data.scanOnStart.present
          ? data.scanOnStart.value
          : this.scanOnStart,
      lastScanAt: data.lastScanAt.present
          ? data.lastScanAt.value
          : this.lastScanAt,
      useDynamicColor: data.useDynamicColor.present
          ? data.useDynamicColor.value
          : this.useDynamicColor,
      pureBlackBackground: data.pureBlackBackground.present
          ? data.pureBlackBackground.value
          : this.pureBlackBackground,
      accentId: data.accentId.present ? data.accentId.value : this.accentId,
      backgroundDepth: data.backgroundDepth.present
          ? data.backgroundDepth.value
          : this.backgroundDepth,
      glassIntensity: data.glassIntensity.present
          ? data.glassIntensity.value
          : this.glassIntensity,
      restoreQueueOnStart: data.restoreQueueOnStart.present
          ? data.restoreQueueOnStart.value
          : this.restoreQueueOnStart,
      gaplessEnabled: data.gaplessEnabled.present
          ? data.gaplessEnabled.value
          : this.gaplessEnabled,
      crossfadeSeconds: data.crossfadeSeconds.present
          ? data.crossfadeSeconds.value
          : this.crossfadeSeconds,
      fadeOnPause: data.fadeOnPause.present
          ? data.fadeOnPause.value
          : this.fadeOnPause,
      fadeOnPauseMs: data.fadeOnPauseMs.present
          ? data.fadeOnPauseMs.value
          : this.fadeOnPauseMs,
      directMode: data.directMode.present
          ? data.directMode.value
          : this.directMode,
      allowOffload: data.allowOffload.present
          ? data.allowOffload.value
          : this.allowOffload,
      playbackSpeed: data.playbackSpeed.present
          ? data.playbackSpeed.value
          : this.playbackSpeed,
      playbackPitch: data.playbackPitch.present
          ? data.playbackPitch.value
          : this.playbackPitch,
      embedCoverInFile: data.embedCoverInFile.present
          ? data.embedCoverInFile.value
          : this.embedCoverInFile,
      widgetEnabled: data.widgetEnabled.present
          ? data.widgetEnabled.value
          : this.widgetEnabled,
      widgetStyle: data.widgetStyle.present
          ? data.widgetStyle.value
          : this.widgetStyle,
      widgetTheme: data.widgetTheme.present
          ? data.widgetTheme.value
          : this.widgetTheme,
      widgetSize: data.widgetSize.present
          ? data.widgetSize.value
          : this.widgetSize,
      widgetAccentColor: data.widgetAccentColor.present
          ? data.widgetAccentColor.value
          : this.widgetAccentColor,
      widgetOpacity: data.widgetOpacity.present
          ? data.widgetOpacity.value
          : this.widgetOpacity,
      widgetShowCover: data.widgetShowCover.present
          ? data.widgetShowCover.value
          : this.widgetShowCover,
      widgetShowTitle: data.widgetShowTitle.present
          ? data.widgetShowTitle.value
          : this.widgetShowTitle,
      widgetShowArtist: data.widgetShowArtist.present
          ? data.widgetShowArtist.value
          : this.widgetShowArtist,
      widgetShowControls: data.widgetShowControls.present
          ? data.widgetShowControls.value
          : this.widgetShowControls,
      widgetShowProgress: data.widgetShowProgress.present
          ? data.widgetShowProgress.value
          : this.widgetShowProgress,
      widgetShowDuration: data.widgetShowDuration.present
          ? data.widgetShowDuration.value
          : this.widgetShowDuration,
      widgetShowNextInQueue: data.widgetShowNextInQueue.present
          ? data.widgetShowNextInQueue.value
          : this.widgetShowNextInQueue,
      widgetOpenOnTap: data.widgetOpenOnTap.present
          ? data.widgetOpenOnTap.value
          : this.widgetOpenOnTap,
      widgetPauseOnDisconnect: data.widgetPauseOnDisconnect.present
          ? data.widgetPauseOnDisconnect.value
          : this.widgetPauseOnDisconnect,
      widgetResumeOnConnect: data.widgetResumeOnConnect.present
          ? data.widgetResumeOnConnect.value
          : this.widgetResumeOnConnect,
      sleepTimerMinutes: data.sleepTimerMinutes.present
          ? data.sleepTimerMinutes.value
          : this.sleepTimerMinutes,
      sleepTimerFinishTrack: data.sleepTimerFinishTrack.present
          ? data.sleepTimerFinishTrack.value
          : this.sleepTimerFinishTrack,
      homeSectionsJson: data.homeSectionsJson.present
          ? data.homeSectionsJson.value
          : this.homeSectionsJson,
      librarySortJson: data.librarySortJson.present
          ? data.librarySortJson.value
          : this.librarySortJson,
      videoBackgroundEnabled: data.videoBackgroundEnabled.present
          ? data.videoBackgroundEnabled.value
          : this.videoBackgroundEnabled,
      playerVisualizerStyle: data.playerVisualizerStyle.present
          ? data.playerVisualizerStyle.value
          : this.playerVisualizerStyle,
      playerVisualScene: data.playerVisualScene.present
          ? data.playerVisualScene.value
          : this.playerVisualScene,
      playerSceneAspectRatio: data.playerSceneAspectRatio.present
          ? data.playerSceneAspectRatio.value
          : this.playerSceneAspectRatio,
      playerControlPreset: data.playerControlPreset.present
          ? data.playerControlPreset.value
          : this.playerControlPreset,
      playerControlLayoutJson: data.playerControlLayoutJson.present
          ? data.playerControlLayoutJson.value
          : this.playerControlLayoutJson,
      playerControlHandedness: data.playerControlHandedness.present
          ? data.playerControlHandedness.value
          : this.playerControlHandedness,
      playerDensity: data.playerDensity.present
          ? data.playerDensity.value
          : this.playerDensity,
      playerGestureDoubleTap: data.playerGestureDoubleTap.present
          ? data.playerGestureDoubleTap.value
          : this.playerGestureDoubleTap,
      playerGestureSwipeTrack: data.playerGestureSwipeTrack.present
          ? data.playerGestureSwipeTrack.value
          : this.playerGestureSwipeTrack,
      playerGestureSwipeVolume: data.playerGestureSwipeVolume.present
          ? data.playerGestureSwipeVolume.value
          : this.playerGestureSwipeVolume,
      playerGestureSwipeDismiss: data.playerGestureSwipeDismiss.present
          ? data.playerGestureSwipeDismiss.value
          : this.playerGestureSwipeDismiss,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('id: $id, ')
          ..write('scanOnStart: $scanOnStart, ')
          ..write('lastScanAt: $lastScanAt, ')
          ..write('useDynamicColor: $useDynamicColor, ')
          ..write('pureBlackBackground: $pureBlackBackground, ')
          ..write('accentId: $accentId, ')
          ..write('backgroundDepth: $backgroundDepth, ')
          ..write('glassIntensity: $glassIntensity, ')
          ..write('restoreQueueOnStart: $restoreQueueOnStart, ')
          ..write('gaplessEnabled: $gaplessEnabled, ')
          ..write('crossfadeSeconds: $crossfadeSeconds, ')
          ..write('fadeOnPause: $fadeOnPause, ')
          ..write('fadeOnPauseMs: $fadeOnPauseMs, ')
          ..write('directMode: $directMode, ')
          ..write('allowOffload: $allowOffload, ')
          ..write('playbackSpeed: $playbackSpeed, ')
          ..write('playbackPitch: $playbackPitch, ')
          ..write('embedCoverInFile: $embedCoverInFile, ')
          ..write('widgetEnabled: $widgetEnabled, ')
          ..write('widgetStyle: $widgetStyle, ')
          ..write('widgetTheme: $widgetTheme, ')
          ..write('widgetSize: $widgetSize, ')
          ..write('widgetAccentColor: $widgetAccentColor, ')
          ..write('widgetOpacity: $widgetOpacity, ')
          ..write('widgetShowCover: $widgetShowCover, ')
          ..write('widgetShowTitle: $widgetShowTitle, ')
          ..write('widgetShowArtist: $widgetShowArtist, ')
          ..write('widgetShowControls: $widgetShowControls, ')
          ..write('widgetShowProgress: $widgetShowProgress, ')
          ..write('widgetShowDuration: $widgetShowDuration, ')
          ..write('widgetShowNextInQueue: $widgetShowNextInQueue, ')
          ..write('widgetOpenOnTap: $widgetOpenOnTap, ')
          ..write('widgetPauseOnDisconnect: $widgetPauseOnDisconnect, ')
          ..write('widgetResumeOnConnect: $widgetResumeOnConnect, ')
          ..write('sleepTimerMinutes: $sleepTimerMinutes, ')
          ..write('sleepTimerFinishTrack: $sleepTimerFinishTrack, ')
          ..write('homeSectionsJson: $homeSectionsJson, ')
          ..write('librarySortJson: $librarySortJson, ')
          ..write('videoBackgroundEnabled: $videoBackgroundEnabled, ')
          ..write('playerVisualizerStyle: $playerVisualizerStyle, ')
          ..write('playerVisualScene: $playerVisualScene, ')
          ..write('playerSceneAspectRatio: $playerSceneAspectRatio, ')
          ..write('playerControlPreset: $playerControlPreset, ')
          ..write('playerControlLayoutJson: $playerControlLayoutJson, ')
          ..write('playerControlHandedness: $playerControlHandedness, ')
          ..write('playerDensity: $playerDensity, ')
          ..write('playerGestureDoubleTap: $playerGestureDoubleTap, ')
          ..write('playerGestureSwipeTrack: $playerGestureSwipeTrack, ')
          ..write('playerGestureSwipeVolume: $playerGestureSwipeVolume, ')
          ..write('playerGestureSwipeDismiss: $playerGestureSwipeDismiss')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    scanOnStart,
    lastScanAt,
    useDynamicColor,
    pureBlackBackground,
    accentId,
    backgroundDepth,
    glassIntensity,
    restoreQueueOnStart,
    gaplessEnabled,
    crossfadeSeconds,
    fadeOnPause,
    fadeOnPauseMs,
    directMode,
    allowOffload,
    playbackSpeed,
    playbackPitch,
    embedCoverInFile,
    widgetEnabled,
    widgetStyle,
    widgetTheme,
    widgetSize,
    widgetAccentColor,
    widgetOpacity,
    widgetShowCover,
    widgetShowTitle,
    widgetShowArtist,
    widgetShowControls,
    widgetShowProgress,
    widgetShowDuration,
    widgetShowNextInQueue,
    widgetOpenOnTap,
    widgetPauseOnDisconnect,
    widgetResumeOnConnect,
    sleepTimerMinutes,
    sleepTimerFinishTrack,
    homeSectionsJson,
    librarySortJson,
    videoBackgroundEnabled,
    playerVisualizerStyle,
    playerVisualScene,
    playerSceneAspectRatio,
    playerControlPreset,
    playerControlLayoutJson,
    playerControlHandedness,
    playerDensity,
    playerGestureDoubleTap,
    playerGestureSwipeTrack,
    playerGestureSwipeVolume,
    playerGestureSwipeDismiss,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.id == this.id &&
          other.scanOnStart == this.scanOnStart &&
          other.lastScanAt == this.lastScanAt &&
          other.useDynamicColor == this.useDynamicColor &&
          other.pureBlackBackground == this.pureBlackBackground &&
          other.accentId == this.accentId &&
          other.backgroundDepth == this.backgroundDepth &&
          other.glassIntensity == this.glassIntensity &&
          other.restoreQueueOnStart == this.restoreQueueOnStart &&
          other.gaplessEnabled == this.gaplessEnabled &&
          other.crossfadeSeconds == this.crossfadeSeconds &&
          other.fadeOnPause == this.fadeOnPause &&
          other.fadeOnPauseMs == this.fadeOnPauseMs &&
          other.directMode == this.directMode &&
          other.allowOffload == this.allowOffload &&
          other.playbackSpeed == this.playbackSpeed &&
          other.playbackPitch == this.playbackPitch &&
          other.embedCoverInFile == this.embedCoverInFile &&
          other.widgetEnabled == this.widgetEnabled &&
          other.widgetStyle == this.widgetStyle &&
          other.widgetTheme == this.widgetTheme &&
          other.widgetSize == this.widgetSize &&
          other.widgetAccentColor == this.widgetAccentColor &&
          other.widgetOpacity == this.widgetOpacity &&
          other.widgetShowCover == this.widgetShowCover &&
          other.widgetShowTitle == this.widgetShowTitle &&
          other.widgetShowArtist == this.widgetShowArtist &&
          other.widgetShowControls == this.widgetShowControls &&
          other.widgetShowProgress == this.widgetShowProgress &&
          other.widgetShowDuration == this.widgetShowDuration &&
          other.widgetShowNextInQueue == this.widgetShowNextInQueue &&
          other.widgetOpenOnTap == this.widgetOpenOnTap &&
          other.widgetPauseOnDisconnect == this.widgetPauseOnDisconnect &&
          other.widgetResumeOnConnect == this.widgetResumeOnConnect &&
          other.sleepTimerMinutes == this.sleepTimerMinutes &&
          other.sleepTimerFinishTrack == this.sleepTimerFinishTrack &&
          other.homeSectionsJson == this.homeSectionsJson &&
          other.librarySortJson == this.librarySortJson &&
          other.videoBackgroundEnabled == this.videoBackgroundEnabled &&
          other.playerVisualizerStyle == this.playerVisualizerStyle &&
          other.playerVisualScene == this.playerVisualScene &&
          other.playerSceneAspectRatio == this.playerSceneAspectRatio &&
          other.playerControlPreset == this.playerControlPreset &&
          other.playerControlLayoutJson == this.playerControlLayoutJson &&
          other.playerControlHandedness == this.playerControlHandedness &&
          other.playerDensity == this.playerDensity &&
          other.playerGestureDoubleTap == this.playerGestureDoubleTap &&
          other.playerGestureSwipeTrack == this.playerGestureSwipeTrack &&
          other.playerGestureSwipeVolume == this.playerGestureSwipeVolume &&
          other.playerGestureSwipeDismiss == this.playerGestureSwipeDismiss);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<int> id;
  final Value<bool> scanOnStart;
  final Value<DateTime?> lastScanAt;
  final Value<bool> useDynamicColor;
  final Value<bool> pureBlackBackground;
  final Value<String> accentId;
  final Value<String> backgroundDepth;
  final Value<String> glassIntensity;
  final Value<bool> restoreQueueOnStart;
  final Value<bool> gaplessEnabled;
  final Value<int> crossfadeSeconds;
  final Value<bool> fadeOnPause;
  final Value<int> fadeOnPauseMs;
  final Value<bool> directMode;
  final Value<bool> allowOffload;
  final Value<double> playbackSpeed;
  final Value<double> playbackPitch;
  final Value<bool> embedCoverInFile;
  final Value<bool> widgetEnabled;
  final Value<int> widgetStyle;
  final Value<int> widgetTheme;
  final Value<int> widgetSize;
  final Value<int> widgetAccentColor;
  final Value<double> widgetOpacity;
  final Value<bool> widgetShowCover;
  final Value<bool> widgetShowTitle;
  final Value<bool> widgetShowArtist;
  final Value<bool> widgetShowControls;
  final Value<bool> widgetShowProgress;
  final Value<bool> widgetShowDuration;
  final Value<bool> widgetShowNextInQueue;
  final Value<bool> widgetOpenOnTap;
  final Value<bool> widgetPauseOnDisconnect;
  final Value<bool> widgetResumeOnConnect;
  final Value<int> sleepTimerMinutes;
  final Value<bool> sleepTimerFinishTrack;
  final Value<String> homeSectionsJson;
  final Value<String> librarySortJson;
  final Value<bool> videoBackgroundEnabled;
  final Value<int> playerVisualizerStyle;
  final Value<int> playerVisualScene;
  final Value<int> playerSceneAspectRatio;
  final Value<String> playerControlPreset;
  final Value<String> playerControlLayoutJson;
  final Value<String> playerControlHandedness;
  final Value<String> playerDensity;
  final Value<bool> playerGestureDoubleTap;
  final Value<bool> playerGestureSwipeTrack;
  final Value<bool> playerGestureSwipeVolume;
  final Value<bool> playerGestureSwipeDismiss;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.scanOnStart = const Value.absent(),
    this.lastScanAt = const Value.absent(),
    this.useDynamicColor = const Value.absent(),
    this.pureBlackBackground = const Value.absent(),
    this.accentId = const Value.absent(),
    this.backgroundDepth = const Value.absent(),
    this.glassIntensity = const Value.absent(),
    this.restoreQueueOnStart = const Value.absent(),
    this.gaplessEnabled = const Value.absent(),
    this.crossfadeSeconds = const Value.absent(),
    this.fadeOnPause = const Value.absent(),
    this.fadeOnPauseMs = const Value.absent(),
    this.directMode = const Value.absent(),
    this.allowOffload = const Value.absent(),
    this.playbackSpeed = const Value.absent(),
    this.playbackPitch = const Value.absent(),
    this.embedCoverInFile = const Value.absent(),
    this.widgetEnabled = const Value.absent(),
    this.widgetStyle = const Value.absent(),
    this.widgetTheme = const Value.absent(),
    this.widgetSize = const Value.absent(),
    this.widgetAccentColor = const Value.absent(),
    this.widgetOpacity = const Value.absent(),
    this.widgetShowCover = const Value.absent(),
    this.widgetShowTitle = const Value.absent(),
    this.widgetShowArtist = const Value.absent(),
    this.widgetShowControls = const Value.absent(),
    this.widgetShowProgress = const Value.absent(),
    this.widgetShowDuration = const Value.absent(),
    this.widgetShowNextInQueue = const Value.absent(),
    this.widgetOpenOnTap = const Value.absent(),
    this.widgetPauseOnDisconnect = const Value.absent(),
    this.widgetResumeOnConnect = const Value.absent(),
    this.sleepTimerMinutes = const Value.absent(),
    this.sleepTimerFinishTrack = const Value.absent(),
    this.homeSectionsJson = const Value.absent(),
    this.librarySortJson = const Value.absent(),
    this.videoBackgroundEnabled = const Value.absent(),
    this.playerVisualizerStyle = const Value.absent(),
    this.playerVisualScene = const Value.absent(),
    this.playerSceneAspectRatio = const Value.absent(),
    this.playerControlPreset = const Value.absent(),
    this.playerControlLayoutJson = const Value.absent(),
    this.playerControlHandedness = const Value.absent(),
    this.playerDensity = const Value.absent(),
    this.playerGestureDoubleTap = const Value.absent(),
    this.playerGestureSwipeTrack = const Value.absent(),
    this.playerGestureSwipeVolume = const Value.absent(),
    this.playerGestureSwipeDismiss = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.scanOnStart = const Value.absent(),
    this.lastScanAt = const Value.absent(),
    this.useDynamicColor = const Value.absent(),
    this.pureBlackBackground = const Value.absent(),
    this.accentId = const Value.absent(),
    this.backgroundDepth = const Value.absent(),
    this.glassIntensity = const Value.absent(),
    this.restoreQueueOnStart = const Value.absent(),
    this.gaplessEnabled = const Value.absent(),
    this.crossfadeSeconds = const Value.absent(),
    this.fadeOnPause = const Value.absent(),
    this.fadeOnPauseMs = const Value.absent(),
    this.directMode = const Value.absent(),
    this.allowOffload = const Value.absent(),
    this.playbackSpeed = const Value.absent(),
    this.playbackPitch = const Value.absent(),
    this.embedCoverInFile = const Value.absent(),
    this.widgetEnabled = const Value.absent(),
    this.widgetStyle = const Value.absent(),
    this.widgetTheme = const Value.absent(),
    this.widgetSize = const Value.absent(),
    this.widgetAccentColor = const Value.absent(),
    this.widgetOpacity = const Value.absent(),
    this.widgetShowCover = const Value.absent(),
    this.widgetShowTitle = const Value.absent(),
    this.widgetShowArtist = const Value.absent(),
    this.widgetShowControls = const Value.absent(),
    this.widgetShowProgress = const Value.absent(),
    this.widgetShowDuration = const Value.absent(),
    this.widgetShowNextInQueue = const Value.absent(),
    this.widgetOpenOnTap = const Value.absent(),
    this.widgetPauseOnDisconnect = const Value.absent(),
    this.widgetResumeOnConnect = const Value.absent(),
    this.sleepTimerMinutes = const Value.absent(),
    this.sleepTimerFinishTrack = const Value.absent(),
    this.homeSectionsJson = const Value.absent(),
    this.librarySortJson = const Value.absent(),
    this.videoBackgroundEnabled = const Value.absent(),
    this.playerVisualizerStyle = const Value.absent(),
    this.playerVisualScene = const Value.absent(),
    this.playerSceneAspectRatio = const Value.absent(),
    this.playerControlPreset = const Value.absent(),
    this.playerControlLayoutJson = const Value.absent(),
    this.playerControlHandedness = const Value.absent(),
    this.playerDensity = const Value.absent(),
    this.playerGestureDoubleTap = const Value.absent(),
    this.playerGestureSwipeTrack = const Value.absent(),
    this.playerGestureSwipeVolume = const Value.absent(),
    this.playerGestureSwipeDismiss = const Value.absent(),
  });
  static Insertable<AppSetting> custom({
    Expression<int>? id,
    Expression<bool>? scanOnStart,
    Expression<DateTime>? lastScanAt,
    Expression<bool>? useDynamicColor,
    Expression<bool>? pureBlackBackground,
    Expression<String>? accentId,
    Expression<String>? backgroundDepth,
    Expression<String>? glassIntensity,
    Expression<bool>? restoreQueueOnStart,
    Expression<bool>? gaplessEnabled,
    Expression<int>? crossfadeSeconds,
    Expression<bool>? fadeOnPause,
    Expression<int>? fadeOnPauseMs,
    Expression<bool>? directMode,
    Expression<bool>? allowOffload,
    Expression<double>? playbackSpeed,
    Expression<double>? playbackPitch,
    Expression<bool>? embedCoverInFile,
    Expression<bool>? widgetEnabled,
    Expression<int>? widgetStyle,
    Expression<int>? widgetTheme,
    Expression<int>? widgetSize,
    Expression<int>? widgetAccentColor,
    Expression<double>? widgetOpacity,
    Expression<bool>? widgetShowCover,
    Expression<bool>? widgetShowTitle,
    Expression<bool>? widgetShowArtist,
    Expression<bool>? widgetShowControls,
    Expression<bool>? widgetShowProgress,
    Expression<bool>? widgetShowDuration,
    Expression<bool>? widgetShowNextInQueue,
    Expression<bool>? widgetOpenOnTap,
    Expression<bool>? widgetPauseOnDisconnect,
    Expression<bool>? widgetResumeOnConnect,
    Expression<int>? sleepTimerMinutes,
    Expression<bool>? sleepTimerFinishTrack,
    Expression<String>? homeSectionsJson,
    Expression<String>? librarySortJson,
    Expression<bool>? videoBackgroundEnabled,
    Expression<int>? playerVisualizerStyle,
    Expression<int>? playerVisualScene,
    Expression<int>? playerSceneAspectRatio,
    Expression<String>? playerControlPreset,
    Expression<String>? playerControlLayoutJson,
    Expression<String>? playerControlHandedness,
    Expression<String>? playerDensity,
    Expression<bool>? playerGestureDoubleTap,
    Expression<bool>? playerGestureSwipeTrack,
    Expression<bool>? playerGestureSwipeVolume,
    Expression<bool>? playerGestureSwipeDismiss,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scanOnStart != null) 'scan_on_start': scanOnStart,
      if (lastScanAt != null) 'last_scan_at': lastScanAt,
      if (useDynamicColor != null) 'use_dynamic_color': useDynamicColor,
      if (pureBlackBackground != null)
        'pure_black_background': pureBlackBackground,
      if (accentId != null) 'accent_id': accentId,
      if (backgroundDepth != null) 'background_depth': backgroundDepth,
      if (glassIntensity != null) 'glass_intensity': glassIntensity,
      if (restoreQueueOnStart != null)
        'restore_queue_on_start': restoreQueueOnStart,
      if (gaplessEnabled != null) 'gapless_enabled': gaplessEnabled,
      if (crossfadeSeconds != null) 'crossfade_seconds': crossfadeSeconds,
      if (fadeOnPause != null) 'fade_on_pause': fadeOnPause,
      if (fadeOnPauseMs != null) 'fade_on_pause_ms': fadeOnPauseMs,
      if (directMode != null) 'direct_mode': directMode,
      if (allowOffload != null) 'allow_offload': allowOffload,
      if (playbackSpeed != null) 'playback_speed': playbackSpeed,
      if (playbackPitch != null) 'playback_pitch': playbackPitch,
      if (embedCoverInFile != null) 'embed_cover_in_file': embedCoverInFile,
      if (widgetEnabled != null) 'widget_enabled': widgetEnabled,
      if (widgetStyle != null) 'widget_style': widgetStyle,
      if (widgetTheme != null) 'widget_theme': widgetTheme,
      if (widgetSize != null) 'widget_size': widgetSize,
      if (widgetAccentColor != null) 'widget_accent_color': widgetAccentColor,
      if (widgetOpacity != null) 'widget_opacity': widgetOpacity,
      if (widgetShowCover != null) 'widget_show_cover': widgetShowCover,
      if (widgetShowTitle != null) 'widget_show_title': widgetShowTitle,
      if (widgetShowArtist != null) 'widget_show_artist': widgetShowArtist,
      if (widgetShowControls != null)
        'widget_show_controls': widgetShowControls,
      if (widgetShowProgress != null)
        'widget_show_progress': widgetShowProgress,
      if (widgetShowDuration != null)
        'widget_show_duration': widgetShowDuration,
      if (widgetShowNextInQueue != null)
        'widget_show_next_in_queue': widgetShowNextInQueue,
      if (widgetOpenOnTap != null) 'widget_open_on_tap': widgetOpenOnTap,
      if (widgetPauseOnDisconnect != null)
        'widget_pause_on_disconnect': widgetPauseOnDisconnect,
      if (widgetResumeOnConnect != null)
        'widget_resume_on_connect': widgetResumeOnConnect,
      if (sleepTimerMinutes != null) 'sleep_timer_minutes': sleepTimerMinutes,
      if (sleepTimerFinishTrack != null)
        'sleep_timer_finish_track': sleepTimerFinishTrack,
      if (homeSectionsJson != null) 'home_sections_json': homeSectionsJson,
      if (librarySortJson != null) 'library_sort_json': librarySortJson,
      if (videoBackgroundEnabled != null)
        'video_background_enabled': videoBackgroundEnabled,
      if (playerVisualizerStyle != null)
        'player_visualizer_style': playerVisualizerStyle,
      if (playerVisualScene != null) 'player_visual_scene': playerVisualScene,
      if (playerSceneAspectRatio != null)
        'player_scene_aspect_ratio': playerSceneAspectRatio,
      if (playerControlPreset != null)
        'player_control_preset': playerControlPreset,
      if (playerControlLayoutJson != null)
        'player_control_layout_json': playerControlLayoutJson,
      if (playerControlHandedness != null)
        'player_control_handedness': playerControlHandedness,
      if (playerDensity != null) 'player_density': playerDensity,
      if (playerGestureDoubleTap != null)
        'player_gesture_double_tap': playerGestureDoubleTap,
      if (playerGestureSwipeTrack != null)
        'player_gesture_swipe_track': playerGestureSwipeTrack,
      if (playerGestureSwipeVolume != null)
        'player_gesture_swipe_volume': playerGestureSwipeVolume,
      if (playerGestureSwipeDismiss != null)
        'player_gesture_swipe_dismiss': playerGestureSwipeDismiss,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<bool>? scanOnStart,
    Value<DateTime?>? lastScanAt,
    Value<bool>? useDynamicColor,
    Value<bool>? pureBlackBackground,
    Value<String>? accentId,
    Value<String>? backgroundDepth,
    Value<String>? glassIntensity,
    Value<bool>? restoreQueueOnStart,
    Value<bool>? gaplessEnabled,
    Value<int>? crossfadeSeconds,
    Value<bool>? fadeOnPause,
    Value<int>? fadeOnPauseMs,
    Value<bool>? directMode,
    Value<bool>? allowOffload,
    Value<double>? playbackSpeed,
    Value<double>? playbackPitch,
    Value<bool>? embedCoverInFile,
    Value<bool>? widgetEnabled,
    Value<int>? widgetStyle,
    Value<int>? widgetTheme,
    Value<int>? widgetSize,
    Value<int>? widgetAccentColor,
    Value<double>? widgetOpacity,
    Value<bool>? widgetShowCover,
    Value<bool>? widgetShowTitle,
    Value<bool>? widgetShowArtist,
    Value<bool>? widgetShowControls,
    Value<bool>? widgetShowProgress,
    Value<bool>? widgetShowDuration,
    Value<bool>? widgetShowNextInQueue,
    Value<bool>? widgetOpenOnTap,
    Value<bool>? widgetPauseOnDisconnect,
    Value<bool>? widgetResumeOnConnect,
    Value<int>? sleepTimerMinutes,
    Value<bool>? sleepTimerFinishTrack,
    Value<String>? homeSectionsJson,
    Value<String>? librarySortJson,
    Value<bool>? videoBackgroundEnabled,
    Value<int>? playerVisualizerStyle,
    Value<int>? playerVisualScene,
    Value<int>? playerSceneAspectRatio,
    Value<String>? playerControlPreset,
    Value<String>? playerControlLayoutJson,
    Value<String>? playerControlHandedness,
    Value<String>? playerDensity,
    Value<bool>? playerGestureDoubleTap,
    Value<bool>? playerGestureSwipeTrack,
    Value<bool>? playerGestureSwipeVolume,
    Value<bool>? playerGestureSwipeDismiss,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      scanOnStart: scanOnStart ?? this.scanOnStart,
      lastScanAt: lastScanAt ?? this.lastScanAt,
      useDynamicColor: useDynamicColor ?? this.useDynamicColor,
      pureBlackBackground: pureBlackBackground ?? this.pureBlackBackground,
      accentId: accentId ?? this.accentId,
      backgroundDepth: backgroundDepth ?? this.backgroundDepth,
      glassIntensity: glassIntensity ?? this.glassIntensity,
      restoreQueueOnStart: restoreQueueOnStart ?? this.restoreQueueOnStart,
      gaplessEnabled: gaplessEnabled ?? this.gaplessEnabled,
      crossfadeSeconds: crossfadeSeconds ?? this.crossfadeSeconds,
      fadeOnPause: fadeOnPause ?? this.fadeOnPause,
      fadeOnPauseMs: fadeOnPauseMs ?? this.fadeOnPauseMs,
      directMode: directMode ?? this.directMode,
      allowOffload: allowOffload ?? this.allowOffload,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      playbackPitch: playbackPitch ?? this.playbackPitch,
      embedCoverInFile: embedCoverInFile ?? this.embedCoverInFile,
      widgetEnabled: widgetEnabled ?? this.widgetEnabled,
      widgetStyle: widgetStyle ?? this.widgetStyle,
      widgetTheme: widgetTheme ?? this.widgetTheme,
      widgetSize: widgetSize ?? this.widgetSize,
      widgetAccentColor: widgetAccentColor ?? this.widgetAccentColor,
      widgetOpacity: widgetOpacity ?? this.widgetOpacity,
      widgetShowCover: widgetShowCover ?? this.widgetShowCover,
      widgetShowTitle: widgetShowTitle ?? this.widgetShowTitle,
      widgetShowArtist: widgetShowArtist ?? this.widgetShowArtist,
      widgetShowControls: widgetShowControls ?? this.widgetShowControls,
      widgetShowProgress: widgetShowProgress ?? this.widgetShowProgress,
      widgetShowDuration: widgetShowDuration ?? this.widgetShowDuration,
      widgetShowNextInQueue:
          widgetShowNextInQueue ?? this.widgetShowNextInQueue,
      widgetOpenOnTap: widgetOpenOnTap ?? this.widgetOpenOnTap,
      widgetPauseOnDisconnect:
          widgetPauseOnDisconnect ?? this.widgetPauseOnDisconnect,
      widgetResumeOnConnect:
          widgetResumeOnConnect ?? this.widgetResumeOnConnect,
      sleepTimerMinutes: sleepTimerMinutes ?? this.sleepTimerMinutes,
      sleepTimerFinishTrack:
          sleepTimerFinishTrack ?? this.sleepTimerFinishTrack,
      homeSectionsJson: homeSectionsJson ?? this.homeSectionsJson,
      librarySortJson: librarySortJson ?? this.librarySortJson,
      videoBackgroundEnabled:
          videoBackgroundEnabled ?? this.videoBackgroundEnabled,
      playerVisualizerStyle:
          playerVisualizerStyle ?? this.playerVisualizerStyle,
      playerVisualScene: playerVisualScene ?? this.playerVisualScene,
      playerSceneAspectRatio:
          playerSceneAspectRatio ?? this.playerSceneAspectRatio,
      playerControlPreset: playerControlPreset ?? this.playerControlPreset,
      playerControlLayoutJson:
          playerControlLayoutJson ?? this.playerControlLayoutJson,
      playerControlHandedness:
          playerControlHandedness ?? this.playerControlHandedness,
      playerDensity: playerDensity ?? this.playerDensity,
      playerGestureDoubleTap:
          playerGestureDoubleTap ?? this.playerGestureDoubleTap,
      playerGestureSwipeTrack:
          playerGestureSwipeTrack ?? this.playerGestureSwipeTrack,
      playerGestureSwipeVolume:
          playerGestureSwipeVolume ?? this.playerGestureSwipeVolume,
      playerGestureSwipeDismiss:
          playerGestureSwipeDismiss ?? this.playerGestureSwipeDismiss,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (scanOnStart.present) {
      map['scan_on_start'] = Variable<bool>(scanOnStart.value);
    }
    if (lastScanAt.present) {
      map['last_scan_at'] = Variable<DateTime>(lastScanAt.value);
    }
    if (useDynamicColor.present) {
      map['use_dynamic_color'] = Variable<bool>(useDynamicColor.value);
    }
    if (pureBlackBackground.present) {
      map['pure_black_background'] = Variable<bool>(pureBlackBackground.value);
    }
    if (accentId.present) {
      map['accent_id'] = Variable<String>(accentId.value);
    }
    if (backgroundDepth.present) {
      map['background_depth'] = Variable<String>(backgroundDepth.value);
    }
    if (glassIntensity.present) {
      map['glass_intensity'] = Variable<String>(glassIntensity.value);
    }
    if (restoreQueueOnStart.present) {
      map['restore_queue_on_start'] = Variable<bool>(restoreQueueOnStart.value);
    }
    if (gaplessEnabled.present) {
      map['gapless_enabled'] = Variable<bool>(gaplessEnabled.value);
    }
    if (crossfadeSeconds.present) {
      map['crossfade_seconds'] = Variable<int>(crossfadeSeconds.value);
    }
    if (fadeOnPause.present) {
      map['fade_on_pause'] = Variable<bool>(fadeOnPause.value);
    }
    if (fadeOnPauseMs.present) {
      map['fade_on_pause_ms'] = Variable<int>(fadeOnPauseMs.value);
    }
    if (directMode.present) {
      map['direct_mode'] = Variable<bool>(directMode.value);
    }
    if (allowOffload.present) {
      map['allow_offload'] = Variable<bool>(allowOffload.value);
    }
    if (playbackSpeed.present) {
      map['playback_speed'] = Variable<double>(playbackSpeed.value);
    }
    if (playbackPitch.present) {
      map['playback_pitch'] = Variable<double>(playbackPitch.value);
    }
    if (embedCoverInFile.present) {
      map['embed_cover_in_file'] = Variable<bool>(embedCoverInFile.value);
    }
    if (widgetEnabled.present) {
      map['widget_enabled'] = Variable<bool>(widgetEnabled.value);
    }
    if (widgetStyle.present) {
      map['widget_style'] = Variable<int>(widgetStyle.value);
    }
    if (widgetTheme.present) {
      map['widget_theme'] = Variable<int>(widgetTheme.value);
    }
    if (widgetSize.present) {
      map['widget_size'] = Variable<int>(widgetSize.value);
    }
    if (widgetAccentColor.present) {
      map['widget_accent_color'] = Variable<int>(widgetAccentColor.value);
    }
    if (widgetOpacity.present) {
      map['widget_opacity'] = Variable<double>(widgetOpacity.value);
    }
    if (widgetShowCover.present) {
      map['widget_show_cover'] = Variable<bool>(widgetShowCover.value);
    }
    if (widgetShowTitle.present) {
      map['widget_show_title'] = Variable<bool>(widgetShowTitle.value);
    }
    if (widgetShowArtist.present) {
      map['widget_show_artist'] = Variable<bool>(widgetShowArtist.value);
    }
    if (widgetShowControls.present) {
      map['widget_show_controls'] = Variable<bool>(widgetShowControls.value);
    }
    if (widgetShowProgress.present) {
      map['widget_show_progress'] = Variable<bool>(widgetShowProgress.value);
    }
    if (widgetShowDuration.present) {
      map['widget_show_duration'] = Variable<bool>(widgetShowDuration.value);
    }
    if (widgetShowNextInQueue.present) {
      map['widget_show_next_in_queue'] = Variable<bool>(
        widgetShowNextInQueue.value,
      );
    }
    if (widgetOpenOnTap.present) {
      map['widget_open_on_tap'] = Variable<bool>(widgetOpenOnTap.value);
    }
    if (widgetPauseOnDisconnect.present) {
      map['widget_pause_on_disconnect'] = Variable<bool>(
        widgetPauseOnDisconnect.value,
      );
    }
    if (widgetResumeOnConnect.present) {
      map['widget_resume_on_connect'] = Variable<bool>(
        widgetResumeOnConnect.value,
      );
    }
    if (sleepTimerMinutes.present) {
      map['sleep_timer_minutes'] = Variable<int>(sleepTimerMinutes.value);
    }
    if (sleepTimerFinishTrack.present) {
      map['sleep_timer_finish_track'] = Variable<bool>(
        sleepTimerFinishTrack.value,
      );
    }
    if (homeSectionsJson.present) {
      map['home_sections_json'] = Variable<String>(homeSectionsJson.value);
    }
    if (librarySortJson.present) {
      map['library_sort_json'] = Variable<String>(librarySortJson.value);
    }
    if (videoBackgroundEnabled.present) {
      map['video_background_enabled'] = Variable<bool>(
        videoBackgroundEnabled.value,
      );
    }
    if (playerVisualizerStyle.present) {
      map['player_visualizer_style'] = Variable<int>(
        playerVisualizerStyle.value,
      );
    }
    if (playerVisualScene.present) {
      map['player_visual_scene'] = Variable<int>(playerVisualScene.value);
    }
    if (playerSceneAspectRatio.present) {
      map['player_scene_aspect_ratio'] = Variable<int>(
        playerSceneAspectRatio.value,
      );
    }
    if (playerControlPreset.present) {
      map['player_control_preset'] = Variable<String>(
        playerControlPreset.value,
      );
    }
    if (playerControlLayoutJson.present) {
      map['player_control_layout_json'] = Variable<String>(
        playerControlLayoutJson.value,
      );
    }
    if (playerControlHandedness.present) {
      map['player_control_handedness'] = Variable<String>(
        playerControlHandedness.value,
      );
    }
    if (playerDensity.present) {
      map['player_density'] = Variable<String>(playerDensity.value);
    }
    if (playerGestureDoubleTap.present) {
      map['player_gesture_double_tap'] = Variable<bool>(
        playerGestureDoubleTap.value,
      );
    }
    if (playerGestureSwipeTrack.present) {
      map['player_gesture_swipe_track'] = Variable<bool>(
        playerGestureSwipeTrack.value,
      );
    }
    if (playerGestureSwipeVolume.present) {
      map['player_gesture_swipe_volume'] = Variable<bool>(
        playerGestureSwipeVolume.value,
      );
    }
    if (playerGestureSwipeDismiss.present) {
      map['player_gesture_swipe_dismiss'] = Variable<bool>(
        playerGestureSwipeDismiss.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('scanOnStart: $scanOnStart, ')
          ..write('lastScanAt: $lastScanAt, ')
          ..write('useDynamicColor: $useDynamicColor, ')
          ..write('pureBlackBackground: $pureBlackBackground, ')
          ..write('accentId: $accentId, ')
          ..write('backgroundDepth: $backgroundDepth, ')
          ..write('glassIntensity: $glassIntensity, ')
          ..write('restoreQueueOnStart: $restoreQueueOnStart, ')
          ..write('gaplessEnabled: $gaplessEnabled, ')
          ..write('crossfadeSeconds: $crossfadeSeconds, ')
          ..write('fadeOnPause: $fadeOnPause, ')
          ..write('fadeOnPauseMs: $fadeOnPauseMs, ')
          ..write('directMode: $directMode, ')
          ..write('allowOffload: $allowOffload, ')
          ..write('playbackSpeed: $playbackSpeed, ')
          ..write('playbackPitch: $playbackPitch, ')
          ..write('embedCoverInFile: $embedCoverInFile, ')
          ..write('widgetEnabled: $widgetEnabled, ')
          ..write('widgetStyle: $widgetStyle, ')
          ..write('widgetTheme: $widgetTheme, ')
          ..write('widgetSize: $widgetSize, ')
          ..write('widgetAccentColor: $widgetAccentColor, ')
          ..write('widgetOpacity: $widgetOpacity, ')
          ..write('widgetShowCover: $widgetShowCover, ')
          ..write('widgetShowTitle: $widgetShowTitle, ')
          ..write('widgetShowArtist: $widgetShowArtist, ')
          ..write('widgetShowControls: $widgetShowControls, ')
          ..write('widgetShowProgress: $widgetShowProgress, ')
          ..write('widgetShowDuration: $widgetShowDuration, ')
          ..write('widgetShowNextInQueue: $widgetShowNextInQueue, ')
          ..write('widgetOpenOnTap: $widgetOpenOnTap, ')
          ..write('widgetPauseOnDisconnect: $widgetPauseOnDisconnect, ')
          ..write('widgetResumeOnConnect: $widgetResumeOnConnect, ')
          ..write('sleepTimerMinutes: $sleepTimerMinutes, ')
          ..write('sleepTimerFinishTrack: $sleepTimerFinishTrack, ')
          ..write('homeSectionsJson: $homeSectionsJson, ')
          ..write('librarySortJson: $librarySortJson, ')
          ..write('videoBackgroundEnabled: $videoBackgroundEnabled, ')
          ..write('playerVisualizerStyle: $playerVisualizerStyle, ')
          ..write('playerVisualScene: $playerVisualScene, ')
          ..write('playerSceneAspectRatio: $playerSceneAspectRatio, ')
          ..write('playerControlPreset: $playerControlPreset, ')
          ..write('playerControlLayoutJson: $playerControlLayoutJson, ')
          ..write('playerControlHandedness: $playerControlHandedness, ')
          ..write('playerDensity: $playerDensity, ')
          ..write('playerGestureDoubleTap: $playerGestureDoubleTap, ')
          ..write('playerGestureSwipeTrack: $playerGestureSwipeTrack, ')
          ..write('playerGestureSwipeVolume: $playerGestureSwipeVolume, ')
          ..write('playerGestureSwipeDismiss: $playerGestureSwipeDismiss')
          ..write(')'))
        .toString();
  }
}

class $SongVideoIdsTable extends SongVideoIds
    with TableInfo<$SongVideoIdsTable, SongVideoId> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SongVideoIdsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _songKeyMeta = const VerificationMeta(
    'songKey',
  );
  @override
  late final GeneratedColumn<String> songKey = GeneratedColumn<String>(
    'song_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _videoIdMeta = const VerificationMeta(
    'videoId',
  );
  @override
  late final GeneratedColumn<String> videoId = GeneratedColumn<String>(
    'video_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('piped'),
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [songKey, videoId, source, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'song_video_ids';
  @override
  VerificationContext validateIntegrity(
    Insertable<SongVideoId> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('song_key')) {
      context.handle(
        _songKeyMeta,
        songKey.isAcceptableOrUnknown(data['song_key']!, _songKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_songKeyMeta);
    }
    if (data.containsKey('video_id')) {
      context.handle(
        _videoIdMeta,
        videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_videoIdMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {songKey};
  @override
  SongVideoId map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SongVideoId(
      songKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}song_key'],
      )!,
      videoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_id'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $SongVideoIdsTable createAlias(String alias) {
    return $SongVideoIdsTable(attachedDatabase, alias);
  }
}

class SongVideoId extends DataClass implements Insertable<SongVideoId> {
  final String songKey;
  final String videoId;

  /// Origen ("piped", "manual", "youtube_api"), por si algun dia hay mas de
  /// una fuente y hay que priorizar.
  final String source;
  final DateTime fetchedAt;
  const SongVideoId({
    required this.songKey,
    required this.videoId,
    required this.source,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['song_key'] = Variable<String>(songKey);
    map['video_id'] = Variable<String>(videoId);
    map['source'] = Variable<String>(source);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  SongVideoIdsCompanion toCompanion(bool nullToAbsent) {
    return SongVideoIdsCompanion(
      songKey: Value(songKey),
      videoId: Value(videoId),
      source: Value(source),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory SongVideoId.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SongVideoId(
      songKey: serializer.fromJson<String>(json['songKey']),
      videoId: serializer.fromJson<String>(json['videoId']),
      source: serializer.fromJson<String>(json['source']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'songKey': serializer.toJson<String>(songKey),
      'videoId': serializer.toJson<String>(videoId),
      'source': serializer.toJson<String>(source),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  SongVideoId copyWith({
    String? songKey,
    String? videoId,
    String? source,
    DateTime? fetchedAt,
  }) => SongVideoId(
    songKey: songKey ?? this.songKey,
    videoId: videoId ?? this.videoId,
    source: source ?? this.source,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  SongVideoId copyWithCompanion(SongVideoIdsCompanion data) {
    return SongVideoId(
      songKey: data.songKey.present ? data.songKey.value : this.songKey,
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      source: data.source.present ? data.source.value : this.source,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SongVideoId(')
          ..write('songKey: $songKey, ')
          ..write('videoId: $videoId, ')
          ..write('source: $source, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(songKey, videoId, source, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SongVideoId &&
          other.songKey == this.songKey &&
          other.videoId == this.videoId &&
          other.source == this.source &&
          other.fetchedAt == this.fetchedAt);
}

class SongVideoIdsCompanion extends UpdateCompanion<SongVideoId> {
  final Value<String> songKey;
  final Value<String> videoId;
  final Value<String> source;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const SongVideoIdsCompanion({
    this.songKey = const Value.absent(),
    this.videoId = const Value.absent(),
    this.source = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SongVideoIdsCompanion.insert({
    required String songKey,
    required String videoId,
    this.source = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : songKey = Value(songKey),
       videoId = Value(videoId);
  static Insertable<SongVideoId> custom({
    Expression<String>? songKey,
    Expression<String>? videoId,
    Expression<String>? source,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (songKey != null) 'song_key': songKey,
      if (videoId != null) 'video_id': videoId,
      if (source != null) 'source': source,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SongVideoIdsCompanion copyWith({
    Value<String>? songKey,
    Value<String>? videoId,
    Value<String>? source,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return SongVideoIdsCompanion(
      songKey: songKey ?? this.songKey,
      videoId: videoId ?? this.videoId,
      source: source ?? this.source,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (songKey.present) {
      map['song_key'] = Variable<String>(songKey.value);
    }
    if (videoId.present) {
      map['video_id'] = Variable<String>(videoId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SongVideoIdsCompanion(')
          ..write('songKey: $songKey, ')
          ..write('videoId: $videoId, ')
          ..write('source: $source, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$NuvTuneDatabase extends GeneratedDatabase {
  _$NuvTuneDatabase(QueryExecutor e) : super(e);
  $NuvTuneDatabaseManager get managers => $NuvTuneDatabaseManager(this);
  late final $FavoritesTable favorites = $FavoritesTable(this);
  late final $PlaylistsTable playlists = $PlaylistsTable(this);
  late final $PlaylistEntriesTable playlistEntries = $PlaylistEntriesTable(
    this,
  );
  late final $PlayHistoryTable playHistory = $PlayHistoryTable(this);
  late final $PlayCountsTable playCounts = $PlayCountsTable(this);
  late final $QueueEntriesTable queueEntries = $QueueEntriesTable(this);
  late final $QueueStateTable queueState = $QueueStateTable(this);
  late final $ExcludedFoldersTable excludedFolders = $ExcludedFoldersTable(
    this,
  );
  late final $SourceFoldersTable sourceFolders = $SourceFoldersTable(this);
  late final $CustomCoversTable customCovers = $CustomCoversTable(this);
  late final $EqualizerPresetsTableTable equalizerPresetsTable =
      $EqualizerPresetsTableTable(this);
  late final $EqualizerStateTable equalizerState = $EqualizerStateTable(this);
  late final $EnhancementStateTable enhancementState = $EnhancementStateTable(
    this,
  );
  late final $OutputProfilesTable outputProfiles = $OutputProfilesTable(this);
  late final $LoudnessAnalysesTable loudnessAnalyses = $LoudnessAnalysesTable(
    this,
  );
  late final $SavedRadiosTable savedRadios = $SavedRadiosTable(this);
  late final $LyricsOverridesTable lyricsOverrides = $LyricsOverridesTable(
    this,
  );
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $SongVideoIdsTable songVideoIds = $SongVideoIdsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    favorites,
    playlists,
    playlistEntries,
    playHistory,
    playCounts,
    queueEntries,
    queueState,
    excludedFolders,
    sourceFolders,
    customCovers,
    equalizerPresetsTable,
    equalizerState,
    enhancementState,
    outputProfiles,
    loudnessAnalyses,
    savedRadios,
    lyricsOverrides,
    appSettings,
    songVideoIds,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'playlists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('playlist_entries', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$FavoritesTableCreateCompanionBuilder =
    FavoritesCompanion Function({Value<int> songId, Value<DateTime> addedAt});
typedef $$FavoritesTableUpdateCompanionBuilder =
    FavoritesCompanion Function({Value<int> songId, Value<DateTime> addedAt});

class $$FavoritesTableFilterComposer
    extends Composer<_$NuvTuneDatabase, $FavoritesTable> {
  $$FavoritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get songId => $composableBuilder(
    column: $table.songId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FavoritesTableOrderingComposer
    extends Composer<_$NuvTuneDatabase, $FavoritesTable> {
  $$FavoritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get songId => $composableBuilder(
    column: $table.songId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FavoritesTableAnnotationComposer
    extends Composer<_$NuvTuneDatabase, $FavoritesTable> {
  $$FavoritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get songId =>
      $composableBuilder(column: $table.songId, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);
}

class $$FavoritesTableTableManager
    extends
        RootTableManager<
          _$NuvTuneDatabase,
          $FavoritesTable,
          Favorite,
          $$FavoritesTableFilterComposer,
          $$FavoritesTableOrderingComposer,
          $$FavoritesTableAnnotationComposer,
          $$FavoritesTableCreateCompanionBuilder,
          $$FavoritesTableUpdateCompanionBuilder,
          (
            Favorite,
            BaseReferences<_$NuvTuneDatabase, $FavoritesTable, Favorite>,
          ),
          Favorite,
          PrefetchHooks Function()
        > {
  $$FavoritesTableTableManager(_$NuvTuneDatabase db, $FavoritesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> songId = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
              }) => FavoritesCompanion(songId: songId, addedAt: addedAt),
          createCompanionCallback:
              ({
                Value<int> songId = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
              }) => FavoritesCompanion.insert(songId: songId, addedAt: addedAt),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FavoritesTableProcessedTableManager =
    ProcessedTableManager<
      _$NuvTuneDatabase,
      $FavoritesTable,
      Favorite,
      $$FavoritesTableFilterComposer,
      $$FavoritesTableOrderingComposer,
      $$FavoritesTableAnnotationComposer,
      $$FavoritesTableCreateCompanionBuilder,
      $$FavoritesTableUpdateCompanionBuilder,
      (Favorite, BaseReferences<_$NuvTuneDatabase, $FavoritesTable, Favorite>),
      Favorite,
      PrefetchHooks Function()
    >;
typedef $$PlaylistsTableCreateCompanionBuilder =
    PlaylistsCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> coverPath,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> giftMode,
      Value<String?> dedication,
      Value<String?> giftFrom,
      Value<String?> giftTo,
      Value<String?> giftAccentId,
      Value<String?> giftId,
    });
typedef $$PlaylistsTableUpdateCompanionBuilder =
    PlaylistsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> coverPath,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> giftMode,
      Value<String?> dedication,
      Value<String?> giftFrom,
      Value<String?> giftTo,
      Value<String?> giftAccentId,
      Value<String?> giftId,
    });

final class $$PlaylistsTableReferences
    extends BaseReferences<_$NuvTuneDatabase, $PlaylistsTable, Playlist> {
  $$PlaylistsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PlaylistEntriesTable, List<PlaylistEntry>>
  _playlistEntriesRefsTable(_$NuvTuneDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.playlistEntries,
        aliasName: 'playlists__id__playlist_entries__playlist_id',
      );

  $$PlaylistEntriesTableProcessedTableManager get playlistEntriesRefs {
    final manager = $$PlaylistEntriesTableTableManager(
      $_db,
      $_db.playlistEntries,
    ).filter((f) => f.playlistId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _playlistEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlaylistsTableFilterComposer
    extends Composer<_$NuvTuneDatabase, $PlaylistsTable> {
  $$PlaylistsTableFilterComposer({
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

  ColumnFilters<String> get coverPath => $composableBuilder(
    column: $table.coverPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get giftMode => $composableBuilder(
    column: $table.giftMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dedication => $composableBuilder(
    column: $table.dedication,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get giftFrom => $composableBuilder(
    column: $table.giftFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get giftTo => $composableBuilder(
    column: $table.giftTo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get giftAccentId => $composableBuilder(
    column: $table.giftAccentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get giftId => $composableBuilder(
    column: $table.giftId,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> playlistEntriesRefs(
    Expression<bool> Function($$PlaylistEntriesTableFilterComposer f) f,
  ) {
    final $$PlaylistEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistEntries,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistEntriesTableFilterComposer(
            $db: $db,
            $table: $db.playlistEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlaylistsTableOrderingComposer
    extends Composer<_$NuvTuneDatabase, $PlaylistsTable> {
  $$PlaylistsTableOrderingComposer({
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

  ColumnOrderings<String> get coverPath => $composableBuilder(
    column: $table.coverPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get giftMode => $composableBuilder(
    column: $table.giftMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dedication => $composableBuilder(
    column: $table.dedication,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get giftFrom => $composableBuilder(
    column: $table.giftFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get giftTo => $composableBuilder(
    column: $table.giftTo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get giftAccentId => $composableBuilder(
    column: $table.giftAccentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get giftId => $composableBuilder(
    column: $table.giftId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlaylistsTableAnnotationComposer
    extends Composer<_$NuvTuneDatabase, $PlaylistsTable> {
  $$PlaylistsTableAnnotationComposer({
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

  GeneratedColumn<String> get coverPath =>
      $composableBuilder(column: $table.coverPath, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get giftMode =>
      $composableBuilder(column: $table.giftMode, builder: (column) => column);

  GeneratedColumn<String> get dedication => $composableBuilder(
    column: $table.dedication,
    builder: (column) => column,
  );

  GeneratedColumn<String> get giftFrom =>
      $composableBuilder(column: $table.giftFrom, builder: (column) => column);

  GeneratedColumn<String> get giftTo =>
      $composableBuilder(column: $table.giftTo, builder: (column) => column);

  GeneratedColumn<String> get giftAccentId => $composableBuilder(
    column: $table.giftAccentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get giftId =>
      $composableBuilder(column: $table.giftId, builder: (column) => column);

  Expression<T> playlistEntriesRefs<T extends Object>(
    Expression<T> Function($$PlaylistEntriesTableAnnotationComposer a) f,
  ) {
    final $$PlaylistEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistEntries,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.playlistEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlaylistsTableTableManager
    extends
        RootTableManager<
          _$NuvTuneDatabase,
          $PlaylistsTable,
          Playlist,
          $$PlaylistsTableFilterComposer,
          $$PlaylistsTableOrderingComposer,
          $$PlaylistsTableAnnotationComposer,
          $$PlaylistsTableCreateCompanionBuilder,
          $$PlaylistsTableUpdateCompanionBuilder,
          (Playlist, $$PlaylistsTableReferences),
          Playlist,
          PrefetchHooks Function({bool playlistEntriesRefs})
        > {
  $$PlaylistsTableTableManager(_$NuvTuneDatabase db, $PlaylistsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> coverPath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> giftMode = const Value.absent(),
                Value<String?> dedication = const Value.absent(),
                Value<String?> giftFrom = const Value.absent(),
                Value<String?> giftTo = const Value.absent(),
                Value<String?> giftAccentId = const Value.absent(),
                Value<String?> giftId = const Value.absent(),
              }) => PlaylistsCompanion(
                id: id,
                name: name,
                coverPath: coverPath,
                createdAt: createdAt,
                updatedAt: updatedAt,
                giftMode: giftMode,
                dedication: dedication,
                giftFrom: giftFrom,
                giftTo: giftTo,
                giftAccentId: giftAccentId,
                giftId: giftId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> coverPath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> giftMode = const Value.absent(),
                Value<String?> dedication = const Value.absent(),
                Value<String?> giftFrom = const Value.absent(),
                Value<String?> giftTo = const Value.absent(),
                Value<String?> giftAccentId = const Value.absent(),
                Value<String?> giftId = const Value.absent(),
              }) => PlaylistsCompanion.insert(
                id: id,
                name: name,
                coverPath: coverPath,
                createdAt: createdAt,
                updatedAt: updatedAt,
                giftMode: giftMode,
                dedication: dedication,
                giftFrom: giftFrom,
                giftTo: giftTo,
                giftAccentId: giftAccentId,
                giftId: giftId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlaylistsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playlistEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (playlistEntriesRefs) db.playlistEntries,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (playlistEntriesRefs)
                    await $_getPrefetchedData<
                      Playlist,
                      $PlaylistsTable,
                      PlaylistEntry
                    >(
                      currentTable: table,
                      referencedTable: $$PlaylistsTableReferences
                          ._playlistEntriesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$PlaylistsTableReferences(
                            db,
                            table,
                            p0,
                          ).playlistEntriesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.playlistId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PlaylistsTableProcessedTableManager =
    ProcessedTableManager<
      _$NuvTuneDatabase,
      $PlaylistsTable,
      Playlist,
      $$PlaylistsTableFilterComposer,
      $$PlaylistsTableOrderingComposer,
      $$PlaylistsTableAnnotationComposer,
      $$PlaylistsTableCreateCompanionBuilder,
      $$PlaylistsTableUpdateCompanionBuilder,
      (Playlist, $$PlaylistsTableReferences),
      Playlist,
      PrefetchHooks Function({bool playlistEntriesRefs})
    >;
typedef $$PlaylistEntriesTableCreateCompanionBuilder =
    PlaylistEntriesCompanion Function({
      required int playlistId,
      required int songId,
      required int position,
      Value<int> rowid,
    });
typedef $$PlaylistEntriesTableUpdateCompanionBuilder =
    PlaylistEntriesCompanion Function({
      Value<int> playlistId,
      Value<int> songId,
      Value<int> position,
      Value<int> rowid,
    });

final class $$PlaylistEntriesTableReferences
    extends
        BaseReferences<
          _$NuvTuneDatabase,
          $PlaylistEntriesTable,
          PlaylistEntry
        > {
  $$PlaylistEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlaylistsTable _playlistIdTable(_$NuvTuneDatabase db) =>
      db.playlists.createAlias('playlist_entries__playlist_id__playlists__id');

  $$PlaylistsTableProcessedTableManager get playlistId {
    final $_column = $_itemColumn<int>('playlist_id')!;

    final manager = $$PlaylistsTableTableManager(
      $_db,
      $_db.playlists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlaylistEntriesTableFilterComposer
    extends Composer<_$NuvTuneDatabase, $PlaylistEntriesTable> {
  $$PlaylistEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get songId => $composableBuilder(
    column: $table.songId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$PlaylistsTableFilterComposer get playlistId {
    final $$PlaylistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableFilterComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistEntriesTableOrderingComposer
    extends Composer<_$NuvTuneDatabase, $PlaylistEntriesTable> {
  $$PlaylistEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get songId => $composableBuilder(
    column: $table.songId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlaylistsTableOrderingComposer get playlistId {
    final $$PlaylistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableOrderingComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistEntriesTableAnnotationComposer
    extends Composer<_$NuvTuneDatabase, $PlaylistEntriesTable> {
  $$PlaylistEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get songId =>
      $composableBuilder(column: $table.songId, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$PlaylistsTableAnnotationComposer get playlistId {
    final $$PlaylistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableAnnotationComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistEntriesTableTableManager
    extends
        RootTableManager<
          _$NuvTuneDatabase,
          $PlaylistEntriesTable,
          PlaylistEntry,
          $$PlaylistEntriesTableFilterComposer,
          $$PlaylistEntriesTableOrderingComposer,
          $$PlaylistEntriesTableAnnotationComposer,
          $$PlaylistEntriesTableCreateCompanionBuilder,
          $$PlaylistEntriesTableUpdateCompanionBuilder,
          (PlaylistEntry, $$PlaylistEntriesTableReferences),
          PlaylistEntry,
          PrefetchHooks Function({bool playlistId})
        > {
  $$PlaylistEntriesTableTableManager(
    _$NuvTuneDatabase db,
    $PlaylistEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> playlistId = const Value.absent(),
                Value<int> songId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaylistEntriesCompanion(
                playlistId: playlistId,
                songId: songId,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int playlistId,
                required int songId,
                required int position,
                Value<int> rowid = const Value.absent(),
              }) => PlaylistEntriesCompanion.insert(
                playlistId: playlistId,
                songId: songId,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlaylistEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playlistId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (playlistId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.playlistId,
                                referencedTable:
                                    $$PlaylistEntriesTableReferences
                                        ._playlistIdTable(db),
                                referencedColumn:
                                    $$PlaylistEntriesTableReferences
                                        ._playlistIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PlaylistEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$NuvTuneDatabase,
      $PlaylistEntriesTable,
      PlaylistEntry,
      $$PlaylistEntriesTableFilterComposer,
      $$PlaylistEntriesTableOrderingComposer,
      $$PlaylistEntriesTableAnnotationComposer,
      $$PlaylistEntriesTableCreateCompanionBuilder,
      $$PlaylistEntriesTableUpdateCompanionBuilder,
      (PlaylistEntry, $$PlaylistEntriesTableReferences),
      PlaylistEntry,
      PrefetchHooks Function({bool playlistId})
    >;
typedef $$PlayHistoryTableCreateCompanionBuilder =
    PlayHistoryCompanion Function({
      Value<int> id,
      required int songId,
      Value<DateTime> playedAt,
    });
typedef $$PlayHistoryTableUpdateCompanionBuilder =
    PlayHistoryCompanion Function({
      Value<int> id,
      Value<int> songId,
      Value<DateTime> playedAt,
    });

class $$PlayHistoryTableFilterComposer
    extends Composer<_$NuvTuneDatabase, $PlayHistoryTable> {
  $$PlayHistoryTableFilterComposer({
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

  ColumnFilters<int> get songId => $composableBuilder(
    column: $table.songId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get playedAt => $composableBuilder(
    column: $table.playedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlayHistoryTableOrderingComposer
    extends Composer<_$NuvTuneDatabase, $PlayHistoryTable> {
  $$PlayHistoryTableOrderingComposer({
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

  ColumnOrderings<int> get songId => $composableBuilder(
    column: $table.songId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get playedAt => $composableBuilder(
    column: $table.playedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlayHistoryTableAnnotationComposer
    extends Composer<_$NuvTuneDatabase, $PlayHistoryTable> {
  $$PlayHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get songId =>
      $composableBuilder(column: $table.songId, builder: (column) => column);

  GeneratedColumn<DateTime> get playedAt =>
      $composableBuilder(column: $table.playedAt, builder: (column) => column);
}

class $$PlayHistoryTableTableManager
    extends
        RootTableManager<
          _$NuvTuneDatabase,
          $PlayHistoryTable,
          PlayHistoryData,
          $$PlayHistoryTableFilterComposer,
          $$PlayHistoryTableOrderingComposer,
          $$PlayHistoryTableAnnotationComposer,
          $$PlayHistoryTableCreateCompanionBuilder,
          $$PlayHistoryTableUpdateCompanionBuilder,
          (
            PlayHistoryData,
            BaseReferences<
              _$NuvTuneDatabase,
              $PlayHistoryTable,
              PlayHistoryData
            >,
          ),
          PlayHistoryData,
          PrefetchHooks Function()
        > {
  $$PlayHistoryTableTableManager(_$NuvTuneDatabase db, $PlayHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlayHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> songId = const Value.absent(),
                Value<DateTime> playedAt = const Value.absent(),
              }) => PlayHistoryCompanion(
                id: id,
                songId: songId,
                playedAt: playedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int songId,
                Value<DateTime> playedAt = const Value.absent(),
              }) => PlayHistoryCompanion.insert(
                id: id,
                songId: songId,
                playedAt: playedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlayHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$NuvTuneDatabase,
      $PlayHistoryTable,
      PlayHistoryData,
      $$PlayHistoryTableFilterComposer,
      $$PlayHistoryTableOrderingComposer,
      $$PlayHistoryTableAnnotationComposer,
      $$PlayHistoryTableCreateCompanionBuilder,
      $$PlayHistoryTableUpdateCompanionBuilder,
      (
        PlayHistoryData,
        BaseReferences<_$NuvTuneDatabase, $PlayHistoryTable, PlayHistoryData>,
      ),
      PlayHistoryData,
      PrefetchHooks Function()
    >;
typedef $$PlayCountsTableCreateCompanionBuilder =
    PlayCountsCompanion Function({
      Value<int> songId,
      Value<int> count,
      Value<DateTime?> lastPlayedAt,
    });
typedef $$PlayCountsTableUpdateCompanionBuilder =
    PlayCountsCompanion Function({
      Value<int> songId,
      Value<int> count,
      Value<DateTime?> lastPlayedAt,
    });

class $$PlayCountsTableFilterComposer
    extends Composer<_$NuvTuneDatabase, $PlayCountsTable> {
  $$PlayCountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get songId => $composableBuilder(
    column: $table.songId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlayCountsTableOrderingComposer
    extends Composer<_$NuvTuneDatabase, $PlayCountsTable> {
  $$PlayCountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get songId => $composableBuilder(
    column: $table.songId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlayCountsTableAnnotationComposer
    extends Composer<_$NuvTuneDatabase, $PlayCountsTable> {
  $$PlayCountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get songId =>
      $composableBuilder(column: $table.songId, builder: (column) => column);

  GeneratedColumn<int> get count =>
      $composableBuilder(column: $table.count, builder: (column) => column);

  GeneratedColumn<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => column,
  );
}

class $$PlayCountsTableTableManager
    extends
        RootTableManager<
          _$NuvTuneDatabase,
          $PlayCountsTable,
          PlayCount,
          $$PlayCountsTableFilterComposer,
          $$PlayCountsTableOrderingComposer,
          $$PlayCountsTableAnnotationComposer,
          $$PlayCountsTableCreateCompanionBuilder,
          $$PlayCountsTableUpdateCompanionBuilder,
          (
            PlayCount,
            BaseReferences<_$NuvTuneDatabase, $PlayCountsTable, PlayCount>,
          ),
          PlayCount,
          PrefetchHooks Function()
        > {
  $$PlayCountsTableTableManager(_$NuvTuneDatabase db, $PlayCountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayCountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayCountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlayCountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> songId = const Value.absent(),
                Value<int> count = const Value.absent(),
                Value<DateTime?> lastPlayedAt = const Value.absent(),
              }) => PlayCountsCompanion(
                songId: songId,
                count: count,
                lastPlayedAt: lastPlayedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> songId = const Value.absent(),
                Value<int> count = const Value.absent(),
                Value<DateTime?> lastPlayedAt = const Value.absent(),
              }) => PlayCountsCompanion.insert(
                songId: songId,
                count: count,
                lastPlayedAt: lastPlayedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlayCountsTableProcessedTableManager =
    ProcessedTableManager<
      _$NuvTuneDatabase,
      $PlayCountsTable,
      PlayCount,
      $$PlayCountsTableFilterComposer,
      $$PlayCountsTableOrderingComposer,
      $$PlayCountsTableAnnotationComposer,
      $$PlayCountsTableCreateCompanionBuilder,
      $$PlayCountsTableUpdateCompanionBuilder,
      (
        PlayCount,
        BaseReferences<_$NuvTuneDatabase, $PlayCountsTable, PlayCount>,
      ),
      PlayCount,
      PrefetchHooks Function()
    >;
typedef $$QueueEntriesTableCreateCompanionBuilder =
    QueueEntriesCompanion Function({Value<int> position, required int songId});
typedef $$QueueEntriesTableUpdateCompanionBuilder =
    QueueEntriesCompanion Function({Value<int> position, Value<int> songId});

class $$QueueEntriesTableFilterComposer
    extends Composer<_$NuvTuneDatabase, $QueueEntriesTable> {
  $$QueueEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get songId => $composableBuilder(
    column: $table.songId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QueueEntriesTableOrderingComposer
    extends Composer<_$NuvTuneDatabase, $QueueEntriesTable> {
  $$QueueEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get songId => $composableBuilder(
    column: $table.songId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QueueEntriesTableAnnotationComposer
    extends Composer<_$NuvTuneDatabase, $QueueEntriesTable> {
  $$QueueEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get songId =>
      $composableBuilder(column: $table.songId, builder: (column) => column);
}

class $$QueueEntriesTableTableManager
    extends
        RootTableManager<
          _$NuvTuneDatabase,
          $QueueEntriesTable,
          QueueEntry,
          $$QueueEntriesTableFilterComposer,
          $$QueueEntriesTableOrderingComposer,
          $$QueueEntriesTableAnnotationComposer,
          $$QueueEntriesTableCreateCompanionBuilder,
          $$QueueEntriesTableUpdateCompanionBuilder,
          (
            QueueEntry,
            BaseReferences<_$NuvTuneDatabase, $QueueEntriesTable, QueueEntry>,
          ),
          QueueEntry,
          PrefetchHooks Function()
        > {
  $$QueueEntriesTableTableManager(
    _$NuvTuneDatabase db,
    $QueueEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QueueEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QueueEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QueueEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> position = const Value.absent(),
                Value<int> songId = const Value.absent(),
              }) => QueueEntriesCompanion(position: position, songId: songId),
          createCompanionCallback:
              ({
                Value<int> position = const Value.absent(),
                required int songId,
              }) => QueueEntriesCompanion.insert(
                position: position,
                songId: songId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QueueEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$NuvTuneDatabase,
      $QueueEntriesTable,
      QueueEntry,
      $$QueueEntriesTableFilterComposer,
      $$QueueEntriesTableOrderingComposer,
      $$QueueEntriesTableAnnotationComposer,
      $$QueueEntriesTableCreateCompanionBuilder,
      $$QueueEntriesTableUpdateCompanionBuilder,
      (
        QueueEntry,
        BaseReferences<_$NuvTuneDatabase, $QueueEntriesTable, QueueEntry>,
      ),
      QueueEntry,
      PrefetchHooks Function()
    >;
typedef $$QueueStateTableCreateCompanionBuilder =
    QueueStateCompanion Function({
      Value<int> id,
      Value<int> currentIndex,
      Value<int> positionMs,
      Value<int> repeatMode,
      Value<bool> shuffleEnabled,
    });
typedef $$QueueStateTableUpdateCompanionBuilder =
    QueueStateCompanion Function({
      Value<int> id,
      Value<int> currentIndex,
      Value<int> positionMs,
      Value<int> repeatMode,
      Value<bool> shuffleEnabled,
    });

class $$QueueStateTableFilterComposer
    extends Composer<_$NuvTuneDatabase, $QueueStateTable> {
  $$QueueStateTableFilterComposer({
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

  ColumnFilters<int> get currentIndex => $composableBuilder(
    column: $table.currentIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repeatMode => $composableBuilder(
    column: $table.repeatMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get shuffleEnabled => $composableBuilder(
    column: $table.shuffleEnabled,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QueueStateTableOrderingComposer
    extends Composer<_$NuvTuneDatabase, $QueueStateTable> {
  $$QueueStateTableOrderingComposer({
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

  ColumnOrderings<int> get currentIndex => $composableBuilder(
    column: $table.currentIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repeatMode => $composableBuilder(
    column: $table.repeatMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get shuffleEnabled => $composableBuilder(
    column: $table.shuffleEnabled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QueueStateTableAnnotationComposer
    extends Composer<_$NuvTuneDatabase, $QueueStateTable> {
  $$QueueStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get currentIndex => $composableBuilder(
    column: $table.currentIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get repeatMode => $composableBuilder(
    column: $table.repeatMode,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get shuffleEnabled => $composableBuilder(
    column: $table.shuffleEnabled,
    builder: (column) => column,
  );
}

class $$QueueStateTableTableManager
    extends
        RootTableManager<
          _$NuvTuneDatabase,
          $QueueStateTable,
          QueueStateData,
          $$QueueStateTableFilterComposer,
          $$QueueStateTableOrderingComposer,
          $$QueueStateTableAnnotationComposer,
          $$QueueStateTableCreateCompanionBuilder,
          $$QueueStateTableUpdateCompanionBuilder,
          (
            QueueStateData,
            BaseReferences<_$NuvTuneDatabase, $QueueStateTable, QueueStateData>,
          ),
          QueueStateData,
          PrefetchHooks Function()
        > {
  $$QueueStateTableTableManager(_$NuvTuneDatabase db, $QueueStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QueueStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QueueStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QueueStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> currentIndex = const Value.absent(),
                Value<int> positionMs = const Value.absent(),
                Value<int> repeatMode = const Value.absent(),
                Value<bool> shuffleEnabled = const Value.absent(),
              }) => QueueStateCompanion(
                id: id,
                currentIndex: currentIndex,
                positionMs: positionMs,
                repeatMode: repeatMode,
                shuffleEnabled: shuffleEnabled,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> currentIndex = const Value.absent(),
                Value<int> positionMs = const Value.absent(),
                Value<int> repeatMode = const Value.absent(),
                Value<bool> shuffleEnabled = const Value.absent(),
              }) => QueueStateCompanion.insert(
                id: id,
                currentIndex: currentIndex,
                positionMs: positionMs,
                repeatMode: repeatMode,
                shuffleEnabled: shuffleEnabled,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QueueStateTableProcessedTableManager =
    ProcessedTableManager<
      _$NuvTuneDatabase,
      $QueueStateTable,
      QueueStateData,
      $$QueueStateTableFilterComposer,
      $$QueueStateTableOrderingComposer,
      $$QueueStateTableAnnotationComposer,
      $$QueueStateTableCreateCompanionBuilder,
      $$QueueStateTableUpdateCompanionBuilder,
      (
        QueueStateData,
        BaseReferences<_$NuvTuneDatabase, $QueueStateTable, QueueStateData>,
      ),
      QueueStateData,
      PrefetchHooks Function()
    >;
typedef $$ExcludedFoldersTableCreateCompanionBuilder =
    ExcludedFoldersCompanion Function({required String path, Value<int> rowid});
typedef $$ExcludedFoldersTableUpdateCompanionBuilder =
    ExcludedFoldersCompanion Function({Value<String> path, Value<int> rowid});

class $$ExcludedFoldersTableFilterComposer
    extends Composer<_$NuvTuneDatabase, $ExcludedFoldersTable> {
  $$ExcludedFoldersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExcludedFoldersTableOrderingComposer
    extends Composer<_$NuvTuneDatabase, $ExcludedFoldersTable> {
  $$ExcludedFoldersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExcludedFoldersTableAnnotationComposer
    extends Composer<_$NuvTuneDatabase, $ExcludedFoldersTable> {
  $$ExcludedFoldersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);
}

class $$ExcludedFoldersTableTableManager
    extends
        RootTableManager<
          _$NuvTuneDatabase,
          $ExcludedFoldersTable,
          ExcludedFolder,
          $$ExcludedFoldersTableFilterComposer,
          $$ExcludedFoldersTableOrderingComposer,
          $$ExcludedFoldersTableAnnotationComposer,
          $$ExcludedFoldersTableCreateCompanionBuilder,
          $$ExcludedFoldersTableUpdateCompanionBuilder,
          (
            ExcludedFolder,
            BaseReferences<
              _$NuvTuneDatabase,
              $ExcludedFoldersTable,
              ExcludedFolder
            >,
          ),
          ExcludedFolder,
          PrefetchHooks Function()
        > {
  $$ExcludedFoldersTableTableManager(
    _$NuvTuneDatabase db,
    $ExcludedFoldersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExcludedFoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExcludedFoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExcludedFoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> path = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExcludedFoldersCompanion(path: path, rowid: rowid),
          createCompanionCallback:
              ({
                required String path,
                Value<int> rowid = const Value.absent(),
              }) => ExcludedFoldersCompanion.insert(path: path, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExcludedFoldersTableProcessedTableManager =
    ProcessedTableManager<
      _$NuvTuneDatabase,
      $ExcludedFoldersTable,
      ExcludedFolder,
      $$ExcludedFoldersTableFilterComposer,
      $$ExcludedFoldersTableOrderingComposer,
      $$ExcludedFoldersTableAnnotationComposer,
      $$ExcludedFoldersTableCreateCompanionBuilder,
      $$ExcludedFoldersTableUpdateCompanionBuilder,
      (
        ExcludedFolder,
        BaseReferences<
          _$NuvTuneDatabase,
          $ExcludedFoldersTable,
          ExcludedFolder
        >,
      ),
      ExcludedFolder,
      PrefetchHooks Function()
    >;
typedef $$SourceFoldersTableCreateCompanionBuilder =
    SourceFoldersCompanion Function({
      required String uri,
      required String displayPath,
      Value<int> rowid,
    });
typedef $$SourceFoldersTableUpdateCompanionBuilder =
    SourceFoldersCompanion Function({
      Value<String> uri,
      Value<String> displayPath,
      Value<int> rowid,
    });

class $$SourceFoldersTableFilterComposer
    extends Composer<_$NuvTuneDatabase, $SourceFoldersTable> {
  $$SourceFoldersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uri => $composableBuilder(
    column: $table.uri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayPath => $composableBuilder(
    column: $table.displayPath,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SourceFoldersTableOrderingComposer
    extends Composer<_$NuvTuneDatabase, $SourceFoldersTable> {
  $$SourceFoldersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uri => $composableBuilder(
    column: $table.uri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayPath => $composableBuilder(
    column: $table.displayPath,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SourceFoldersTableAnnotationComposer
    extends Composer<_$NuvTuneDatabase, $SourceFoldersTable> {
  $$SourceFoldersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uri =>
      $composableBuilder(column: $table.uri, builder: (column) => column);

  GeneratedColumn<String> get displayPath => $composableBuilder(
    column: $table.displayPath,
    builder: (column) => column,
  );
}

class $$SourceFoldersTableTableManager
    extends
        RootTableManager<
          _$NuvTuneDatabase,
          $SourceFoldersTable,
          SourceFolder,
          $$SourceFoldersTableFilterComposer,
          $$SourceFoldersTableOrderingComposer,
          $$SourceFoldersTableAnnotationComposer,
          $$SourceFoldersTableCreateCompanionBuilder,
          $$SourceFoldersTableUpdateCompanionBuilder,
          (
            SourceFolder,
            BaseReferences<
              _$NuvTuneDatabase,
              $SourceFoldersTable,
              SourceFolder
            >,
          ),
          SourceFolder,
          PrefetchHooks Function()
        > {
  $$SourceFoldersTableTableManager(
    _$NuvTuneDatabase db,
    $SourceFoldersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SourceFoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SourceFoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SourceFoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uri = const Value.absent(),
                Value<String> displayPath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SourceFoldersCompanion(
                uri: uri,
                displayPath: displayPath,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uri,
                required String displayPath,
                Value<int> rowid = const Value.absent(),
              }) => SourceFoldersCompanion.insert(
                uri: uri,
                displayPath: displayPath,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SourceFoldersTableProcessedTableManager =
    ProcessedTableManager<
      _$NuvTuneDatabase,
      $SourceFoldersTable,
      SourceFolder,
      $$SourceFoldersTableFilterComposer,
      $$SourceFoldersTableOrderingComposer,
      $$SourceFoldersTableAnnotationComposer,
      $$SourceFoldersTableCreateCompanionBuilder,
      $$SourceFoldersTableUpdateCompanionBuilder,
      (
        SourceFolder,
        BaseReferences<_$NuvTuneDatabase, $SourceFoldersTable, SourceFolder>,
      ),
      SourceFolder,
      PrefetchHooks Function()
    >;
typedef $$CustomCoversTableCreateCompanionBuilder =
    CustomCoversCompanion Function({
      required String target,
      required String imagePath,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$CustomCoversTableUpdateCompanionBuilder =
    CustomCoversCompanion Function({
      Value<String> target,
      Value<String> imagePath,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CustomCoversTableFilterComposer
    extends Composer<_$NuvTuneDatabase, $CustomCoversTable> {
  $$CustomCoversTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get target => $composableBuilder(
    column: $table.target,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomCoversTableOrderingComposer
    extends Composer<_$NuvTuneDatabase, $CustomCoversTable> {
  $$CustomCoversTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get target => $composableBuilder(
    column: $table.target,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomCoversTableAnnotationComposer
    extends Composer<_$NuvTuneDatabase, $CustomCoversTable> {
  $$CustomCoversTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get target =>
      $composableBuilder(column: $table.target, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CustomCoversTableTableManager
    extends
        RootTableManager<
          _$NuvTuneDatabase,
          $CustomCoversTable,
          CustomCover,
          $$CustomCoversTableFilterComposer,
          $$CustomCoversTableOrderingComposer,
          $$CustomCoversTableAnnotationComposer,
          $$CustomCoversTableCreateCompanionBuilder,
          $$CustomCoversTableUpdateCompanionBuilder,
          (
            CustomCover,
            BaseReferences<_$NuvTuneDatabase, $CustomCoversTable, CustomCover>,
          ),
          CustomCover,
          PrefetchHooks Function()
        > {
  $$CustomCoversTableTableManager(
    _$NuvTuneDatabase db,
    $CustomCoversTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomCoversTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomCoversTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomCoversTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> target = const Value.absent(),
                Value<String> imagePath = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomCoversCompanion(
                target: target,
                imagePath: imagePath,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String target,
                required String imagePath,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomCoversCompanion.insert(
                target: target,
                imagePath: imagePath,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomCoversTableProcessedTableManager =
    ProcessedTableManager<
      _$NuvTuneDatabase,
      $CustomCoversTable,
      CustomCover,
      $$CustomCoversTableFilterComposer,
      $$CustomCoversTableOrderingComposer,
      $$CustomCoversTableAnnotationComposer,
      $$CustomCoversTableCreateCompanionBuilder,
      $$CustomCoversTableUpdateCompanionBuilder,
      (
        CustomCover,
        BaseReferences<_$NuvTuneDatabase, $CustomCoversTable, CustomCover>,
      ),
      CustomCover,
      PrefetchHooks Function()
    >;
typedef $$EqualizerPresetsTableTableCreateCompanionBuilder =
    EqualizerPresetsTableCompanion Function({
      required String name,
      required int bandCount,
      required String gainsJson,
      Value<double> preampDb,
      Value<int> rowid,
    });
typedef $$EqualizerPresetsTableTableUpdateCompanionBuilder =
    EqualizerPresetsTableCompanion Function({
      Value<String> name,
      Value<int> bandCount,
      Value<String> gainsJson,
      Value<double> preampDb,
      Value<int> rowid,
    });

class $$EqualizerPresetsTableTableFilterComposer
    extends Composer<_$NuvTuneDatabase, $EqualizerPresetsTableTable> {
  $$EqualizerPresetsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bandCount => $composableBuilder(
    column: $table.bandCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gainsJson => $composableBuilder(
    column: $table.gainsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get preampDb => $composableBuilder(
    column: $table.preampDb,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EqualizerPresetsTableTableOrderingComposer
    extends Composer<_$NuvTuneDatabase, $EqualizerPresetsTableTable> {
  $$EqualizerPresetsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bandCount => $composableBuilder(
    column: $table.bandCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gainsJson => $composableBuilder(
    column: $table.gainsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get preampDb => $composableBuilder(
    column: $table.preampDb,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EqualizerPresetsTableTableAnnotationComposer
    extends Composer<_$NuvTuneDatabase, $EqualizerPresetsTableTable> {
  $$EqualizerPresetsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get bandCount =>
      $composableBuilder(column: $table.bandCount, builder: (column) => column);

  GeneratedColumn<String> get gainsJson =>
      $composableBuilder(column: $table.gainsJson, builder: (column) => column);

  GeneratedColumn<double> get preampDb =>
      $composableBuilder(column: $table.preampDb, builder: (column) => column);
}

class $$EqualizerPresetsTableTableTableManager
    extends
        RootTableManager<
          _$NuvTuneDatabase,
          $EqualizerPresetsTableTable,
          EqualizerPreset,
          $$EqualizerPresetsTableTableFilterComposer,
          $$EqualizerPresetsTableTableOrderingComposer,
          $$EqualizerPresetsTableTableAnnotationComposer,
          $$EqualizerPresetsTableTableCreateCompanionBuilder,
          $$EqualizerPresetsTableTableUpdateCompanionBuilder,
          (
            EqualizerPreset,
            BaseReferences<
              _$NuvTuneDatabase,
              $EqualizerPresetsTableTable,
              EqualizerPreset
            >,
          ),
          EqualizerPreset,
          PrefetchHooks Function()
        > {
  $$EqualizerPresetsTableTableTableManager(
    _$NuvTuneDatabase db,
    $EqualizerPresetsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EqualizerPresetsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$EqualizerPresetsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$EqualizerPresetsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> name = const Value.absent(),
                Value<int> bandCount = const Value.absent(),
                Value<String> gainsJson = const Value.absent(),
                Value<double> preampDb = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EqualizerPresetsTableCompanion(
                name: name,
                bandCount: bandCount,
                gainsJson: gainsJson,
                preampDb: preampDb,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String name,
                required int bandCount,
                required String gainsJson,
                Value<double> preampDb = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EqualizerPresetsTableCompanion.insert(
                name: name,
                bandCount: bandCount,
                gainsJson: gainsJson,
                preampDb: preampDb,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EqualizerPresetsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$NuvTuneDatabase,
      $EqualizerPresetsTableTable,
      EqualizerPreset,
      $$EqualizerPresetsTableTableFilterComposer,
      $$EqualizerPresetsTableTableOrderingComposer,
      $$EqualizerPresetsTableTableAnnotationComposer,
      $$EqualizerPresetsTableTableCreateCompanionBuilder,
      $$EqualizerPresetsTableTableUpdateCompanionBuilder,
      (
        EqualizerPreset,
        BaseReferences<
          _$NuvTuneDatabase,
          $EqualizerPresetsTableTable,
          EqualizerPreset
        >,
      ),
      EqualizerPreset,
      PrefetchHooks Function()
    >;
typedef $$EqualizerStateTableCreateCompanionBuilder =
    EqualizerStateCompanion Function({
      Value<int> id,
      Value<bool> enabled,
      Value<int> bandCount,
      Value<String> gainsJson,
      Value<double> preampDb,
      Value<bool> autoPreventClipping,
      Value<double> balance,
      Value<bool> monoOutput,
      Value<String> presetName,
    });
typedef $$EqualizerStateTableUpdateCompanionBuilder =
    EqualizerStateCompanion Function({
      Value<int> id,
      Value<bool> enabled,
      Value<int> bandCount,
      Value<String> gainsJson,
      Value<double> preampDb,
      Value<bool> autoPreventClipping,
      Value<double> balance,
      Value<bool> monoOutput,
      Value<String> presetName,
    });

class $$EqualizerStateTableFilterComposer
    extends Composer<_$NuvTuneDatabase, $EqualizerStateTable> {
  $$EqualizerStateTableFilterComposer({
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

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bandCount => $composableBuilder(
    column: $table.bandCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gainsJson => $composableBuilder(
    column: $table.gainsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get preampDb => $composableBuilder(
    column: $table.preampDb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoPreventClipping => $composableBuilder(
    column: $table.autoPreventClipping,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get monoOutput => $composableBuilder(
    column: $table.monoOutput,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get presetName => $composableBuilder(
    column: $table.presetName,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EqualizerStateTableOrderingComposer
    extends Composer<_$NuvTuneDatabase, $EqualizerStateTable> {
  $$EqualizerStateTableOrderingComposer({
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

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bandCount => $composableBuilder(
    column: $table.bandCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gainsJson => $composableBuilder(
    column: $table.gainsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get preampDb => $composableBuilder(
    column: $table.preampDb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoPreventClipping => $composableBuilder(
    column: $table.autoPreventClipping,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get monoOutput => $composableBuilder(
    column: $table.monoOutput,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get presetName => $composableBuilder(
    column: $table.presetName,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EqualizerStateTableAnnotationComposer
    extends Composer<_$NuvTuneDatabase, $EqualizerStateTable> {
  $$EqualizerStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get bandCount =>
      $composableBuilder(column: $table.bandCount, builder: (column) => column);

  GeneratedColumn<String> get gainsJson =>
      $composableBuilder(column: $table.gainsJson, builder: (column) => column);

  GeneratedColumn<double> get preampDb =>
      $composableBuilder(column: $table.preampDb, builder: (column) => column);

  GeneratedColumn<bool> get autoPreventClipping => $composableBuilder(
    column: $table.autoPreventClipping,
    builder: (column) => column,
  );

  GeneratedColumn<double> get balance =>
      $composableBuilder(column: $table.balance, builder: (column) => column);

  GeneratedColumn<bool> get monoOutput => $composableBuilder(
    column: $table.monoOutput,
    builder: (column) => column,
  );

  GeneratedColumn<String> get presetName => $composableBuilder(
    column: $table.presetName,
    builder: (column) => column,
  );
}

class $$EqualizerStateTableTableManager
    extends
        RootTableManager<
          _$NuvTuneDatabase,
          $EqualizerStateTable,
          EqualizerStateData,
          $$EqualizerStateTableFilterComposer,
          $$EqualizerStateTableOrderingComposer,
          $$EqualizerStateTableAnnotationComposer,
          $$EqualizerStateTableCreateCompanionBuilder,
          $$EqualizerStateTableUpdateCompanionBuilder,
          (
            EqualizerStateData,
            BaseReferences<
              _$NuvTuneDatabase,
              $EqualizerStateTable,
              EqualizerStateData
            >,
          ),
          EqualizerStateData,
          PrefetchHooks Function()
        > {
  $$EqualizerStateTableTableManager(
    _$NuvTuneDatabase db,
    $EqualizerStateTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EqualizerStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EqualizerStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EqualizerStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> bandCount = const Value.absent(),
                Value<String> gainsJson = const Value.absent(),
                Value<double> preampDb = const Value.absent(),
                Value<bool> autoPreventClipping = const Value.absent(),
                Value<double> balance = const Value.absent(),
                Value<bool> monoOutput = const Value.absent(),
                Value<String> presetName = const Value.absent(),
              }) => EqualizerStateCompanion(
                id: id,
                enabled: enabled,
                bandCount: bandCount,
                gainsJson: gainsJson,
                preampDb: preampDb,
                autoPreventClipping: autoPreventClipping,
                balance: balance,
                monoOutput: monoOutput,
                presetName: presetName,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> bandCount = const Value.absent(),
                Value<String> gainsJson = const Value.absent(),
                Value<double> preampDb = const Value.absent(),
                Value<bool> autoPreventClipping = const Value.absent(),
                Value<double> balance = const Value.absent(),
                Value<bool> monoOutput = const Value.absent(),
                Value<String> presetName = const Value.absent(),
              }) => EqualizerStateCompanion.insert(
                id: id,
                enabled: enabled,
                bandCount: bandCount,
                gainsJson: gainsJson,
                preampDb: preampDb,
                autoPreventClipping: autoPreventClipping,
                balance: balance,
                monoOutput: monoOutput,
                presetName: presetName,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EqualizerStateTableProcessedTableManager =
    ProcessedTableManager<
      _$NuvTuneDatabase,
      $EqualizerStateTable,
      EqualizerStateData,
      $$EqualizerStateTableFilterComposer,
      $$EqualizerStateTableOrderingComposer,
      $$EqualizerStateTableAnnotationComposer,
      $$EqualizerStateTableCreateCompanionBuilder,
      $$EqualizerStateTableUpdateCompanionBuilder,
      (
        EqualizerStateData,
        BaseReferences<
          _$NuvTuneDatabase,
          $EqualizerStateTable,
          EqualizerStateData
        >,
      ),
      EqualizerStateData,
      PrefetchHooks Function()
    >;
typedef $$EnhancementStateTableCreateCompanionBuilder =
    EnhancementStateCompanion Function({
      Value<int> id,
      Value<bool> enabled,
      Value<int> profileIndex,
      Value<int> detailIndex,
      Value<double> multibandStrength,
      Value<int> normalizationIndex,
      Value<double> targetLevelDb,
      Value<bool> stereoExpansionEnabled,
      Value<double> stereoWidth,
    });
typedef $$EnhancementStateTableUpdateCompanionBuilder =
    EnhancementStateCompanion Function({
      Value<int> id,
      Value<bool> enabled,
      Value<int> profileIndex,
      Value<int> detailIndex,
      Value<double> multibandStrength,
      Value<int> normalizationIndex,
      Value<double> targetLevelDb,
      Value<bool> stereoExpansionEnabled,
      Value<double> stereoWidth,
    });

class $$EnhancementStateTableFilterComposer
    extends Composer<_$NuvTuneDatabase, $EnhancementStateTable> {
  $$EnhancementStateTableFilterComposer({
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

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get profileIndex => $composableBuilder(
    column: $table.profileIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get detailIndex => $composableBuilder(
    column: $table.detailIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get multibandStrength => $composableBuilder(
    column: $table.multibandStrength,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get normalizationIndex => $composableBuilder(
    column: $table.normalizationIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetLevelDb => $composableBuilder(
    column: $table.targetLevelDb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get stereoExpansionEnabled => $composableBuilder(
    column: $table.stereoExpansionEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get stereoWidth => $composableBuilder(
    column: $table.stereoWidth,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EnhancementStateTableOrderingComposer
    extends Composer<_$NuvTuneDatabase, $EnhancementStateTable> {
  $$EnhancementStateTableOrderingComposer({
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

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get profileIndex => $composableBuilder(
    column: $table.profileIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get detailIndex => $composableBuilder(
    column: $table.detailIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get multibandStrength => $composableBuilder(
    column: $table.multibandStrength,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get normalizationIndex => $composableBuilder(
    column: $table.normalizationIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetLevelDb => $composableBuilder(
    column: $table.targetLevelDb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get stereoExpansionEnabled => $composableBuilder(
    column: $table.stereoExpansionEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get stereoWidth => $composableBuilder(
    column: $table.stereoWidth,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EnhancementStateTableAnnotationComposer
    extends Composer<_$NuvTuneDatabase, $EnhancementStateTable> {
  $$EnhancementStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get profileIndex => $composableBuilder(
    column: $table.profileIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get detailIndex => $composableBuilder(
    column: $table.detailIndex,
    builder: (column) => column,
  );

  GeneratedColumn<double> get multibandStrength => $composableBuilder(
    column: $table.multibandStrength,
    builder: (column) => column,
  );

  GeneratedColumn<int> get normalizationIndex => $composableBuilder(
    column: $table.normalizationIndex,
    builder: (column) => column,
  );

  GeneratedColumn<double> get targetLevelDb => $composableBuilder(
    column: $table.targetLevelDb,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get stereoExpansionEnabled => $composableBuilder(
    column: $table.stereoExpansionEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<double> get stereoWidth => $composableBuilder(
    column: $table.stereoWidth,
    builder: (column) => column,
  );
}

class $$EnhancementStateTableTableManager
    extends
        RootTableManager<
          _$NuvTuneDatabase,
          $EnhancementStateTable,
          EnhancementStateData,
          $$EnhancementStateTableFilterComposer,
          $$EnhancementStateTableOrderingComposer,
          $$EnhancementStateTableAnnotationComposer,
          $$EnhancementStateTableCreateCompanionBuilder,
          $$EnhancementStateTableUpdateCompanionBuilder,
          (
            EnhancementStateData,
            BaseReferences<
              _$NuvTuneDatabase,
              $EnhancementStateTable,
              EnhancementStateData
            >,
          ),
          EnhancementStateData,
          PrefetchHooks Function()
        > {
  $$EnhancementStateTableTableManager(
    _$NuvTuneDatabase db,
    $EnhancementStateTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EnhancementStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EnhancementStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EnhancementStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> profileIndex = const Value.absent(),
                Value<int> detailIndex = const Value.absent(),
                Value<double> multibandStrength = const Value.absent(),
                Value<int> normalizationIndex = const Value.absent(),
                Value<double> targetLevelDb = const Value.absent(),
                Value<bool> stereoExpansionEnabled = const Value.absent(),
                Value<double> stereoWidth = const Value.absent(),
              }) => EnhancementStateCompanion(
                id: id,
                enabled: enabled,
                profileIndex: profileIndex,
                detailIndex: detailIndex,
                multibandStrength: multibandStrength,
                normalizationIndex: normalizationIndex,
                targetLevelDb: targetLevelDb,
                stereoExpansionEnabled: stereoExpansionEnabled,
                stereoWidth: stereoWidth,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> profileIndex = const Value.absent(),
                Value<int> detailIndex = const Value.absent(),
                Value<double> multibandStrength = const Value.absent(),
                Value<int> normalizationIndex = const Value.absent(),
                Value<double> targetLevelDb = const Value.absent(),
                Value<bool> stereoExpansionEnabled = const Value.absent(),
                Value<double> stereoWidth = const Value.absent(),
              }) => EnhancementStateCompanion.insert(
                id: id,
                enabled: enabled,
                profileIndex: profileIndex,
                detailIndex: detailIndex,
                multibandStrength: multibandStrength,
                normalizationIndex: normalizationIndex,
                targetLevelDb: targetLevelDb,
                stereoExpansionEnabled: stereoExpansionEnabled,
                stereoWidth: stereoWidth,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EnhancementStateTableProcessedTableManager =
    ProcessedTableManager<
      _$NuvTuneDatabase,
      $EnhancementStateTable,
      EnhancementStateData,
      $$EnhancementStateTableFilterComposer,
      $$EnhancementStateTableOrderingComposer,
      $$EnhancementStateTableAnnotationComposer,
      $$EnhancementStateTableCreateCompanionBuilder,
      $$EnhancementStateTableUpdateCompanionBuilder,
      (
        EnhancementStateData,
        BaseReferences<
          _$NuvTuneDatabase,
          $EnhancementStateTable,
          EnhancementStateData
        >,
      ),
      EnhancementStateData,
      PrefetchHooks Function()
    >;
typedef $$OutputProfilesTableCreateCompanionBuilder =
    OutputProfilesCompanion Function({
      Value<int> outputIndex,
      Value<int> bandCount,
      Value<String> gainsJson,
      Value<String> presetName,
      Value<double> preampDb,
      Value<int> profileIndex,
      Value<bool> enhancementEnabled,
    });
typedef $$OutputProfilesTableUpdateCompanionBuilder =
    OutputProfilesCompanion Function({
      Value<int> outputIndex,
      Value<int> bandCount,
      Value<String> gainsJson,
      Value<String> presetName,
      Value<double> preampDb,
      Value<int> profileIndex,
      Value<bool> enhancementEnabled,
    });

class $$OutputProfilesTableFilterComposer
    extends Composer<_$NuvTuneDatabase, $OutputProfilesTable> {
  $$OutputProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get outputIndex => $composableBuilder(
    column: $table.outputIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bandCount => $composableBuilder(
    column: $table.bandCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gainsJson => $composableBuilder(
    column: $table.gainsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get presetName => $composableBuilder(
    column: $table.presetName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get preampDb => $composableBuilder(
    column: $table.preampDb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get profileIndex => $composableBuilder(
    column: $table.profileIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enhancementEnabled => $composableBuilder(
    column: $table.enhancementEnabled,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutputProfilesTableOrderingComposer
    extends Composer<_$NuvTuneDatabase, $OutputProfilesTable> {
  $$OutputProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get outputIndex => $composableBuilder(
    column: $table.outputIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bandCount => $composableBuilder(
    column: $table.bandCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gainsJson => $composableBuilder(
    column: $table.gainsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get presetName => $composableBuilder(
    column: $table.presetName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get preampDb => $composableBuilder(
    column: $table.preampDb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get profileIndex => $composableBuilder(
    column: $table.profileIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enhancementEnabled => $composableBuilder(
    column: $table.enhancementEnabled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutputProfilesTableAnnotationComposer
    extends Composer<_$NuvTuneDatabase, $OutputProfilesTable> {
  $$OutputProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get outputIndex => $composableBuilder(
    column: $table.outputIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bandCount =>
      $composableBuilder(column: $table.bandCount, builder: (column) => column);

  GeneratedColumn<String> get gainsJson =>
      $composableBuilder(column: $table.gainsJson, builder: (column) => column);

  GeneratedColumn<String> get presetName => $composableBuilder(
    column: $table.presetName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get preampDb =>
      $composableBuilder(column: $table.preampDb, builder: (column) => column);

  GeneratedColumn<int> get profileIndex => $composableBuilder(
    column: $table.profileIndex,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enhancementEnabled => $composableBuilder(
    column: $table.enhancementEnabled,
    builder: (column) => column,
  );
}

class $$OutputProfilesTableTableManager
    extends
        RootTableManager<
          _$NuvTuneDatabase,
          $OutputProfilesTable,
          OutputProfile,
          $$OutputProfilesTableFilterComposer,
          $$OutputProfilesTableOrderingComposer,
          $$OutputProfilesTableAnnotationComposer,
          $$OutputProfilesTableCreateCompanionBuilder,
          $$OutputProfilesTableUpdateCompanionBuilder,
          (
            OutputProfile,
            BaseReferences<
              _$NuvTuneDatabase,
              $OutputProfilesTable,
              OutputProfile
            >,
          ),
          OutputProfile,
          PrefetchHooks Function()
        > {
  $$OutputProfilesTableTableManager(
    _$NuvTuneDatabase db,
    $OutputProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutputProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutputProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutputProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> outputIndex = const Value.absent(),
                Value<int> bandCount = const Value.absent(),
                Value<String> gainsJson = const Value.absent(),
                Value<String> presetName = const Value.absent(),
                Value<double> preampDb = const Value.absent(),
                Value<int> profileIndex = const Value.absent(),
                Value<bool> enhancementEnabled = const Value.absent(),
              }) => OutputProfilesCompanion(
                outputIndex: outputIndex,
                bandCount: bandCount,
                gainsJson: gainsJson,
                presetName: presetName,
                preampDb: preampDb,
                profileIndex: profileIndex,
                enhancementEnabled: enhancementEnabled,
              ),
          createCompanionCallback:
              ({
                Value<int> outputIndex = const Value.absent(),
                Value<int> bandCount = const Value.absent(),
                Value<String> gainsJson = const Value.absent(),
                Value<String> presetName = const Value.absent(),
                Value<double> preampDb = const Value.absent(),
                Value<int> profileIndex = const Value.absent(),
                Value<bool> enhancementEnabled = const Value.absent(),
              }) => OutputProfilesCompanion.insert(
                outputIndex: outputIndex,
                bandCount: bandCount,
                gainsJson: gainsJson,
                presetName: presetName,
                preampDb: preampDb,
                profileIndex: profileIndex,
                enhancementEnabled: enhancementEnabled,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutputProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$NuvTuneDatabase,
      $OutputProfilesTable,
      OutputProfile,
      $$OutputProfilesTableFilterComposer,
      $$OutputProfilesTableOrderingComposer,
      $$OutputProfilesTableAnnotationComposer,
      $$OutputProfilesTableCreateCompanionBuilder,
      $$OutputProfilesTableUpdateCompanionBuilder,
      (
        OutputProfile,
        BaseReferences<_$NuvTuneDatabase, $OutputProfilesTable, OutputProfile>,
      ),
      OutputProfile,
      PrefetchHooks Function()
    >;
typedef $$LoudnessAnalysesTableCreateCompanionBuilder =
    LoudnessAnalysesCompanion Function({
      Value<int> songId,
      required double gainDb,
      required double peak,
      Value<DateTime> analyzedAt,
    });
typedef $$LoudnessAnalysesTableUpdateCompanionBuilder =
    LoudnessAnalysesCompanion Function({
      Value<int> songId,
      Value<double> gainDb,
      Value<double> peak,
      Value<DateTime> analyzedAt,
    });

class $$LoudnessAnalysesTableFilterComposer
    extends Composer<_$NuvTuneDatabase, $LoudnessAnalysesTable> {
  $$LoudnessAnalysesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get songId => $composableBuilder(
    column: $table.songId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get gainDb => $composableBuilder(
    column: $table.gainDb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get peak => $composableBuilder(
    column: $table.peak,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get analyzedAt => $composableBuilder(
    column: $table.analyzedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LoudnessAnalysesTableOrderingComposer
    extends Composer<_$NuvTuneDatabase, $LoudnessAnalysesTable> {
  $$LoudnessAnalysesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get songId => $composableBuilder(
    column: $table.songId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get gainDb => $composableBuilder(
    column: $table.gainDb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get peak => $composableBuilder(
    column: $table.peak,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get analyzedAt => $composableBuilder(
    column: $table.analyzedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LoudnessAnalysesTableAnnotationComposer
    extends Composer<_$NuvTuneDatabase, $LoudnessAnalysesTable> {
  $$LoudnessAnalysesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get songId =>
      $composableBuilder(column: $table.songId, builder: (column) => column);

  GeneratedColumn<double> get gainDb =>
      $composableBuilder(column: $table.gainDb, builder: (column) => column);

  GeneratedColumn<double> get peak =>
      $composableBuilder(column: $table.peak, builder: (column) => column);

  GeneratedColumn<DateTime> get analyzedAt => $composableBuilder(
    column: $table.analyzedAt,
    builder: (column) => column,
  );
}

class $$LoudnessAnalysesTableTableManager
    extends
        RootTableManager<
          _$NuvTuneDatabase,
          $LoudnessAnalysesTable,
          LoudnessAnalyse,
          $$LoudnessAnalysesTableFilterComposer,
          $$LoudnessAnalysesTableOrderingComposer,
          $$LoudnessAnalysesTableAnnotationComposer,
          $$LoudnessAnalysesTableCreateCompanionBuilder,
          $$LoudnessAnalysesTableUpdateCompanionBuilder,
          (
            LoudnessAnalyse,
            BaseReferences<
              _$NuvTuneDatabase,
              $LoudnessAnalysesTable,
              LoudnessAnalyse
            >,
          ),
          LoudnessAnalyse,
          PrefetchHooks Function()
        > {
  $$LoudnessAnalysesTableTableManager(
    _$NuvTuneDatabase db,
    $LoudnessAnalysesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LoudnessAnalysesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LoudnessAnalysesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LoudnessAnalysesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> songId = const Value.absent(),
                Value<double> gainDb = const Value.absent(),
                Value<double> peak = const Value.absent(),
                Value<DateTime> analyzedAt = const Value.absent(),
              }) => LoudnessAnalysesCompanion(
                songId: songId,
                gainDb: gainDb,
                peak: peak,
                analyzedAt: analyzedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> songId = const Value.absent(),
                required double gainDb,
                required double peak,
                Value<DateTime> analyzedAt = const Value.absent(),
              }) => LoudnessAnalysesCompanion.insert(
                songId: songId,
                gainDb: gainDb,
                peak: peak,
                analyzedAt: analyzedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LoudnessAnalysesTableProcessedTableManager =
    ProcessedTableManager<
      _$NuvTuneDatabase,
      $LoudnessAnalysesTable,
      LoudnessAnalyse,
      $$LoudnessAnalysesTableFilterComposer,
      $$LoudnessAnalysesTableOrderingComposer,
      $$LoudnessAnalysesTableAnnotationComposer,
      $$LoudnessAnalysesTableCreateCompanionBuilder,
      $$LoudnessAnalysesTableUpdateCompanionBuilder,
      (
        LoudnessAnalyse,
        BaseReferences<
          _$NuvTuneDatabase,
          $LoudnessAnalysesTable,
          LoudnessAnalyse
        >,
      ),
      LoudnessAnalyse,
      PrefetchHooks Function()
    >;
typedef $$SavedRadiosTableCreateCompanionBuilder =
    SavedRadiosCompanion Function({
      Value<int> id,
      required String name,
      required String url,
      Value<DateTime> addedAt,
    });
typedef $$SavedRadiosTableUpdateCompanionBuilder =
    SavedRadiosCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> url,
      Value<DateTime> addedAt,
    });

class $$SavedRadiosTableFilterComposer
    extends Composer<_$NuvTuneDatabase, $SavedRadiosTable> {
  $$SavedRadiosTableFilterComposer({
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

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SavedRadiosTableOrderingComposer
    extends Composer<_$NuvTuneDatabase, $SavedRadiosTable> {
  $$SavedRadiosTableOrderingComposer({
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

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SavedRadiosTableAnnotationComposer
    extends Composer<_$NuvTuneDatabase, $SavedRadiosTable> {
  $$SavedRadiosTableAnnotationComposer({
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

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);
}

class $$SavedRadiosTableTableManager
    extends
        RootTableManager<
          _$NuvTuneDatabase,
          $SavedRadiosTable,
          SavedRadio,
          $$SavedRadiosTableFilterComposer,
          $$SavedRadiosTableOrderingComposer,
          $$SavedRadiosTableAnnotationComposer,
          $$SavedRadiosTableCreateCompanionBuilder,
          $$SavedRadiosTableUpdateCompanionBuilder,
          (
            SavedRadio,
            BaseReferences<_$NuvTuneDatabase, $SavedRadiosTable, SavedRadio>,
          ),
          SavedRadio,
          PrefetchHooks Function()
        > {
  $$SavedRadiosTableTableManager(_$NuvTuneDatabase db, $SavedRadiosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedRadiosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedRadiosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavedRadiosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
              }) => SavedRadiosCompanion(
                id: id,
                name: name,
                url: url,
                addedAt: addedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String url,
                Value<DateTime> addedAt = const Value.absent(),
              }) => SavedRadiosCompanion.insert(
                id: id,
                name: name,
                url: url,
                addedAt: addedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SavedRadiosTableProcessedTableManager =
    ProcessedTableManager<
      _$NuvTuneDatabase,
      $SavedRadiosTable,
      SavedRadio,
      $$SavedRadiosTableFilterComposer,
      $$SavedRadiosTableOrderingComposer,
      $$SavedRadiosTableAnnotationComposer,
      $$SavedRadiosTableCreateCompanionBuilder,
      $$SavedRadiosTableUpdateCompanionBuilder,
      (
        SavedRadio,
        BaseReferences<_$NuvTuneDatabase, $SavedRadiosTable, SavedRadio>,
      ),
      SavedRadio,
      PrefetchHooks Function()
    >;
typedef $$LyricsOverridesTableCreateCompanionBuilder =
    LyricsOverridesCompanion Function({
      Value<int> songId,
      required String content,
      Value<int> offsetMs,
      Value<bool> synchronized,
      Value<DateTime> updatedAt,
    });
typedef $$LyricsOverridesTableUpdateCompanionBuilder =
    LyricsOverridesCompanion Function({
      Value<int> songId,
      Value<String> content,
      Value<int> offsetMs,
      Value<bool> synchronized,
      Value<DateTime> updatedAt,
    });

class $$LyricsOverridesTableFilterComposer
    extends Composer<_$NuvTuneDatabase, $LyricsOverridesTable> {
  $$LyricsOverridesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get songId => $composableBuilder(
    column: $table.songId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get offsetMs => $composableBuilder(
    column: $table.offsetMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synchronized => $composableBuilder(
    column: $table.synchronized,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LyricsOverridesTableOrderingComposer
    extends Composer<_$NuvTuneDatabase, $LyricsOverridesTable> {
  $$LyricsOverridesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get songId => $composableBuilder(
    column: $table.songId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get offsetMs => $composableBuilder(
    column: $table.offsetMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synchronized => $composableBuilder(
    column: $table.synchronized,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LyricsOverridesTableAnnotationComposer
    extends Composer<_$NuvTuneDatabase, $LyricsOverridesTable> {
  $$LyricsOverridesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get songId =>
      $composableBuilder(column: $table.songId, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<int> get offsetMs =>
      $composableBuilder(column: $table.offsetMs, builder: (column) => column);

  GeneratedColumn<bool> get synchronized => $composableBuilder(
    column: $table.synchronized,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LyricsOverridesTableTableManager
    extends
        RootTableManager<
          _$NuvTuneDatabase,
          $LyricsOverridesTable,
          LyricsOverride,
          $$LyricsOverridesTableFilterComposer,
          $$LyricsOverridesTableOrderingComposer,
          $$LyricsOverridesTableAnnotationComposer,
          $$LyricsOverridesTableCreateCompanionBuilder,
          $$LyricsOverridesTableUpdateCompanionBuilder,
          (
            LyricsOverride,
            BaseReferences<
              _$NuvTuneDatabase,
              $LyricsOverridesTable,
              LyricsOverride
            >,
          ),
          LyricsOverride,
          PrefetchHooks Function()
        > {
  $$LyricsOverridesTableTableManager(
    _$NuvTuneDatabase db,
    $LyricsOverridesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LyricsOverridesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LyricsOverridesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LyricsOverridesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> songId = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<int> offsetMs = const Value.absent(),
                Value<bool> synchronized = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LyricsOverridesCompanion(
                songId: songId,
                content: content,
                offsetMs: offsetMs,
                synchronized: synchronized,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> songId = const Value.absent(),
                required String content,
                Value<int> offsetMs = const Value.absent(),
                Value<bool> synchronized = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LyricsOverridesCompanion.insert(
                songId: songId,
                content: content,
                offsetMs: offsetMs,
                synchronized: synchronized,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LyricsOverridesTableProcessedTableManager =
    ProcessedTableManager<
      _$NuvTuneDatabase,
      $LyricsOverridesTable,
      LyricsOverride,
      $$LyricsOverridesTableFilterComposer,
      $$LyricsOverridesTableOrderingComposer,
      $$LyricsOverridesTableAnnotationComposer,
      $$LyricsOverridesTableCreateCompanionBuilder,
      $$LyricsOverridesTableUpdateCompanionBuilder,
      (
        LyricsOverride,
        BaseReferences<
          _$NuvTuneDatabase,
          $LyricsOverridesTable,
          LyricsOverride
        >,
      ),
      LyricsOverride,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<bool> scanOnStart,
      Value<DateTime?> lastScanAt,
      Value<bool> useDynamicColor,
      Value<bool> pureBlackBackground,
      Value<String> accentId,
      Value<String> backgroundDepth,
      Value<String> glassIntensity,
      Value<bool> restoreQueueOnStart,
      Value<bool> gaplessEnabled,
      Value<int> crossfadeSeconds,
      Value<bool> fadeOnPause,
      Value<int> fadeOnPauseMs,
      Value<bool> directMode,
      Value<bool> allowOffload,
      Value<double> playbackSpeed,
      Value<double> playbackPitch,
      Value<bool> embedCoverInFile,
      Value<bool> widgetEnabled,
      Value<int> widgetStyle,
      Value<int> widgetTheme,
      Value<int> widgetSize,
      Value<int> widgetAccentColor,
      Value<double> widgetOpacity,
      Value<bool> widgetShowCover,
      Value<bool> widgetShowTitle,
      Value<bool> widgetShowArtist,
      Value<bool> widgetShowControls,
      Value<bool> widgetShowProgress,
      Value<bool> widgetShowDuration,
      Value<bool> widgetShowNextInQueue,
      Value<bool> widgetOpenOnTap,
      Value<bool> widgetPauseOnDisconnect,
      Value<bool> widgetResumeOnConnect,
      Value<int> sleepTimerMinutes,
      Value<bool> sleepTimerFinishTrack,
      Value<String> homeSectionsJson,
      Value<String> librarySortJson,
      Value<bool> videoBackgroundEnabled,
      Value<int> playerVisualizerStyle,
      Value<int> playerVisualScene,
      Value<int> playerSceneAspectRatio,
      Value<String> playerControlPreset,
      Value<String> playerControlLayoutJson,
      Value<String> playerControlHandedness,
      Value<String> playerDensity,
      Value<bool> playerGestureDoubleTap,
      Value<bool> playerGestureSwipeTrack,
      Value<bool> playerGestureSwipeVolume,
      Value<bool> playerGestureSwipeDismiss,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<bool> scanOnStart,
      Value<DateTime?> lastScanAt,
      Value<bool> useDynamicColor,
      Value<bool> pureBlackBackground,
      Value<String> accentId,
      Value<String> backgroundDepth,
      Value<String> glassIntensity,
      Value<bool> restoreQueueOnStart,
      Value<bool> gaplessEnabled,
      Value<int> crossfadeSeconds,
      Value<bool> fadeOnPause,
      Value<int> fadeOnPauseMs,
      Value<bool> directMode,
      Value<bool> allowOffload,
      Value<double> playbackSpeed,
      Value<double> playbackPitch,
      Value<bool> embedCoverInFile,
      Value<bool> widgetEnabled,
      Value<int> widgetStyle,
      Value<int> widgetTheme,
      Value<int> widgetSize,
      Value<int> widgetAccentColor,
      Value<double> widgetOpacity,
      Value<bool> widgetShowCover,
      Value<bool> widgetShowTitle,
      Value<bool> widgetShowArtist,
      Value<bool> widgetShowControls,
      Value<bool> widgetShowProgress,
      Value<bool> widgetShowDuration,
      Value<bool> widgetShowNextInQueue,
      Value<bool> widgetOpenOnTap,
      Value<bool> widgetPauseOnDisconnect,
      Value<bool> widgetResumeOnConnect,
      Value<int> sleepTimerMinutes,
      Value<bool> sleepTimerFinishTrack,
      Value<String> homeSectionsJson,
      Value<String> librarySortJson,
      Value<bool> videoBackgroundEnabled,
      Value<int> playerVisualizerStyle,
      Value<int> playerVisualScene,
      Value<int> playerSceneAspectRatio,
      Value<String> playerControlPreset,
      Value<String> playerControlLayoutJson,
      Value<String> playerControlHandedness,
      Value<String> playerDensity,
      Value<bool> playerGestureDoubleTap,
      Value<bool> playerGestureSwipeTrack,
      Value<bool> playerGestureSwipeVolume,
      Value<bool> playerGestureSwipeDismiss,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$NuvTuneDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
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

  ColumnFilters<bool> get scanOnStart => $composableBuilder(
    column: $table.scanOnStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastScanAt => $composableBuilder(
    column: $table.lastScanAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get useDynamicColor => $composableBuilder(
    column: $table.useDynamicColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pureBlackBackground => $composableBuilder(
    column: $table.pureBlackBackground,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accentId => $composableBuilder(
    column: $table.accentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backgroundDepth => $composableBuilder(
    column: $table.backgroundDepth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get glassIntensity => $composableBuilder(
    column: $table.glassIntensity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get restoreQueueOnStart => $composableBuilder(
    column: $table.restoreQueueOnStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get gaplessEnabled => $composableBuilder(
    column: $table.gaplessEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get crossfadeSeconds => $composableBuilder(
    column: $table.crossfadeSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get fadeOnPause => $composableBuilder(
    column: $table.fadeOnPause,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fadeOnPauseMs => $composableBuilder(
    column: $table.fadeOnPauseMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get directMode => $composableBuilder(
    column: $table.directMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get allowOffload => $composableBuilder(
    column: $table.allowOffload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get playbackSpeed => $composableBuilder(
    column: $table.playbackSpeed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get playbackPitch => $composableBuilder(
    column: $table.playbackPitch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get embedCoverInFile => $composableBuilder(
    column: $table.embedCoverInFile,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get widgetEnabled => $composableBuilder(
    column: $table.widgetEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get widgetStyle => $composableBuilder(
    column: $table.widgetStyle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get widgetTheme => $composableBuilder(
    column: $table.widgetTheme,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get widgetSize => $composableBuilder(
    column: $table.widgetSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get widgetAccentColor => $composableBuilder(
    column: $table.widgetAccentColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get widgetOpacity => $composableBuilder(
    column: $table.widgetOpacity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get widgetShowCover => $composableBuilder(
    column: $table.widgetShowCover,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get widgetShowTitle => $composableBuilder(
    column: $table.widgetShowTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get widgetShowArtist => $composableBuilder(
    column: $table.widgetShowArtist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get widgetShowControls => $composableBuilder(
    column: $table.widgetShowControls,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get widgetShowProgress => $composableBuilder(
    column: $table.widgetShowProgress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get widgetShowDuration => $composableBuilder(
    column: $table.widgetShowDuration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get widgetShowNextInQueue => $composableBuilder(
    column: $table.widgetShowNextInQueue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get widgetOpenOnTap => $composableBuilder(
    column: $table.widgetOpenOnTap,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get widgetPauseOnDisconnect => $composableBuilder(
    column: $table.widgetPauseOnDisconnect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get widgetResumeOnConnect => $composableBuilder(
    column: $table.widgetResumeOnConnect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sleepTimerMinutes => $composableBuilder(
    column: $table.sleepTimerMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get sleepTimerFinishTrack => $composableBuilder(
    column: $table.sleepTimerFinishTrack,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get homeSectionsJson => $composableBuilder(
    column: $table.homeSectionsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get librarySortJson => $composableBuilder(
    column: $table.librarySortJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get videoBackgroundEnabled => $composableBuilder(
    column: $table.videoBackgroundEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playerVisualizerStyle => $composableBuilder(
    column: $table.playerVisualizerStyle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playerVisualScene => $composableBuilder(
    column: $table.playerVisualScene,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playerSceneAspectRatio => $composableBuilder(
    column: $table.playerSceneAspectRatio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get playerControlPreset => $composableBuilder(
    column: $table.playerControlPreset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get playerControlLayoutJson => $composableBuilder(
    column: $table.playerControlLayoutJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get playerControlHandedness => $composableBuilder(
    column: $table.playerControlHandedness,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get playerDensity => $composableBuilder(
    column: $table.playerDensity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get playerGestureDoubleTap => $composableBuilder(
    column: $table.playerGestureDoubleTap,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get playerGestureSwipeTrack => $composableBuilder(
    column: $table.playerGestureSwipeTrack,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get playerGestureSwipeVolume => $composableBuilder(
    column: $table.playerGestureSwipeVolume,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get playerGestureSwipeDismiss => $composableBuilder(
    column: $table.playerGestureSwipeDismiss,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$NuvTuneDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
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

  ColumnOrderings<bool> get scanOnStart => $composableBuilder(
    column: $table.scanOnStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastScanAt => $composableBuilder(
    column: $table.lastScanAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get useDynamicColor => $composableBuilder(
    column: $table.useDynamicColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pureBlackBackground => $composableBuilder(
    column: $table.pureBlackBackground,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accentId => $composableBuilder(
    column: $table.accentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backgroundDepth => $composableBuilder(
    column: $table.backgroundDepth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get glassIntensity => $composableBuilder(
    column: $table.glassIntensity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get restoreQueueOnStart => $composableBuilder(
    column: $table.restoreQueueOnStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get gaplessEnabled => $composableBuilder(
    column: $table.gaplessEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get crossfadeSeconds => $composableBuilder(
    column: $table.crossfadeSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get fadeOnPause => $composableBuilder(
    column: $table.fadeOnPause,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fadeOnPauseMs => $composableBuilder(
    column: $table.fadeOnPauseMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get directMode => $composableBuilder(
    column: $table.directMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get allowOffload => $composableBuilder(
    column: $table.allowOffload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get playbackSpeed => $composableBuilder(
    column: $table.playbackSpeed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get playbackPitch => $composableBuilder(
    column: $table.playbackPitch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get embedCoverInFile => $composableBuilder(
    column: $table.embedCoverInFile,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get widgetEnabled => $composableBuilder(
    column: $table.widgetEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get widgetStyle => $composableBuilder(
    column: $table.widgetStyle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get widgetTheme => $composableBuilder(
    column: $table.widgetTheme,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get widgetSize => $composableBuilder(
    column: $table.widgetSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get widgetAccentColor => $composableBuilder(
    column: $table.widgetAccentColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get widgetOpacity => $composableBuilder(
    column: $table.widgetOpacity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get widgetShowCover => $composableBuilder(
    column: $table.widgetShowCover,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get widgetShowTitle => $composableBuilder(
    column: $table.widgetShowTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get widgetShowArtist => $composableBuilder(
    column: $table.widgetShowArtist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get widgetShowControls => $composableBuilder(
    column: $table.widgetShowControls,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get widgetShowProgress => $composableBuilder(
    column: $table.widgetShowProgress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get widgetShowDuration => $composableBuilder(
    column: $table.widgetShowDuration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get widgetShowNextInQueue => $composableBuilder(
    column: $table.widgetShowNextInQueue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get widgetOpenOnTap => $composableBuilder(
    column: $table.widgetOpenOnTap,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get widgetPauseOnDisconnect => $composableBuilder(
    column: $table.widgetPauseOnDisconnect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get widgetResumeOnConnect => $composableBuilder(
    column: $table.widgetResumeOnConnect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sleepTimerMinutes => $composableBuilder(
    column: $table.sleepTimerMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get sleepTimerFinishTrack => $composableBuilder(
    column: $table.sleepTimerFinishTrack,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get homeSectionsJson => $composableBuilder(
    column: $table.homeSectionsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get librarySortJson => $composableBuilder(
    column: $table.librarySortJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get videoBackgroundEnabled => $composableBuilder(
    column: $table.videoBackgroundEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playerVisualizerStyle => $composableBuilder(
    column: $table.playerVisualizerStyle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playerVisualScene => $composableBuilder(
    column: $table.playerVisualScene,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playerSceneAspectRatio => $composableBuilder(
    column: $table.playerSceneAspectRatio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get playerControlPreset => $composableBuilder(
    column: $table.playerControlPreset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get playerControlLayoutJson => $composableBuilder(
    column: $table.playerControlLayoutJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get playerControlHandedness => $composableBuilder(
    column: $table.playerControlHandedness,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get playerDensity => $composableBuilder(
    column: $table.playerDensity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get playerGestureDoubleTap => $composableBuilder(
    column: $table.playerGestureDoubleTap,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get playerGestureSwipeTrack => $composableBuilder(
    column: $table.playerGestureSwipeTrack,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get playerGestureSwipeVolume => $composableBuilder(
    column: $table.playerGestureSwipeVolume,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get playerGestureSwipeDismiss => $composableBuilder(
    column: $table.playerGestureSwipeDismiss,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$NuvTuneDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get scanOnStart => $composableBuilder(
    column: $table.scanOnStart,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastScanAt => $composableBuilder(
    column: $table.lastScanAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get useDynamicColor => $composableBuilder(
    column: $table.useDynamicColor,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get pureBlackBackground => $composableBuilder(
    column: $table.pureBlackBackground,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accentId =>
      $composableBuilder(column: $table.accentId, builder: (column) => column);

  GeneratedColumn<String> get backgroundDepth => $composableBuilder(
    column: $table.backgroundDepth,
    builder: (column) => column,
  );

  GeneratedColumn<String> get glassIntensity => $composableBuilder(
    column: $table.glassIntensity,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get restoreQueueOnStart => $composableBuilder(
    column: $table.restoreQueueOnStart,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get gaplessEnabled => $composableBuilder(
    column: $table.gaplessEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get crossfadeSeconds => $composableBuilder(
    column: $table.crossfadeSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get fadeOnPause => $composableBuilder(
    column: $table.fadeOnPause,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fadeOnPauseMs => $composableBuilder(
    column: $table.fadeOnPauseMs,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get directMode => $composableBuilder(
    column: $table.directMode,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get allowOffload => $composableBuilder(
    column: $table.allowOffload,
    builder: (column) => column,
  );

  GeneratedColumn<double> get playbackSpeed => $composableBuilder(
    column: $table.playbackSpeed,
    builder: (column) => column,
  );

  GeneratedColumn<double> get playbackPitch => $composableBuilder(
    column: $table.playbackPitch,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get embedCoverInFile => $composableBuilder(
    column: $table.embedCoverInFile,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get widgetEnabled => $composableBuilder(
    column: $table.widgetEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get widgetStyle => $composableBuilder(
    column: $table.widgetStyle,
    builder: (column) => column,
  );

  GeneratedColumn<int> get widgetTheme => $composableBuilder(
    column: $table.widgetTheme,
    builder: (column) => column,
  );

  GeneratedColumn<int> get widgetSize => $composableBuilder(
    column: $table.widgetSize,
    builder: (column) => column,
  );

  GeneratedColumn<int> get widgetAccentColor => $composableBuilder(
    column: $table.widgetAccentColor,
    builder: (column) => column,
  );

  GeneratedColumn<double> get widgetOpacity => $composableBuilder(
    column: $table.widgetOpacity,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get widgetShowCover => $composableBuilder(
    column: $table.widgetShowCover,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get widgetShowTitle => $composableBuilder(
    column: $table.widgetShowTitle,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get widgetShowArtist => $composableBuilder(
    column: $table.widgetShowArtist,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get widgetShowControls => $composableBuilder(
    column: $table.widgetShowControls,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get widgetShowProgress => $composableBuilder(
    column: $table.widgetShowProgress,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get widgetShowDuration => $composableBuilder(
    column: $table.widgetShowDuration,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get widgetShowNextInQueue => $composableBuilder(
    column: $table.widgetShowNextInQueue,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get widgetOpenOnTap => $composableBuilder(
    column: $table.widgetOpenOnTap,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get widgetPauseOnDisconnect => $composableBuilder(
    column: $table.widgetPauseOnDisconnect,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get widgetResumeOnConnect => $composableBuilder(
    column: $table.widgetResumeOnConnect,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sleepTimerMinutes => $composableBuilder(
    column: $table.sleepTimerMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get sleepTimerFinishTrack => $composableBuilder(
    column: $table.sleepTimerFinishTrack,
    builder: (column) => column,
  );

  GeneratedColumn<String> get homeSectionsJson => $composableBuilder(
    column: $table.homeSectionsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get librarySortJson => $composableBuilder(
    column: $table.librarySortJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get videoBackgroundEnabled => $composableBuilder(
    column: $table.videoBackgroundEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get playerVisualizerStyle => $composableBuilder(
    column: $table.playerVisualizerStyle,
    builder: (column) => column,
  );

  GeneratedColumn<int> get playerVisualScene => $composableBuilder(
    column: $table.playerVisualScene,
    builder: (column) => column,
  );

  GeneratedColumn<int> get playerSceneAspectRatio => $composableBuilder(
    column: $table.playerSceneAspectRatio,
    builder: (column) => column,
  );

  GeneratedColumn<String> get playerControlPreset => $composableBuilder(
    column: $table.playerControlPreset,
    builder: (column) => column,
  );

  GeneratedColumn<String> get playerControlLayoutJson => $composableBuilder(
    column: $table.playerControlLayoutJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get playerControlHandedness => $composableBuilder(
    column: $table.playerControlHandedness,
    builder: (column) => column,
  );

  GeneratedColumn<String> get playerDensity => $composableBuilder(
    column: $table.playerDensity,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get playerGestureDoubleTap => $composableBuilder(
    column: $table.playerGestureDoubleTap,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get playerGestureSwipeTrack => $composableBuilder(
    column: $table.playerGestureSwipeTrack,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get playerGestureSwipeVolume => $composableBuilder(
    column: $table.playerGestureSwipeVolume,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get playerGestureSwipeDismiss => $composableBuilder(
    column: $table.playerGestureSwipeDismiss,
    builder: (column) => column,
  );
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$NuvTuneDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$NuvTuneDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$NuvTuneDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> scanOnStart = const Value.absent(),
                Value<DateTime?> lastScanAt = const Value.absent(),
                Value<bool> useDynamicColor = const Value.absent(),
                Value<bool> pureBlackBackground = const Value.absent(),
                Value<String> accentId = const Value.absent(),
                Value<String> backgroundDepth = const Value.absent(),
                Value<String> glassIntensity = const Value.absent(),
                Value<bool> restoreQueueOnStart = const Value.absent(),
                Value<bool> gaplessEnabled = const Value.absent(),
                Value<int> crossfadeSeconds = const Value.absent(),
                Value<bool> fadeOnPause = const Value.absent(),
                Value<int> fadeOnPauseMs = const Value.absent(),
                Value<bool> directMode = const Value.absent(),
                Value<bool> allowOffload = const Value.absent(),
                Value<double> playbackSpeed = const Value.absent(),
                Value<double> playbackPitch = const Value.absent(),
                Value<bool> embedCoverInFile = const Value.absent(),
                Value<bool> widgetEnabled = const Value.absent(),
                Value<int> widgetStyle = const Value.absent(),
                Value<int> widgetTheme = const Value.absent(),
                Value<int> widgetSize = const Value.absent(),
                Value<int> widgetAccentColor = const Value.absent(),
                Value<double> widgetOpacity = const Value.absent(),
                Value<bool> widgetShowCover = const Value.absent(),
                Value<bool> widgetShowTitle = const Value.absent(),
                Value<bool> widgetShowArtist = const Value.absent(),
                Value<bool> widgetShowControls = const Value.absent(),
                Value<bool> widgetShowProgress = const Value.absent(),
                Value<bool> widgetShowDuration = const Value.absent(),
                Value<bool> widgetShowNextInQueue = const Value.absent(),
                Value<bool> widgetOpenOnTap = const Value.absent(),
                Value<bool> widgetPauseOnDisconnect = const Value.absent(),
                Value<bool> widgetResumeOnConnect = const Value.absent(),
                Value<int> sleepTimerMinutes = const Value.absent(),
                Value<bool> sleepTimerFinishTrack = const Value.absent(),
                Value<String> homeSectionsJson = const Value.absent(),
                Value<String> librarySortJson = const Value.absent(),
                Value<bool> videoBackgroundEnabled = const Value.absent(),
                Value<int> playerVisualizerStyle = const Value.absent(),
                Value<int> playerVisualScene = const Value.absent(),
                Value<int> playerSceneAspectRatio = const Value.absent(),
                Value<String> playerControlPreset = const Value.absent(),
                Value<String> playerControlLayoutJson = const Value.absent(),
                Value<String> playerControlHandedness = const Value.absent(),
                Value<String> playerDensity = const Value.absent(),
                Value<bool> playerGestureDoubleTap = const Value.absent(),
                Value<bool> playerGestureSwipeTrack = const Value.absent(),
                Value<bool> playerGestureSwipeVolume = const Value.absent(),
                Value<bool> playerGestureSwipeDismiss = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                scanOnStart: scanOnStart,
                lastScanAt: lastScanAt,
                useDynamicColor: useDynamicColor,
                pureBlackBackground: pureBlackBackground,
                accentId: accentId,
                backgroundDepth: backgroundDepth,
                glassIntensity: glassIntensity,
                restoreQueueOnStart: restoreQueueOnStart,
                gaplessEnabled: gaplessEnabled,
                crossfadeSeconds: crossfadeSeconds,
                fadeOnPause: fadeOnPause,
                fadeOnPauseMs: fadeOnPauseMs,
                directMode: directMode,
                allowOffload: allowOffload,
                playbackSpeed: playbackSpeed,
                playbackPitch: playbackPitch,
                embedCoverInFile: embedCoverInFile,
                widgetEnabled: widgetEnabled,
                widgetStyle: widgetStyle,
                widgetTheme: widgetTheme,
                widgetSize: widgetSize,
                widgetAccentColor: widgetAccentColor,
                widgetOpacity: widgetOpacity,
                widgetShowCover: widgetShowCover,
                widgetShowTitle: widgetShowTitle,
                widgetShowArtist: widgetShowArtist,
                widgetShowControls: widgetShowControls,
                widgetShowProgress: widgetShowProgress,
                widgetShowDuration: widgetShowDuration,
                widgetShowNextInQueue: widgetShowNextInQueue,
                widgetOpenOnTap: widgetOpenOnTap,
                widgetPauseOnDisconnect: widgetPauseOnDisconnect,
                widgetResumeOnConnect: widgetResumeOnConnect,
                sleepTimerMinutes: sleepTimerMinutes,
                sleepTimerFinishTrack: sleepTimerFinishTrack,
                homeSectionsJson: homeSectionsJson,
                librarySortJson: librarySortJson,
                videoBackgroundEnabled: videoBackgroundEnabled,
                playerVisualizerStyle: playerVisualizerStyle,
                playerVisualScene: playerVisualScene,
                playerSceneAspectRatio: playerSceneAspectRatio,
                playerControlPreset: playerControlPreset,
                playerControlLayoutJson: playerControlLayoutJson,
                playerControlHandedness: playerControlHandedness,
                playerDensity: playerDensity,
                playerGestureDoubleTap: playerGestureDoubleTap,
                playerGestureSwipeTrack: playerGestureSwipeTrack,
                playerGestureSwipeVolume: playerGestureSwipeVolume,
                playerGestureSwipeDismiss: playerGestureSwipeDismiss,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> scanOnStart = const Value.absent(),
                Value<DateTime?> lastScanAt = const Value.absent(),
                Value<bool> useDynamicColor = const Value.absent(),
                Value<bool> pureBlackBackground = const Value.absent(),
                Value<String> accentId = const Value.absent(),
                Value<String> backgroundDepth = const Value.absent(),
                Value<String> glassIntensity = const Value.absent(),
                Value<bool> restoreQueueOnStart = const Value.absent(),
                Value<bool> gaplessEnabled = const Value.absent(),
                Value<int> crossfadeSeconds = const Value.absent(),
                Value<bool> fadeOnPause = const Value.absent(),
                Value<int> fadeOnPauseMs = const Value.absent(),
                Value<bool> directMode = const Value.absent(),
                Value<bool> allowOffload = const Value.absent(),
                Value<double> playbackSpeed = const Value.absent(),
                Value<double> playbackPitch = const Value.absent(),
                Value<bool> embedCoverInFile = const Value.absent(),
                Value<bool> widgetEnabled = const Value.absent(),
                Value<int> widgetStyle = const Value.absent(),
                Value<int> widgetTheme = const Value.absent(),
                Value<int> widgetSize = const Value.absent(),
                Value<int> widgetAccentColor = const Value.absent(),
                Value<double> widgetOpacity = const Value.absent(),
                Value<bool> widgetShowCover = const Value.absent(),
                Value<bool> widgetShowTitle = const Value.absent(),
                Value<bool> widgetShowArtist = const Value.absent(),
                Value<bool> widgetShowControls = const Value.absent(),
                Value<bool> widgetShowProgress = const Value.absent(),
                Value<bool> widgetShowDuration = const Value.absent(),
                Value<bool> widgetShowNextInQueue = const Value.absent(),
                Value<bool> widgetOpenOnTap = const Value.absent(),
                Value<bool> widgetPauseOnDisconnect = const Value.absent(),
                Value<bool> widgetResumeOnConnect = const Value.absent(),
                Value<int> sleepTimerMinutes = const Value.absent(),
                Value<bool> sleepTimerFinishTrack = const Value.absent(),
                Value<String> homeSectionsJson = const Value.absent(),
                Value<String> librarySortJson = const Value.absent(),
                Value<bool> videoBackgroundEnabled = const Value.absent(),
                Value<int> playerVisualizerStyle = const Value.absent(),
                Value<int> playerVisualScene = const Value.absent(),
                Value<int> playerSceneAspectRatio = const Value.absent(),
                Value<String> playerControlPreset = const Value.absent(),
                Value<String> playerControlLayoutJson = const Value.absent(),
                Value<String> playerControlHandedness = const Value.absent(),
                Value<String> playerDensity = const Value.absent(),
                Value<bool> playerGestureDoubleTap = const Value.absent(),
                Value<bool> playerGestureSwipeTrack = const Value.absent(),
                Value<bool> playerGestureSwipeVolume = const Value.absent(),
                Value<bool> playerGestureSwipeDismiss = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                id: id,
                scanOnStart: scanOnStart,
                lastScanAt: lastScanAt,
                useDynamicColor: useDynamicColor,
                pureBlackBackground: pureBlackBackground,
                accentId: accentId,
                backgroundDepth: backgroundDepth,
                glassIntensity: glassIntensity,
                restoreQueueOnStart: restoreQueueOnStart,
                gaplessEnabled: gaplessEnabled,
                crossfadeSeconds: crossfadeSeconds,
                fadeOnPause: fadeOnPause,
                fadeOnPauseMs: fadeOnPauseMs,
                directMode: directMode,
                allowOffload: allowOffload,
                playbackSpeed: playbackSpeed,
                playbackPitch: playbackPitch,
                embedCoverInFile: embedCoverInFile,
                widgetEnabled: widgetEnabled,
                widgetStyle: widgetStyle,
                widgetTheme: widgetTheme,
                widgetSize: widgetSize,
                widgetAccentColor: widgetAccentColor,
                widgetOpacity: widgetOpacity,
                widgetShowCover: widgetShowCover,
                widgetShowTitle: widgetShowTitle,
                widgetShowArtist: widgetShowArtist,
                widgetShowControls: widgetShowControls,
                widgetShowProgress: widgetShowProgress,
                widgetShowDuration: widgetShowDuration,
                widgetShowNextInQueue: widgetShowNextInQueue,
                widgetOpenOnTap: widgetOpenOnTap,
                widgetPauseOnDisconnect: widgetPauseOnDisconnect,
                widgetResumeOnConnect: widgetResumeOnConnect,
                sleepTimerMinutes: sleepTimerMinutes,
                sleepTimerFinishTrack: sleepTimerFinishTrack,
                homeSectionsJson: homeSectionsJson,
                librarySortJson: librarySortJson,
                videoBackgroundEnabled: videoBackgroundEnabled,
                playerVisualizerStyle: playerVisualizerStyle,
                playerVisualScene: playerVisualScene,
                playerSceneAspectRatio: playerSceneAspectRatio,
                playerControlPreset: playerControlPreset,
                playerControlLayoutJson: playerControlLayoutJson,
                playerControlHandedness: playerControlHandedness,
                playerDensity: playerDensity,
                playerGestureDoubleTap: playerGestureDoubleTap,
                playerGestureSwipeTrack: playerGestureSwipeTrack,
                playerGestureSwipeVolume: playerGestureSwipeVolume,
                playerGestureSwipeDismiss: playerGestureSwipeDismiss,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$NuvTuneDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$NuvTuneDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$SongVideoIdsTableCreateCompanionBuilder =
    SongVideoIdsCompanion Function({
      required String songKey,
      required String videoId,
      Value<String> source,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });
typedef $$SongVideoIdsTableUpdateCompanionBuilder =
    SongVideoIdsCompanion Function({
      Value<String> songKey,
      Value<String> videoId,
      Value<String> source,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });

class $$SongVideoIdsTableFilterComposer
    extends Composer<_$NuvTuneDatabase, $SongVideoIdsTable> {
  $$SongVideoIdsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get songKey => $composableBuilder(
    column: $table.songKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SongVideoIdsTableOrderingComposer
    extends Composer<_$NuvTuneDatabase, $SongVideoIdsTable> {
  $$SongVideoIdsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get songKey => $composableBuilder(
    column: $table.songKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SongVideoIdsTableAnnotationComposer
    extends Composer<_$NuvTuneDatabase, $SongVideoIdsTable> {
  $$SongVideoIdsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get songKey =>
      $composableBuilder(column: $table.songKey, builder: (column) => column);

  GeneratedColumn<String> get videoId =>
      $composableBuilder(column: $table.videoId, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$SongVideoIdsTableTableManager
    extends
        RootTableManager<
          _$NuvTuneDatabase,
          $SongVideoIdsTable,
          SongVideoId,
          $$SongVideoIdsTableFilterComposer,
          $$SongVideoIdsTableOrderingComposer,
          $$SongVideoIdsTableAnnotationComposer,
          $$SongVideoIdsTableCreateCompanionBuilder,
          $$SongVideoIdsTableUpdateCompanionBuilder,
          (
            SongVideoId,
            BaseReferences<_$NuvTuneDatabase, $SongVideoIdsTable, SongVideoId>,
          ),
          SongVideoId,
          PrefetchHooks Function()
        > {
  $$SongVideoIdsTableTableManager(
    _$NuvTuneDatabase db,
    $SongVideoIdsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SongVideoIdsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SongVideoIdsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SongVideoIdsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> songKey = const Value.absent(),
                Value<String> videoId = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SongVideoIdsCompanion(
                songKey: songKey,
                videoId: videoId,
                source: source,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String songKey,
                required String videoId,
                Value<String> source = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SongVideoIdsCompanion.insert(
                songKey: songKey,
                videoId: videoId,
                source: source,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SongVideoIdsTableProcessedTableManager =
    ProcessedTableManager<
      _$NuvTuneDatabase,
      $SongVideoIdsTable,
      SongVideoId,
      $$SongVideoIdsTableFilterComposer,
      $$SongVideoIdsTableOrderingComposer,
      $$SongVideoIdsTableAnnotationComposer,
      $$SongVideoIdsTableCreateCompanionBuilder,
      $$SongVideoIdsTableUpdateCompanionBuilder,
      (
        SongVideoId,
        BaseReferences<_$NuvTuneDatabase, $SongVideoIdsTable, SongVideoId>,
      ),
      SongVideoId,
      PrefetchHooks Function()
    >;

class $NuvTuneDatabaseManager {
  final _$NuvTuneDatabase _db;
  $NuvTuneDatabaseManager(this._db);
  $$FavoritesTableTableManager get favorites =>
      $$FavoritesTableTableManager(_db, _db.favorites);
  $$PlaylistsTableTableManager get playlists =>
      $$PlaylistsTableTableManager(_db, _db.playlists);
  $$PlaylistEntriesTableTableManager get playlistEntries =>
      $$PlaylistEntriesTableTableManager(_db, _db.playlistEntries);
  $$PlayHistoryTableTableManager get playHistory =>
      $$PlayHistoryTableTableManager(_db, _db.playHistory);
  $$PlayCountsTableTableManager get playCounts =>
      $$PlayCountsTableTableManager(_db, _db.playCounts);
  $$QueueEntriesTableTableManager get queueEntries =>
      $$QueueEntriesTableTableManager(_db, _db.queueEntries);
  $$QueueStateTableTableManager get queueState =>
      $$QueueStateTableTableManager(_db, _db.queueState);
  $$ExcludedFoldersTableTableManager get excludedFolders =>
      $$ExcludedFoldersTableTableManager(_db, _db.excludedFolders);
  $$SourceFoldersTableTableManager get sourceFolders =>
      $$SourceFoldersTableTableManager(_db, _db.sourceFolders);
  $$CustomCoversTableTableManager get customCovers =>
      $$CustomCoversTableTableManager(_db, _db.customCovers);
  $$EqualizerPresetsTableTableTableManager get equalizerPresetsTable =>
      $$EqualizerPresetsTableTableTableManager(_db, _db.equalizerPresetsTable);
  $$EqualizerStateTableTableManager get equalizerState =>
      $$EqualizerStateTableTableManager(_db, _db.equalizerState);
  $$EnhancementStateTableTableManager get enhancementState =>
      $$EnhancementStateTableTableManager(_db, _db.enhancementState);
  $$OutputProfilesTableTableManager get outputProfiles =>
      $$OutputProfilesTableTableManager(_db, _db.outputProfiles);
  $$LoudnessAnalysesTableTableManager get loudnessAnalyses =>
      $$LoudnessAnalysesTableTableManager(_db, _db.loudnessAnalyses);
  $$SavedRadiosTableTableManager get savedRadios =>
      $$SavedRadiosTableTableManager(_db, _db.savedRadios);
  $$LyricsOverridesTableTableManager get lyricsOverrides =>
      $$LyricsOverridesTableTableManager(_db, _db.lyricsOverrides);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$SongVideoIdsTableTableManager get songVideoIds =>
      $$SongVideoIdsTableTableManager(_db, _db.songVideoIds);
}
