import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';

class FireContactService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addNote(String name,String phone,String email,bool favorite) async {
    await _db.collection('examen2').add({
      'name': name,
      'phone': phone,
      'email': email,
      'createAt': DateTime.now(),
      'favorite': favorite
    });
  }


  Stream<QuerySnapshot> getNoteStream() {
    return _db.collection('examen2').orderBy('createAt', descending: true).snapshots();
  }



  Future<void> updateNote(String id, String name,String phone,String email,bool favorite) async{
  await _db.collection('examen2').doc(id).update({ 
    'name': name,     
    'phone': phone,
      'email': email,
      'favorite': favorite
      });
}

Future<void> deleteNote(String id) async{
  await _db.collection('examen2').doc(id).delete();
}

}
