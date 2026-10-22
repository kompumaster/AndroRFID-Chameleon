import 'dart:typed_data';

import '../../core/chameleon/helpers/utils.dart';
import '../openspool/openspool_data.dart';
import '../openspool/openspool_ntag.dart';
import '../qidi/qidi_data.dart';

enum TagRecordType { qidi, openspool }

class TagRecord {
  TagRecord({
    required this.id,
    required this.name,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.qidiModel,
    this.qidiData,
    this.openspoolProfile,
    this.openspoolTier,
    this.openspoolData,
  });

  final String id;
  String name;
  final TagRecordType type;
  final DateTime createdAt;
  DateTime updatedAt;
  final QidiPrinterModel? qidiModel;
  final QidiTagData? qidiData;
  final OpenSpoolProfile? openspoolProfile;
  final OpenSpoolTier? openspoolTier;
  final OpenSpoolTagData? openspoolData;

  String get summary {
    if (type == TagRecordType.qidi && qidiData != null) {
      return qidiData!.describe(qidiModel ?? QidiPrinterModel.plus4);
    }
    if (type == TagRecordType.openspool && openspoolData != null) {
      return openspoolData!.displayName;
    }
    return 'Метка';
  }

  TagRecord copyWith({String? name}) {
    return TagRecord(
      id: id,
      name: name ?? this.name,
      type: type,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      qidiModel: qidiModel,
      qidiData: qidiData,
      openspoolProfile: openspoolProfile,
      openspoolTier: openspoolTier,
      openspoolData: openspoolData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (qidiModel != null) 'qidiModel': qidiModel!.name,
      if (qidiData != null)
        'qidi': {
          'materialId': qidiData!.materialId,
          'colorId': qidiData!.colorId,
          'manufacturerId': qidiData!.manufacturerId,
          if (qidiData!.rawBlock != null)
            'rawBlock': bytesToHex(qidiData!.rawBlock!),
          if (qidiData!.uid != null) 'uid': bytesToHex(qidiData!.uid!),
        },
      if (openspoolData != null)
        'openspool': {
          'profile': (openspoolProfile ?? OpenSpoolProfile.standard).name,
          'tier': (openspoolTier ?? OpenSpoolTier.all).name,
          'ntagType': openspoolData!.ntagType.name,
          'json': openspoolData!.toJson(
            profile: openspoolProfile ?? OpenSpoolProfile.standard,
            tier: openspoolTier ?? OpenSpoolTier.all,
          ),
          if (openspoolData!.uid != null)
            'uid': bytesToHex(openspoolData!.uid!),
        },
    };
  }

  static TagRecord? fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final name = json['name'] as String?;
    final typeName = json['type'] as String?;
    if (id == null || name == null || typeName == null) {
      return null;
    }

    final type = TagRecordType.values
        .where((value) => value.name == typeName)
        .firstOrNull;
    if (type == null) {
      return null;
    }

    final createdAt =
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now();
    final updatedAt =
        DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? createdAt;

    QidiPrinterModel? qidiModel;
    final modelName = json['qidiModel'] as String?;
    if (modelName != null) {
      qidiModel = QidiPrinterModel.values
          .where((value) => value.name == modelName)
          .firstOrNull;
    }

    QidiTagData? qidiData;
    final qidiJson = json['qidi'];
    if (qidiJson is Map) {
      final materialId = qidiJson['materialId'];
      final colorId = qidiJson['colorId'];
      final manufacturerId = qidiJson['manufacturerId'];
      if (materialId is int && colorId is int && manufacturerId is int) {
        Uint8List? rawBlock;
        final raw = qidiJson['rawBlock'];
        if (raw is String && raw.isNotEmpty) {
          rawBlock = hexToBytes(raw);
        }
        Uint8List? uid;
        final uidHex = qidiJson['uid'];
        if (uidHex is String && uidHex.isNotEmpty) {
          uid = hexToBytes(uidHex);
        }
        qidiData = QidiTagData(
          materialId: materialId,
          colorId: colorId,
          manufacturerId: manufacturerId,
          rawBlock: rawBlock,
          uid: uid,
        );
      }
    }

    final openspool = json['openspool'];
    OpenSpoolProfile? openspoolProfile;
    OpenSpoolTier? openspoolTier;
    OpenSpoolTagData? openspoolData;
    if (openspool is Map) {
      final profileName = openspool['profile'];
      if (profileName is String) {
        openspoolProfile = OpenSpoolProfile.values
            .where((value) => value.name == profileName)
            .firstOrNull;
      }
      final tierName = openspool['tier'];
      if (tierName is String) {
        openspoolTier = OpenSpoolTier.values
            .where((value) => value.name == tierName)
            .firstOrNull;
      }
      var ntagType = OpenSpoolNtagType.ntag215;
      final ntagTypeName = openspool['ntagType'];
      if (ntagTypeName is String) {
        ntagType =
            OpenSpoolNtagType.values
                .where((value) => value.name == ntagTypeName)
                .firstOrNull ??
            ntagType;
      }
      final dataJson = openspool['json'];
      if (dataJson is Map) {
        try {
          openspoolData = OpenSpoolTagData.fromJson(
            Map<String, dynamic>.from(dataJson),
          ).withNtagType(ntagType);
        } on OpenSpoolFormatException {
          openspoolData = null;
        }
        final uidHex = openspool['uid'];
        if (openspoolData != null && uidHex is String && uidHex.isNotEmpty) {
          openspoolData = openspoolData.withUid(hexToBytes(uidHex));
        }
      }
    }

    return TagRecord(
      id: id,
      name: name,
      type: type,
      createdAt: createdAt,
      updatedAt: updatedAt,
      qidiModel: qidiModel,
      qidiData: qidiData,
      openspoolProfile: openspoolProfile,
      openspoolTier: openspoolTier,
      openspoolData: openspoolData,
    );
  }
}
