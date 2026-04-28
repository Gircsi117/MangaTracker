import 'package:flutter/material.dart';
import '../../modules/securestore.module.dart';

const _storeKey = "credentials";

class Credential {
  final String login;
  final String password;

  Credential({required this.login, required this.password});

  factory Credential.fromJson(Map<String, dynamic> json) => Credential(
    login: json["login"] as String,
    password: json["password"] as String,
  );

  Map<String, dynamic> toJson() => {"login": login, "password": password};
}

class CredentialsStore extends ChangeNotifier {
  Map<String, Credential> _credentials = {};

  static final CredentialsStore instance = CredentialsStore._();
  CredentialsStore._();

  Future<void> load() async {
    final data = await SecureStore.getJSON<Map<String, dynamic>>(_storeKey);
    if (data == null) return;
    _credentials = data.map(
      (k, v) => MapEntry(k, Credential.fromJson(v as Map<String, dynamic>)),
    );
    notifyListeners();
  }

  Future<void> set(String site, Credential credential) async {
    _credentials = {..._credentials, site: credential};
    await SecureStore.setJSON(
      _storeKey,
      _credentials.map((k, v) => MapEntry(k, v.toJson())),
    );
    notifyListeners();
  }

  Future<void> delete(String site) async {
    _credentials = Map.from(_credentials)..remove(site);
    await SecureStore.setJSON(
      _storeKey,
      _credentials.map((k, v) => MapEntry(k, v.toJson())),
    );
    notifyListeners();
  }

  Credential? get(String site) => _credentials[site];
}
