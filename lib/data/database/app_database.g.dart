// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [name, value];
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
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {name};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String name;
  final String value;
  const AppSetting({required this.name, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(name: Value(name), value: Value(value));
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      name: serializer.fromJson<String>(json['name']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({String? name, String? value}) =>
      AppSetting(name: name ?? this.name, value: value ?? this.value);
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      name: data.name.present ? data.name.value : this.name,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('name: $name, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(name, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.name == this.name &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> name;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.name = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String name,
    required String value,
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? name,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? name,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      name: name ?? this.name,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('name: $name, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MediaItemsTable extends MediaItems
    with TableInfo<$MediaItemsTable, MediaItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaItemsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _sourceMediaIdMeta = const VerificationMeta(
    'sourceMediaId',
  );
  @override
  late final GeneratedColumn<String> sourceMediaId = GeneratedColumn<String>(
    'source_media_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateTakenMillisMeta = const VerificationMeta(
    'dateTakenMillis',
  );
  @override
  late final GeneratedColumn<int> dateTakenMillis = GeneratedColumn<int>(
    'date_taken_millis',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateModifiedMillisMeta =
      const VerificationMeta('dateModifiedMillis');
  @override
  late final GeneratedColumn<int> dateModifiedMillis = GeneratedColumn<int>(
    'date_modified_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relativePathMeta = const VerificationMeta(
    'relativePath',
  );
  @override
  late final GeneratedColumn<String> relativePath = GeneratedColumn<String>(
    'relative_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MediaKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<MediaKind>($MediaItemsTable.$converterkind);
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TransferStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TransferStatus>($MediaItemsTable.$converterstatus);
  static const VerificationMeta _firstSeenAtMeta = const VerificationMeta(
    'firstSeenAt',
  );
  @override
  late final GeneratedColumn<DateTime> firstSeenAt = GeneratedColumn<DateTime>(
    'first_seen_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transferredAtMeta = const VerificationMeta(
    'transferredAt',
  );
  @override
  late final GeneratedColumn<DateTime> transferredAt =
      GeneratedColumn<DateTime>(
        'transferred_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _receiverAcknowledgementIdMeta =
      const VerificationMeta('receiverAcknowledgementId');
  @override
  late final GeneratedColumn<String> receiverAcknowledgementId =
      GeneratedColumn<String>(
        'receiver_acknowledgement_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _removedFromLibraryAtMeta =
      const VerificationMeta('removedFromLibraryAt');
  @override
  late final GeneratedColumn<DateTime> removedFromLibraryAt =
      GeneratedColumn<DateTime>(
        'removed_from_library_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceMediaId,
    displayName,
    mimeType,
    sizeBytes,
    dateTakenMillis,
    dateModifiedMillis,
    relativePath,
    kind,
    sha256,
    status,
    firstSeenAt,
    transferredAt,
    receiverAcknowledgementId,
    lastError,
    removedFromLibraryAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<MediaItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source_media_id')) {
      context.handle(
        _sourceMediaIdMeta,
        sourceMediaId.isAcceptableOrUnknown(
          data['source_media_id']!,
          _sourceMediaIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceMediaIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('date_taken_millis')) {
      context.handle(
        _dateTakenMillisMeta,
        dateTakenMillis.isAcceptableOrUnknown(
          data['date_taken_millis']!,
          _dateTakenMillisMeta,
        ),
      );
    }
    if (data.containsKey('date_modified_millis')) {
      context.handle(
        _dateModifiedMillisMeta,
        dateModifiedMillis.isAcceptableOrUnknown(
          data['date_modified_millis']!,
          _dateModifiedMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dateModifiedMillisMeta);
    }
    if (data.containsKey('relative_path')) {
      context.handle(
        _relativePathMeta,
        relativePath.isAcceptableOrUnknown(
          data['relative_path']!,
          _relativePathMeta,
        ),
      );
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    }
    if (data.containsKey('first_seen_at')) {
      context.handle(
        _firstSeenAtMeta,
        firstSeenAt.isAcceptableOrUnknown(
          data['first_seen_at']!,
          _firstSeenAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_firstSeenAtMeta);
    }
    if (data.containsKey('transferred_at')) {
      context.handle(
        _transferredAtMeta,
        transferredAt.isAcceptableOrUnknown(
          data['transferred_at']!,
          _transferredAtMeta,
        ),
      );
    }
    if (data.containsKey('receiver_acknowledgement_id')) {
      context.handle(
        _receiverAcknowledgementIdMeta,
        receiverAcknowledgementId.isAcceptableOrUnknown(
          data['receiver_acknowledgement_id']!,
          _receiverAcknowledgementIdMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('removed_from_library_at')) {
      context.handle(
        _removedFromLibraryAtMeta,
        removedFromLibraryAt.isAcceptableOrUnknown(
          data['removed_from_library_at']!,
          _removedFromLibraryAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MediaItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sourceMediaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_media_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      dateTakenMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date_taken_millis'],
      ),
      dateModifiedMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date_modified_millis'],
      )!,
      relativePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relative_path'],
      ),
      kind: $MediaItemsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      ),
      status: $MediaItemsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      firstSeenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}first_seen_at'],
      )!,
      transferredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}transferred_at'],
      ),
      receiverAcknowledgementId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receiver_acknowledgement_id'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      removedFromLibraryAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}removed_from_library_at'],
      ),
    );
  }

  @override
  $MediaItemsTable createAlias(String alias) {
    return $MediaItemsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MediaKind, String, String> $converterkind =
      const EnumNameConverter<MediaKind>(MediaKind.values);
  static JsonTypeConverter2<TransferStatus, String, String> $converterstatus =
      const EnumNameConverter<TransferStatus>(TransferStatus.values);
}

class MediaItem extends DataClass implements Insertable<MediaItem> {
  final int id;

  /// MediaStore `_id`. Can change after a restore or re-index.
  final String sourceMediaId;
  final String displayName;
  final String mimeType;
  final int sizeBytes;

  /// MediaStore `DATE_TAKEN`, or `DATE_ADDED` when the file has none.
  final int? dateTakenMillis;
  final int dateModifiedMillis;
  final String? relativePath;
  final MediaKind kind;

  /// Filled in during transfer (Milestone 4).
  final String? sha256;
  final TransferStatus status;
  final DateTime firstSeenAt;
  final DateTime? transferredAt;
  final String? receiverAcknowledgementId;
  final String? lastError;

  /// Set when the file is no longer in the media library. The row stays as
  /// history and is never deleted automatically.
  final DateTime? removedFromLibraryAt;
  const MediaItem({
    required this.id,
    required this.sourceMediaId,
    required this.displayName,
    required this.mimeType,
    required this.sizeBytes,
    this.dateTakenMillis,
    required this.dateModifiedMillis,
    this.relativePath,
    required this.kind,
    this.sha256,
    required this.status,
    required this.firstSeenAt,
    this.transferredAt,
    this.receiverAcknowledgementId,
    this.lastError,
    this.removedFromLibraryAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['source_media_id'] = Variable<String>(sourceMediaId);
    map['display_name'] = Variable<String>(displayName);
    map['mime_type'] = Variable<String>(mimeType);
    map['size_bytes'] = Variable<int>(sizeBytes);
    if (!nullToAbsent || dateTakenMillis != null) {
      map['date_taken_millis'] = Variable<int>(dateTakenMillis);
    }
    map['date_modified_millis'] = Variable<int>(dateModifiedMillis);
    if (!nullToAbsent || relativePath != null) {
      map['relative_path'] = Variable<String>(relativePath);
    }
    {
      map['kind'] = Variable<String>(
        $MediaItemsTable.$converterkind.toSql(kind),
      );
    }
    if (!nullToAbsent || sha256 != null) {
      map['sha256'] = Variable<String>(sha256);
    }
    {
      map['status'] = Variable<String>(
        $MediaItemsTable.$converterstatus.toSql(status),
      );
    }
    map['first_seen_at'] = Variable<DateTime>(firstSeenAt);
    if (!nullToAbsent || transferredAt != null) {
      map['transferred_at'] = Variable<DateTime>(transferredAt);
    }
    if (!nullToAbsent || receiverAcknowledgementId != null) {
      map['receiver_acknowledgement_id'] = Variable<String>(
        receiverAcknowledgementId,
      );
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || removedFromLibraryAt != null) {
      map['removed_from_library_at'] = Variable<DateTime>(removedFromLibraryAt);
    }
    return map;
  }

  MediaItemsCompanion toCompanion(bool nullToAbsent) {
    return MediaItemsCompanion(
      id: Value(id),
      sourceMediaId: Value(sourceMediaId),
      displayName: Value(displayName),
      mimeType: Value(mimeType),
      sizeBytes: Value(sizeBytes),
      dateTakenMillis: dateTakenMillis == null && nullToAbsent
          ? const Value.absent()
          : Value(dateTakenMillis),
      dateModifiedMillis: Value(dateModifiedMillis),
      relativePath: relativePath == null && nullToAbsent
          ? const Value.absent()
          : Value(relativePath),
      kind: Value(kind),
      sha256: sha256 == null && nullToAbsent
          ? const Value.absent()
          : Value(sha256),
      status: Value(status),
      firstSeenAt: Value(firstSeenAt),
      transferredAt: transferredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(transferredAt),
      receiverAcknowledgementId:
          receiverAcknowledgementId == null && nullToAbsent
          ? const Value.absent()
          : Value(receiverAcknowledgementId),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      removedFromLibraryAt: removedFromLibraryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(removedFromLibraryAt),
    );
  }

  factory MediaItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaItem(
      id: serializer.fromJson<int>(json['id']),
      sourceMediaId: serializer.fromJson<String>(json['sourceMediaId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      dateTakenMillis: serializer.fromJson<int?>(json['dateTakenMillis']),
      dateModifiedMillis: serializer.fromJson<int>(json['dateModifiedMillis']),
      relativePath: serializer.fromJson<String?>(json['relativePath']),
      kind: $MediaItemsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      sha256: serializer.fromJson<String?>(json['sha256']),
      status: $MediaItemsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      firstSeenAt: serializer.fromJson<DateTime>(json['firstSeenAt']),
      transferredAt: serializer.fromJson<DateTime?>(json['transferredAt']),
      receiverAcknowledgementId: serializer.fromJson<String?>(
        json['receiverAcknowledgementId'],
      ),
      lastError: serializer.fromJson<String?>(json['lastError']),
      removedFromLibraryAt: serializer.fromJson<DateTime?>(
        json['removedFromLibraryAt'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sourceMediaId': serializer.toJson<String>(sourceMediaId),
      'displayName': serializer.toJson<String>(displayName),
      'mimeType': serializer.toJson<String>(mimeType),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'dateTakenMillis': serializer.toJson<int?>(dateTakenMillis),
      'dateModifiedMillis': serializer.toJson<int>(dateModifiedMillis),
      'relativePath': serializer.toJson<String?>(relativePath),
      'kind': serializer.toJson<String>(
        $MediaItemsTable.$converterkind.toJson(kind),
      ),
      'sha256': serializer.toJson<String?>(sha256),
      'status': serializer.toJson<String>(
        $MediaItemsTable.$converterstatus.toJson(status),
      ),
      'firstSeenAt': serializer.toJson<DateTime>(firstSeenAt),
      'transferredAt': serializer.toJson<DateTime?>(transferredAt),
      'receiverAcknowledgementId': serializer.toJson<String?>(
        receiverAcknowledgementId,
      ),
      'lastError': serializer.toJson<String?>(lastError),
      'removedFromLibraryAt': serializer.toJson<DateTime?>(
        removedFromLibraryAt,
      ),
    };
  }

  MediaItem copyWith({
    int? id,
    String? sourceMediaId,
    String? displayName,
    String? mimeType,
    int? sizeBytes,
    Value<int?> dateTakenMillis = const Value.absent(),
    int? dateModifiedMillis,
    Value<String?> relativePath = const Value.absent(),
    MediaKind? kind,
    Value<String?> sha256 = const Value.absent(),
    TransferStatus? status,
    DateTime? firstSeenAt,
    Value<DateTime?> transferredAt = const Value.absent(),
    Value<String?> receiverAcknowledgementId = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    Value<DateTime?> removedFromLibraryAt = const Value.absent(),
  }) => MediaItem(
    id: id ?? this.id,
    sourceMediaId: sourceMediaId ?? this.sourceMediaId,
    displayName: displayName ?? this.displayName,
    mimeType: mimeType ?? this.mimeType,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    dateTakenMillis: dateTakenMillis.present
        ? dateTakenMillis.value
        : this.dateTakenMillis,
    dateModifiedMillis: dateModifiedMillis ?? this.dateModifiedMillis,
    relativePath: relativePath.present ? relativePath.value : this.relativePath,
    kind: kind ?? this.kind,
    sha256: sha256.present ? sha256.value : this.sha256,
    status: status ?? this.status,
    firstSeenAt: firstSeenAt ?? this.firstSeenAt,
    transferredAt: transferredAt.present
        ? transferredAt.value
        : this.transferredAt,
    receiverAcknowledgementId: receiverAcknowledgementId.present
        ? receiverAcknowledgementId.value
        : this.receiverAcknowledgementId,
    lastError: lastError.present ? lastError.value : this.lastError,
    removedFromLibraryAt: removedFromLibraryAt.present
        ? removedFromLibraryAt.value
        : this.removedFromLibraryAt,
  );
  MediaItem copyWithCompanion(MediaItemsCompanion data) {
    return MediaItem(
      id: data.id.present ? data.id.value : this.id,
      sourceMediaId: data.sourceMediaId.present
          ? data.sourceMediaId.value
          : this.sourceMediaId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      dateTakenMillis: data.dateTakenMillis.present
          ? data.dateTakenMillis.value
          : this.dateTakenMillis,
      dateModifiedMillis: data.dateModifiedMillis.present
          ? data.dateModifiedMillis.value
          : this.dateModifiedMillis,
      relativePath: data.relativePath.present
          ? data.relativePath.value
          : this.relativePath,
      kind: data.kind.present ? data.kind.value : this.kind,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      status: data.status.present ? data.status.value : this.status,
      firstSeenAt: data.firstSeenAt.present
          ? data.firstSeenAt.value
          : this.firstSeenAt,
      transferredAt: data.transferredAt.present
          ? data.transferredAt.value
          : this.transferredAt,
      receiverAcknowledgementId: data.receiverAcknowledgementId.present
          ? data.receiverAcknowledgementId.value
          : this.receiverAcknowledgementId,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      removedFromLibraryAt: data.removedFromLibraryAt.present
          ? data.removedFromLibraryAt.value
          : this.removedFromLibraryAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaItem(')
          ..write('id: $id, ')
          ..write('sourceMediaId: $sourceMediaId, ')
          ..write('displayName: $displayName, ')
          ..write('mimeType: $mimeType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('dateTakenMillis: $dateTakenMillis, ')
          ..write('dateModifiedMillis: $dateModifiedMillis, ')
          ..write('relativePath: $relativePath, ')
          ..write('kind: $kind, ')
          ..write('sha256: $sha256, ')
          ..write('status: $status, ')
          ..write('firstSeenAt: $firstSeenAt, ')
          ..write('transferredAt: $transferredAt, ')
          ..write('receiverAcknowledgementId: $receiverAcknowledgementId, ')
          ..write('lastError: $lastError, ')
          ..write('removedFromLibraryAt: $removedFromLibraryAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceMediaId,
    displayName,
    mimeType,
    sizeBytes,
    dateTakenMillis,
    dateModifiedMillis,
    relativePath,
    kind,
    sha256,
    status,
    firstSeenAt,
    transferredAt,
    receiverAcknowledgementId,
    lastError,
    removedFromLibraryAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaItem &&
          other.id == this.id &&
          other.sourceMediaId == this.sourceMediaId &&
          other.displayName == this.displayName &&
          other.mimeType == this.mimeType &&
          other.sizeBytes == this.sizeBytes &&
          other.dateTakenMillis == this.dateTakenMillis &&
          other.dateModifiedMillis == this.dateModifiedMillis &&
          other.relativePath == this.relativePath &&
          other.kind == this.kind &&
          other.sha256 == this.sha256 &&
          other.status == this.status &&
          other.firstSeenAt == this.firstSeenAt &&
          other.transferredAt == this.transferredAt &&
          other.receiverAcknowledgementId == this.receiverAcknowledgementId &&
          other.lastError == this.lastError &&
          other.removedFromLibraryAt == this.removedFromLibraryAt);
}

class MediaItemsCompanion extends UpdateCompanion<MediaItem> {
  final Value<int> id;
  final Value<String> sourceMediaId;
  final Value<String> displayName;
  final Value<String> mimeType;
  final Value<int> sizeBytes;
  final Value<int?> dateTakenMillis;
  final Value<int> dateModifiedMillis;
  final Value<String?> relativePath;
  final Value<MediaKind> kind;
  final Value<String?> sha256;
  final Value<TransferStatus> status;
  final Value<DateTime> firstSeenAt;
  final Value<DateTime?> transferredAt;
  final Value<String?> receiverAcknowledgementId;
  final Value<String?> lastError;
  final Value<DateTime?> removedFromLibraryAt;
  const MediaItemsCompanion({
    this.id = const Value.absent(),
    this.sourceMediaId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.dateTakenMillis = const Value.absent(),
    this.dateModifiedMillis = const Value.absent(),
    this.relativePath = const Value.absent(),
    this.kind = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.status = const Value.absent(),
    this.firstSeenAt = const Value.absent(),
    this.transferredAt = const Value.absent(),
    this.receiverAcknowledgementId = const Value.absent(),
    this.lastError = const Value.absent(),
    this.removedFromLibraryAt = const Value.absent(),
  });
  MediaItemsCompanion.insert({
    this.id = const Value.absent(),
    required String sourceMediaId,
    required String displayName,
    required String mimeType,
    required int sizeBytes,
    this.dateTakenMillis = const Value.absent(),
    required int dateModifiedMillis,
    this.relativePath = const Value.absent(),
    required MediaKind kind,
    this.sha256 = const Value.absent(),
    required TransferStatus status,
    required DateTime firstSeenAt,
    this.transferredAt = const Value.absent(),
    this.receiverAcknowledgementId = const Value.absent(),
    this.lastError = const Value.absent(),
    this.removedFromLibraryAt = const Value.absent(),
  }) : sourceMediaId = Value(sourceMediaId),
       displayName = Value(displayName),
       mimeType = Value(mimeType),
       sizeBytes = Value(sizeBytes),
       dateModifiedMillis = Value(dateModifiedMillis),
       kind = Value(kind),
       status = Value(status),
       firstSeenAt = Value(firstSeenAt);
  static Insertable<MediaItem> custom({
    Expression<int>? id,
    Expression<String>? sourceMediaId,
    Expression<String>? displayName,
    Expression<String>? mimeType,
    Expression<int>? sizeBytes,
    Expression<int>? dateTakenMillis,
    Expression<int>? dateModifiedMillis,
    Expression<String>? relativePath,
    Expression<String>? kind,
    Expression<String>? sha256,
    Expression<String>? status,
    Expression<DateTime>? firstSeenAt,
    Expression<DateTime>? transferredAt,
    Expression<String>? receiverAcknowledgementId,
    Expression<String>? lastError,
    Expression<DateTime>? removedFromLibraryAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceMediaId != null) 'source_media_id': sourceMediaId,
      if (displayName != null) 'display_name': displayName,
      if (mimeType != null) 'mime_type': mimeType,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (dateTakenMillis != null) 'date_taken_millis': dateTakenMillis,
      if (dateModifiedMillis != null)
        'date_modified_millis': dateModifiedMillis,
      if (relativePath != null) 'relative_path': relativePath,
      if (kind != null) 'kind': kind,
      if (sha256 != null) 'sha256': sha256,
      if (status != null) 'status': status,
      if (firstSeenAt != null) 'first_seen_at': firstSeenAt,
      if (transferredAt != null) 'transferred_at': transferredAt,
      if (receiverAcknowledgementId != null)
        'receiver_acknowledgement_id': receiverAcknowledgementId,
      if (lastError != null) 'last_error': lastError,
      if (removedFromLibraryAt != null)
        'removed_from_library_at': removedFromLibraryAt,
    });
  }

  MediaItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? sourceMediaId,
    Value<String>? displayName,
    Value<String>? mimeType,
    Value<int>? sizeBytes,
    Value<int?>? dateTakenMillis,
    Value<int>? dateModifiedMillis,
    Value<String?>? relativePath,
    Value<MediaKind>? kind,
    Value<String?>? sha256,
    Value<TransferStatus>? status,
    Value<DateTime>? firstSeenAt,
    Value<DateTime?>? transferredAt,
    Value<String?>? receiverAcknowledgementId,
    Value<String?>? lastError,
    Value<DateTime?>? removedFromLibraryAt,
  }) {
    return MediaItemsCompanion(
      id: id ?? this.id,
      sourceMediaId: sourceMediaId ?? this.sourceMediaId,
      displayName: displayName ?? this.displayName,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      dateTakenMillis: dateTakenMillis ?? this.dateTakenMillis,
      dateModifiedMillis: dateModifiedMillis ?? this.dateModifiedMillis,
      relativePath: relativePath ?? this.relativePath,
      kind: kind ?? this.kind,
      sha256: sha256 ?? this.sha256,
      status: status ?? this.status,
      firstSeenAt: firstSeenAt ?? this.firstSeenAt,
      transferredAt: transferredAt ?? this.transferredAt,
      receiverAcknowledgementId:
          receiverAcknowledgementId ?? this.receiverAcknowledgementId,
      lastError: lastError ?? this.lastError,
      removedFromLibraryAt: removedFromLibraryAt ?? this.removedFromLibraryAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sourceMediaId.present) {
      map['source_media_id'] = Variable<String>(sourceMediaId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (dateTakenMillis.present) {
      map['date_taken_millis'] = Variable<int>(dateTakenMillis.value);
    }
    if (dateModifiedMillis.present) {
      map['date_modified_millis'] = Variable<int>(dateModifiedMillis.value);
    }
    if (relativePath.present) {
      map['relative_path'] = Variable<String>(relativePath.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $MediaItemsTable.$converterkind.toSql(kind.value),
      );
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $MediaItemsTable.$converterstatus.toSql(status.value),
      );
    }
    if (firstSeenAt.present) {
      map['first_seen_at'] = Variable<DateTime>(firstSeenAt.value);
    }
    if (transferredAt.present) {
      map['transferred_at'] = Variable<DateTime>(transferredAt.value);
    }
    if (receiverAcknowledgementId.present) {
      map['receiver_acknowledgement_id'] = Variable<String>(
        receiverAcknowledgementId.value,
      );
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (removedFromLibraryAt.present) {
      map['removed_from_library_at'] = Variable<DateTime>(
        removedFromLibraryAt.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaItemsCompanion(')
          ..write('id: $id, ')
          ..write('sourceMediaId: $sourceMediaId, ')
          ..write('displayName: $displayName, ')
          ..write('mimeType: $mimeType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('dateTakenMillis: $dateTakenMillis, ')
          ..write('dateModifiedMillis: $dateModifiedMillis, ')
          ..write('relativePath: $relativePath, ')
          ..write('kind: $kind, ')
          ..write('sha256: $sha256, ')
          ..write('status: $status, ')
          ..write('firstSeenAt: $firstSeenAt, ')
          ..write('transferredAt: $transferredAt, ')
          ..write('receiverAcknowledgementId: $receiverAcknowledgementId, ')
          ..write('lastError: $lastError, ')
          ..write('removedFromLibraryAt: $removedFromLibraryAt')
          ..write(')'))
        .toString();
  }
}

class $PairedDevicesTable extends PairedDevices
    with TableInfo<$PairedDevicesTable, PairedDevice> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PairedDevicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DeviceRole, String> peerRole =
      GeneratedColumn<String>(
        'peer_role',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DeviceRole>($PairedDevicesTable.$converterpeerRole);
  static const VerificationMeta _certificateFingerprintMeta =
      const VerificationMeta('certificateFingerprint');
  @override
  late final GeneratedColumn<String> certificateFingerprint =
      GeneratedColumn<String>(
        'certificate_fingerprint',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _authTokenHashMeta = const VerificationMeta(
    'authTokenHash',
  );
  @override
  late final GeneratedColumn<String> authTokenHash = GeneratedColumn<String>(
    'auth_token_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastKnownHostMeta = const VerificationMeta(
    'lastKnownHost',
  );
  @override
  late final GeneratedColumn<String> lastKnownHost = GeneratedColumn<String>(
    'last_known_host',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastKnownPortMeta = const VerificationMeta(
    'lastKnownPort',
  );
  @override
  late final GeneratedColumn<int> lastKnownPort = GeneratedColumn<int>(
    'last_known_port',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pairedAtMeta = const VerificationMeta(
    'pairedAt',
  );
  @override
  late final GeneratedColumn<DateTime> pairedAt = GeneratedColumn<DateTime>(
    'paired_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSeenAtMeta = const VerificationMeta(
    'lastSeenAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSeenAt = GeneratedColumn<DateTime>(
    'last_seen_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    deviceId,
    displayName,
    peerRole,
    certificateFingerprint,
    authTokenHash,
    lastKnownHost,
    lastKnownPort,
    pairedAt,
    lastSeenAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'paired_devices';
  @override
  VerificationContext validateIntegrity(
    Insertable<PairedDevice> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('certificate_fingerprint')) {
      context.handle(
        _certificateFingerprintMeta,
        certificateFingerprint.isAcceptableOrUnknown(
          data['certificate_fingerprint']!,
          _certificateFingerprintMeta,
        ),
      );
    }
    if (data.containsKey('auth_token_hash')) {
      context.handle(
        _authTokenHashMeta,
        authTokenHash.isAcceptableOrUnknown(
          data['auth_token_hash']!,
          _authTokenHashMeta,
        ),
      );
    }
    if (data.containsKey('last_known_host')) {
      context.handle(
        _lastKnownHostMeta,
        lastKnownHost.isAcceptableOrUnknown(
          data['last_known_host']!,
          _lastKnownHostMeta,
        ),
      );
    }
    if (data.containsKey('last_known_port')) {
      context.handle(
        _lastKnownPortMeta,
        lastKnownPort.isAcceptableOrUnknown(
          data['last_known_port']!,
          _lastKnownPortMeta,
        ),
      );
    }
    if (data.containsKey('paired_at')) {
      context.handle(
        _pairedAtMeta,
        pairedAt.isAcceptableOrUnknown(data['paired_at']!, _pairedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_pairedAtMeta);
    }
    if (data.containsKey('last_seen_at')) {
      context.handle(
        _lastSeenAtMeta,
        lastSeenAt.isAcceptableOrUnknown(
          data['last_seen_at']!,
          _lastSeenAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId};
  @override
  PairedDevice map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PairedDevice(
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      peerRole: $PairedDevicesTable.$converterpeerRole.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}peer_role'],
        )!,
      ),
      certificateFingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}certificate_fingerprint'],
      ),
      authTokenHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}auth_token_hash'],
      ),
      lastKnownHost: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_known_host'],
      ),
      lastKnownPort: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_known_port'],
      ),
      pairedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}paired_at'],
      )!,
      lastSeenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_seen_at'],
      ),
    );
  }

  @override
  $PairedDevicesTable createAlias(String alias) {
    return $PairedDevicesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DeviceRole, String, String> $converterpeerRole =
      const EnumNameConverter<DeviceRole>(DeviceRole.values);
}

class PairedDevice extends DataClass implements Insertable<PairedDevice> {
  final String deviceId;
  final String displayName;
  final DeviceRole peerRole;

  /// Receiver certificate SHA-256, pinned by the sender.
  final String? certificateFingerprint;

  /// SHA-256 of the sender's auth token, kept by the receiver.
  final String? authTokenHash;
  final String? lastKnownHost;
  final int? lastKnownPort;
  final DateTime pairedAt;
  final DateTime? lastSeenAt;
  const PairedDevice({
    required this.deviceId,
    required this.displayName,
    required this.peerRole,
    this.certificateFingerprint,
    this.authTokenHash,
    this.lastKnownHost,
    this.lastKnownPort,
    required this.pairedAt,
    this.lastSeenAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['display_name'] = Variable<String>(displayName);
    {
      map['peer_role'] = Variable<String>(
        $PairedDevicesTable.$converterpeerRole.toSql(peerRole),
      );
    }
    if (!nullToAbsent || certificateFingerprint != null) {
      map['certificate_fingerprint'] = Variable<String>(certificateFingerprint);
    }
    if (!nullToAbsent || authTokenHash != null) {
      map['auth_token_hash'] = Variable<String>(authTokenHash);
    }
    if (!nullToAbsent || lastKnownHost != null) {
      map['last_known_host'] = Variable<String>(lastKnownHost);
    }
    if (!nullToAbsent || lastKnownPort != null) {
      map['last_known_port'] = Variable<int>(lastKnownPort);
    }
    map['paired_at'] = Variable<DateTime>(pairedAt);
    if (!nullToAbsent || lastSeenAt != null) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt);
    }
    return map;
  }

  PairedDevicesCompanion toCompanion(bool nullToAbsent) {
    return PairedDevicesCompanion(
      deviceId: Value(deviceId),
      displayName: Value(displayName),
      peerRole: Value(peerRole),
      certificateFingerprint: certificateFingerprint == null && nullToAbsent
          ? const Value.absent()
          : Value(certificateFingerprint),
      authTokenHash: authTokenHash == null && nullToAbsent
          ? const Value.absent()
          : Value(authTokenHash),
      lastKnownHost: lastKnownHost == null && nullToAbsent
          ? const Value.absent()
          : Value(lastKnownHost),
      lastKnownPort: lastKnownPort == null && nullToAbsent
          ? const Value.absent()
          : Value(lastKnownPort),
      pairedAt: Value(pairedAt),
      lastSeenAt: lastSeenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSeenAt),
    );
  }

  factory PairedDevice.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PairedDevice(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      peerRole: $PairedDevicesTable.$converterpeerRole.fromJson(
        serializer.fromJson<String>(json['peerRole']),
      ),
      certificateFingerprint: serializer.fromJson<String?>(
        json['certificateFingerprint'],
      ),
      authTokenHash: serializer.fromJson<String?>(json['authTokenHash']),
      lastKnownHost: serializer.fromJson<String?>(json['lastKnownHost']),
      lastKnownPort: serializer.fromJson<int?>(json['lastKnownPort']),
      pairedAt: serializer.fromJson<DateTime>(json['pairedAt']),
      lastSeenAt: serializer.fromJson<DateTime?>(json['lastSeenAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'displayName': serializer.toJson<String>(displayName),
      'peerRole': serializer.toJson<String>(
        $PairedDevicesTable.$converterpeerRole.toJson(peerRole),
      ),
      'certificateFingerprint': serializer.toJson<String?>(
        certificateFingerprint,
      ),
      'authTokenHash': serializer.toJson<String?>(authTokenHash),
      'lastKnownHost': serializer.toJson<String?>(lastKnownHost),
      'lastKnownPort': serializer.toJson<int?>(lastKnownPort),
      'pairedAt': serializer.toJson<DateTime>(pairedAt),
      'lastSeenAt': serializer.toJson<DateTime?>(lastSeenAt),
    };
  }

  PairedDevice copyWith({
    String? deviceId,
    String? displayName,
    DeviceRole? peerRole,
    Value<String?> certificateFingerprint = const Value.absent(),
    Value<String?> authTokenHash = const Value.absent(),
    Value<String?> lastKnownHost = const Value.absent(),
    Value<int?> lastKnownPort = const Value.absent(),
    DateTime? pairedAt,
    Value<DateTime?> lastSeenAt = const Value.absent(),
  }) => PairedDevice(
    deviceId: deviceId ?? this.deviceId,
    displayName: displayName ?? this.displayName,
    peerRole: peerRole ?? this.peerRole,
    certificateFingerprint: certificateFingerprint.present
        ? certificateFingerprint.value
        : this.certificateFingerprint,
    authTokenHash: authTokenHash.present
        ? authTokenHash.value
        : this.authTokenHash,
    lastKnownHost: lastKnownHost.present
        ? lastKnownHost.value
        : this.lastKnownHost,
    lastKnownPort: lastKnownPort.present
        ? lastKnownPort.value
        : this.lastKnownPort,
    pairedAt: pairedAt ?? this.pairedAt,
    lastSeenAt: lastSeenAt.present ? lastSeenAt.value : this.lastSeenAt,
  );
  PairedDevice copyWithCompanion(PairedDevicesCompanion data) {
    return PairedDevice(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      peerRole: data.peerRole.present ? data.peerRole.value : this.peerRole,
      certificateFingerprint: data.certificateFingerprint.present
          ? data.certificateFingerprint.value
          : this.certificateFingerprint,
      authTokenHash: data.authTokenHash.present
          ? data.authTokenHash.value
          : this.authTokenHash,
      lastKnownHost: data.lastKnownHost.present
          ? data.lastKnownHost.value
          : this.lastKnownHost,
      lastKnownPort: data.lastKnownPort.present
          ? data.lastKnownPort.value
          : this.lastKnownPort,
      pairedAt: data.pairedAt.present ? data.pairedAt.value : this.pairedAt,
      lastSeenAt: data.lastSeenAt.present
          ? data.lastSeenAt.value
          : this.lastSeenAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PairedDevice(')
          ..write('deviceId: $deviceId, ')
          ..write('displayName: $displayName, ')
          ..write('peerRole: $peerRole, ')
          ..write('certificateFingerprint: $certificateFingerprint, ')
          ..write('authTokenHash: $authTokenHash, ')
          ..write('lastKnownHost: $lastKnownHost, ')
          ..write('lastKnownPort: $lastKnownPort, ')
          ..write('pairedAt: $pairedAt, ')
          ..write('lastSeenAt: $lastSeenAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    deviceId,
    displayName,
    peerRole,
    certificateFingerprint,
    authTokenHash,
    lastKnownHost,
    lastKnownPort,
    pairedAt,
    lastSeenAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PairedDevice &&
          other.deviceId == this.deviceId &&
          other.displayName == this.displayName &&
          other.peerRole == this.peerRole &&
          other.certificateFingerprint == this.certificateFingerprint &&
          other.authTokenHash == this.authTokenHash &&
          other.lastKnownHost == this.lastKnownHost &&
          other.lastKnownPort == this.lastKnownPort &&
          other.pairedAt == this.pairedAt &&
          other.lastSeenAt == this.lastSeenAt);
}

class PairedDevicesCompanion extends UpdateCompanion<PairedDevice> {
  final Value<String> deviceId;
  final Value<String> displayName;
  final Value<DeviceRole> peerRole;
  final Value<String?> certificateFingerprint;
  final Value<String?> authTokenHash;
  final Value<String?> lastKnownHost;
  final Value<int?> lastKnownPort;
  final Value<DateTime> pairedAt;
  final Value<DateTime?> lastSeenAt;
  final Value<int> rowid;
  const PairedDevicesCompanion({
    this.deviceId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.peerRole = const Value.absent(),
    this.certificateFingerprint = const Value.absent(),
    this.authTokenHash = const Value.absent(),
    this.lastKnownHost = const Value.absent(),
    this.lastKnownPort = const Value.absent(),
    this.pairedAt = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PairedDevicesCompanion.insert({
    required String deviceId,
    required String displayName,
    required DeviceRole peerRole,
    this.certificateFingerprint = const Value.absent(),
    this.authTokenHash = const Value.absent(),
    this.lastKnownHost = const Value.absent(),
    this.lastKnownPort = const Value.absent(),
    required DateTime pairedAt,
    this.lastSeenAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       displayName = Value(displayName),
       peerRole = Value(peerRole),
       pairedAt = Value(pairedAt);
  static Insertable<PairedDevice> custom({
    Expression<String>? deviceId,
    Expression<String>? displayName,
    Expression<String>? peerRole,
    Expression<String>? certificateFingerprint,
    Expression<String>? authTokenHash,
    Expression<String>? lastKnownHost,
    Expression<int>? lastKnownPort,
    Expression<DateTime>? pairedAt,
    Expression<DateTime>? lastSeenAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (displayName != null) 'display_name': displayName,
      if (peerRole != null) 'peer_role': peerRole,
      if (certificateFingerprint != null)
        'certificate_fingerprint': certificateFingerprint,
      if (authTokenHash != null) 'auth_token_hash': authTokenHash,
      if (lastKnownHost != null) 'last_known_host': lastKnownHost,
      if (lastKnownPort != null) 'last_known_port': lastKnownPort,
      if (pairedAt != null) 'paired_at': pairedAt,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PairedDevicesCompanion copyWith({
    Value<String>? deviceId,
    Value<String>? displayName,
    Value<DeviceRole>? peerRole,
    Value<String?>? certificateFingerprint,
    Value<String?>? authTokenHash,
    Value<String?>? lastKnownHost,
    Value<int?>? lastKnownPort,
    Value<DateTime>? pairedAt,
    Value<DateTime?>? lastSeenAt,
    Value<int>? rowid,
  }) {
    return PairedDevicesCompanion(
      deviceId: deviceId ?? this.deviceId,
      displayName: displayName ?? this.displayName,
      peerRole: peerRole ?? this.peerRole,
      certificateFingerprint:
          certificateFingerprint ?? this.certificateFingerprint,
      authTokenHash: authTokenHash ?? this.authTokenHash,
      lastKnownHost: lastKnownHost ?? this.lastKnownHost,
      lastKnownPort: lastKnownPort ?? this.lastKnownPort,
      pairedAt: pairedAt ?? this.pairedAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (peerRole.present) {
      map['peer_role'] = Variable<String>(
        $PairedDevicesTable.$converterpeerRole.toSql(peerRole.value),
      );
    }
    if (certificateFingerprint.present) {
      map['certificate_fingerprint'] = Variable<String>(
        certificateFingerprint.value,
      );
    }
    if (authTokenHash.present) {
      map['auth_token_hash'] = Variable<String>(authTokenHash.value);
    }
    if (lastKnownHost.present) {
      map['last_known_host'] = Variable<String>(lastKnownHost.value);
    }
    if (lastKnownPort.present) {
      map['last_known_port'] = Variable<int>(lastKnownPort.value);
    }
    if (pairedAt.present) {
      map['paired_at'] = Variable<DateTime>(pairedAt.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PairedDevicesCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('displayName: $displayName, ')
          ..write('peerRole: $peerRole, ')
          ..write('certificateFingerprint: $certificateFingerprint, ')
          ..write('authTokenHash: $authTokenHash, ')
          ..write('lastKnownHost: $lastKnownHost, ')
          ..write('lastKnownPort: $lastKnownPort, ')
          ..write('pairedAt: $pairedAt, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReceivedFilesTable extends ReceivedFiles
    with TableInfo<$ReceivedFilesTable, ReceivedFile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReceivedFilesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _senderDeviceIdMeta = const VerificationMeta(
    'senderDeviceId',
  );
  @override
  late final GeneratedColumn<String> senderDeviceId = GeneratedColumn<String>(
    'sender_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transferIdMeta = const VerificationMeta(
    'transferId',
  );
  @override
  late final GeneratedColumn<String> transferId = GeneratedColumn<String>(
    'transfer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceModifiedMillisMeta =
      const VerificationMeta('sourceModifiedMillis');
  @override
  late final GeneratedColumn<int> sourceModifiedMillis = GeneratedColumn<int>(
    'source_modified_millis',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originalNameMeta = const VerificationMeta(
    'originalName',
  );
  @override
  late final GeneratedColumn<String> originalName = GeneratedColumn<String>(
    'original_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _publishedMediaIdMeta = const VerificationMeta(
    'publishedMediaId',
  );
  @override
  late final GeneratedColumn<String> publishedMediaId = GeneratedColumn<String>(
    'published_media_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _publishedNameMeta = const VerificationMeta(
    'publishedName',
  );
  @override
  late final GeneratedColumn<String> publishedName = GeneratedColumn<String>(
    'published_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _acknowledgementIdMeta = const VerificationMeta(
    'acknowledgementId',
  );
  @override
  late final GeneratedColumn<String> acknowledgementId =
      GeneratedColumn<String>(
        'acknowledgement_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _receivedAtMeta = const VerificationMeta(
    'receivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> receivedAt = GeneratedColumn<DateTime>(
    'received_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    senderDeviceId,
    transferId,
    sha256,
    sizeBytes,
    sourceModifiedMillis,
    originalName,
    publishedMediaId,
    publishedName,
    acknowledgementId,
    receivedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'received_files';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReceivedFile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sender_device_id')) {
      context.handle(
        _senderDeviceIdMeta,
        senderDeviceId.isAcceptableOrUnknown(
          data['sender_device_id']!,
          _senderDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_senderDeviceIdMeta);
    }
    if (data.containsKey('transfer_id')) {
      context.handle(
        _transferIdMeta,
        transferId.isAcceptableOrUnknown(data['transfer_id']!, _transferIdMeta),
      );
    } else if (isInserting) {
      context.missing(_transferIdMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    } else if (isInserting) {
      context.missing(_sha256Meta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('source_modified_millis')) {
      context.handle(
        _sourceModifiedMillisMeta,
        sourceModifiedMillis.isAcceptableOrUnknown(
          data['source_modified_millis']!,
          _sourceModifiedMillisMeta,
        ),
      );
    }
    if (data.containsKey('original_name')) {
      context.handle(
        _originalNameMeta,
        originalName.isAcceptableOrUnknown(
          data['original_name']!,
          _originalNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalNameMeta);
    }
    if (data.containsKey('published_media_id')) {
      context.handle(
        _publishedMediaIdMeta,
        publishedMediaId.isAcceptableOrUnknown(
          data['published_media_id']!,
          _publishedMediaIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_publishedMediaIdMeta);
    }
    if (data.containsKey('published_name')) {
      context.handle(
        _publishedNameMeta,
        publishedName.isAcceptableOrUnknown(
          data['published_name']!,
          _publishedNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_publishedNameMeta);
    }
    if (data.containsKey('acknowledgement_id')) {
      context.handle(
        _acknowledgementIdMeta,
        acknowledgementId.isAcceptableOrUnknown(
          data['acknowledgement_id']!,
          _acknowledgementIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_acknowledgementIdMeta);
    }
    if (data.containsKey('received_at')) {
      context.handle(
        _receivedAtMeta,
        receivedAt.isAcceptableOrUnknown(data['received_at']!, _receivedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_receivedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReceivedFile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReceivedFile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      senderDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_device_id'],
      )!,
      transferId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transfer_id'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      sourceModifiedMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_modified_millis'],
      ),
      originalName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_name'],
      )!,
      publishedMediaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}published_media_id'],
      )!,
      publishedName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}published_name'],
      )!,
      acknowledgementId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}acknowledgement_id'],
      )!,
      receivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}received_at'],
      )!,
    );
  }

  @override
  $ReceivedFilesTable createAlias(String alias) {
    return $ReceivedFilesTable(attachedDatabase, alias);
  }
}

class ReceivedFile extends DataClass implements Insertable<ReceivedFile> {
  final int id;
  final String senderDeviceId;
  final String transferId;
  final String sha256;
  final int sizeBytes;
  final int? sourceModifiedMillis;
  final String originalName;

  /// MediaStore id of the published copy.
  final String publishedMediaId;

  /// Final name in DCIM/Camera; Android renames on a name clash.
  final String publishedName;
  final String acknowledgementId;
  final DateTime receivedAt;
  const ReceivedFile({
    required this.id,
    required this.senderDeviceId,
    required this.transferId,
    required this.sha256,
    required this.sizeBytes,
    this.sourceModifiedMillis,
    required this.originalName,
    required this.publishedMediaId,
    required this.publishedName,
    required this.acknowledgementId,
    required this.receivedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sender_device_id'] = Variable<String>(senderDeviceId);
    map['transfer_id'] = Variable<String>(transferId);
    map['sha256'] = Variable<String>(sha256);
    map['size_bytes'] = Variable<int>(sizeBytes);
    if (!nullToAbsent || sourceModifiedMillis != null) {
      map['source_modified_millis'] = Variable<int>(sourceModifiedMillis);
    }
    map['original_name'] = Variable<String>(originalName);
    map['published_media_id'] = Variable<String>(publishedMediaId);
    map['published_name'] = Variable<String>(publishedName);
    map['acknowledgement_id'] = Variable<String>(acknowledgementId);
    map['received_at'] = Variable<DateTime>(receivedAt);
    return map;
  }

  ReceivedFilesCompanion toCompanion(bool nullToAbsent) {
    return ReceivedFilesCompanion(
      id: Value(id),
      senderDeviceId: Value(senderDeviceId),
      transferId: Value(transferId),
      sha256: Value(sha256),
      sizeBytes: Value(sizeBytes),
      sourceModifiedMillis: sourceModifiedMillis == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceModifiedMillis),
      originalName: Value(originalName),
      publishedMediaId: Value(publishedMediaId),
      publishedName: Value(publishedName),
      acknowledgementId: Value(acknowledgementId),
      receivedAt: Value(receivedAt),
    );
  }

  factory ReceivedFile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReceivedFile(
      id: serializer.fromJson<int>(json['id']),
      senderDeviceId: serializer.fromJson<String>(json['senderDeviceId']),
      transferId: serializer.fromJson<String>(json['transferId']),
      sha256: serializer.fromJson<String>(json['sha256']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      sourceModifiedMillis: serializer.fromJson<int?>(
        json['sourceModifiedMillis'],
      ),
      originalName: serializer.fromJson<String>(json['originalName']),
      publishedMediaId: serializer.fromJson<String>(json['publishedMediaId']),
      publishedName: serializer.fromJson<String>(json['publishedName']),
      acknowledgementId: serializer.fromJson<String>(json['acknowledgementId']),
      receivedAt: serializer.fromJson<DateTime>(json['receivedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'senderDeviceId': serializer.toJson<String>(senderDeviceId),
      'transferId': serializer.toJson<String>(transferId),
      'sha256': serializer.toJson<String>(sha256),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'sourceModifiedMillis': serializer.toJson<int?>(sourceModifiedMillis),
      'originalName': serializer.toJson<String>(originalName),
      'publishedMediaId': serializer.toJson<String>(publishedMediaId),
      'publishedName': serializer.toJson<String>(publishedName),
      'acknowledgementId': serializer.toJson<String>(acknowledgementId),
      'receivedAt': serializer.toJson<DateTime>(receivedAt),
    };
  }

  ReceivedFile copyWith({
    int? id,
    String? senderDeviceId,
    String? transferId,
    String? sha256,
    int? sizeBytes,
    Value<int?> sourceModifiedMillis = const Value.absent(),
    String? originalName,
    String? publishedMediaId,
    String? publishedName,
    String? acknowledgementId,
    DateTime? receivedAt,
  }) => ReceivedFile(
    id: id ?? this.id,
    senderDeviceId: senderDeviceId ?? this.senderDeviceId,
    transferId: transferId ?? this.transferId,
    sha256: sha256 ?? this.sha256,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    sourceModifiedMillis: sourceModifiedMillis.present
        ? sourceModifiedMillis.value
        : this.sourceModifiedMillis,
    originalName: originalName ?? this.originalName,
    publishedMediaId: publishedMediaId ?? this.publishedMediaId,
    publishedName: publishedName ?? this.publishedName,
    acknowledgementId: acknowledgementId ?? this.acknowledgementId,
    receivedAt: receivedAt ?? this.receivedAt,
  );
  ReceivedFile copyWithCompanion(ReceivedFilesCompanion data) {
    return ReceivedFile(
      id: data.id.present ? data.id.value : this.id,
      senderDeviceId: data.senderDeviceId.present
          ? data.senderDeviceId.value
          : this.senderDeviceId,
      transferId: data.transferId.present
          ? data.transferId.value
          : this.transferId,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      sourceModifiedMillis: data.sourceModifiedMillis.present
          ? data.sourceModifiedMillis.value
          : this.sourceModifiedMillis,
      originalName: data.originalName.present
          ? data.originalName.value
          : this.originalName,
      publishedMediaId: data.publishedMediaId.present
          ? data.publishedMediaId.value
          : this.publishedMediaId,
      publishedName: data.publishedName.present
          ? data.publishedName.value
          : this.publishedName,
      acknowledgementId: data.acknowledgementId.present
          ? data.acknowledgementId.value
          : this.acknowledgementId,
      receivedAt: data.receivedAt.present
          ? data.receivedAt.value
          : this.receivedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReceivedFile(')
          ..write('id: $id, ')
          ..write('senderDeviceId: $senderDeviceId, ')
          ..write('transferId: $transferId, ')
          ..write('sha256: $sha256, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('sourceModifiedMillis: $sourceModifiedMillis, ')
          ..write('originalName: $originalName, ')
          ..write('publishedMediaId: $publishedMediaId, ')
          ..write('publishedName: $publishedName, ')
          ..write('acknowledgementId: $acknowledgementId, ')
          ..write('receivedAt: $receivedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    senderDeviceId,
    transferId,
    sha256,
    sizeBytes,
    sourceModifiedMillis,
    originalName,
    publishedMediaId,
    publishedName,
    acknowledgementId,
    receivedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReceivedFile &&
          other.id == this.id &&
          other.senderDeviceId == this.senderDeviceId &&
          other.transferId == this.transferId &&
          other.sha256 == this.sha256 &&
          other.sizeBytes == this.sizeBytes &&
          other.sourceModifiedMillis == this.sourceModifiedMillis &&
          other.originalName == this.originalName &&
          other.publishedMediaId == this.publishedMediaId &&
          other.publishedName == this.publishedName &&
          other.acknowledgementId == this.acknowledgementId &&
          other.receivedAt == this.receivedAt);
}

class ReceivedFilesCompanion extends UpdateCompanion<ReceivedFile> {
  final Value<int> id;
  final Value<String> senderDeviceId;
  final Value<String> transferId;
  final Value<String> sha256;
  final Value<int> sizeBytes;
  final Value<int?> sourceModifiedMillis;
  final Value<String> originalName;
  final Value<String> publishedMediaId;
  final Value<String> publishedName;
  final Value<String> acknowledgementId;
  final Value<DateTime> receivedAt;
  const ReceivedFilesCompanion({
    this.id = const Value.absent(),
    this.senderDeviceId = const Value.absent(),
    this.transferId = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.sourceModifiedMillis = const Value.absent(),
    this.originalName = const Value.absent(),
    this.publishedMediaId = const Value.absent(),
    this.publishedName = const Value.absent(),
    this.acknowledgementId = const Value.absent(),
    this.receivedAt = const Value.absent(),
  });
  ReceivedFilesCompanion.insert({
    this.id = const Value.absent(),
    required String senderDeviceId,
    required String transferId,
    required String sha256,
    required int sizeBytes,
    this.sourceModifiedMillis = const Value.absent(),
    required String originalName,
    required String publishedMediaId,
    required String publishedName,
    required String acknowledgementId,
    required DateTime receivedAt,
  }) : senderDeviceId = Value(senderDeviceId),
       transferId = Value(transferId),
       sha256 = Value(sha256),
       sizeBytes = Value(sizeBytes),
       originalName = Value(originalName),
       publishedMediaId = Value(publishedMediaId),
       publishedName = Value(publishedName),
       acknowledgementId = Value(acknowledgementId),
       receivedAt = Value(receivedAt);
  static Insertable<ReceivedFile> custom({
    Expression<int>? id,
    Expression<String>? senderDeviceId,
    Expression<String>? transferId,
    Expression<String>? sha256,
    Expression<int>? sizeBytes,
    Expression<int>? sourceModifiedMillis,
    Expression<String>? originalName,
    Expression<String>? publishedMediaId,
    Expression<String>? publishedName,
    Expression<String>? acknowledgementId,
    Expression<DateTime>? receivedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (senderDeviceId != null) 'sender_device_id': senderDeviceId,
      if (transferId != null) 'transfer_id': transferId,
      if (sha256 != null) 'sha256': sha256,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (sourceModifiedMillis != null)
        'source_modified_millis': sourceModifiedMillis,
      if (originalName != null) 'original_name': originalName,
      if (publishedMediaId != null) 'published_media_id': publishedMediaId,
      if (publishedName != null) 'published_name': publishedName,
      if (acknowledgementId != null) 'acknowledgement_id': acknowledgementId,
      if (receivedAt != null) 'received_at': receivedAt,
    });
  }

  ReceivedFilesCompanion copyWith({
    Value<int>? id,
    Value<String>? senderDeviceId,
    Value<String>? transferId,
    Value<String>? sha256,
    Value<int>? sizeBytes,
    Value<int?>? sourceModifiedMillis,
    Value<String>? originalName,
    Value<String>? publishedMediaId,
    Value<String>? publishedName,
    Value<String>? acknowledgementId,
    Value<DateTime>? receivedAt,
  }) {
    return ReceivedFilesCompanion(
      id: id ?? this.id,
      senderDeviceId: senderDeviceId ?? this.senderDeviceId,
      transferId: transferId ?? this.transferId,
      sha256: sha256 ?? this.sha256,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      sourceModifiedMillis: sourceModifiedMillis ?? this.sourceModifiedMillis,
      originalName: originalName ?? this.originalName,
      publishedMediaId: publishedMediaId ?? this.publishedMediaId,
      publishedName: publishedName ?? this.publishedName,
      acknowledgementId: acknowledgementId ?? this.acknowledgementId,
      receivedAt: receivedAt ?? this.receivedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (senderDeviceId.present) {
      map['sender_device_id'] = Variable<String>(senderDeviceId.value);
    }
    if (transferId.present) {
      map['transfer_id'] = Variable<String>(transferId.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (sourceModifiedMillis.present) {
      map['source_modified_millis'] = Variable<int>(sourceModifiedMillis.value);
    }
    if (originalName.present) {
      map['original_name'] = Variable<String>(originalName.value);
    }
    if (publishedMediaId.present) {
      map['published_media_id'] = Variable<String>(publishedMediaId.value);
    }
    if (publishedName.present) {
      map['published_name'] = Variable<String>(publishedName.value);
    }
    if (acknowledgementId.present) {
      map['acknowledgement_id'] = Variable<String>(acknowledgementId.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<DateTime>(receivedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReceivedFilesCompanion(')
          ..write('id: $id, ')
          ..write('senderDeviceId: $senderDeviceId, ')
          ..write('transferId: $transferId, ')
          ..write('sha256: $sha256, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('sourceModifiedMillis: $sourceModifiedMillis, ')
          ..write('originalName: $originalName, ')
          ..write('publishedMediaId: $publishedMediaId, ')
          ..write('publishedName: $publishedName, ')
          ..write('acknowledgementId: $acknowledgementId, ')
          ..write('receivedAt: $receivedAt')
          ..write(')'))
        .toString();
  }
}

class $ScheduleSettingsTableTable extends ScheduleSettingsTable
    with TableInfo<$ScheduleSettingsTableTable, ScheduleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScheduleSettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
  );
  static const VerificationMeta _hourMeta = const VerificationMeta('hour');
  @override
  late final GeneratedColumn<int> hour = GeneratedColumn<int>(
    'hour',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minuteMeta = const VerificationMeta('minute');
  @override
  late final GeneratedColumn<int> minute = GeneratedColumn<int>(
    'minute',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weekdaysMeta = const VerificationMeta(
    'weekdays',
  );
  @override
  late final GeneratedColumn<String> weekdays = GeneratedColumn<String>(
    'weekdays',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wifiOnlyMeta = const VerificationMeta(
    'wifiOnly',
  );
  @override
  late final GeneratedColumn<bool> wifiOnly = GeneratedColumn<bool>(
    'wifi_only',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("wifi_only" IN (0, 1))',
    ),
  );
  static const VerificationMeta _chargingOnlyMeta = const VerificationMeta(
    'chargingOnly',
  );
  @override
  late final GeneratedColumn<bool> chargingOnly = GeneratedColumn<bool>(
    'charging_only',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("charging_only" IN (0, 1))',
    ),
  );
  static const VerificationMeta _retryHoursMeta = const VerificationMeta(
    'retryHours',
  );
  @override
  late final GeneratedColumn<int> retryHours = GeneratedColumn<int>(
    'retry_hours',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enabledAtMeta = const VerificationMeta(
    'enabledAt',
  );
  @override
  late final GeneratedColumn<DateTime> enabledAt = GeneratedColumn<DateTime>(
    'enabled_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastOutcomeMeta = const VerificationMeta(
    'lastOutcome',
  );
  @override
  late final GeneratedColumn<String> lastOutcome = GeneratedColumn<String>(
    'last_outcome',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastMessageMeta = const VerificationMeta(
    'lastMessage',
  );
  @override
  late final GeneratedColumn<String> lastMessage = GeneratedColumn<String>(
    'last_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSuccessAtMeta = const VerificationMeta(
    'lastSuccessAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSuccessAt =
      GeneratedColumn<DateTime>(
        'last_success_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _nextRunEstimateMeta = const VerificationMeta(
    'nextRunEstimate',
  );
  @override
  late final GeneratedColumn<DateTime> nextRunEstimate =
      GeneratedColumn<DateTime>(
        'next_run_estimate',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    enabled,
    hour,
    minute,
    weekdays,
    wifiOnly,
    chargingOnly,
    retryHours,
    enabledAt,
    lastAttemptAt,
    lastOutcome,
    lastMessage,
    lastSuccessAt,
    nextRunEstimate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'schedule_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScheduleRow> instance, {
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
    } else if (isInserting) {
      context.missing(_enabledMeta);
    }
    if (data.containsKey('hour')) {
      context.handle(
        _hourMeta,
        hour.isAcceptableOrUnknown(data['hour']!, _hourMeta),
      );
    } else if (isInserting) {
      context.missing(_hourMeta);
    }
    if (data.containsKey('minute')) {
      context.handle(
        _minuteMeta,
        minute.isAcceptableOrUnknown(data['minute']!, _minuteMeta),
      );
    } else if (isInserting) {
      context.missing(_minuteMeta);
    }
    if (data.containsKey('weekdays')) {
      context.handle(
        _weekdaysMeta,
        weekdays.isAcceptableOrUnknown(data['weekdays']!, _weekdaysMeta),
      );
    } else if (isInserting) {
      context.missing(_weekdaysMeta);
    }
    if (data.containsKey('wifi_only')) {
      context.handle(
        _wifiOnlyMeta,
        wifiOnly.isAcceptableOrUnknown(data['wifi_only']!, _wifiOnlyMeta),
      );
    } else if (isInserting) {
      context.missing(_wifiOnlyMeta);
    }
    if (data.containsKey('charging_only')) {
      context.handle(
        _chargingOnlyMeta,
        chargingOnly.isAcceptableOrUnknown(
          data['charging_only']!,
          _chargingOnlyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_chargingOnlyMeta);
    }
    if (data.containsKey('retry_hours')) {
      context.handle(
        _retryHoursMeta,
        retryHours.isAcceptableOrUnknown(data['retry_hours']!, _retryHoursMeta),
      );
    } else if (isInserting) {
      context.missing(_retryHoursMeta);
    }
    if (data.containsKey('enabled_at')) {
      context.handle(
        _enabledAtMeta,
        enabledAt.isAcceptableOrUnknown(data['enabled_at']!, _enabledAtMeta),
      );
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('last_outcome')) {
      context.handle(
        _lastOutcomeMeta,
        lastOutcome.isAcceptableOrUnknown(
          data['last_outcome']!,
          _lastOutcomeMeta,
        ),
      );
    }
    if (data.containsKey('last_message')) {
      context.handle(
        _lastMessageMeta,
        lastMessage.isAcceptableOrUnknown(
          data['last_message']!,
          _lastMessageMeta,
        ),
      );
    }
    if (data.containsKey('last_success_at')) {
      context.handle(
        _lastSuccessAtMeta,
        lastSuccessAt.isAcceptableOrUnknown(
          data['last_success_at']!,
          _lastSuccessAtMeta,
        ),
      );
    }
    if (data.containsKey('next_run_estimate')) {
      context.handle(
        _nextRunEstimateMeta,
        nextRunEstimate.isAcceptableOrUnknown(
          data['next_run_estimate']!,
          _nextRunEstimateMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScheduleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScheduleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      hour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hour'],
      )!,
      minute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minute'],
      )!,
      weekdays: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weekdays'],
      )!,
      wifiOnly: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}wifi_only'],
      )!,
      chargingOnly: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}charging_only'],
      )!,
      retryHours: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_hours'],
      )!,
      enabledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}enabled_at'],
      ),
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
      lastOutcome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_outcome'],
      ),
      lastMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message'],
      ),
      lastSuccessAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_success_at'],
      ),
      nextRunEstimate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_run_estimate'],
      ),
    );
  }

  @override
  $ScheduleSettingsTableTable createAlias(String alias) {
    return $ScheduleSettingsTableTable(attachedDatabase, alias);
  }
}

class ScheduleRow extends DataClass implements Insertable<ScheduleRow> {
  final int id;
  final bool enabled;
  final int hour;
  final int minute;

  /// ISO weekdays as "1,2,3".
  final String weekdays;
  final bool wifiOnly;
  final bool chargingOnly;
  final int retryHours;
  final DateTime? enabledAt;
  final DateTime? lastAttemptAt;
  final String? lastOutcome;
  final String? lastMessage;
  final DateTime? lastSuccessAt;
  final DateTime? nextRunEstimate;
  const ScheduleRow({
    required this.id,
    required this.enabled,
    required this.hour,
    required this.minute,
    required this.weekdays,
    required this.wifiOnly,
    required this.chargingOnly,
    required this.retryHours,
    this.enabledAt,
    this.lastAttemptAt,
    this.lastOutcome,
    this.lastMessage,
    this.lastSuccessAt,
    this.nextRunEstimate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['enabled'] = Variable<bool>(enabled);
    map['hour'] = Variable<int>(hour);
    map['minute'] = Variable<int>(minute);
    map['weekdays'] = Variable<String>(weekdays);
    map['wifi_only'] = Variable<bool>(wifiOnly);
    map['charging_only'] = Variable<bool>(chargingOnly);
    map['retry_hours'] = Variable<int>(retryHours);
    if (!nullToAbsent || enabledAt != null) {
      map['enabled_at'] = Variable<DateTime>(enabledAt);
    }
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    if (!nullToAbsent || lastOutcome != null) {
      map['last_outcome'] = Variable<String>(lastOutcome);
    }
    if (!nullToAbsent || lastMessage != null) {
      map['last_message'] = Variable<String>(lastMessage);
    }
    if (!nullToAbsent || lastSuccessAt != null) {
      map['last_success_at'] = Variable<DateTime>(lastSuccessAt);
    }
    if (!nullToAbsent || nextRunEstimate != null) {
      map['next_run_estimate'] = Variable<DateTime>(nextRunEstimate);
    }
    return map;
  }

  ScheduleSettingsTableCompanion toCompanion(bool nullToAbsent) {
    return ScheduleSettingsTableCompanion(
      id: Value(id),
      enabled: Value(enabled),
      hour: Value(hour),
      minute: Value(minute),
      weekdays: Value(weekdays),
      wifiOnly: Value(wifiOnly),
      chargingOnly: Value(chargingOnly),
      retryHours: Value(retryHours),
      enabledAt: enabledAt == null && nullToAbsent
          ? const Value.absent()
          : Value(enabledAt),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      lastOutcome: lastOutcome == null && nullToAbsent
          ? const Value.absent()
          : Value(lastOutcome),
      lastMessage: lastMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessage),
      lastSuccessAt: lastSuccessAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSuccessAt),
      nextRunEstimate: nextRunEstimate == null && nullToAbsent
          ? const Value.absent()
          : Value(nextRunEstimate),
    );
  }

  factory ScheduleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScheduleRow(
      id: serializer.fromJson<int>(json['id']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      hour: serializer.fromJson<int>(json['hour']),
      minute: serializer.fromJson<int>(json['minute']),
      weekdays: serializer.fromJson<String>(json['weekdays']),
      wifiOnly: serializer.fromJson<bool>(json['wifiOnly']),
      chargingOnly: serializer.fromJson<bool>(json['chargingOnly']),
      retryHours: serializer.fromJson<int>(json['retryHours']),
      enabledAt: serializer.fromJson<DateTime?>(json['enabledAt']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      lastOutcome: serializer.fromJson<String?>(json['lastOutcome']),
      lastMessage: serializer.fromJson<String?>(json['lastMessage']),
      lastSuccessAt: serializer.fromJson<DateTime?>(json['lastSuccessAt']),
      nextRunEstimate: serializer.fromJson<DateTime?>(json['nextRunEstimate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'enabled': serializer.toJson<bool>(enabled),
      'hour': serializer.toJson<int>(hour),
      'minute': serializer.toJson<int>(minute),
      'weekdays': serializer.toJson<String>(weekdays),
      'wifiOnly': serializer.toJson<bool>(wifiOnly),
      'chargingOnly': serializer.toJson<bool>(chargingOnly),
      'retryHours': serializer.toJson<int>(retryHours),
      'enabledAt': serializer.toJson<DateTime?>(enabledAt),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'lastOutcome': serializer.toJson<String?>(lastOutcome),
      'lastMessage': serializer.toJson<String?>(lastMessage),
      'lastSuccessAt': serializer.toJson<DateTime?>(lastSuccessAt),
      'nextRunEstimate': serializer.toJson<DateTime?>(nextRunEstimate),
    };
  }

  ScheduleRow copyWith({
    int? id,
    bool? enabled,
    int? hour,
    int? minute,
    String? weekdays,
    bool? wifiOnly,
    bool? chargingOnly,
    int? retryHours,
    Value<DateTime?> enabledAt = const Value.absent(),
    Value<DateTime?> lastAttemptAt = const Value.absent(),
    Value<String?> lastOutcome = const Value.absent(),
    Value<String?> lastMessage = const Value.absent(),
    Value<DateTime?> lastSuccessAt = const Value.absent(),
    Value<DateTime?> nextRunEstimate = const Value.absent(),
  }) => ScheduleRow(
    id: id ?? this.id,
    enabled: enabled ?? this.enabled,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    weekdays: weekdays ?? this.weekdays,
    wifiOnly: wifiOnly ?? this.wifiOnly,
    chargingOnly: chargingOnly ?? this.chargingOnly,
    retryHours: retryHours ?? this.retryHours,
    enabledAt: enabledAt.present ? enabledAt.value : this.enabledAt,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    lastOutcome: lastOutcome.present ? lastOutcome.value : this.lastOutcome,
    lastMessage: lastMessage.present ? lastMessage.value : this.lastMessage,
    lastSuccessAt: lastSuccessAt.present
        ? lastSuccessAt.value
        : this.lastSuccessAt,
    nextRunEstimate: nextRunEstimate.present
        ? nextRunEstimate.value
        : this.nextRunEstimate,
  );
  ScheduleRow copyWithCompanion(ScheduleSettingsTableCompanion data) {
    return ScheduleRow(
      id: data.id.present ? data.id.value : this.id,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      hour: data.hour.present ? data.hour.value : this.hour,
      minute: data.minute.present ? data.minute.value : this.minute,
      weekdays: data.weekdays.present ? data.weekdays.value : this.weekdays,
      wifiOnly: data.wifiOnly.present ? data.wifiOnly.value : this.wifiOnly,
      chargingOnly: data.chargingOnly.present
          ? data.chargingOnly.value
          : this.chargingOnly,
      retryHours: data.retryHours.present
          ? data.retryHours.value
          : this.retryHours,
      enabledAt: data.enabledAt.present ? data.enabledAt.value : this.enabledAt,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      lastOutcome: data.lastOutcome.present
          ? data.lastOutcome.value
          : this.lastOutcome,
      lastMessage: data.lastMessage.present
          ? data.lastMessage.value
          : this.lastMessage,
      lastSuccessAt: data.lastSuccessAt.present
          ? data.lastSuccessAt.value
          : this.lastSuccessAt,
      nextRunEstimate: data.nextRunEstimate.present
          ? data.nextRunEstimate.value
          : this.nextRunEstimate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScheduleRow(')
          ..write('id: $id, ')
          ..write('enabled: $enabled, ')
          ..write('hour: $hour, ')
          ..write('minute: $minute, ')
          ..write('weekdays: $weekdays, ')
          ..write('wifiOnly: $wifiOnly, ')
          ..write('chargingOnly: $chargingOnly, ')
          ..write('retryHours: $retryHours, ')
          ..write('enabledAt: $enabledAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('lastOutcome: $lastOutcome, ')
          ..write('lastMessage: $lastMessage, ')
          ..write('lastSuccessAt: $lastSuccessAt, ')
          ..write('nextRunEstimate: $nextRunEstimate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    enabled,
    hour,
    minute,
    weekdays,
    wifiOnly,
    chargingOnly,
    retryHours,
    enabledAt,
    lastAttemptAt,
    lastOutcome,
    lastMessage,
    lastSuccessAt,
    nextRunEstimate,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScheduleRow &&
          other.id == this.id &&
          other.enabled == this.enabled &&
          other.hour == this.hour &&
          other.minute == this.minute &&
          other.weekdays == this.weekdays &&
          other.wifiOnly == this.wifiOnly &&
          other.chargingOnly == this.chargingOnly &&
          other.retryHours == this.retryHours &&
          other.enabledAt == this.enabledAt &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.lastOutcome == this.lastOutcome &&
          other.lastMessage == this.lastMessage &&
          other.lastSuccessAt == this.lastSuccessAt &&
          other.nextRunEstimate == this.nextRunEstimate);
}

class ScheduleSettingsTableCompanion extends UpdateCompanion<ScheduleRow> {
  final Value<int> id;
  final Value<bool> enabled;
  final Value<int> hour;
  final Value<int> minute;
  final Value<String> weekdays;
  final Value<bool> wifiOnly;
  final Value<bool> chargingOnly;
  final Value<int> retryHours;
  final Value<DateTime?> enabledAt;
  final Value<DateTime?> lastAttemptAt;
  final Value<String?> lastOutcome;
  final Value<String?> lastMessage;
  final Value<DateTime?> lastSuccessAt;
  final Value<DateTime?> nextRunEstimate;
  const ScheduleSettingsTableCompanion({
    this.id = const Value.absent(),
    this.enabled = const Value.absent(),
    this.hour = const Value.absent(),
    this.minute = const Value.absent(),
    this.weekdays = const Value.absent(),
    this.wifiOnly = const Value.absent(),
    this.chargingOnly = const Value.absent(),
    this.retryHours = const Value.absent(),
    this.enabledAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.lastOutcome = const Value.absent(),
    this.lastMessage = const Value.absent(),
    this.lastSuccessAt = const Value.absent(),
    this.nextRunEstimate = const Value.absent(),
  });
  ScheduleSettingsTableCompanion.insert({
    this.id = const Value.absent(),
    required bool enabled,
    required int hour,
    required int minute,
    required String weekdays,
    required bool wifiOnly,
    required bool chargingOnly,
    required int retryHours,
    this.enabledAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.lastOutcome = const Value.absent(),
    this.lastMessage = const Value.absent(),
    this.lastSuccessAt = const Value.absent(),
    this.nextRunEstimate = const Value.absent(),
  }) : enabled = Value(enabled),
       hour = Value(hour),
       minute = Value(minute),
       weekdays = Value(weekdays),
       wifiOnly = Value(wifiOnly),
       chargingOnly = Value(chargingOnly),
       retryHours = Value(retryHours);
  static Insertable<ScheduleRow> custom({
    Expression<int>? id,
    Expression<bool>? enabled,
    Expression<int>? hour,
    Expression<int>? minute,
    Expression<String>? weekdays,
    Expression<bool>? wifiOnly,
    Expression<bool>? chargingOnly,
    Expression<int>? retryHours,
    Expression<DateTime>? enabledAt,
    Expression<DateTime>? lastAttemptAt,
    Expression<String>? lastOutcome,
    Expression<String>? lastMessage,
    Expression<DateTime>? lastSuccessAt,
    Expression<DateTime>? nextRunEstimate,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (enabled != null) 'enabled': enabled,
      if (hour != null) 'hour': hour,
      if (minute != null) 'minute': minute,
      if (weekdays != null) 'weekdays': weekdays,
      if (wifiOnly != null) 'wifi_only': wifiOnly,
      if (chargingOnly != null) 'charging_only': chargingOnly,
      if (retryHours != null) 'retry_hours': retryHours,
      if (enabledAt != null) 'enabled_at': enabledAt,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (lastOutcome != null) 'last_outcome': lastOutcome,
      if (lastMessage != null) 'last_message': lastMessage,
      if (lastSuccessAt != null) 'last_success_at': lastSuccessAt,
      if (nextRunEstimate != null) 'next_run_estimate': nextRunEstimate,
    });
  }

  ScheduleSettingsTableCompanion copyWith({
    Value<int>? id,
    Value<bool>? enabled,
    Value<int>? hour,
    Value<int>? minute,
    Value<String>? weekdays,
    Value<bool>? wifiOnly,
    Value<bool>? chargingOnly,
    Value<int>? retryHours,
    Value<DateTime?>? enabledAt,
    Value<DateTime?>? lastAttemptAt,
    Value<String?>? lastOutcome,
    Value<String?>? lastMessage,
    Value<DateTime?>? lastSuccessAt,
    Value<DateTime?>? nextRunEstimate,
  }) {
    return ScheduleSettingsTableCompanion(
      id: id ?? this.id,
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      weekdays: weekdays ?? this.weekdays,
      wifiOnly: wifiOnly ?? this.wifiOnly,
      chargingOnly: chargingOnly ?? this.chargingOnly,
      retryHours: retryHours ?? this.retryHours,
      enabledAt: enabledAt ?? this.enabledAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      lastOutcome: lastOutcome ?? this.lastOutcome,
      lastMessage: lastMessage ?? this.lastMessage,
      lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
      nextRunEstimate: nextRunEstimate ?? this.nextRunEstimate,
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
    if (hour.present) {
      map['hour'] = Variable<int>(hour.value);
    }
    if (minute.present) {
      map['minute'] = Variable<int>(minute.value);
    }
    if (weekdays.present) {
      map['weekdays'] = Variable<String>(weekdays.value);
    }
    if (wifiOnly.present) {
      map['wifi_only'] = Variable<bool>(wifiOnly.value);
    }
    if (chargingOnly.present) {
      map['charging_only'] = Variable<bool>(chargingOnly.value);
    }
    if (retryHours.present) {
      map['retry_hours'] = Variable<int>(retryHours.value);
    }
    if (enabledAt.present) {
      map['enabled_at'] = Variable<DateTime>(enabledAt.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (lastOutcome.present) {
      map['last_outcome'] = Variable<String>(lastOutcome.value);
    }
    if (lastMessage.present) {
      map['last_message'] = Variable<String>(lastMessage.value);
    }
    if (lastSuccessAt.present) {
      map['last_success_at'] = Variable<DateTime>(lastSuccessAt.value);
    }
    if (nextRunEstimate.present) {
      map['next_run_estimate'] = Variable<DateTime>(nextRunEstimate.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScheduleSettingsTableCompanion(')
          ..write('id: $id, ')
          ..write('enabled: $enabled, ')
          ..write('hour: $hour, ')
          ..write('minute: $minute, ')
          ..write('weekdays: $weekdays, ')
          ..write('wifiOnly: $wifiOnly, ')
          ..write('chargingOnly: $chargingOnly, ')
          ..write('retryHours: $retryHours, ')
          ..write('enabledAt: $enabledAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('lastOutcome: $lastOutcome, ')
          ..write('lastMessage: $lastMessage, ')
          ..write('lastSuccessAt: $lastSuccessAt, ')
          ..write('nextRunEstimate: $nextRunEstimate')
          ..write(')'))
        .toString();
  }
}

class $TransferLocksTable extends TransferLocks
    with TableInfo<$TransferLocksTable, TransferLock> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransferLocksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerMeta = const VerificationMeta('owner');
  @override
  late final GeneratedColumn<String> owner = GeneratedColumn<String>(
    'owner',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMillisMeta = const VerificationMeta(
    'expiresAtMillis',
  );
  @override
  late final GeneratedColumn<int> expiresAtMillis = GeneratedColumn<int>(
    'expires_at_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [name, owner, expiresAtMillis];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transfer_locks';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransferLock> instance, {
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
    if (data.containsKey('owner')) {
      context.handle(
        _ownerMeta,
        owner.isAcceptableOrUnknown(data['owner']!, _ownerMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerMeta);
    }
    if (data.containsKey('expires_at_millis')) {
      context.handle(
        _expiresAtMillisMeta,
        expiresAtMillis.isAcceptableOrUnknown(
          data['expires_at_millis']!,
          _expiresAtMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMillisMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {name};
  @override
  TransferLock map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransferLock(
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      owner: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner'],
      )!,
      expiresAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expires_at_millis'],
      )!,
    );
  }

  @override
  $TransferLocksTable createAlias(String alias) {
    return $TransferLocksTable(attachedDatabase, alias);
  }
}

class TransferLock extends DataClass implements Insertable<TransferLock> {
  final String name;
  final String owner;
  final int expiresAtMillis;
  const TransferLock({
    required this.name,
    required this.owner,
    required this.expiresAtMillis,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    map['owner'] = Variable<String>(owner);
    map['expires_at_millis'] = Variable<int>(expiresAtMillis);
    return map;
  }

  TransferLocksCompanion toCompanion(bool nullToAbsent) {
    return TransferLocksCompanion(
      name: Value(name),
      owner: Value(owner),
      expiresAtMillis: Value(expiresAtMillis),
    );
  }

  factory TransferLock.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransferLock(
      name: serializer.fromJson<String>(json['name']),
      owner: serializer.fromJson<String>(json['owner']),
      expiresAtMillis: serializer.fromJson<int>(json['expiresAtMillis']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'owner': serializer.toJson<String>(owner),
      'expiresAtMillis': serializer.toJson<int>(expiresAtMillis),
    };
  }

  TransferLock copyWith({String? name, String? owner, int? expiresAtMillis}) =>
      TransferLock(
        name: name ?? this.name,
        owner: owner ?? this.owner,
        expiresAtMillis: expiresAtMillis ?? this.expiresAtMillis,
      );
  TransferLock copyWithCompanion(TransferLocksCompanion data) {
    return TransferLock(
      name: data.name.present ? data.name.value : this.name,
      owner: data.owner.present ? data.owner.value : this.owner,
      expiresAtMillis: data.expiresAtMillis.present
          ? data.expiresAtMillis.value
          : this.expiresAtMillis,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransferLock(')
          ..write('name: $name, ')
          ..write('owner: $owner, ')
          ..write('expiresAtMillis: $expiresAtMillis')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(name, owner, expiresAtMillis);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransferLock &&
          other.name == this.name &&
          other.owner == this.owner &&
          other.expiresAtMillis == this.expiresAtMillis);
}

class TransferLocksCompanion extends UpdateCompanion<TransferLock> {
  final Value<String> name;
  final Value<String> owner;
  final Value<int> expiresAtMillis;
  final Value<int> rowid;
  const TransferLocksCompanion({
    this.name = const Value.absent(),
    this.owner = const Value.absent(),
    this.expiresAtMillis = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransferLocksCompanion.insert({
    required String name,
    required String owner,
    required int expiresAtMillis,
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       owner = Value(owner),
       expiresAtMillis = Value(expiresAtMillis);
  static Insertable<TransferLock> custom({
    Expression<String>? name,
    Expression<String>? owner,
    Expression<int>? expiresAtMillis,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (owner != null) 'owner': owner,
      if (expiresAtMillis != null) 'expires_at_millis': expiresAtMillis,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransferLocksCompanion copyWith({
    Value<String>? name,
    Value<String>? owner,
    Value<int>? expiresAtMillis,
    Value<int>? rowid,
  }) {
    return TransferLocksCompanion(
      name: name ?? this.name,
      owner: owner ?? this.owner,
      expiresAtMillis: expiresAtMillis ?? this.expiresAtMillis,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (owner.present) {
      map['owner'] = Variable<String>(owner.value);
    }
    if (expiresAtMillis.present) {
      map['expires_at_millis'] = Variable<int>(expiresAtMillis.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransferLocksCompanion(')
          ..write('name: $name, ')
          ..write('owner: $owner, ')
          ..write('expiresAtMillis: $expiresAtMillis, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $MediaItemsTable mediaItems = $MediaItemsTable(this);
  late final $PairedDevicesTable pairedDevices = $PairedDevicesTable(this);
  late final $ReceivedFilesTable receivedFiles = $ReceivedFilesTable(this);
  late final $ScheduleSettingsTableTable scheduleSettingsTable =
      $ScheduleSettingsTableTable(this);
  late final $TransferLocksTable transferLocks = $TransferLocksTable(this);
  late final Index mediaItemsStatus = Index(
    'media_items_status',
    'CREATE INDEX media_items_status ON media_items (status)',
  );
  late final Index mediaItemsSourceMediaId = Index(
    'media_items_source_media_id',
    'CREATE INDEX media_items_source_media_id ON media_items (source_media_id)',
  );
  late final Index receivedFilesTransferId = Index(
    'received_files_transfer_id',
    'CREATE INDEX received_files_transfer_id ON received_files (transfer_id)',
  );
  late final Index receivedFilesSha256 = Index(
    'received_files_sha256',
    'CREATE INDEX received_files_sha256 ON received_files (sha256)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    appSettings,
    mediaItems,
    pairedDevices,
    receivedFiles,
    scheduleSettingsTable,
    transferLocks,
    mediaItemsStatus,
    mediaItemsSourceMediaId,
    receivedFilesTransferId,
    receivedFilesSha256,
  ];
}

typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String name,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> name,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
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

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
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

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
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
          updateCompanionCallback: ({
            Value<String> name = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AppSettingsCompanion(name: name, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String name,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                name: name,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSetting>(table),
                  BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$MediaItemsTableCreateCompanionBuilder = MediaItemsCompanion Function({
  Value<int> id,
  required String sourceMediaId,
  required String displayName,
  required String mimeType,
  required int sizeBytes,
  Value<int?> dateTakenMillis,
  required int dateModifiedMillis,
  Value<String?> relativePath,
  required MediaKind kind,
  Value<String?> sha256,
  required TransferStatus status,
  required DateTime firstSeenAt,
  Value<DateTime?> transferredAt,
  Value<String?> receiverAcknowledgementId,
  Value<String?> lastError,
  Value<DateTime?> removedFromLibraryAt,
});
typedef $$MediaItemsTableUpdateCompanionBuilder = MediaItemsCompanion Function({
  Value<int> id,
  Value<String> sourceMediaId,
  Value<String> displayName,
  Value<String> mimeType,
  Value<int> sizeBytes,
  Value<int?> dateTakenMillis,
  Value<int> dateModifiedMillis,
  Value<String?> relativePath,
  Value<MediaKind> kind,
  Value<String?> sha256,
  Value<TransferStatus> status,
  Value<DateTime> firstSeenAt,
  Value<DateTime?> transferredAt,
  Value<String?> receiverAcknowledgementId,
  Value<String?> lastError,
  Value<DateTime?> removedFromLibraryAt,
});

class $$MediaItemsTableFilterComposer
    extends Composer<_$AppDatabase, $MediaItemsTable> {
  $$MediaItemsTableFilterComposer({
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

  ColumnFilters<String> get sourceMediaId => $composableBuilder(
    column: $table.sourceMediaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dateTakenMillis => $composableBuilder(
    column: $table.dateTakenMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dateModifiedMillis => $composableBuilder(
    column: $table.dateModifiedMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MediaKind, MediaKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TransferStatus, TransferStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get firstSeenAt => $composableBuilder(
    column: $table.firstSeenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get transferredAt => $composableBuilder(
    column: $table.transferredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiverAcknowledgementId => $composableBuilder(
    column: $table.receiverAcknowledgementId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get removedFromLibraryAt => $composableBuilder(
    column: $table.removedFromLibraryAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MediaItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaItemsTable> {
  $$MediaItemsTableOrderingComposer({
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

  ColumnOrderings<String> get sourceMediaId => $composableBuilder(
    column: $table.sourceMediaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dateTakenMillis => $composableBuilder(
    column: $table.dateTakenMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dateModifiedMillis => $composableBuilder(
    column: $table.dateModifiedMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get firstSeenAt => $composableBuilder(
    column: $table.firstSeenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get transferredAt => $composableBuilder(
    column: $table.transferredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiverAcknowledgementId => $composableBuilder(
    column: $table.receiverAcknowledgementId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get removedFromLibraryAt => $composableBuilder(
    column: $table.removedFromLibraryAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MediaItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaItemsTable> {
  $$MediaItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceMediaId => $composableBuilder(
    column: $table.sourceMediaId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<int> get dateTakenMillis => $composableBuilder(
    column: $table.dateTakenMillis,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dateModifiedMillis => $composableBuilder(
    column: $table.dateModifiedMillis,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<MediaKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TransferStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get firstSeenAt => $composableBuilder(
    column: $table.firstSeenAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get transferredAt => $composableBuilder(
    column: $table.transferredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get receiverAcknowledgementId => $composableBuilder(
    column: $table.receiverAcknowledgementId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get removedFromLibraryAt => $composableBuilder(
    column: $table.removedFromLibraryAt,
    builder: (column) => column,
  );
}

class $$MediaItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MediaItemsTable,
          MediaItem,
          $$MediaItemsTableFilterComposer,
          $$MediaItemsTableOrderingComposer,
          $$MediaItemsTableAnnotationComposer,
          $$MediaItemsTableCreateCompanionBuilder,
          $$MediaItemsTableUpdateCompanionBuilder,
          (
            MediaItem,
            BaseReferences<_$AppDatabase, $MediaItemsTable, MediaItem>,
          ),
          MediaItem,
          PrefetchHooks Function()
        > {
  $$MediaItemsTableTableManager(_$AppDatabase db, $MediaItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sourceMediaId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> mimeType = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<int?> dateTakenMillis = const Value.absent(),
                Value<int> dateModifiedMillis = const Value.absent(),
                Value<String?> relativePath = const Value.absent(),
                Value<MediaKind> kind = const Value.absent(),
                Value<String?> sha256 = const Value.absent(),
                Value<TransferStatus> status = const Value.absent(),
                Value<DateTime> firstSeenAt = const Value.absent(),
                Value<DateTime?> transferredAt = const Value.absent(),
                Value<String?> receiverAcknowledgementId = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime?> removedFromLibraryAt = const Value.absent(),
              }) => MediaItemsCompanion(
                id: id,
                sourceMediaId: sourceMediaId,
                displayName: displayName,
                mimeType: mimeType,
                sizeBytes: sizeBytes,
                dateTakenMillis: dateTakenMillis,
                dateModifiedMillis: dateModifiedMillis,
                relativePath: relativePath,
                kind: kind,
                sha256: sha256,
                status: status,
                firstSeenAt: firstSeenAt,
                transferredAt: transferredAt,
                receiverAcknowledgementId: receiverAcknowledgementId,
                lastError: lastError,
                removedFromLibraryAt: removedFromLibraryAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sourceMediaId,
                required String displayName,
                required String mimeType,
                required int sizeBytes,
                Value<int?> dateTakenMillis = const Value.absent(),
                required int dateModifiedMillis,
                Value<String?> relativePath = const Value.absent(),
                required MediaKind kind,
                Value<String?> sha256 = const Value.absent(),
                required TransferStatus status,
                required DateTime firstSeenAt,
                Value<DateTime?> transferredAt = const Value.absent(),
                Value<String?> receiverAcknowledgementId = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime?> removedFromLibraryAt = const Value.absent(),
              }) => MediaItemsCompanion.insert(
                id: id,
                sourceMediaId: sourceMediaId,
                displayName: displayName,
                mimeType: mimeType,
                sizeBytes: sizeBytes,
                dateTakenMillis: dateTakenMillis,
                dateModifiedMillis: dateModifiedMillis,
                relativePath: relativePath,
                kind: kind,
                sha256: sha256,
                status: status,
                firstSeenAt: firstSeenAt,
                transferredAt: transferredAt,
                receiverAcknowledgementId: receiverAcknowledgementId,
                lastError: lastError,
                removedFromLibraryAt: removedFromLibraryAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MediaItemsTable, MediaItem>(table),
                  BaseReferences<_$AppDatabase, $MediaItemsTable, MediaItem>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MediaItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MediaItemsTable,
      MediaItem,
      $$MediaItemsTableFilterComposer,
      $$MediaItemsTableOrderingComposer,
      $$MediaItemsTableAnnotationComposer,
      $$MediaItemsTableCreateCompanionBuilder,
      $$MediaItemsTableUpdateCompanionBuilder,
      (MediaItem, BaseReferences<_$AppDatabase, $MediaItemsTable, MediaItem>),
      MediaItem,
      PrefetchHooks Function()
    >;
typedef $$PairedDevicesTableCreateCompanionBuilder =
    PairedDevicesCompanion Function({
      required String deviceId,
      required String displayName,
      required DeviceRole peerRole,
      Value<String?> certificateFingerprint,
      Value<String?> authTokenHash,
      Value<String?> lastKnownHost,
      Value<int?> lastKnownPort,
      required DateTime pairedAt,
      Value<DateTime?> lastSeenAt,
      Value<int> rowid,
    });
typedef $$PairedDevicesTableUpdateCompanionBuilder =
    PairedDevicesCompanion Function({
      Value<String> deviceId,
      Value<String> displayName,
      Value<DeviceRole> peerRole,
      Value<String?> certificateFingerprint,
      Value<String?> authTokenHash,
      Value<String?> lastKnownHost,
      Value<int?> lastKnownPort,
      Value<DateTime> pairedAt,
      Value<DateTime?> lastSeenAt,
      Value<int> rowid,
    });

class $$PairedDevicesTableFilterComposer
    extends Composer<_$AppDatabase, $PairedDevicesTable> {
  $$PairedDevicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DeviceRole, DeviceRole, String> get peerRole =>
      $composableBuilder(
        column: $table.peerRole,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get certificateFingerprint => $composableBuilder(
    column: $table.certificateFingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authTokenHash => $composableBuilder(
    column: $table.authTokenHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastKnownHost => $composableBuilder(
    column: $table.lastKnownHost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastKnownPort => $composableBuilder(
    column: $table.lastKnownPort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get pairedAt => $composableBuilder(
    column: $table.pairedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PairedDevicesTableOrderingComposer
    extends Composer<_$AppDatabase, $PairedDevicesTable> {
  $$PairedDevicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get peerRole => $composableBuilder(
    column: $table.peerRole,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get certificateFingerprint => $composableBuilder(
    column: $table.certificateFingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authTokenHash => $composableBuilder(
    column: $table.authTokenHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastKnownHost => $composableBuilder(
    column: $table.lastKnownHost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastKnownPort => $composableBuilder(
    column: $table.lastKnownPort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get pairedAt => $composableBuilder(
    column: $table.pairedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PairedDevicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PairedDevicesTable> {
  $$PairedDevicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DeviceRole, String> get peerRole =>
      $composableBuilder(column: $table.peerRole, builder: (column) => column);

  GeneratedColumn<String> get certificateFingerprint => $composableBuilder(
    column: $table.certificateFingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<String> get authTokenHash => $composableBuilder(
    column: $table.authTokenHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastKnownHost => $composableBuilder(
    column: $table.lastKnownHost,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastKnownPort => $composableBuilder(
    column: $table.lastKnownPort,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get pairedAt =>
      $composableBuilder(column: $table.pairedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => column,
  );
}

class $$PairedDevicesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PairedDevicesTable,
          PairedDevice,
          $$PairedDevicesTableFilterComposer,
          $$PairedDevicesTableOrderingComposer,
          $$PairedDevicesTableAnnotationComposer,
          $$PairedDevicesTableCreateCompanionBuilder,
          $$PairedDevicesTableUpdateCompanionBuilder,
          (
            PairedDevice,
            BaseReferences<_$AppDatabase, $PairedDevicesTable, PairedDevice>,
          ),
          PairedDevice,
          PrefetchHooks Function()
        > {
  $$PairedDevicesTableTableManager(_$AppDatabase db, $PairedDevicesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PairedDevicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PairedDevicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PairedDevicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> deviceId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<DeviceRole> peerRole = const Value.absent(),
                Value<String?> certificateFingerprint = const Value.absent(),
                Value<String?> authTokenHash = const Value.absent(),
                Value<String?> lastKnownHost = const Value.absent(),
                Value<int?> lastKnownPort = const Value.absent(),
                Value<DateTime> pairedAt = const Value.absent(),
                Value<DateTime?> lastSeenAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PairedDevicesCompanion(
                deviceId: deviceId,
                displayName: displayName,
                peerRole: peerRole,
                certificateFingerprint: certificateFingerprint,
                authTokenHash: authTokenHash,
                lastKnownHost: lastKnownHost,
                lastKnownPort: lastKnownPort,
                pairedAt: pairedAt,
                lastSeenAt: lastSeenAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deviceId,
                required String displayName,
                required DeviceRole peerRole,
                Value<String?> certificateFingerprint = const Value.absent(),
                Value<String?> authTokenHash = const Value.absent(),
                Value<String?> lastKnownHost = const Value.absent(),
                Value<int?> lastKnownPort = const Value.absent(),
                required DateTime pairedAt,
                Value<DateTime?> lastSeenAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PairedDevicesCompanion.insert(
                deviceId: deviceId,
                displayName: displayName,
                peerRole: peerRole,
                certificateFingerprint: certificateFingerprint,
                authTokenHash: authTokenHash,
                lastKnownHost: lastKnownHost,
                lastKnownPort: lastKnownPort,
                pairedAt: pairedAt,
                lastSeenAt: lastSeenAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PairedDevicesTable, PairedDevice>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PairedDevicesTable,
                    PairedDevice
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PairedDevicesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PairedDevicesTable,
      PairedDevice,
      $$PairedDevicesTableFilterComposer,
      $$PairedDevicesTableOrderingComposer,
      $$PairedDevicesTableAnnotationComposer,
      $$PairedDevicesTableCreateCompanionBuilder,
      $$PairedDevicesTableUpdateCompanionBuilder,
      (
        PairedDevice,
        BaseReferences<_$AppDatabase, $PairedDevicesTable, PairedDevice>,
      ),
      PairedDevice,
      PrefetchHooks Function()
    >;
typedef $$ReceivedFilesTableCreateCompanionBuilder =
    ReceivedFilesCompanion Function({
      Value<int> id,
      required String senderDeviceId,
      required String transferId,
      required String sha256,
      required int sizeBytes,
      Value<int?> sourceModifiedMillis,
      required String originalName,
      required String publishedMediaId,
      required String publishedName,
      required String acknowledgementId,
      required DateTime receivedAt,
    });
typedef $$ReceivedFilesTableUpdateCompanionBuilder =
    ReceivedFilesCompanion Function({
      Value<int> id,
      Value<String> senderDeviceId,
      Value<String> transferId,
      Value<String> sha256,
      Value<int> sizeBytes,
      Value<int?> sourceModifiedMillis,
      Value<String> originalName,
      Value<String> publishedMediaId,
      Value<String> publishedName,
      Value<String> acknowledgementId,
      Value<DateTime> receivedAt,
    });

class $$ReceivedFilesTableFilterComposer
    extends Composer<_$AppDatabase, $ReceivedFilesTable> {
  $$ReceivedFilesTableFilterComposer({
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

  ColumnFilters<String> get senderDeviceId => $composableBuilder(
    column: $table.senderDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transferId => $composableBuilder(
    column: $table.transferId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sourceModifiedMillis => $composableBuilder(
    column: $table.sourceModifiedMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalName => $composableBuilder(
    column: $table.originalName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publishedMediaId => $composableBuilder(
    column: $table.publishedMediaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publishedName => $composableBuilder(
    column: $table.publishedName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get acknowledgementId => $composableBuilder(
    column: $table.acknowledgementId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReceivedFilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ReceivedFilesTable> {
  $$ReceivedFilesTableOrderingComposer({
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

  ColumnOrderings<String> get senderDeviceId => $composableBuilder(
    column: $table.senderDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transferId => $composableBuilder(
    column: $table.transferId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sourceModifiedMillis => $composableBuilder(
    column: $table.sourceModifiedMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalName => $composableBuilder(
    column: $table.originalName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publishedMediaId => $composableBuilder(
    column: $table.publishedMediaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publishedName => $composableBuilder(
    column: $table.publishedName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get acknowledgementId => $composableBuilder(
    column: $table.acknowledgementId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReceivedFilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReceivedFilesTable> {
  $$ReceivedFilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get senderDeviceId => $composableBuilder(
    column: $table.senderDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get transferId => $composableBuilder(
    column: $table.transferId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<int> get sourceModifiedMillis => $composableBuilder(
    column: $table.sourceModifiedMillis,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originalName => $composableBuilder(
    column: $table.originalName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get publishedMediaId => $composableBuilder(
    column: $table.publishedMediaId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get publishedName => $composableBuilder(
    column: $table.publishedName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get acknowledgementId => $composableBuilder(
    column: $table.acknowledgementId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => column,
  );
}

class $$ReceivedFilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReceivedFilesTable,
          ReceivedFile,
          $$ReceivedFilesTableFilterComposer,
          $$ReceivedFilesTableOrderingComposer,
          $$ReceivedFilesTableAnnotationComposer,
          $$ReceivedFilesTableCreateCompanionBuilder,
          $$ReceivedFilesTableUpdateCompanionBuilder,
          (
            ReceivedFile,
            BaseReferences<_$AppDatabase, $ReceivedFilesTable, ReceivedFile>,
          ),
          ReceivedFile,
          PrefetchHooks Function()
        > {
  $$ReceivedFilesTableTableManager(_$AppDatabase db, $ReceivedFilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReceivedFilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReceivedFilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReceivedFilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> senderDeviceId = const Value.absent(),
                Value<String> transferId = const Value.absent(),
                Value<String> sha256 = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<int?> sourceModifiedMillis = const Value.absent(),
                Value<String> originalName = const Value.absent(),
                Value<String> publishedMediaId = const Value.absent(),
                Value<String> publishedName = const Value.absent(),
                Value<String> acknowledgementId = const Value.absent(),
                Value<DateTime> receivedAt = const Value.absent(),
              }) => ReceivedFilesCompanion(
                id: id,
                senderDeviceId: senderDeviceId,
                transferId: transferId,
                sha256: sha256,
                sizeBytes: sizeBytes,
                sourceModifiedMillis: sourceModifiedMillis,
                originalName: originalName,
                publishedMediaId: publishedMediaId,
                publishedName: publishedName,
                acknowledgementId: acknowledgementId,
                receivedAt: receivedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String senderDeviceId,
                required String transferId,
                required String sha256,
                required int sizeBytes,
                Value<int?> sourceModifiedMillis = const Value.absent(),
                required String originalName,
                required String publishedMediaId,
                required String publishedName,
                required String acknowledgementId,
                required DateTime receivedAt,
              }) => ReceivedFilesCompanion.insert(
                id: id,
                senderDeviceId: senderDeviceId,
                transferId: transferId,
                sha256: sha256,
                sizeBytes: sizeBytes,
                sourceModifiedMillis: sourceModifiedMillis,
                originalName: originalName,
                publishedMediaId: publishedMediaId,
                publishedName: publishedName,
                acknowledgementId: acknowledgementId,
                receivedAt: receivedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReceivedFilesTable, ReceivedFile>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ReceivedFilesTable,
                    ReceivedFile
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReceivedFilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReceivedFilesTable,
      ReceivedFile,
      $$ReceivedFilesTableFilterComposer,
      $$ReceivedFilesTableOrderingComposer,
      $$ReceivedFilesTableAnnotationComposer,
      $$ReceivedFilesTableCreateCompanionBuilder,
      $$ReceivedFilesTableUpdateCompanionBuilder,
      (
        ReceivedFile,
        BaseReferences<_$AppDatabase, $ReceivedFilesTable, ReceivedFile>,
      ),
      ReceivedFile,
      PrefetchHooks Function()
    >;
typedef $$ScheduleSettingsTableTableCreateCompanionBuilder =
    ScheduleSettingsTableCompanion Function({
      Value<int> id,
      required bool enabled,
      required int hour,
      required int minute,
      required String weekdays,
      required bool wifiOnly,
      required bool chargingOnly,
      required int retryHours,
      Value<DateTime?> enabledAt,
      Value<DateTime?> lastAttemptAt,
      Value<String?> lastOutcome,
      Value<String?> lastMessage,
      Value<DateTime?> lastSuccessAt,
      Value<DateTime?> nextRunEstimate,
    });
typedef $$ScheduleSettingsTableTableUpdateCompanionBuilder =
    ScheduleSettingsTableCompanion Function({
      Value<int> id,
      Value<bool> enabled,
      Value<int> hour,
      Value<int> minute,
      Value<String> weekdays,
      Value<bool> wifiOnly,
      Value<bool> chargingOnly,
      Value<int> retryHours,
      Value<DateTime?> enabledAt,
      Value<DateTime?> lastAttemptAt,
      Value<String?> lastOutcome,
      Value<String?> lastMessage,
      Value<DateTime?> lastSuccessAt,
      Value<DateTime?> nextRunEstimate,
    });

class $$ScheduleSettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ScheduleSettingsTableTable> {
  $$ScheduleSettingsTableTableFilterComposer({
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

  ColumnFilters<int> get hour => $composableBuilder(
    column: $table.hour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minute => $composableBuilder(
    column: $table.minute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weekdays => $composableBuilder(
    column: $table.weekdays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get wifiOnly => $composableBuilder(
    column: $table.wifiOnly,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get chargingOnly => $composableBuilder(
    column: $table.chargingOnly,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryHours => $composableBuilder(
    column: $table.retryHours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get enabledAt => $composableBuilder(
    column: $table.enabledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastOutcome => $composableBuilder(
    column: $table.lastOutcome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessage => $composableBuilder(
    column: $table.lastMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSuccessAt => $composableBuilder(
    column: $table.lastSuccessAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextRunEstimate => $composableBuilder(
    column: $table.nextRunEstimate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ScheduleSettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ScheduleSettingsTableTable> {
  $$ScheduleSettingsTableTableOrderingComposer({
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

  ColumnOrderings<int> get hour => $composableBuilder(
    column: $table.hour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minute => $composableBuilder(
    column: $table.minute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weekdays => $composableBuilder(
    column: $table.weekdays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get wifiOnly => $composableBuilder(
    column: $table.wifiOnly,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get chargingOnly => $composableBuilder(
    column: $table.chargingOnly,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryHours => $composableBuilder(
    column: $table.retryHours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get enabledAt => $composableBuilder(
    column: $table.enabledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastOutcome => $composableBuilder(
    column: $table.lastOutcome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessage => $composableBuilder(
    column: $table.lastMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSuccessAt => $composableBuilder(
    column: $table.lastSuccessAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextRunEstimate => $composableBuilder(
    column: $table.nextRunEstimate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ScheduleSettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScheduleSettingsTableTable> {
  $$ScheduleSettingsTableTableAnnotationComposer({
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

  GeneratedColumn<int> get hour =>
      $composableBuilder(column: $table.hour, builder: (column) => column);

  GeneratedColumn<int> get minute =>
      $composableBuilder(column: $table.minute, builder: (column) => column);

  GeneratedColumn<String> get weekdays =>
      $composableBuilder(column: $table.weekdays, builder: (column) => column);

  GeneratedColumn<bool> get wifiOnly =>
      $composableBuilder(column: $table.wifiOnly, builder: (column) => column);

  GeneratedColumn<bool> get chargingOnly => $composableBuilder(
    column: $table.chargingOnly,
    builder: (column) => column,
  );

  GeneratedColumn<int> get retryHours => $composableBuilder(
    column: $table.retryHours,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get enabledAt =>
      $composableBuilder(column: $table.enabledAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastOutcome => $composableBuilder(
    column: $table.lastOutcome,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastMessage => $composableBuilder(
    column: $table.lastMessage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSuccessAt => $composableBuilder(
    column: $table.lastSuccessAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextRunEstimate => $composableBuilder(
    column: $table.nextRunEstimate,
    builder: (column) => column,
  );
}

class $$ScheduleSettingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScheduleSettingsTableTable,
          ScheduleRow,
          $$ScheduleSettingsTableTableFilterComposer,
          $$ScheduleSettingsTableTableOrderingComposer,
          $$ScheduleSettingsTableTableAnnotationComposer,
          $$ScheduleSettingsTableTableCreateCompanionBuilder,
          $$ScheduleSettingsTableTableUpdateCompanionBuilder,
          (
            ScheduleRow,
            BaseReferences<
              _$AppDatabase,
              $ScheduleSettingsTableTable,
              ScheduleRow
            >,
          ),
          ScheduleRow,
          PrefetchHooks Function()
        > {
  $$ScheduleSettingsTableTableTableManager(
    _$AppDatabase db,
    $ScheduleSettingsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScheduleSettingsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ScheduleSettingsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ScheduleSettingsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> hour = const Value.absent(),
                Value<int> minute = const Value.absent(),
                Value<String> weekdays = const Value.absent(),
                Value<bool> wifiOnly = const Value.absent(),
                Value<bool> chargingOnly = const Value.absent(),
                Value<int> retryHours = const Value.absent(),
                Value<DateTime?> enabledAt = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<String?> lastOutcome = const Value.absent(),
                Value<String?> lastMessage = const Value.absent(),
                Value<DateTime?> lastSuccessAt = const Value.absent(),
                Value<DateTime?> nextRunEstimate = const Value.absent(),
              }) => ScheduleSettingsTableCompanion(
                id: id,
                enabled: enabled,
                hour: hour,
                minute: minute,
                weekdays: weekdays,
                wifiOnly: wifiOnly,
                chargingOnly: chargingOnly,
                retryHours: retryHours,
                enabledAt: enabledAt,
                lastAttemptAt: lastAttemptAt,
                lastOutcome: lastOutcome,
                lastMessage: lastMessage,
                lastSuccessAt: lastSuccessAt,
                nextRunEstimate: nextRunEstimate,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required bool enabled,
                required int hour,
                required int minute,
                required String weekdays,
                required bool wifiOnly,
                required bool chargingOnly,
                required int retryHours,
                Value<DateTime?> enabledAt = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<String?> lastOutcome = const Value.absent(),
                Value<String?> lastMessage = const Value.absent(),
                Value<DateTime?> lastSuccessAt = const Value.absent(),
                Value<DateTime?> nextRunEstimate = const Value.absent(),
              }) => ScheduleSettingsTableCompanion.insert(
                id: id,
                enabled: enabled,
                hour: hour,
                minute: minute,
                weekdays: weekdays,
                wifiOnly: wifiOnly,
                chargingOnly: chargingOnly,
                retryHours: retryHours,
                enabledAt: enabledAt,
                lastAttemptAt: lastAttemptAt,
                lastOutcome: lastOutcome,
                lastMessage: lastMessage,
                lastSuccessAt: lastSuccessAt,
                nextRunEstimate: nextRunEstimate,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ScheduleSettingsTableTable, ScheduleRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ScheduleSettingsTableTable,
                    ScheduleRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ScheduleSettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScheduleSettingsTableTable,
      ScheduleRow,
      $$ScheduleSettingsTableTableFilterComposer,
      $$ScheduleSettingsTableTableOrderingComposer,
      $$ScheduleSettingsTableTableAnnotationComposer,
      $$ScheduleSettingsTableTableCreateCompanionBuilder,
      $$ScheduleSettingsTableTableUpdateCompanionBuilder,
      (
        ScheduleRow,
        BaseReferences<_$AppDatabase, $ScheduleSettingsTableTable, ScheduleRow>,
      ),
      ScheduleRow,
      PrefetchHooks Function()
    >;
typedef $$TransferLocksTableCreateCompanionBuilder =
    TransferLocksCompanion Function({
      required String name,
      required String owner,
      required int expiresAtMillis,
      Value<int> rowid,
    });
typedef $$TransferLocksTableUpdateCompanionBuilder =
    TransferLocksCompanion Function({
      Value<String> name,
      Value<String> owner,
      Value<int> expiresAtMillis,
      Value<int> rowid,
    });

class $$TransferLocksTableFilterComposer
    extends Composer<_$AppDatabase, $TransferLocksTable> {
  $$TransferLocksTableFilterComposer({
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

  ColumnFilters<String> get owner => $composableBuilder(
    column: $table.owner,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expiresAtMillis => $composableBuilder(
    column: $table.expiresAtMillis,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransferLocksTableOrderingComposer
    extends Composer<_$AppDatabase, $TransferLocksTable> {
  $$TransferLocksTableOrderingComposer({
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

  ColumnOrderings<String> get owner => $composableBuilder(
    column: $table.owner,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expiresAtMillis => $composableBuilder(
    column: $table.expiresAtMillis,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransferLocksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransferLocksTable> {
  $$TransferLocksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get owner =>
      $composableBuilder(column: $table.owner, builder: (column) => column);

  GeneratedColumn<int> get expiresAtMillis => $composableBuilder(
    column: $table.expiresAtMillis,
    builder: (column) => column,
  );
}

class $$TransferLocksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransferLocksTable,
          TransferLock,
          $$TransferLocksTableFilterComposer,
          $$TransferLocksTableOrderingComposer,
          $$TransferLocksTableAnnotationComposer,
          $$TransferLocksTableCreateCompanionBuilder,
          $$TransferLocksTableUpdateCompanionBuilder,
          (
            TransferLock,
            BaseReferences<_$AppDatabase, $TransferLocksTable, TransferLock>,
          ),
          TransferLock,
          PrefetchHooks Function()
        > {
  $$TransferLocksTableTableManager(_$AppDatabase db, $TransferLocksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransferLocksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransferLocksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransferLocksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> name = const Value.absent(),
                Value<String> owner = const Value.absent(),
                Value<int> expiresAtMillis = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransferLocksCompanion(
                name: name,
                owner: owner,
                expiresAtMillis: expiresAtMillis,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String name,
                required String owner,
                required int expiresAtMillis,
                Value<int> rowid = const Value.absent(),
              }) => TransferLocksCompanion.insert(
                name: name,
                owner: owner,
                expiresAtMillis: expiresAtMillis,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TransferLocksTable, TransferLock>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $TransferLocksTable,
                    TransferLock
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransferLocksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransferLocksTable,
      TransferLock,
      $$TransferLocksTableFilterComposer,
      $$TransferLocksTableOrderingComposer,
      $$TransferLocksTableAnnotationComposer,
      $$TransferLocksTableCreateCompanionBuilder,
      $$TransferLocksTableUpdateCompanionBuilder,
      (
        TransferLock,
        BaseReferences<_$AppDatabase, $TransferLocksTable, TransferLock>,
      ),
      TransferLock,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$MediaItemsTableTableManager get mediaItems =>
      $$MediaItemsTableTableManager(_db, _db.mediaItems);
  $$PairedDevicesTableTableManager get pairedDevices =>
      $$PairedDevicesTableTableManager(_db, _db.pairedDevices);
  $$ReceivedFilesTableTableManager get receivedFiles =>
      $$ReceivedFilesTableTableManager(_db, _db.receivedFiles);
  $$ScheduleSettingsTableTableTableManager get scheduleSettingsTable =>
      $$ScheduleSettingsTableTableTableManager(_db, _db.scheduleSettingsTable);
  $$TransferLocksTableTableManager get transferLocks =>
      $$TransferLocksTableTableManager(_db, _db.transferLocks);
}
