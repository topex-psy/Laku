import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report.dart';
import '../utils/helpers.dart';

class FirestoreService {
  Firestore _firestore = Firestore.instance;

  Stream<List<ReportModel>> getReports() {
    return _firestore.collection('reports')
      .where('uid', isEqualTo: currentPersonUid)
      .orderBy('timee', descending: true)
      .snapshots()
      .map((snapshot) => snapshot
        .documents
        .map((document) => ReportModel.fromJson(document.data))
        .toList());
  }

  Stream<ReportModel> getReport() {
    print(" ==> GETTING REPORT ...............");
    return _firestore.collection('reports')
      .where('uid', isEqualTo: currentPersonUid)
      .orderBy('timee', descending: true)
      .limit(1)
      .snapshots()
      .map((snapshot) => ReportModel.fromJson(snapshot.documents[0].data));
  }

  Future addReport(Map<String, dynamic> dataMap) {
    return _firestore.collection('reports').add(dataMap);
  }
}
