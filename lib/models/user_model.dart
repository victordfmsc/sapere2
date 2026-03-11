import 'dart:convert';

class UserModel {
  String uId;
  String userName;
  String email;
  String profileImage;
  String gender;
  String phone;
  String dateOfBirth;
  String address;
  String userType;
  int credits;
  String signIn;
  String? lastCreditSync;
  Map<String, String>? shippingAddress;

  UserModel({
    required this.uId,
    required this.userName,
    required this.email,
    required this.profileImage,
    required this.gender,
    required this.phone,
    required this.dateOfBirth,
    required this.address,
    required this.userType,
    required this.credits,
    required this.signIn,
    this.lastCreditSync,
    this.shippingAddress,
  });

  UserModel copyWith({
    String? uId,
    String? userName,
    String? email,
    String? profileImage,
    String? gender,
    String? phone,
    String? dateOfBirth,
    String? address,
    String? userType,
    int? credits,
    String? signIn,
    String? lastCreditSync,
    Map<String, String>? shippingAddress,
  }) {
    return UserModel(
      uId: uId ?? this.uId,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      userType: userType ?? this.userType,
      credits: credits ?? this.credits,
      signIn: signIn ?? this.signIn,
      lastCreditSync: lastCreditSync ?? this.lastCreditSync,
      shippingAddress: shippingAddress ?? this.shippingAddress,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'uId': uId});
    result.addAll({'userName': userName});
    result.addAll({'email': email});
    result.addAll({'profileImage': profileImage});
    result.addAll({'gender': gender});
    result.addAll({'phone': phone});
    result.addAll({'dateOfBirth': dateOfBirth});
    result.addAll({'address': address});
    result.addAll({'userType': userType});
    result.addAll({'credits': credits});
    result.addAll({'signIn': signIn});
    result.addAll({'lastCreditSync': lastCreditSync});
    result.addAll({'shippingAddress': shippingAddress});

    return result;
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uId: map['uId'] ?? '',
      userName: map['userName'] ?? '',
      email: map['email'] ?? '',
      profileImage: map['profileImage'] ?? '',
      gender: map['gender'] ?? '',
      phone: map['phone'] ?? '',
      dateOfBirth: map['dateOfBirth'] ?? '',
      address: map['address'] ?? '',
      userType: map['userType'] ?? '',
      credits: map['credits']?.toInt() ?? 0,
      signIn: map['signIn'] ?? '',
      lastCreditSync: map['lastCreditSync'],
      shippingAddress: Map<String, String>.from(map['shippingAddress'] ?? {}),
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source));
}
