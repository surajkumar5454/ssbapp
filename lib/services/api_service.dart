import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pay_slip.dart';
import '../models/training.dart';
import '../models/deputation.dart';
import '../models/user_profile.dart';

class ApiService {
  static const String _baseUrl = 'https://api.example.com'; // Replace with your API URL
  final String _token;

  ApiService(this._token);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      };

  // Pay Slips
  Future<List<PaySlip>> getPaySlips(String uidNo) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/payslips?uidNo=$uidNo'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => PaySlip.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load pay slips');
      }
    } catch (e) {
      throw Exception('Error fetching pay slips: $e');
    }
  }

  // Trainings
  Future<List<Training>> getTrainings(String uidNo) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/trainings?uidNo=$uidNo'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Training.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load trainings');
      }
    } catch (e) {
      throw Exception('Error fetching trainings: $e');
    }
  }

  Future<void> requestTraining(String uidNo, Map<String, dynamic> trainingData) async {
    try {
      final requestData = {
        'uidNo': uidNo,
        ...trainingData,
      };
      final response = await http.post(
        Uri.parse('$_baseUrl/trainings/request'),
        headers: _headers,
        body: json.encode(requestData),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to submit training request');
      }
    } catch (e) {
      throw Exception('Error submitting training request: $e');
    }
  }

  // Deputations
  Future<List<Deputation>> getDeputations(String uidNo) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/deputations?uidNo=$uidNo'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Deputation.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load deputations');
      }
    } catch (e) {
      throw Exception('Error fetching deputations: $e');
    }
  }

  Future<void> submitDeputationRequest(String uidNo, Map<String, dynamic> deputationData) async {
    try {
      final requestData = {
        'uidNo': uidNo,
        ...deputationData,
      };
      final response = await http.post(
        Uri.parse('$_baseUrl/deputations'),
        headers: _headers,
        body: json.encode(requestData),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to submit deputation request');
      }
    } catch (e) {
      throw Exception('Error submitting deputation request: $e');
    }
  }

  Future<void> withdrawDeputationRequest(String deputationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/deputations/$deputationId'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to withdraw deputation request');
      }
    } catch (e) {
      throw Exception('Error withdrawing deputation request: $e');
    }
  }

  // Profile
  Future<void> updateProfile(String uidNo, Map<String, dynamic> profileData) async {
    try {
      final requestData = {
        'uidNo': uidNo,
        ...profileData,
      };
      final response = await http.put(
        Uri.parse('$_baseUrl/profile/$uidNo'),
        headers: _headers,
        body: json.encode(requestData),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/change-password'),
        headers: _headers,
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to change password');
      }
    } catch (e) {
      throw Exception('Error changing password: $e');
    }
  }

  Future<UserProfile> getUserProfile(String uidNo) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/profile/$uidNo'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return UserProfile.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      throw Exception('Error fetching profile: $e');
    }
  }

  Future<String> uploadProfileImage(String uidNo, String imagePath) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/profile/$uidNo/image'),
      );

      request.headers.addAll(_headers);
      request.files.add(
        await http.MultipartFile.fromPath('image', imagePath),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseData);
        return data['imageUrl'];
      } else {
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }
} 