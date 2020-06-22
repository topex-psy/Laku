import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../utils/helpers.dart';

class FirestoreService {
  Firestore _firestore = Firestore.instance;

  Stream<List<UserModel>> getReports() {
    return _firestore.collection('users')
      .where('uid', isEqualTo: userSession.uid)
      .orderBy('timee', descending: true)
      .snapshots()
      .map((snapshot) => snapshot
        .documents
        .map((document) => UserModel.fromJson(document.data))
        .toList());
  }

  Stream<UserModel> getUser() {
    print(" ==> FIRESTORE GETTING USER ...............");
    return _firestore.collection('users')
      .where('uid', isEqualTo: userSession.uid)
      .orderBy('timee', descending: true)
      .limit(1)
      .snapshots()
      .map((snapshot) => UserModel.fromJson(snapshot.documents[0].data));
  }

  Future<void> addUser(Map<String, dynamic> dataMap) {
    return _firestore.collection('users').add(dataMap);
  }

  Future<void> setUser(Map<String, dynamic> dataMap) {
    return _firestore.collection('users').document().setData(dataMap);
  }

  listenUser(dynamic Function(dynamic) listener) {
    _firestore
      .collection('users')
      .where('uid', isEqualTo: userSession.uid)
      .snapshots()
      .listen(listener);
  }
}
