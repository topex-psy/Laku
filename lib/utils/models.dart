import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'constants.dart';

class SessionModel {
  SessionModel({
    required this.id,
    required this.email,
    required this.name,
    this.address,
    this.phone,
    this.photo,
    this.dob,
  });

  final int id;
  final String email;
  final String name;
  final String? address;
  final String? phone;
  final String? photo;
  final DateTime? dob;

  SessionModel.fromJson(Map<String, dynamic> loginData)
  : id = int.tryParse(loginData['id'].toString()) ?? 0,
    email = loginData['email'],
    name = loginData['fullname'],
    address = loginData['address'],
    phone = loginData['phone'],
    photo = loginData['photo'],
    dob = DateTime.tryParse(loginData['dob'] ?? "");

  String getUserPic({double size = 50.0}) {
    return photo ?? DEFAULT_USER_PIC_ASSET;
    // final fallbackImage = Image.asset(DEFAULT_USER_PIC_ASSET, width: size, height: size, fit: BoxFit.cover);
    // return photo == null ? fallbackImage : CachedNetworkImage(
    //   imageUrl: Uri.encodeFull(photo!),
    //   placeholder: (context, url) => SizedBox(width: size, height: size, child: const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: APP_UI_COLOR_MAIN))),
    //   errorWidget: (context, url, error) => fallbackImage,
    //   width: size, height: size,
    //   fit: BoxFit.cover,
    // );
  }

  @override
  String toString() => "SessionModel ($id/$name/$email)";
}

class MenuModel {
  MenuModel(this.label, this.value, {this.additionalValue, this.icon, this.color, this.size, this.total, this.onPressed});
  final String label;
  final dynamic value;
  final dynamic additionalValue;
  final IconData? icon;
  final Color? color;
  final double? size;
  final int? total;
  final VoidCallback? onPressed;

  @override
  String toString() => label;

  @override
  int get hashCode => 1;

  @override
  bool operator ==(Object other) => identical(this, other) || (
    other is MenuModel &&
    runtimeType == other.runtimeType &&
    other.label == label &&
    other.value == value
  );
}

class ContentModel {
  ContentModel({required this.title, this.description, this.image});
  final String title;
  final String? description;
  final String? image;
}