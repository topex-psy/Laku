import 'package:flutter/material.dart';
// import 'constants.dart';

class SessionModel {
  SessionModel({
    required this.id,
    required this.email,
    required this.loginTime,
  });

  final int id;
  final String email;
  final DateTime loginTime;

  SessionModel.fromUserModel(UserModel user)
  : id = user.id,
    email = user.email,
    loginTime = DateTime.now();

  @override
  String toString() => "SessionModel ($id/$email/$loginTime)";
}

class RegisterModel {
  RegisterModel({
    required this.name,
    required this.password,
    required this.email,
    required this.gender,
    required this.dob,
    required this.isFingerPrint,
    required this.isFacebook,
    this.lastLatitude,
    this.lastLongitude,
    this.image,
  });

  final String name;
  final String password;
  final String email;
  final String gender;
  final String dob;
  final double? lastLatitude;
  final double? lastLongitude;
  final String? image;
  final bool isFingerPrint;
  final bool isFacebook;

  toJson() => {
    "name": name,
    "password": password,
    "email": email,
    "gender": gender,
    "dob": dob.split("/").reversed.join("-"),
    "last_latitude": lastLatitude,
    "last_longitude": lastLongitude,
    "image": image,
    "is_fingerprint": isFingerPrint,
    "is_facebook": isFacebook,
  };

  @override
  String toString() => "RegisterModel: ${toJson()}";
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

class PageModel {
  PageModel({required this.title, required this.icon, required this.content});
  String title;
  IconData icon;
  Widget content;
}

class NotifModel {
  NotifModel({
    required this.listingPosted,
    required this.listingFavorites,
    required this.broadcastActive,
    required this.inbox,
    required this.notification,
    required this.broadcastTicket,
    required this.listing,
    required this.user,
    required this.seeker,
  });

  final int listingPosted;
  final int listingFavorites;
  final int broadcastActive;
  final int inbox;
  final int notification;
  final int broadcastTicket;
  final int listing;
  final int user;
  final int seeker;

  NotifModel.fromJson(Map<String, dynamic> row)
  : listingPosted    = int.parse(row['listing_posted']),
    listingFavorites = int.parse(row['listing_favorites']),
    broadcastActive  = int.parse(row['broadcast_active']),
    inbox            = int.parse(row['inbox']),
    notification     = int.parse(row['notification']),
    broadcastTicket  = int.parse(row['broadcast_ticket']),
    listing          = int.parse(row['listing']),
    user             = int.parse(row['user']),
    seeker           = int.parse(row['seeker']);
}

class UserModel {
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.gender,
    required this.dob,
    required this.phone,
    required this.image,
    required this.listingCount,
    required this.shopCount,
    required this.favoriteCount,
    required this.isMine,
    required this.isNear,
    required this.isFavorite,
    required this.lastActive,
    required this.lastLatitude,
    required this.lastLongitude,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String email;
  final String gender;
  final DateTime dob;
  final String? phone;
  final String image;
  final int? listingCount;
  final int? shopCount;
  final int? favoriteCount;
  final bool? isMine;
  final bool? isNear;
  final bool? isFavorite;
  final DateTime lastActive;
  final double lastLatitude;
  final double lastLongitude;
  final DateTime createdAt;

  UserModel.fromJson(Map<String, dynamic> row)
  : id = int.parse(row['id']),
    name = row['name'],
    email = row['email'],
    gender = row['gender'],
    dob = DateTime.parse(row['dob']),
    phone = row['phone'],
    image = row['image'],
    listingCount = int.tryParse(row['listing_count']??""),
    shopCount = int.tryParse(row['shop_count']??""),
    favoriteCount = int.tryParse(row['favorite_count']??""),
    isMine = row['is_mine'],
    isNear = row['is_near'],
    isFavorite = row['is_favorite'],
    lastActive = DateTime.parse(row['last_active']),
    lastLatitude = double.parse(row['last_latitude']),
    lastLongitude = double.parse(row['last_longitude']),
    createdAt = DateTime.parse(row['created_at']);

  @override
  String toString() => "UserModel ($id/$name/$email/$gender/$dob)";
}

class ListingModel {
  ListingModel({
    required this.id,
    required this.owner,
    required this.shop,
    required this.type,
    required this.category,
    required this.subcategory,
    required this.title,
    required this.description,
    required this.images,
    required this.price,
    required this.viewCount,
    required this.latitude,
    required this.longitude,
    required this.distanceMeter,
    required this.isMine,
    required this.isNear,
    required this.isNew,
    required this.isForAdult,
    required this.isNegotiable,
    required this.deliveryInfo,
    required this.isFavorite,
    required this.favoriteCount,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final UserModel owner;
  final ShopModel? shop;
  final String type;
  final String? category;
  final String? subcategory;
  final String title;
  final String description;
  final List<String> images;
  final double price;
  final int viewCount;
  final double latitude;
  final double longitude;
  final double distanceMeter;
  final bool isMine;
  final bool isNear;
  final bool isNew;
  final bool isForAdult;
  final bool isNegotiable;
  final String? deliveryInfo;
  final DateTime createdAt;
  final DateTime updatedAt;
  bool isFavorite;
  int favoriteCount;

  toggleFav() {
    isFavorite = !isFavorite;
    if (isFavorite) {
      favoriteCount++;
    } else if (favoriteCount > 0) {
      favoriteCount--;
    }
  }

  ListingModel.fromJson(Map<String, dynamic> row)
  : id = int.parse(row['id']),
    owner = UserModel.fromJson(row['user']),
    shop = ShopModel.fromJson(row['shop']),
    type = row['type'],
    category = row['category'],
    subcategory = row['subcategory'],
    title = row['title'],
    description = row['description'],
    images = List<String>.from(row['images']),
    price = double.parse(row['price']),
    viewCount = int.parse(row['view_count']??'0'),
    latitude = double.parse(row['latitude']),
    longitude = double.parse(row['longitude']),
    distanceMeter = double.parse(row['distance_meter']),
    deliveryInfo = row['delivery_info'],
    isMine = row['is_mine'],
    isNear = row['is_near'],
    isNew = row['is_new']??true,
    isForAdult = row['is_for_adult']??false,
    isNegotiable = row['is_negotiable']??false,
    isFavorite = row['is_favorite'],
    favoriteCount = int.parse(row['favorite_count']),
    createdAt = DateTime.parse(row['created_at']),
    updatedAt = DateTime.parse(row['updated_at']);
}

class ShopModel {
  ShopModel({
    required this.id,
    required this.type,
    required this.category,
    required this.subcategory,
    required this.name,
    required this.address,
    required this.phone,
    required this.image,
    required this.listingCount,
    required this.favoriteCount,
    required this.isFavorite,
    required this.isMine,
    required this.isNear,
    required this.createdAt,
  });

  final int id;
  final String type;
  final String? category;
  final String? subcategory;
  final String name;
  final String? address;
  final String? phone;
  final String? image;
  final int listingCount;
  final int favoriteCount;
  final bool isFavorite;
  final bool isMine;
  final bool isNear;
  final DateTime createdAt;

  ShopModel.fromJson(Map<String, dynamic> row)
  : id = int.parse(row['id']),
    type = row['type'],
    category = row['category'],
    subcategory = row['subcategory'],
    name = row['name'],
    address = row['address'],
    phone = row['phone'],
    image = row['image'],
    listingCount = int.parse(row['listing_count']),
    favoriteCount = int.parse(row['favorite_count']),
    isFavorite = row['is_favorite'],
    isMine = row['is_mine'],
    isNear = row['is_near'],
    createdAt = DateTime.parse(row['created_at']);
}
