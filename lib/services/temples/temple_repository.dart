import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/temple_config.dart';

class TempleRepository {
  TempleRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _templesRef =>
      _firestore.collection('temples');

  Future<TempleConfig?> fetchTempleById(String templeId) async {
    try {
      final doc = await _templesRef.doc(templeId).get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      final temple = TempleConfig.fromMap(doc.data()!);

      if (!temple.active) {
        return null;
      }

      if (temple.id.trim().isEmpty) {
        return null;
      }

      return temple;
    } catch (_) {
      return null;
    }
  }
}
