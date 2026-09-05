// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_database.dart';

// ignore_for_file: type=lint
class $FilmRollsTable extends FilmRolls
    with TableInfo<$FilmRollsTable, FilmRollRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FilmRollsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<RegionCode, String> regionCode =
      GeneratedColumn<String>(
        'region_code',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<RegionCode>($FilmRollsTable.$converterregionCode);
  static const VerificationMeta _regionNameMeta = const VerificationMeta(
    'regionName',
  );
  @override
  late final GeneratedColumn<String> regionName = GeneratedColumn<String>(
    'region_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<FilmRollStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<FilmRollStatus>($FilmRollsTable.$converterstatus);
  static const VerificationMeta _selectedCourseIdMeta = const VerificationMeta(
    'selectedCourseId',
  );
  @override
  late final GeneratedColumn<String> selectedCourseId = GeneratedColumn<String>(
    'selected_course_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _selectedCourseTitleMeta =
      const VerificationMeta('selectedCourseTitle');
  @override
  late final GeneratedColumn<String> selectedCourseTitle =
      GeneratedColumn<String>(
        'selected_course_title',
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _developAvailableAtMeta =
      const VerificationMeta('developAvailableAt');
  @override
  late final GeneratedColumn<DateTime> developAvailableAt =
      GeneratedColumn<DateTime>(
        'develop_available_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _regionIdMeta = const VerificationMeta(
    'regionId',
  );
  @override
  late final GeneratedColumn<int> regionId = GeneratedColumn<int>(
    'region_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _filterIdMeta = const VerificationMeta(
    'filterId',
  );
  @override
  late final GeneratedColumn<String> filterId = GeneratedColumn<String>(
    'filter_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _filterStrengthMeta = const VerificationMeta(
    'filterStrength',
  );
  @override
  late final GeneratedColumn<double> filterStrength = GeneratedColumn<double>(
    'filter_strength',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverFilmRollIdMeta = const VerificationMeta(
    'serverFilmRollId',
  );
  @override
  late final GeneratedColumn<int> serverFilmRollId = GeneratedColumn<int>(
    'server_film_roll_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverStatusMeta = const VerificationMeta(
    'serverStatus',
  );
  @override
  late final GeneratedColumn<String> serverStatus = GeneratedColumn<String>(
    'server_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    regionCode,
    regionName,
    title,
    status,
    selectedCourseId,
    selectedCourseTitle,
    createdAt,
    updatedAt,
    completedAt,
    developAvailableAt,
    regionId,
    filterId,
    filterStrength,
    serverFilmRollId,
    serverStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'film_rolls';
  @override
  VerificationContext validateIntegrity(
    Insertable<FilmRollRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('region_name')) {
      context.handle(
        _regionNameMeta,
        regionName.isAcceptableOrUnknown(data['region_name']!, _regionNameMeta),
      );
    } else if (isInserting) {
      context.missing(_regionNameMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('selected_course_id')) {
      context.handle(
        _selectedCourseIdMeta,
        selectedCourseId.isAcceptableOrUnknown(
          data['selected_course_id']!,
          _selectedCourseIdMeta,
        ),
      );
    }
    if (data.containsKey('selected_course_title')) {
      context.handle(
        _selectedCourseTitleMeta,
        selectedCourseTitle.isAcceptableOrUnknown(
          data['selected_course_title']!,
          _selectedCourseTitleMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('develop_available_at')) {
      context.handle(
        _developAvailableAtMeta,
        developAvailableAt.isAcceptableOrUnknown(
          data['develop_available_at']!,
          _developAvailableAtMeta,
        ),
      );
    }
    if (data.containsKey('region_id')) {
      context.handle(
        _regionIdMeta,
        regionId.isAcceptableOrUnknown(data['region_id']!, _regionIdMeta),
      );
    }
    if (data.containsKey('filter_id')) {
      context.handle(
        _filterIdMeta,
        filterId.isAcceptableOrUnknown(data['filter_id']!, _filterIdMeta),
      );
    }
    if (data.containsKey('filter_strength')) {
      context.handle(
        _filterStrengthMeta,
        filterStrength.isAcceptableOrUnknown(
          data['filter_strength']!,
          _filterStrengthMeta,
        ),
      );
    }
    if (data.containsKey('server_film_roll_id')) {
      context.handle(
        _serverFilmRollIdMeta,
        serverFilmRollId.isAcceptableOrUnknown(
          data['server_film_roll_id']!,
          _serverFilmRollIdMeta,
        ),
      );
    }
    if (data.containsKey('server_status')) {
      context.handle(
        _serverStatusMeta,
        serverStatus.isAcceptableOrUnknown(
          data['server_status']!,
          _serverStatusMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FilmRollRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilmRollRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      ),
      regionCode: $FilmRollsTable.$converterregionCode.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}region_code'],
        )!,
      ),
      regionName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}region_name'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      status: $FilmRollsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      selectedCourseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selected_course_id'],
      ),
      selectedCourseTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selected_course_title'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      developAvailableAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}develop_available_at'],
      ),
      regionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}region_id'],
      ),
      filterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filter_id'],
      ),
      filterStrength: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}filter_strength'],
      ),
      serverFilmRollId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_film_roll_id'],
      ),
      serverStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_status'],
      ),
    );
  }

  @override
  $FilmRollsTable createAlias(String alias) {
    return $FilmRollsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<RegionCode, String, String> $converterregionCode =
      const EnumNameConverter<RegionCode>(RegionCode.values);
  static JsonTypeConverter2<FilmRollStatus, String, String> $converterstatus =
      const EnumNameConverter<FilmRollStatus>(FilmRollStatus.values);
}

class FilmRollRow extends DataClass implements Insertable<FilmRollRow> {
  final String id;
  final int? userId;
  final RegionCode regionCode;
  final String regionName;
  final String title;
  final FilmRollStatus status;
  final String? selectedCourseId;
  final String? selectedCourseTitle;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final DateTime? developAvailableAt;
  final int? regionId;
  final String? filterId;
  final double? filterStrength;
  final int? serverFilmRollId;
  final String? serverStatus;
  const FilmRollRow({
    required this.id,
    this.userId,
    required this.regionCode,
    required this.regionName,
    required this.title,
    required this.status,
    this.selectedCourseId,
    this.selectedCourseTitle,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.developAvailableAt,
    this.regionId,
    this.filterId,
    this.filterStrength,
    this.serverFilmRollId,
    this.serverStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<int>(userId);
    }
    {
      map['region_code'] = Variable<String>(
        $FilmRollsTable.$converterregionCode.toSql(regionCode),
      );
    }
    map['region_name'] = Variable<String>(regionName);
    map['title'] = Variable<String>(title);
    {
      map['status'] = Variable<String>(
        $FilmRollsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || selectedCourseId != null) {
      map['selected_course_id'] = Variable<String>(selectedCourseId);
    }
    if (!nullToAbsent || selectedCourseTitle != null) {
      map['selected_course_title'] = Variable<String>(selectedCourseTitle);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || developAvailableAt != null) {
      map['develop_available_at'] = Variable<DateTime>(developAvailableAt);
    }
    if (!nullToAbsent || regionId != null) {
      map['region_id'] = Variable<int>(regionId);
    }
    if (!nullToAbsent || filterId != null) {
      map['filter_id'] = Variable<String>(filterId);
    }
    if (!nullToAbsent || filterStrength != null) {
      map['filter_strength'] = Variable<double>(filterStrength);
    }
    if (!nullToAbsent || serverFilmRollId != null) {
      map['server_film_roll_id'] = Variable<int>(serverFilmRollId);
    }
    if (!nullToAbsent || serverStatus != null) {
      map['server_status'] = Variable<String>(serverStatus);
    }
    return map;
  }

  FilmRollsCompanion toCompanion(bool nullToAbsent) {
    return FilmRollsCompanion(
      id: Value(id),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      regionCode: Value(regionCode),
      regionName: Value(regionName),
      title: Value(title),
      status: Value(status),
      selectedCourseId: selectedCourseId == null && nullToAbsent
          ? const Value.absent()
          : Value(selectedCourseId),
      selectedCourseTitle: selectedCourseTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(selectedCourseTitle),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      developAvailableAt: developAvailableAt == null && nullToAbsent
          ? const Value.absent()
          : Value(developAvailableAt),
      regionId: regionId == null && nullToAbsent
          ? const Value.absent()
          : Value(regionId),
      filterId: filterId == null && nullToAbsent
          ? const Value.absent()
          : Value(filterId),
      filterStrength: filterStrength == null && nullToAbsent
          ? const Value.absent()
          : Value(filterStrength),
      serverFilmRollId: serverFilmRollId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverFilmRollId),
      serverStatus: serverStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(serverStatus),
    );
  }

  factory FilmRollRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilmRollRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<int?>(json['userId']),
      regionCode: $FilmRollsTable.$converterregionCode.fromJson(
        serializer.fromJson<String>(json['regionCode']),
      ),
      regionName: serializer.fromJson<String>(json['regionName']),
      title: serializer.fromJson<String>(json['title']),
      status: $FilmRollsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      selectedCourseId: serializer.fromJson<String?>(json['selectedCourseId']),
      selectedCourseTitle: serializer.fromJson<String?>(
        json['selectedCourseTitle'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      developAvailableAt: serializer.fromJson<DateTime?>(
        json['developAvailableAt'],
      ),
      regionId: serializer.fromJson<int?>(json['regionId']),
      filterId: serializer.fromJson<String?>(json['filterId']),
      filterStrength: serializer.fromJson<double?>(json['filterStrength']),
      serverFilmRollId: serializer.fromJson<int?>(json['serverFilmRollId']),
      serverStatus: serializer.fromJson<String?>(json['serverStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<int?>(userId),
      'regionCode': serializer.toJson<String>(
        $FilmRollsTable.$converterregionCode.toJson(regionCode),
      ),
      'regionName': serializer.toJson<String>(regionName),
      'title': serializer.toJson<String>(title),
      'status': serializer.toJson<String>(
        $FilmRollsTable.$converterstatus.toJson(status),
      ),
      'selectedCourseId': serializer.toJson<String?>(selectedCourseId),
      'selectedCourseTitle': serializer.toJson<String?>(selectedCourseTitle),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'developAvailableAt': serializer.toJson<DateTime?>(developAvailableAt),
      'regionId': serializer.toJson<int?>(regionId),
      'filterId': serializer.toJson<String?>(filterId),
      'filterStrength': serializer.toJson<double?>(filterStrength),
      'serverFilmRollId': serializer.toJson<int?>(serverFilmRollId),
      'serverStatus': serializer.toJson<String?>(serverStatus),
    };
  }

  FilmRollRow copyWith({
    String? id,
    Value<int?> userId = const Value.absent(),
    RegionCode? regionCode,
    String? regionName,
    String? title,
    FilmRollStatus? status,
    Value<String?> selectedCourseId = const Value.absent(),
    Value<String?> selectedCourseTitle = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> completedAt = const Value.absent(),
    Value<DateTime?> developAvailableAt = const Value.absent(),
    Value<int?> regionId = const Value.absent(),
    Value<String?> filterId = const Value.absent(),
    Value<double?> filterStrength = const Value.absent(),
    Value<int?> serverFilmRollId = const Value.absent(),
    Value<String?> serverStatus = const Value.absent(),
  }) => FilmRollRow(
    id: id ?? this.id,
    userId: userId.present ? userId.value : this.userId,
    regionCode: regionCode ?? this.regionCode,
    regionName: regionName ?? this.regionName,
    title: title ?? this.title,
    status: status ?? this.status,
    selectedCourseId: selectedCourseId.present
        ? selectedCourseId.value
        : this.selectedCourseId,
    selectedCourseTitle: selectedCourseTitle.present
        ? selectedCourseTitle.value
        : this.selectedCourseTitle,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    developAvailableAt: developAvailableAt.present
        ? developAvailableAt.value
        : this.developAvailableAt,
    regionId: regionId.present ? regionId.value : this.regionId,
    filterId: filterId.present ? filterId.value : this.filterId,
    filterStrength: filterStrength.present
        ? filterStrength.value
        : this.filterStrength,
    serverFilmRollId: serverFilmRollId.present
        ? serverFilmRollId.value
        : this.serverFilmRollId,
    serverStatus: serverStatus.present ? serverStatus.value : this.serverStatus,
  );
  FilmRollRow copyWithCompanion(FilmRollsCompanion data) {
    return FilmRollRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      regionCode: data.regionCode.present
          ? data.regionCode.value
          : this.regionCode,
      regionName: data.regionName.present
          ? data.regionName.value
          : this.regionName,
      title: data.title.present ? data.title.value : this.title,
      status: data.status.present ? data.status.value : this.status,
      selectedCourseId: data.selectedCourseId.present
          ? data.selectedCourseId.value
          : this.selectedCourseId,
      selectedCourseTitle: data.selectedCourseTitle.present
          ? data.selectedCourseTitle.value
          : this.selectedCourseTitle,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      developAvailableAt: data.developAvailableAt.present
          ? data.developAvailableAt.value
          : this.developAvailableAt,
      regionId: data.regionId.present ? data.regionId.value : this.regionId,
      filterId: data.filterId.present ? data.filterId.value : this.filterId,
      filterStrength: data.filterStrength.present
          ? data.filterStrength.value
          : this.filterStrength,
      serverFilmRollId: data.serverFilmRollId.present
          ? data.serverFilmRollId.value
          : this.serverFilmRollId,
      serverStatus: data.serverStatus.present
          ? data.serverStatus.value
          : this.serverStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilmRollRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('regionCode: $regionCode, ')
          ..write('regionName: $regionName, ')
          ..write('title: $title, ')
          ..write('status: $status, ')
          ..write('selectedCourseId: $selectedCourseId, ')
          ..write('selectedCourseTitle: $selectedCourseTitle, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('developAvailableAt: $developAvailableAt, ')
          ..write('regionId: $regionId, ')
          ..write('filterId: $filterId, ')
          ..write('filterStrength: $filterStrength, ')
          ..write('serverFilmRollId: $serverFilmRollId, ')
          ..write('serverStatus: $serverStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    regionCode,
    regionName,
    title,
    status,
    selectedCourseId,
    selectedCourseTitle,
    createdAt,
    updatedAt,
    completedAt,
    developAvailableAt,
    regionId,
    filterId,
    filterStrength,
    serverFilmRollId,
    serverStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilmRollRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.regionCode == this.regionCode &&
          other.regionName == this.regionName &&
          other.title == this.title &&
          other.status == this.status &&
          other.selectedCourseId == this.selectedCourseId &&
          other.selectedCourseTitle == this.selectedCourseTitle &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.completedAt == this.completedAt &&
          other.developAvailableAt == this.developAvailableAt &&
          other.regionId == this.regionId &&
          other.filterId == this.filterId &&
          other.filterStrength == this.filterStrength &&
          other.serverFilmRollId == this.serverFilmRollId &&
          other.serverStatus == this.serverStatus);
}

class FilmRollsCompanion extends UpdateCompanion<FilmRollRow> {
  final Value<String> id;
  final Value<int?> userId;
  final Value<RegionCode> regionCode;
  final Value<String> regionName;
  final Value<String> title;
  final Value<FilmRollStatus> status;
  final Value<String?> selectedCourseId;
  final Value<String?> selectedCourseTitle;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> completedAt;
  final Value<DateTime?> developAvailableAt;
  final Value<int?> regionId;
  final Value<String?> filterId;
  final Value<double?> filterStrength;
  final Value<int?> serverFilmRollId;
  final Value<String?> serverStatus;
  final Value<int> rowid;
  const FilmRollsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.regionCode = const Value.absent(),
    this.regionName = const Value.absent(),
    this.title = const Value.absent(),
    this.status = const Value.absent(),
    this.selectedCourseId = const Value.absent(),
    this.selectedCourseTitle = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.developAvailableAt = const Value.absent(),
    this.regionId = const Value.absent(),
    this.filterId = const Value.absent(),
    this.filterStrength = const Value.absent(),
    this.serverFilmRollId = const Value.absent(),
    this.serverStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FilmRollsCompanion.insert({
    required String id,
    this.userId = const Value.absent(),
    required RegionCode regionCode,
    required String regionName,
    required String title,
    required FilmRollStatus status,
    this.selectedCourseId = const Value.absent(),
    this.selectedCourseTitle = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.completedAt = const Value.absent(),
    this.developAvailableAt = const Value.absent(),
    this.regionId = const Value.absent(),
    this.filterId = const Value.absent(),
    this.filterStrength = const Value.absent(),
    this.serverFilmRollId = const Value.absent(),
    this.serverStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       regionCode = Value(regionCode),
       regionName = Value(regionName),
       title = Value(title),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<FilmRollRow> custom({
    Expression<String>? id,
    Expression<int>? userId,
    Expression<String>? regionCode,
    Expression<String>? regionName,
    Expression<String>? title,
    Expression<String>? status,
    Expression<String>? selectedCourseId,
    Expression<String>? selectedCourseTitle,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? developAvailableAt,
    Expression<int>? regionId,
    Expression<String>? filterId,
    Expression<double>? filterStrength,
    Expression<int>? serverFilmRollId,
    Expression<String>? serverStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (regionCode != null) 'region_code': regionCode,
      if (regionName != null) 'region_name': regionName,
      if (title != null) 'title': title,
      if (status != null) 'status': status,
      if (selectedCourseId != null) 'selected_course_id': selectedCourseId,
      if (selectedCourseTitle != null)
        'selected_course_title': selectedCourseTitle,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (developAvailableAt != null)
        'develop_available_at': developAvailableAt,
      if (regionId != null) 'region_id': regionId,
      if (filterId != null) 'filter_id': filterId,
      if (filterStrength != null) 'filter_strength': filterStrength,
      if (serverFilmRollId != null) 'server_film_roll_id': serverFilmRollId,
      if (serverStatus != null) 'server_status': serverStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FilmRollsCompanion copyWith({
    Value<String>? id,
    Value<int?>? userId,
    Value<RegionCode>? regionCode,
    Value<String>? regionName,
    Value<String>? title,
    Value<FilmRollStatus>? status,
    Value<String?>? selectedCourseId,
    Value<String?>? selectedCourseTitle,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? completedAt,
    Value<DateTime?>? developAvailableAt,
    Value<int?>? regionId,
    Value<String?>? filterId,
    Value<double?>? filterStrength,
    Value<int?>? serverFilmRollId,
    Value<String?>? serverStatus,
    Value<int>? rowid,
  }) {
    return FilmRollsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      regionCode: regionCode ?? this.regionCode,
      regionName: regionName ?? this.regionName,
      title: title ?? this.title,
      status: status ?? this.status,
      selectedCourseId: selectedCourseId ?? this.selectedCourseId,
      selectedCourseTitle: selectedCourseTitle ?? this.selectedCourseTitle,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      developAvailableAt: developAvailableAt ?? this.developAvailableAt,
      regionId: regionId ?? this.regionId,
      filterId: filterId ?? this.filterId,
      filterStrength: filterStrength ?? this.filterStrength,
      serverFilmRollId: serverFilmRollId ?? this.serverFilmRollId,
      serverStatus: serverStatus ?? this.serverStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (regionCode.present) {
      map['region_code'] = Variable<String>(
        $FilmRollsTable.$converterregionCode.toSql(regionCode.value),
      );
    }
    if (regionName.present) {
      map['region_name'] = Variable<String>(regionName.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $FilmRollsTable.$converterstatus.toSql(status.value),
      );
    }
    if (selectedCourseId.present) {
      map['selected_course_id'] = Variable<String>(selectedCourseId.value);
    }
    if (selectedCourseTitle.present) {
      map['selected_course_title'] = Variable<String>(
        selectedCourseTitle.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (developAvailableAt.present) {
      map['develop_available_at'] = Variable<DateTime>(
        developAvailableAt.value,
      );
    }
    if (regionId.present) {
      map['region_id'] = Variable<int>(regionId.value);
    }
    if (filterId.present) {
      map['filter_id'] = Variable<String>(filterId.value);
    }
    if (filterStrength.present) {
      map['filter_strength'] = Variable<double>(filterStrength.value);
    }
    if (serverFilmRollId.present) {
      map['server_film_roll_id'] = Variable<int>(serverFilmRollId.value);
    }
    if (serverStatus.present) {
      map['server_status'] = Variable<String>(serverStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FilmRollsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('regionCode: $regionCode, ')
          ..write('regionName: $regionName, ')
          ..write('title: $title, ')
          ..write('status: $status, ')
          ..write('selectedCourseId: $selectedCourseId, ')
          ..write('selectedCourseTitle: $selectedCourseTitle, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('developAvailableAt: $developAvailableAt, ')
          ..write('regionId: $regionId, ')
          ..write('filterId: $filterId, ')
          ..write('filterStrength: $filterStrength, ')
          ..write('serverFilmRollId: $serverFilmRollId, ')
          ..write('serverStatus: $serverStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FilmRollPlacesTable extends FilmRollPlaces
    with TableInfo<$FilmRollPlacesTable, FilmRollPlaceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FilmRollPlacesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filmRollIdMeta = const VerificationMeta(
    'filmRollId',
  );
  @override
  late final GeneratedColumn<String> filmRollId = GeneratedColumn<String>(
    'film_roll_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES film_rolls (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _serverPlaceIdMeta = const VerificationMeta(
    'serverPlaceId',
  );
  @override
  late final GeneratedColumn<int> serverPlaceId = GeneratedColumn<int>(
    'server_place_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _externalPlaceIdMeta = const VerificationMeta(
    'externalPlaceId',
  );
  @override
  late final GeneratedColumn<String> externalPlaceId = GeneratedColumn<String>(
    'external_place_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _visitOrderMeta = const VerificationMeta(
    'visitOrder',
  );
  @override
  late final GeneratedColumn<int> visitOrder = GeneratedColumn<int>(
    'visit_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isVisitedMeta = const VerificationMeta(
    'isVisited',
  );
  @override
  late final GeneratedColumn<bool> isVisited = GeneratedColumn<bool>(
    'is_visited',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_visited" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _visitedAtMeta = const VerificationMeta(
    'visitedAt',
  );
  @override
  late final GeneratedColumn<DateTime> visitedAt = GeneratedColumn<DateTime>(
    'visited_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _visitSyncedAtMeta = const VerificationMeta(
    'visitSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> visitSyncedAt =
      GeneratedColumn<DateTime>(
        'visit_synced_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    filmRollId,
    serverPlaceId,
    externalPlaceId,
    name,
    address,
    category,
    latitude,
    longitude,
    imageUrl,
    visitOrder,
    isVisited,
    visitedAt,
    visitSyncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'film_roll_places';
  @override
  VerificationContext validateIntegrity(
    Insertable<FilmRollPlaceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('film_roll_id')) {
      context.handle(
        _filmRollIdMeta,
        filmRollId.isAcceptableOrUnknown(
          data['film_roll_id']!,
          _filmRollIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_filmRollIdMeta);
    }
    if (data.containsKey('server_place_id')) {
      context.handle(
        _serverPlaceIdMeta,
        serverPlaceId.isAcceptableOrUnknown(
          data['server_place_id']!,
          _serverPlaceIdMeta,
        ),
      );
    }
    if (data.containsKey('external_place_id')) {
      context.handle(
        _externalPlaceIdMeta,
        externalPlaceId.isAcceptableOrUnknown(
          data['external_place_id']!,
          _externalPlaceIdMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    } else if (isInserting) {
      context.missing(_addressMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('visit_order')) {
      context.handle(
        _visitOrderMeta,
        visitOrder.isAcceptableOrUnknown(data['visit_order']!, _visitOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_visitOrderMeta);
    }
    if (data.containsKey('is_visited')) {
      context.handle(
        _isVisitedMeta,
        isVisited.isAcceptableOrUnknown(data['is_visited']!, _isVisitedMeta),
      );
    }
    if (data.containsKey('visited_at')) {
      context.handle(
        _visitedAtMeta,
        visitedAt.isAcceptableOrUnknown(data['visited_at']!, _visitedAtMeta),
      );
    }
    if (data.containsKey('visit_synced_at')) {
      context.handle(
        _visitSyncedAtMeta,
        visitSyncedAt.isAcceptableOrUnknown(
          data['visit_synced_at']!,
          _visitSyncedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {filmRollId, id},
  ];
  @override
  FilmRollPlaceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilmRollPlaceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      filmRollId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}film_roll_id'],
      )!,
      serverPlaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_place_id'],
      ),
      externalPlaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_place_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      visitOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}visit_order'],
      )!,
      isVisited: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_visited'],
      )!,
      visitedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}visited_at'],
      ),
      visitSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}visit_synced_at'],
      ),
    );
  }

  @override
  $FilmRollPlacesTable createAlias(String alias) {
    return $FilmRollPlacesTable(attachedDatabase, alias);
  }
}

class FilmRollPlaceRow extends DataClass
    implements Insertable<FilmRollPlaceRow> {
  final String id;
  final String filmRollId;
  final int? serverPlaceId;
  final String? externalPlaceId;
  final String name;
  final String address;
  final String category;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final int visitOrder;
  final bool isVisited;
  final DateTime? visitedAt;

  /// 이 장소의 방문 인증이 서버(`POST /film-rolls/{id}/visits`)에 반영된 시각.
  /// null이면 아직 서버로 전송되지 않은 상태.
  final DateTime? visitSyncedAt;
  const FilmRollPlaceRow({
    required this.id,
    required this.filmRollId,
    this.serverPlaceId,
    this.externalPlaceId,
    required this.name,
    required this.address,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    required this.visitOrder,
    required this.isVisited,
    this.visitedAt,
    this.visitSyncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['film_roll_id'] = Variable<String>(filmRollId);
    if (!nullToAbsent || serverPlaceId != null) {
      map['server_place_id'] = Variable<int>(serverPlaceId);
    }
    if (!nullToAbsent || externalPlaceId != null) {
      map['external_place_id'] = Variable<String>(externalPlaceId);
    }
    map['name'] = Variable<String>(name);
    map['address'] = Variable<String>(address);
    map['category'] = Variable<String>(category);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    map['visit_order'] = Variable<int>(visitOrder);
    map['is_visited'] = Variable<bool>(isVisited);
    if (!nullToAbsent || visitedAt != null) {
      map['visited_at'] = Variable<DateTime>(visitedAt);
    }
    if (!nullToAbsent || visitSyncedAt != null) {
      map['visit_synced_at'] = Variable<DateTime>(visitSyncedAt);
    }
    return map;
  }

  FilmRollPlacesCompanion toCompanion(bool nullToAbsent) {
    return FilmRollPlacesCompanion(
      id: Value(id),
      filmRollId: Value(filmRollId),
      serverPlaceId: serverPlaceId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverPlaceId),
      externalPlaceId: externalPlaceId == null && nullToAbsent
          ? const Value.absent()
          : Value(externalPlaceId),
      name: Value(name),
      address: Value(address),
      category: Value(category),
      latitude: Value(latitude),
      longitude: Value(longitude),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      visitOrder: Value(visitOrder),
      isVisited: Value(isVisited),
      visitedAt: visitedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(visitedAt),
      visitSyncedAt: visitSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(visitSyncedAt),
    );
  }

  factory FilmRollPlaceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilmRollPlaceRow(
      id: serializer.fromJson<String>(json['id']),
      filmRollId: serializer.fromJson<String>(json['filmRollId']),
      serverPlaceId: serializer.fromJson<int?>(json['serverPlaceId']),
      externalPlaceId: serializer.fromJson<String?>(json['externalPlaceId']),
      name: serializer.fromJson<String>(json['name']),
      address: serializer.fromJson<String>(json['address']),
      category: serializer.fromJson<String>(json['category']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      visitOrder: serializer.fromJson<int>(json['visitOrder']),
      isVisited: serializer.fromJson<bool>(json['isVisited']),
      visitedAt: serializer.fromJson<DateTime?>(json['visitedAt']),
      visitSyncedAt: serializer.fromJson<DateTime?>(json['visitSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'filmRollId': serializer.toJson<String>(filmRollId),
      'serverPlaceId': serializer.toJson<int?>(serverPlaceId),
      'externalPlaceId': serializer.toJson<String?>(externalPlaceId),
      'name': serializer.toJson<String>(name),
      'address': serializer.toJson<String>(address),
      'category': serializer.toJson<String>(category),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'visitOrder': serializer.toJson<int>(visitOrder),
      'isVisited': serializer.toJson<bool>(isVisited),
      'visitedAt': serializer.toJson<DateTime?>(visitedAt),
      'visitSyncedAt': serializer.toJson<DateTime?>(visitSyncedAt),
    };
  }

  FilmRollPlaceRow copyWith({
    String? id,
    String? filmRollId,
    Value<int?> serverPlaceId = const Value.absent(),
    Value<String?> externalPlaceId = const Value.absent(),
    String? name,
    String? address,
    String? category,
    double? latitude,
    double? longitude,
    Value<String?> imageUrl = const Value.absent(),
    int? visitOrder,
    bool? isVisited,
    Value<DateTime?> visitedAt = const Value.absent(),
    Value<DateTime?> visitSyncedAt = const Value.absent(),
  }) => FilmRollPlaceRow(
    id: id ?? this.id,
    filmRollId: filmRollId ?? this.filmRollId,
    serverPlaceId: serverPlaceId.present
        ? serverPlaceId.value
        : this.serverPlaceId,
    externalPlaceId: externalPlaceId.present
        ? externalPlaceId.value
        : this.externalPlaceId,
    name: name ?? this.name,
    address: address ?? this.address,
    category: category ?? this.category,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    visitOrder: visitOrder ?? this.visitOrder,
    isVisited: isVisited ?? this.isVisited,
    visitedAt: visitedAt.present ? visitedAt.value : this.visitedAt,
    visitSyncedAt: visitSyncedAt.present
        ? visitSyncedAt.value
        : this.visitSyncedAt,
  );
  FilmRollPlaceRow copyWithCompanion(FilmRollPlacesCompanion data) {
    return FilmRollPlaceRow(
      id: data.id.present ? data.id.value : this.id,
      filmRollId: data.filmRollId.present
          ? data.filmRollId.value
          : this.filmRollId,
      serverPlaceId: data.serverPlaceId.present
          ? data.serverPlaceId.value
          : this.serverPlaceId,
      externalPlaceId: data.externalPlaceId.present
          ? data.externalPlaceId.value
          : this.externalPlaceId,
      name: data.name.present ? data.name.value : this.name,
      address: data.address.present ? data.address.value : this.address,
      category: data.category.present ? data.category.value : this.category,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      visitOrder: data.visitOrder.present
          ? data.visitOrder.value
          : this.visitOrder,
      isVisited: data.isVisited.present ? data.isVisited.value : this.isVisited,
      visitedAt: data.visitedAt.present ? data.visitedAt.value : this.visitedAt,
      visitSyncedAt: data.visitSyncedAt.present
          ? data.visitSyncedAt.value
          : this.visitSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilmRollPlaceRow(')
          ..write('id: $id, ')
          ..write('filmRollId: $filmRollId, ')
          ..write('serverPlaceId: $serverPlaceId, ')
          ..write('externalPlaceId: $externalPlaceId, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('category: $category, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('visitOrder: $visitOrder, ')
          ..write('isVisited: $isVisited, ')
          ..write('visitedAt: $visitedAt, ')
          ..write('visitSyncedAt: $visitSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    filmRollId,
    serverPlaceId,
    externalPlaceId,
    name,
    address,
    category,
    latitude,
    longitude,
    imageUrl,
    visitOrder,
    isVisited,
    visitedAt,
    visitSyncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilmRollPlaceRow &&
          other.id == this.id &&
          other.filmRollId == this.filmRollId &&
          other.serverPlaceId == this.serverPlaceId &&
          other.externalPlaceId == this.externalPlaceId &&
          other.name == this.name &&
          other.address == this.address &&
          other.category == this.category &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.imageUrl == this.imageUrl &&
          other.visitOrder == this.visitOrder &&
          other.isVisited == this.isVisited &&
          other.visitedAt == this.visitedAt &&
          other.visitSyncedAt == this.visitSyncedAt);
}

class FilmRollPlacesCompanion extends UpdateCompanion<FilmRollPlaceRow> {
  final Value<String> id;
  final Value<String> filmRollId;
  final Value<int?> serverPlaceId;
  final Value<String?> externalPlaceId;
  final Value<String> name;
  final Value<String> address;
  final Value<String> category;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<String?> imageUrl;
  final Value<int> visitOrder;
  final Value<bool> isVisited;
  final Value<DateTime?> visitedAt;
  final Value<DateTime?> visitSyncedAt;
  final Value<int> rowid;
  const FilmRollPlacesCompanion({
    this.id = const Value.absent(),
    this.filmRollId = const Value.absent(),
    this.serverPlaceId = const Value.absent(),
    this.externalPlaceId = const Value.absent(),
    this.name = const Value.absent(),
    this.address = const Value.absent(),
    this.category = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.visitOrder = const Value.absent(),
    this.isVisited = const Value.absent(),
    this.visitedAt = const Value.absent(),
    this.visitSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FilmRollPlacesCompanion.insert({
    required String id,
    required String filmRollId,
    this.serverPlaceId = const Value.absent(),
    this.externalPlaceId = const Value.absent(),
    required String name,
    required String address,
    required String category,
    required double latitude,
    required double longitude,
    this.imageUrl = const Value.absent(),
    required int visitOrder,
    this.isVisited = const Value.absent(),
    this.visitedAt = const Value.absent(),
    this.visitSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       filmRollId = Value(filmRollId),
       name = Value(name),
       address = Value(address),
       category = Value(category),
       latitude = Value(latitude),
       longitude = Value(longitude),
       visitOrder = Value(visitOrder);
  static Insertable<FilmRollPlaceRow> custom({
    Expression<String>? id,
    Expression<String>? filmRollId,
    Expression<int>? serverPlaceId,
    Expression<String>? externalPlaceId,
    Expression<String>? name,
    Expression<String>? address,
    Expression<String>? category,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? imageUrl,
    Expression<int>? visitOrder,
    Expression<bool>? isVisited,
    Expression<DateTime>? visitedAt,
    Expression<DateTime>? visitSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (filmRollId != null) 'film_roll_id': filmRollId,
      if (serverPlaceId != null) 'server_place_id': serverPlaceId,
      if (externalPlaceId != null) 'external_place_id': externalPlaceId,
      if (name != null) 'name': name,
      if (address != null) 'address': address,
      if (category != null) 'category': category,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (imageUrl != null) 'image_url': imageUrl,
      if (visitOrder != null) 'visit_order': visitOrder,
      if (isVisited != null) 'is_visited': isVisited,
      if (visitedAt != null) 'visited_at': visitedAt,
      if (visitSyncedAt != null) 'visit_synced_at': visitSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FilmRollPlacesCompanion copyWith({
    Value<String>? id,
    Value<String>? filmRollId,
    Value<int?>? serverPlaceId,
    Value<String?>? externalPlaceId,
    Value<String>? name,
    Value<String>? address,
    Value<String>? category,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<String?>? imageUrl,
    Value<int>? visitOrder,
    Value<bool>? isVisited,
    Value<DateTime?>? visitedAt,
    Value<DateTime?>? visitSyncedAt,
    Value<int>? rowid,
  }) {
    return FilmRollPlacesCompanion(
      id: id ?? this.id,
      filmRollId: filmRollId ?? this.filmRollId,
      serverPlaceId: serverPlaceId ?? this.serverPlaceId,
      externalPlaceId: externalPlaceId ?? this.externalPlaceId,
      name: name ?? this.name,
      address: address ?? this.address,
      category: category ?? this.category,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      visitOrder: visitOrder ?? this.visitOrder,
      isVisited: isVisited ?? this.isVisited,
      visitedAt: visitedAt ?? this.visitedAt,
      visitSyncedAt: visitSyncedAt ?? this.visitSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (filmRollId.present) {
      map['film_roll_id'] = Variable<String>(filmRollId.value);
    }
    if (serverPlaceId.present) {
      map['server_place_id'] = Variable<int>(serverPlaceId.value);
    }
    if (externalPlaceId.present) {
      map['external_place_id'] = Variable<String>(externalPlaceId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (visitOrder.present) {
      map['visit_order'] = Variable<int>(visitOrder.value);
    }
    if (isVisited.present) {
      map['is_visited'] = Variable<bool>(isVisited.value);
    }
    if (visitedAt.present) {
      map['visited_at'] = Variable<DateTime>(visitedAt.value);
    }
    if (visitSyncedAt.present) {
      map['visit_synced_at'] = Variable<DateTime>(visitSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FilmRollPlacesCompanion(')
          ..write('id: $id, ')
          ..write('filmRollId: $filmRollId, ')
          ..write('serverPlaceId: $serverPlaceId, ')
          ..write('externalPlaceId: $externalPlaceId, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('category: $category, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('visitOrder: $visitOrder, ')
          ..write('isVisited: $isVisited, ')
          ..write('visitedAt: $visitedAt, ')
          ..write('visitSyncedAt: $visitSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PhotosTable extends Photos with TableInfo<$PhotosTable, Photo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PhotosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filmRollIdMeta = const VerificationMeta(
    'filmRollId',
  );
  @override
  late final GeneratedColumn<String> filmRollId = GeneratedColumn<String>(
    'film_roll_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES film_rolls (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _filmRollPlaceIdMeta = const VerificationMeta(
    'filmRollPlaceId',
  );
  @override
  late final GeneratedColumn<String> filmRollPlaceId = GeneratedColumn<String>(
    'film_roll_place_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalPathMeta = const VerificationMeta(
    'originalPath',
  );
  @override
  late final GeneratedColumn<String> originalPath = GeneratedColumn<String>(
    'original_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thumbnailPathMeta = const VerificationMeta(
    'thumbnailPath',
  );
  @override
  late final GeneratedColumn<String> thumbnailPath = GeneratedColumn<String>(
    'thumbnail_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _takenAtMeta = const VerificationMeta(
    'takenAt',
  );
  @override
  late final GeneratedColumn<DateTime> takenAt = GeneratedColumn<DateTime>(
    'taken_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sequenceMeta = const VerificationMeta(
    'sequence',
  );
  @override
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
    'sequence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _serverPhotoIdMeta = const VerificationMeta(
    'serverPhotoId',
  );
  @override
  late final GeneratedColumn<int> serverPhotoId = GeneratedColumn<int>(
    'server_photo_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    filmRollId,
    filmRollPlaceId,
    originalPath,
    thumbnailPath,
    latitude,
    longitude,
    takenAt,
    sequence,
    serverPhotoId,
    isSynced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'photos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Photo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('film_roll_id')) {
      context.handle(
        _filmRollIdMeta,
        filmRollId.isAcceptableOrUnknown(
          data['film_roll_id']!,
          _filmRollIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_filmRollIdMeta);
    }
    if (data.containsKey('film_roll_place_id')) {
      context.handle(
        _filmRollPlaceIdMeta,
        filmRollPlaceId.isAcceptableOrUnknown(
          data['film_roll_place_id']!,
          _filmRollPlaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_filmRollPlaceIdMeta);
    }
    if (data.containsKey('original_path')) {
      context.handle(
        _originalPathMeta,
        originalPath.isAcceptableOrUnknown(
          data['original_path']!,
          _originalPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalPathMeta);
    }
    if (data.containsKey('thumbnail_path')) {
      context.handle(
        _thumbnailPathMeta,
        thumbnailPath.isAcceptableOrUnknown(
          data['thumbnail_path']!,
          _thumbnailPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_thumbnailPathMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('taken_at')) {
      context.handle(
        _takenAtMeta,
        takenAt.isAcceptableOrUnknown(data['taken_at']!, _takenAtMeta),
      );
    } else if (isInserting) {
      context.missing(_takenAtMeta);
    }
    if (data.containsKey('sequence')) {
      context.handle(
        _sequenceMeta,
        sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta),
      );
    }
    if (data.containsKey('server_photo_id')) {
      context.handle(
        _serverPhotoIdMeta,
        serverPhotoId.isAcceptableOrUnknown(
          data['server_photo_id']!,
          _serverPhotoIdMeta,
        ),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Photo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Photo(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      filmRollId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}film_roll_id'],
      )!,
      filmRollPlaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}film_roll_place_id'],
      )!,
      originalPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_path'],
      )!,
      thumbnailPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_path'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      takenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}taken_at'],
      )!,
      sequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence'],
      )!,
      serverPhotoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_photo_id'],
      ),
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
    );
  }

  @override
  $PhotosTable createAlias(String alias) {
    return $PhotosTable(attachedDatabase, alias);
  }
}

class Photo extends DataClass implements Insertable<Photo> {
  final String id;
  final String filmRollId;
  final String filmRollPlaceId;
  final String originalPath;
  final String thumbnailPath;
  final double? latitude;
  final double? longitude;
  final DateTime takenAt;

  /// 서버 필름롤 안에서의 사진 순서(1~24). 촬영 시점에 로컬에서 부여하고
  /// `POST .../photos/upload-url` 의 sequence로 보낸다.
  final int sequence;

  /// 서버가 발급한 photoId. null이면 아직 업로드되지 않은 상태.
  final int? serverPhotoId;

  /// 서버 업로드 완료 여부. true면 [serverPhotoId]가 채워져 있다.
  final bool isSynced;
  const Photo({
    required this.id,
    required this.filmRollId,
    required this.filmRollPlaceId,
    required this.originalPath,
    required this.thumbnailPath,
    this.latitude,
    this.longitude,
    required this.takenAt,
    required this.sequence,
    this.serverPhotoId,
    required this.isSynced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['film_roll_id'] = Variable<String>(filmRollId);
    map['film_roll_place_id'] = Variable<String>(filmRollPlaceId);
    map['original_path'] = Variable<String>(originalPath);
    map['thumbnail_path'] = Variable<String>(thumbnailPath);
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    map['taken_at'] = Variable<DateTime>(takenAt);
    map['sequence'] = Variable<int>(sequence);
    if (!nullToAbsent || serverPhotoId != null) {
      map['server_photo_id'] = Variable<int>(serverPhotoId);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  PhotosCompanion toCompanion(bool nullToAbsent) {
    return PhotosCompanion(
      id: Value(id),
      filmRollId: Value(filmRollId),
      filmRollPlaceId: Value(filmRollPlaceId),
      originalPath: Value(originalPath),
      thumbnailPath: Value(thumbnailPath),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      takenAt: Value(takenAt),
      sequence: Value(sequence),
      serverPhotoId: serverPhotoId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverPhotoId),
      isSynced: Value(isSynced),
    );
  }

  factory Photo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Photo(
      id: serializer.fromJson<String>(json['id']),
      filmRollId: serializer.fromJson<String>(json['filmRollId']),
      filmRollPlaceId: serializer.fromJson<String>(json['filmRollPlaceId']),
      originalPath: serializer.fromJson<String>(json['originalPath']),
      thumbnailPath: serializer.fromJson<String>(json['thumbnailPath']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      takenAt: serializer.fromJson<DateTime>(json['takenAt']),
      sequence: serializer.fromJson<int>(json['sequence']),
      serverPhotoId: serializer.fromJson<int?>(json['serverPhotoId']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'filmRollId': serializer.toJson<String>(filmRollId),
      'filmRollPlaceId': serializer.toJson<String>(filmRollPlaceId),
      'originalPath': serializer.toJson<String>(originalPath),
      'thumbnailPath': serializer.toJson<String>(thumbnailPath),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'takenAt': serializer.toJson<DateTime>(takenAt),
      'sequence': serializer.toJson<int>(sequence),
      'serverPhotoId': serializer.toJson<int?>(serverPhotoId),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  Photo copyWith({
    String? id,
    String? filmRollId,
    String? filmRollPlaceId,
    String? originalPath,
    String? thumbnailPath,
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    DateTime? takenAt,
    int? sequence,
    Value<int?> serverPhotoId = const Value.absent(),
    bool? isSynced,
  }) => Photo(
    id: id ?? this.id,
    filmRollId: filmRollId ?? this.filmRollId,
    filmRollPlaceId: filmRollPlaceId ?? this.filmRollPlaceId,
    originalPath: originalPath ?? this.originalPath,
    thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    takenAt: takenAt ?? this.takenAt,
    sequence: sequence ?? this.sequence,
    serverPhotoId: serverPhotoId.present
        ? serverPhotoId.value
        : this.serverPhotoId,
    isSynced: isSynced ?? this.isSynced,
  );
  Photo copyWithCompanion(PhotosCompanion data) {
    return Photo(
      id: data.id.present ? data.id.value : this.id,
      filmRollId: data.filmRollId.present
          ? data.filmRollId.value
          : this.filmRollId,
      filmRollPlaceId: data.filmRollPlaceId.present
          ? data.filmRollPlaceId.value
          : this.filmRollPlaceId,
      originalPath: data.originalPath.present
          ? data.originalPath.value
          : this.originalPath,
      thumbnailPath: data.thumbnailPath.present
          ? data.thumbnailPath.value
          : this.thumbnailPath,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      takenAt: data.takenAt.present ? data.takenAt.value : this.takenAt,
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      serverPhotoId: data.serverPhotoId.present
          ? data.serverPhotoId.value
          : this.serverPhotoId,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Photo(')
          ..write('id: $id, ')
          ..write('filmRollId: $filmRollId, ')
          ..write('filmRollPlaceId: $filmRollPlaceId, ')
          ..write('originalPath: $originalPath, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('takenAt: $takenAt, ')
          ..write('sequence: $sequence, ')
          ..write('serverPhotoId: $serverPhotoId, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    filmRollId,
    filmRollPlaceId,
    originalPath,
    thumbnailPath,
    latitude,
    longitude,
    takenAt,
    sequence,
    serverPhotoId,
    isSynced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Photo &&
          other.id == this.id &&
          other.filmRollId == this.filmRollId &&
          other.filmRollPlaceId == this.filmRollPlaceId &&
          other.originalPath == this.originalPath &&
          other.thumbnailPath == this.thumbnailPath &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.takenAt == this.takenAt &&
          other.sequence == this.sequence &&
          other.serverPhotoId == this.serverPhotoId &&
          other.isSynced == this.isSynced);
}

class PhotosCompanion extends UpdateCompanion<Photo> {
  final Value<String> id;
  final Value<String> filmRollId;
  final Value<String> filmRollPlaceId;
  final Value<String> originalPath;
  final Value<String> thumbnailPath;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<DateTime> takenAt;
  final Value<int> sequence;
  final Value<int?> serverPhotoId;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const PhotosCompanion({
    this.id = const Value.absent(),
    this.filmRollId = const Value.absent(),
    this.filmRollPlaceId = const Value.absent(),
    this.originalPath = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.takenAt = const Value.absent(),
    this.sequence = const Value.absent(),
    this.serverPhotoId = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PhotosCompanion.insert({
    required String id,
    required String filmRollId,
    required String filmRollPlaceId,
    required String originalPath,
    required String thumbnailPath,
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    required DateTime takenAt,
    this.sequence = const Value.absent(),
    this.serverPhotoId = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       filmRollId = Value(filmRollId),
       filmRollPlaceId = Value(filmRollPlaceId),
       originalPath = Value(originalPath),
       thumbnailPath = Value(thumbnailPath),
       takenAt = Value(takenAt);
  static Insertable<Photo> custom({
    Expression<String>? id,
    Expression<String>? filmRollId,
    Expression<String>? filmRollPlaceId,
    Expression<String>? originalPath,
    Expression<String>? thumbnailPath,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<DateTime>? takenAt,
    Expression<int>? sequence,
    Expression<int>? serverPhotoId,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (filmRollId != null) 'film_roll_id': filmRollId,
      if (filmRollPlaceId != null) 'film_roll_place_id': filmRollPlaceId,
      if (originalPath != null) 'original_path': originalPath,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (takenAt != null) 'taken_at': takenAt,
      if (sequence != null) 'sequence': sequence,
      if (serverPhotoId != null) 'server_photo_id': serverPhotoId,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PhotosCompanion copyWith({
    Value<String>? id,
    Value<String>? filmRollId,
    Value<String>? filmRollPlaceId,
    Value<String>? originalPath,
    Value<String>? thumbnailPath,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<DateTime>? takenAt,
    Value<int>? sequence,
    Value<int?>? serverPhotoId,
    Value<bool>? isSynced,
    Value<int>? rowid,
  }) {
    return PhotosCompanion(
      id: id ?? this.id,
      filmRollId: filmRollId ?? this.filmRollId,
      filmRollPlaceId: filmRollPlaceId ?? this.filmRollPlaceId,
      originalPath: originalPath ?? this.originalPath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      takenAt: takenAt ?? this.takenAt,
      sequence: sequence ?? this.sequence,
      serverPhotoId: serverPhotoId ?? this.serverPhotoId,
      isSynced: isSynced ?? this.isSynced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (filmRollId.present) {
      map['film_roll_id'] = Variable<String>(filmRollId.value);
    }
    if (filmRollPlaceId.present) {
      map['film_roll_place_id'] = Variable<String>(filmRollPlaceId.value);
    }
    if (originalPath.present) {
      map['original_path'] = Variable<String>(originalPath.value);
    }
    if (thumbnailPath.present) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (takenAt.present) {
      map['taken_at'] = Variable<DateTime>(takenAt.value);
    }
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (serverPhotoId.present) {
      map['server_photo_id'] = Variable<int>(serverPhotoId.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PhotosCompanion(')
          ..write('id: $id, ')
          ..write('filmRollId: $filmRollId, ')
          ..write('filmRollPlaceId: $filmRollPlaceId, ')
          ..write('originalPath: $originalPath, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('takenAt: $takenAt, ')
          ..write('sequence: $sequence, ')
          ..write('serverPhotoId: $serverPhotoId, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FilmRollsTable filmRolls = $FilmRollsTable(this);
  late final $FilmRollPlacesTable filmRollPlaces = $FilmRollPlacesTable(this);
  late final $PhotosTable photos = $PhotosTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    filmRolls,
    filmRollPlaces,
    photos,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'film_rolls',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('film_roll_places', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'film_rolls',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('photos', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$FilmRollsTableCreateCompanionBuilder =
    FilmRollsCompanion Function({
      required String id,
      Value<int?> userId,
      required RegionCode regionCode,
      required String regionName,
      required String title,
      required FilmRollStatus status,
      Value<String?> selectedCourseId,
      Value<String?> selectedCourseTitle,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> completedAt,
      Value<DateTime?> developAvailableAt,
      Value<int?> regionId,
      Value<String?> filterId,
      Value<double?> filterStrength,
      Value<int?> serverFilmRollId,
      Value<String?> serverStatus,
      Value<int> rowid,
    });
typedef $$FilmRollsTableUpdateCompanionBuilder =
    FilmRollsCompanion Function({
      Value<String> id,
      Value<int?> userId,
      Value<RegionCode> regionCode,
      Value<String> regionName,
      Value<String> title,
      Value<FilmRollStatus> status,
      Value<String?> selectedCourseId,
      Value<String?> selectedCourseTitle,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> completedAt,
      Value<DateTime?> developAvailableAt,
      Value<int?> regionId,
      Value<String?> filterId,
      Value<double?> filterStrength,
      Value<int?> serverFilmRollId,
      Value<String?> serverStatus,
      Value<int> rowid,
    });

final class $$FilmRollsTableReferences
    extends BaseReferences<_$AppDatabase, $FilmRollsTable, FilmRollRow> {
  $$FilmRollsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$FilmRollPlacesTable, List<FilmRollPlaceRow>>
  _filmRollPlacesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.filmRollPlaces,
    aliasName: $_aliasNameGenerator(
      db.filmRolls.id,
      db.filmRollPlaces.filmRollId,
    ),
  );

  $$FilmRollPlacesTableProcessedTableManager get filmRollPlacesRefs {
    final manager = $$FilmRollPlacesTableTableManager(
      $_db,
      $_db.filmRollPlaces,
    ).filter((f) => f.filmRollId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_filmRollPlacesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PhotosTable, List<Photo>> _photosRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.photos,
    aliasName: $_aliasNameGenerator(db.filmRolls.id, db.photos.filmRollId),
  );

  $$PhotosTableProcessedTableManager get photosRefs {
    final manager = $$PhotosTableTableManager(
      $_db,
      $_db.photos,
    ).filter((f) => f.filmRollId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_photosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FilmRollsTableFilterComposer
    extends Composer<_$AppDatabase, $FilmRollsTable> {
  $$FilmRollsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<RegionCode, RegionCode, String>
  get regionCode => $composableBuilder(
    column: $table.regionCode,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get regionName => $composableBuilder(
    column: $table.regionName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<FilmRollStatus, FilmRollStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get selectedCourseId => $composableBuilder(
    column: $table.selectedCourseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get selectedCourseTitle => $composableBuilder(
    column: $table.selectedCourseTitle,
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

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get developAvailableAt => $composableBuilder(
    column: $table.developAvailableAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get regionId => $composableBuilder(
    column: $table.regionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filterId => $composableBuilder(
    column: $table.filterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get filterStrength => $composableBuilder(
    column: $table.filterStrength,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverFilmRollId => $composableBuilder(
    column: $table.serverFilmRollId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverStatus => $composableBuilder(
    column: $table.serverStatus,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> filmRollPlacesRefs(
    Expression<bool> Function($$FilmRollPlacesTableFilterComposer f) f,
  ) {
    final $$FilmRollPlacesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.filmRollPlaces,
      getReferencedColumn: (t) => t.filmRollId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FilmRollPlacesTableFilterComposer(
            $db: $db,
            $table: $db.filmRollPlaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> photosRefs(
    Expression<bool> Function($$PhotosTableFilterComposer f) f,
  ) {
    final $$PhotosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.photos,
      getReferencedColumn: (t) => t.filmRollId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PhotosTableFilterComposer(
            $db: $db,
            $table: $db.photos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FilmRollsTableOrderingComposer
    extends Composer<_$AppDatabase, $FilmRollsTable> {
  $$FilmRollsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get regionCode => $composableBuilder(
    column: $table.regionCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get regionName => $composableBuilder(
    column: $table.regionName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get selectedCourseId => $composableBuilder(
    column: $table.selectedCourseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get selectedCourseTitle => $composableBuilder(
    column: $table.selectedCourseTitle,
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

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get developAvailableAt => $composableBuilder(
    column: $table.developAvailableAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get regionId => $composableBuilder(
    column: $table.regionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filterId => $composableBuilder(
    column: $table.filterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get filterStrength => $composableBuilder(
    column: $table.filterStrength,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverFilmRollId => $composableBuilder(
    column: $table.serverFilmRollId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverStatus => $composableBuilder(
    column: $table.serverStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FilmRollsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FilmRollsTable> {
  $$FilmRollsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<RegionCode, String> get regionCode =>
      $composableBuilder(
        column: $table.regionCode,
        builder: (column) => column,
      );

  GeneratedColumn<String> get regionName => $composableBuilder(
    column: $table.regionName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumnWithTypeConverter<FilmRollStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get selectedCourseId => $composableBuilder(
    column: $table.selectedCourseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get selectedCourseTitle => $composableBuilder(
    column: $table.selectedCourseTitle,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get developAvailableAt => $composableBuilder(
    column: $table.developAvailableAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get regionId =>
      $composableBuilder(column: $table.regionId, builder: (column) => column);

  GeneratedColumn<String> get filterId =>
      $composableBuilder(column: $table.filterId, builder: (column) => column);

  GeneratedColumn<double> get filterStrength => $composableBuilder(
    column: $table.filterStrength,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverFilmRollId => $composableBuilder(
    column: $table.serverFilmRollId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serverStatus => $composableBuilder(
    column: $table.serverStatus,
    builder: (column) => column,
  );

  Expression<T> filmRollPlacesRefs<T extends Object>(
    Expression<T> Function($$FilmRollPlacesTableAnnotationComposer a) f,
  ) {
    final $$FilmRollPlacesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.filmRollPlaces,
      getReferencedColumn: (t) => t.filmRollId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FilmRollPlacesTableAnnotationComposer(
            $db: $db,
            $table: $db.filmRollPlaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> photosRefs<T extends Object>(
    Expression<T> Function($$PhotosTableAnnotationComposer a) f,
  ) {
    final $$PhotosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.photos,
      getReferencedColumn: (t) => t.filmRollId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PhotosTableAnnotationComposer(
            $db: $db,
            $table: $db.photos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FilmRollsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FilmRollsTable,
          FilmRollRow,
          $$FilmRollsTableFilterComposer,
          $$FilmRollsTableOrderingComposer,
          $$FilmRollsTableAnnotationComposer,
          $$FilmRollsTableCreateCompanionBuilder,
          $$FilmRollsTableUpdateCompanionBuilder,
          (FilmRollRow, $$FilmRollsTableReferences),
          FilmRollRow,
          PrefetchHooks Function({bool filmRollPlacesRefs, bool photosRefs})
        > {
  $$FilmRollsTableTableManager(_$AppDatabase db, $FilmRollsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FilmRollsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FilmRollsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FilmRollsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int?> userId = const Value.absent(),
                Value<RegionCode> regionCode = const Value.absent(),
                Value<String> regionName = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<FilmRollStatus> status = const Value.absent(),
                Value<String?> selectedCourseId = const Value.absent(),
                Value<String?> selectedCourseTitle = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime?> developAvailableAt = const Value.absent(),
                Value<int?> regionId = const Value.absent(),
                Value<String?> filterId = const Value.absent(),
                Value<double?> filterStrength = const Value.absent(),
                Value<int?> serverFilmRollId = const Value.absent(),
                Value<String?> serverStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FilmRollsCompanion(
                id: id,
                userId: userId,
                regionCode: regionCode,
                regionName: regionName,
                title: title,
                status: status,
                selectedCourseId: selectedCourseId,
                selectedCourseTitle: selectedCourseTitle,
                createdAt: createdAt,
                updatedAt: updatedAt,
                completedAt: completedAt,
                developAvailableAt: developAvailableAt,
                regionId: regionId,
                filterId: filterId,
                filterStrength: filterStrength,
                serverFilmRollId: serverFilmRollId,
                serverStatus: serverStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<int?> userId = const Value.absent(),
                required RegionCode regionCode,
                required String regionName,
                required String title,
                required FilmRollStatus status,
                Value<String?> selectedCourseId = const Value.absent(),
                Value<String?> selectedCourseTitle = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime?> developAvailableAt = const Value.absent(),
                Value<int?> regionId = const Value.absent(),
                Value<String?> filterId = const Value.absent(),
                Value<double?> filterStrength = const Value.absent(),
                Value<int?> serverFilmRollId = const Value.absent(),
                Value<String?> serverStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FilmRollsCompanion.insert(
                id: id,
                userId: userId,
                regionCode: regionCode,
                regionName: regionName,
                title: title,
                status: status,
                selectedCourseId: selectedCourseId,
                selectedCourseTitle: selectedCourseTitle,
                createdAt: createdAt,
                updatedAt: updatedAt,
                completedAt: completedAt,
                developAvailableAt: developAvailableAt,
                regionId: regionId,
                filterId: filterId,
                filterStrength: filterStrength,
                serverFilmRollId: serverFilmRollId,
                serverStatus: serverStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FilmRollsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({filmRollPlacesRefs = false, photosRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (filmRollPlacesRefs) db.filmRollPlaces,
                    if (photosRefs) db.photos,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (filmRollPlacesRefs)
                        await $_getPrefetchedData<
                          FilmRollRow,
                          $FilmRollsTable,
                          FilmRollPlaceRow
                        >(
                          currentTable: table,
                          referencedTable: $$FilmRollsTableReferences
                              ._filmRollPlacesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FilmRollsTableReferences(
                                db,
                                table,
                                p0,
                              ).filmRollPlacesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.filmRollId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (photosRefs)
                        await $_getPrefetchedData<
                          FilmRollRow,
                          $FilmRollsTable,
                          Photo
                        >(
                          currentTable: table,
                          referencedTable: $$FilmRollsTableReferences
                              ._photosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FilmRollsTableReferences(
                                db,
                                table,
                                p0,
                              ).photosRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.filmRollId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$FilmRollsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FilmRollsTable,
      FilmRollRow,
      $$FilmRollsTableFilterComposer,
      $$FilmRollsTableOrderingComposer,
      $$FilmRollsTableAnnotationComposer,
      $$FilmRollsTableCreateCompanionBuilder,
      $$FilmRollsTableUpdateCompanionBuilder,
      (FilmRollRow, $$FilmRollsTableReferences),
      FilmRollRow,
      PrefetchHooks Function({bool filmRollPlacesRefs, bool photosRefs})
    >;
typedef $$FilmRollPlacesTableCreateCompanionBuilder =
    FilmRollPlacesCompanion Function({
      required String id,
      required String filmRollId,
      Value<int?> serverPlaceId,
      Value<String?> externalPlaceId,
      required String name,
      required String address,
      required String category,
      required double latitude,
      required double longitude,
      Value<String?> imageUrl,
      required int visitOrder,
      Value<bool> isVisited,
      Value<DateTime?> visitedAt,
      Value<DateTime?> visitSyncedAt,
      Value<int> rowid,
    });
typedef $$FilmRollPlacesTableUpdateCompanionBuilder =
    FilmRollPlacesCompanion Function({
      Value<String> id,
      Value<String> filmRollId,
      Value<int?> serverPlaceId,
      Value<String?> externalPlaceId,
      Value<String> name,
      Value<String> address,
      Value<String> category,
      Value<double> latitude,
      Value<double> longitude,
      Value<String?> imageUrl,
      Value<int> visitOrder,
      Value<bool> isVisited,
      Value<DateTime?> visitedAt,
      Value<DateTime?> visitSyncedAt,
      Value<int> rowid,
    });

final class $$FilmRollPlacesTableReferences
    extends
        BaseReferences<_$AppDatabase, $FilmRollPlacesTable, FilmRollPlaceRow> {
  $$FilmRollPlacesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $FilmRollsTable _filmRollIdTable(_$AppDatabase db) =>
      db.filmRolls.createAlias(
        $_aliasNameGenerator(db.filmRollPlaces.filmRollId, db.filmRolls.id),
      );

  $$FilmRollsTableProcessedTableManager get filmRollId {
    final $_column = $_itemColumn<String>('film_roll_id')!;

    final manager = $$FilmRollsTableTableManager(
      $_db,
      $_db.filmRolls,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_filmRollIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FilmRollPlacesTableFilterComposer
    extends Composer<_$AppDatabase, $FilmRollPlacesTable> {
  $$FilmRollPlacesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverPlaceId => $composableBuilder(
    column: $table.serverPlaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalPlaceId => $composableBuilder(
    column: $table.externalPlaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get visitOrder => $composableBuilder(
    column: $table.visitOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isVisited => $composableBuilder(
    column: $table.isVisited,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get visitedAt => $composableBuilder(
    column: $table.visitedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get visitSyncedAt => $composableBuilder(
    column: $table.visitSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$FilmRollsTableFilterComposer get filmRollId {
    final $$FilmRollsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.filmRollId,
      referencedTable: $db.filmRolls,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FilmRollsTableFilterComposer(
            $db: $db,
            $table: $db.filmRolls,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FilmRollPlacesTableOrderingComposer
    extends Composer<_$AppDatabase, $FilmRollPlacesTable> {
  $$FilmRollPlacesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverPlaceId => $composableBuilder(
    column: $table.serverPlaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalPlaceId => $composableBuilder(
    column: $table.externalPlaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get visitOrder => $composableBuilder(
    column: $table.visitOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isVisited => $composableBuilder(
    column: $table.isVisited,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get visitedAt => $composableBuilder(
    column: $table.visitedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get visitSyncedAt => $composableBuilder(
    column: $table.visitSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$FilmRollsTableOrderingComposer get filmRollId {
    final $$FilmRollsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.filmRollId,
      referencedTable: $db.filmRolls,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FilmRollsTableOrderingComposer(
            $db: $db,
            $table: $db.filmRolls,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FilmRollPlacesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FilmRollPlacesTable> {
  $$FilmRollPlacesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverPlaceId => $composableBuilder(
    column: $table.serverPlaceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get externalPlaceId => $composableBuilder(
    column: $table.externalPlaceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<int> get visitOrder => $composableBuilder(
    column: $table.visitOrder,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isVisited =>
      $composableBuilder(column: $table.isVisited, builder: (column) => column);

  GeneratedColumn<DateTime> get visitedAt =>
      $composableBuilder(column: $table.visitedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get visitSyncedAt => $composableBuilder(
    column: $table.visitSyncedAt,
    builder: (column) => column,
  );

  $$FilmRollsTableAnnotationComposer get filmRollId {
    final $$FilmRollsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.filmRollId,
      referencedTable: $db.filmRolls,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FilmRollsTableAnnotationComposer(
            $db: $db,
            $table: $db.filmRolls,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FilmRollPlacesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FilmRollPlacesTable,
          FilmRollPlaceRow,
          $$FilmRollPlacesTableFilterComposer,
          $$FilmRollPlacesTableOrderingComposer,
          $$FilmRollPlacesTableAnnotationComposer,
          $$FilmRollPlacesTableCreateCompanionBuilder,
          $$FilmRollPlacesTableUpdateCompanionBuilder,
          (FilmRollPlaceRow, $$FilmRollPlacesTableReferences),
          FilmRollPlaceRow,
          PrefetchHooks Function({bool filmRollId})
        > {
  $$FilmRollPlacesTableTableManager(
    _$AppDatabase db,
    $FilmRollPlacesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FilmRollPlacesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FilmRollPlacesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FilmRollPlacesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> filmRollId = const Value.absent(),
                Value<int?> serverPlaceId = const Value.absent(),
                Value<String?> externalPlaceId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<int> visitOrder = const Value.absent(),
                Value<bool> isVisited = const Value.absent(),
                Value<DateTime?> visitedAt = const Value.absent(),
                Value<DateTime?> visitSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FilmRollPlacesCompanion(
                id: id,
                filmRollId: filmRollId,
                serverPlaceId: serverPlaceId,
                externalPlaceId: externalPlaceId,
                name: name,
                address: address,
                category: category,
                latitude: latitude,
                longitude: longitude,
                imageUrl: imageUrl,
                visitOrder: visitOrder,
                isVisited: isVisited,
                visitedAt: visitedAt,
                visitSyncedAt: visitSyncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String filmRollId,
                Value<int?> serverPlaceId = const Value.absent(),
                Value<String?> externalPlaceId = const Value.absent(),
                required String name,
                required String address,
                required String category,
                required double latitude,
                required double longitude,
                Value<String?> imageUrl = const Value.absent(),
                required int visitOrder,
                Value<bool> isVisited = const Value.absent(),
                Value<DateTime?> visitedAt = const Value.absent(),
                Value<DateTime?> visitSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FilmRollPlacesCompanion.insert(
                id: id,
                filmRollId: filmRollId,
                serverPlaceId: serverPlaceId,
                externalPlaceId: externalPlaceId,
                name: name,
                address: address,
                category: category,
                latitude: latitude,
                longitude: longitude,
                imageUrl: imageUrl,
                visitOrder: visitOrder,
                isVisited: isVisited,
                visitedAt: visitedAt,
                visitSyncedAt: visitSyncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FilmRollPlacesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({filmRollId = false}) {
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
                    if (filmRollId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.filmRollId,
                                referencedTable: $$FilmRollPlacesTableReferences
                                    ._filmRollIdTable(db),
                                referencedColumn:
                                    $$FilmRollPlacesTableReferences
                                        ._filmRollIdTable(db)
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

typedef $$FilmRollPlacesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FilmRollPlacesTable,
      FilmRollPlaceRow,
      $$FilmRollPlacesTableFilterComposer,
      $$FilmRollPlacesTableOrderingComposer,
      $$FilmRollPlacesTableAnnotationComposer,
      $$FilmRollPlacesTableCreateCompanionBuilder,
      $$FilmRollPlacesTableUpdateCompanionBuilder,
      (FilmRollPlaceRow, $$FilmRollPlacesTableReferences),
      FilmRollPlaceRow,
      PrefetchHooks Function({bool filmRollId})
    >;
typedef $$PhotosTableCreateCompanionBuilder =
    PhotosCompanion Function({
      required String id,
      required String filmRollId,
      required String filmRollPlaceId,
      required String originalPath,
      required String thumbnailPath,
      Value<double?> latitude,
      Value<double?> longitude,
      required DateTime takenAt,
      Value<int> sequence,
      Value<int?> serverPhotoId,
      Value<bool> isSynced,
      Value<int> rowid,
    });
typedef $$PhotosTableUpdateCompanionBuilder =
    PhotosCompanion Function({
      Value<String> id,
      Value<String> filmRollId,
      Value<String> filmRollPlaceId,
      Value<String> originalPath,
      Value<String> thumbnailPath,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<DateTime> takenAt,
      Value<int> sequence,
      Value<int?> serverPhotoId,
      Value<bool> isSynced,
      Value<int> rowid,
    });

final class $$PhotosTableReferences
    extends BaseReferences<_$AppDatabase, $PhotosTable, Photo> {
  $$PhotosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FilmRollsTable _filmRollIdTable(_$AppDatabase db) => db.filmRolls
      .createAlias($_aliasNameGenerator(db.photos.filmRollId, db.filmRolls.id));

  $$FilmRollsTableProcessedTableManager get filmRollId {
    final $_column = $_itemColumn<String>('film_roll_id')!;

    final manager = $$FilmRollsTableTableManager(
      $_db,
      $_db.filmRolls,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_filmRollIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PhotosTableFilterComposer
    extends Composer<_$AppDatabase, $PhotosTable> {
  $$PhotosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filmRollPlaceId => $composableBuilder(
    column: $table.filmRollPlaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalPath => $composableBuilder(
    column: $table.originalPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverPhotoId => $composableBuilder(
    column: $table.serverPhotoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  $$FilmRollsTableFilterComposer get filmRollId {
    final $$FilmRollsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.filmRollId,
      referencedTable: $db.filmRolls,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FilmRollsTableFilterComposer(
            $db: $db,
            $table: $db.filmRolls,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PhotosTableOrderingComposer
    extends Composer<_$AppDatabase, $PhotosTable> {
  $$PhotosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filmRollPlaceId => $composableBuilder(
    column: $table.filmRollPlaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalPath => $composableBuilder(
    column: $table.originalPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverPhotoId => $composableBuilder(
    column: $table.serverPhotoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  $$FilmRollsTableOrderingComposer get filmRollId {
    final $$FilmRollsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.filmRollId,
      referencedTable: $db.filmRolls,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FilmRollsTableOrderingComposer(
            $db: $db,
            $table: $db.filmRolls,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PhotosTableAnnotationComposer
    extends Composer<_$AppDatabase, $PhotosTable> {
  $$PhotosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get filmRollPlaceId => $composableBuilder(
    column: $table.filmRollPlaceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originalPath => $composableBuilder(
    column: $table.originalPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<DateTime> get takenAt =>
      $composableBuilder(column: $table.takenAt, builder: (column) => column);

  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  GeneratedColumn<int> get serverPhotoId => $composableBuilder(
    column: $table.serverPhotoId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  $$FilmRollsTableAnnotationComposer get filmRollId {
    final $$FilmRollsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.filmRollId,
      referencedTable: $db.filmRolls,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FilmRollsTableAnnotationComposer(
            $db: $db,
            $table: $db.filmRolls,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PhotosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PhotosTable,
          Photo,
          $$PhotosTableFilterComposer,
          $$PhotosTableOrderingComposer,
          $$PhotosTableAnnotationComposer,
          $$PhotosTableCreateCompanionBuilder,
          $$PhotosTableUpdateCompanionBuilder,
          (Photo, $$PhotosTableReferences),
          Photo,
          PrefetchHooks Function({bool filmRollId})
        > {
  $$PhotosTableTableManager(_$AppDatabase db, $PhotosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PhotosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PhotosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PhotosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> filmRollId = const Value.absent(),
                Value<String> filmRollPlaceId = const Value.absent(),
                Value<String> originalPath = const Value.absent(),
                Value<String> thumbnailPath = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<DateTime> takenAt = const Value.absent(),
                Value<int> sequence = const Value.absent(),
                Value<int?> serverPhotoId = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PhotosCompanion(
                id: id,
                filmRollId: filmRollId,
                filmRollPlaceId: filmRollPlaceId,
                originalPath: originalPath,
                thumbnailPath: thumbnailPath,
                latitude: latitude,
                longitude: longitude,
                takenAt: takenAt,
                sequence: sequence,
                serverPhotoId: serverPhotoId,
                isSynced: isSynced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String filmRollId,
                required String filmRollPlaceId,
                required String originalPath,
                required String thumbnailPath,
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                required DateTime takenAt,
                Value<int> sequence = const Value.absent(),
                Value<int?> serverPhotoId = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PhotosCompanion.insert(
                id: id,
                filmRollId: filmRollId,
                filmRollPlaceId: filmRollPlaceId,
                originalPath: originalPath,
                thumbnailPath: thumbnailPath,
                latitude: latitude,
                longitude: longitude,
                takenAt: takenAt,
                sequence: sequence,
                serverPhotoId: serverPhotoId,
                isSynced: isSynced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$PhotosTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({filmRollId = false}) {
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
                    if (filmRollId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.filmRollId,
                                referencedTable: $$PhotosTableReferences
                                    ._filmRollIdTable(db),
                                referencedColumn: $$PhotosTableReferences
                                    ._filmRollIdTable(db)
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

typedef $$PhotosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PhotosTable,
      Photo,
      $$PhotosTableFilterComposer,
      $$PhotosTableOrderingComposer,
      $$PhotosTableAnnotationComposer,
      $$PhotosTableCreateCompanionBuilder,
      $$PhotosTableUpdateCompanionBuilder,
      (Photo, $$PhotosTableReferences),
      Photo,
      PrefetchHooks Function({bool filmRollId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FilmRollsTableTableManager get filmRolls =>
      $$FilmRollsTableTableManager(_db, _db.filmRolls);
  $$FilmRollPlacesTableTableManager get filmRollPlaces =>
      $$FilmRollPlacesTableTableManager(_db, _db.filmRollPlaces);
  $$PhotosTableTableManager get photos =>
      $$PhotosTableTableManager(_db, _db.photos);
}
