import 'package:track_loved/core/Data/BodyModel/UpdateLocationBodyModel.dart';
import 'dart:io';

import 'package:track_loved/core/Data/BodyModel/ForgetPasswordOtpBodyModel.dart';
import 'package:track_loved/core/Data/BodyModel/ForgotPasswordBodyModel.dart';
import 'package:track_loved/core/Data/BodyModel/LoginBodyModel.dart';
import 'package:track_loved/core/Data/BodyModel/OtpVerifyBodyModel.dart';
import 'package:track_loved/core/Data/BodyModel/RegisterBodyModel.dart';
import 'package:track_loved/core/Data/BodyModel/ResetPasswordBodyModel.dart';
import 'package:track_loved/core/Data/BodyModel/locationSharingBodyModel.dart';
import 'package:track_loved/core/Data/ResponseModel/AddNetworkSearchResModel.dart';
import 'package:track_loved/core/Data/ResponseModel/ForgetPasswordResMode.dart';
import 'package:track_loved/core/Data/ResponseModel/ForgotPasswordOtpResModel.dart';
import 'package:track_loved/core/Data/ResponseModel/LoginResModel.dart';
import 'package:track_loved/core/Data/ResponseModel/NetworkRequestResModel.dart';
import 'package:track_loved/core/Data/ResponseModel/OtpVerifyResModel.dart';
import 'package:track_loved/core/Data/ResponseModel/RegisterResModel.dart';
import 'package:track_loved/core/Data/ResponseModel/ResetPasswordResModel.dart';
import 'package:track_loved/core/Data/ResponseModel/LocationSharingReceivedResModel.dart';
import 'package:track_loved/core/Network/ApiStateNetwork.dart';

import '../Data/BodyModel/MatchContactsBodyModel.dart';
import '../Data/BodyModel/UpdateProfileBodyModel.dart';
import '../Data/ResponseModel/MatchContactsResModel.dart';
import '../Data/ResponseModel/acceptResModel.dart';
import '../Data/ResponseModel/getMyProfileModel.dart';
import '../Data/ResponseModel/rejectResModel.dart';
import '../Data/ResponseModel/sendReqeustResModel.dart';
import '../Data/ResponseModel/trackFriendModel.dart';
import '../Data/ResponseModel/updateProfileResModel.dart';
import '../Data/ResponseModel/uploadImageResModel.dart';
import '../Data/BodyModel/BusinessProfileBodyModel.dart';
import '../Data/ResponseModel/BusinessProfileResModel.dart';
import '../Data/ResponseModel/ChatHistoryResModel.dart';

class Authservice {
  final ApiStateNetwork api;
  Authservice(this.api);

  Future<LoginResModel> loginData({required email, required password}) async {
    try {
      final body = LoginBodyModel(email: email, password: password);
      final response = await api.login(body);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<RegisterResModel> registerData({
    required email,
    required password,
    required name,
    required phone,
    String role = "user",
  }) async {
    try {
      final body = RegisterBodyModel(
        email: email,
        password: password,
        name: name,
        phone: phone,
        role: role,
      );
      final response = await api.register(body);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<OtpVerifyResModel> otpData({required email, required otp}) async {
    try {
      final body = OtpVerifyBodyModel(email: email, otp: otp);
      final response = await api.otp(body);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ForgetPasswordResModel> forgetPasswordData({required email}) async {
    try {
      final body = ForgetPasswordBodyModel(email: email);
      final response = await api.forgetPassword(body);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ForgetPasswordOtpResModel> forgetPasswordOtpData({
    required email,
    required otp,
  }) async {
    try {
      final body = ForgetPasswordOtpBodyModel(email: email, otp: otp);
      final response = await api.forgetPasswordOtp(body);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResetPasswordResModel> resetPasswordData({
    required newPassword,
    required confirmPassword,
  }) async {
    try {
      final body = ResetPasswordBodyModel(
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      final response = await api.resetPassword(body);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<AddNetworkSearchResModel> addNetworkSearchData({
    required String search,
  }) async {
    try {
      final response = await api.getAddNetworkSearch(search);

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<NetworkRequestResModel> getNetworkRequestData() async {
    try {
      final response = await api.getNetworkRequest();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<UploadImageResModel> uploadImage(File? file) async {
    try {
      final response = await api.uploadImage(file);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<GetMyProfileModel> getMyProfileData() async {
    try {
      final response = await api.getMyProfile();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<UpdateProfileResModel> updateUserProfileData(
    UpdateProfileBodyModel body,
  ) async {
    try {
      final response = await api.updateUserProfile(body);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<MatchContactsResModel> matchContactsData(
    MatchContactsBodyModel body,
  ) async {
    try {
      final response = await api.matchContacts(body);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<MatchContactsResModel> getMatchContactsData() async {
    try {
      final response = await api.getMatchContacts();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<SendRequest> sendRequest({required String id}) async {
    try {
      final response = await api.sendRequest(id);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<RejectResModel> rejectRequest({required String id}) async {
    try {
      final response = await api.rejectRequest(id);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<AcceptResModel> acceptRequest({required String id}) async {
    try {
      final response = await api.acceptRequest(id);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<TrackFriendModel> trackFriend({
    String? search,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await api.trackFriend(search, page, limit);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getLocation({required String id}) async {
    try {
      final response = await api.getLocation(id);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> locationSharing({
    required String id,
    required bool value,
  }) async {
    try {
      final body = LocationSharingBodyModel(enabled: value);
      final response = await api.locationSharing(id, body);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<LocationSharingReceivedResModel> getLocationSharingReceived() async {
    try {
      final response = await api.getLocationSharingReceived();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getLawContent() async {
    try {
      final response = await api.getLawContent();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> updateLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final body = UpdateLocationBodyModel(
        latitude: latitude,
        longitude: longitude,
      );
      return await api.updateLocation(body);
    } catch (e) {
      rethrow;
    }
  }

  Future<BusinessProfileResModel> saveBusinessProfileData(
    BusinessProfileBodyModel body,
  ) async {
    try {
      final response = await api.saveBusinessProfile(body);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ChatHistoryResModel> getChatHistoryData({
    required String receiverId,
  }) async {
    try {
      final response = await api.getChatHistory(receiverId);
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
