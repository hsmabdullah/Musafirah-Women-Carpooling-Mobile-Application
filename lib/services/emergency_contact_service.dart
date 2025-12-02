import 'dart:convert';
import 'package:musafirah_app/models/emergency_contact.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmergencyContactService {
  static const String _key = 'emergency_contacts';

  // Save emergency contacts
  static Future<bool> saveEmergencyContacts(
    List<EmergencyContact> contacts,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> contactsJson = contacts
          .map((contact) => contact.toJson())
          .toList();
      final String contactsString = jsonEncode(contactsJson);
      return await prefs.setString(_key, contactsString);
    } catch (e) {
      return false;
    }
  }

  // Get emergency contacts
  static Future<List<EmergencyContact>> getEmergencyContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? contactsString = prefs.getString(_key);
      if (contactsString == null || contactsString.isEmpty) {
        return [];
      }
      final List<dynamic> contactsJson = jsonDecode(contactsString);
      return contactsJson
          .map(
            (json) => EmergencyContact.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Clear emergency contacts
  static Future<bool> clearEmergencyContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_key);
    } catch (e) {
      return false;
    }
  }
}
