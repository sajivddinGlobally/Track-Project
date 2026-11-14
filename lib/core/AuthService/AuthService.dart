import 'package:dio/dio.dart';
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
import 'package:track_loved/core/Data/ResponseModel/getNotificationListModel.dart';
import 'package:track_loved/core/Data/ResponseModel/updateJobPostResModel.dart';
import 'package:track_loved/core/Network/ApiStateNetwork.dart';
import '../Data/BodyModel/MatchContactsBodyModel.dart';
import '../Data/BodyModel/ManualContactBodyModel.dart';
import '../Data/BodyModel/deleteContactBodyModel.dart';
import '../Data/BodyModel/updateJobPostBodyModel.dart';
import '../Data/ResponseModel/deleteContactResModel.dart';
import '../Data/BodyModel/UpdateProfileBodyModel.dart';
import '../Data/ResponseModel/MatchContactsResModel.dart';
import '../Data/ResponseModel/acceptResModel.dart';
import '../Data/ResponseModel/getBusinnesProfileModel.dart';
import '../Data/ResponseModel/getDashboardModel.dart';
import '../Data/ResponseModel/getMyProfileModel.dart';
import '../Data/ResponseModel/rejectResModel.dart';
import '../Data/ResponseModel/sendNotificatoinResModel.dart';
import '../Data/ResponseModel/sendReqeustResModel.dart';
import '../Data/ResponseModel/trackFriendModel.dart';
import '../Data/ResponseModel/updateProfileResModel.dart';
import '../Data/ResponseModel/uploadImageResModel.dart';
import '../Data/BodyModel/BusinessProfileBodyModel.dart';
import '../Data/ResponseModel/BusinessProfileResModel.dart';
import '../Data/ResponseModel/ChatHistoryResModel.dart';
import '../Data/BodyModel/TriggerSosBodyModel.dart';
import '../Data/ResponseModel/TriggerSosResModel.dart';
import '../Data/BodyModel/CreateJobPostBodyModel.dart';
import '../Data/ResponseModel/CreateJobPostResModel.dart';
import '../Data/BodyModel/CreateBusinessOpportunityBodyModel.dart';
import '../Data/ResponseModel/CreateBusinessOpportunityResModel.dart';
import '../Data/BodyModel/UpdateConsentsBodyModel.dart';
import '../Data/ResponseModel/UpdateConsentsResModel.dart';
import '../Data/ResponseModel/GetBusinessOpportunitiesResModel.dart';
import '../Data/BodyModel/CreateOpportunityReportBodyModel.dart';
import '../Data/ResponseModel/CreateOpportunityReportResModel.dart';
import '../Data/ResponseModel/GetMyCompanyJobPostsResModel.dart';
import '../Data/ResponseModel/GetMyBusinessOpportunitiesResModel.dart';
import '../Data/ResponseModel/GetLawContentResModel.dart';
import '../Data/ResponseModel/DeleteJobPostResModel.dart';
import '../Data/BodyModel/SubmitGrievanceBodyModel.dart';
import '../Data/ResponseModel/SubmitGrievanceResModel.dart';
import '../Data/BodyModel/RequestDataSummaryBodyModel.dart';
import '../Data/ResponseModel/RequestDataSummaryResModel.dart';
import '../Data/ResponseModel/GetMyJobApplicationsResModel.dart';
import '../Data/ResponseModel/ApplyJobProfileResModel.dart';
import '../Data/BodyModel/DeleteUserAccountBodyModel.dart';
import '../Data/ResponseModel/SendDeletionOtpResModel.dart';
import '../Data/ResponseModel/DeleteUserAccountResModel.dart';
import '../Data/BodyModel/SubmitFeedbackBodyModel.dart';
import '../Data/ResponseModel/SubmitFeedbackResModel.dart';
import '../Data/BodyModel/CompanyTransferSendOtpBodyModel.dart';
import '../Data/ResponseModel/CompanyTransferSendOtpResModel.dart';
import '../Data/ResponseModel/CompanyTransferLookupResModel.dart';
import '../Data/BodyModel/CompanyTransferExecuteBodyModel.dart';
import '../Data/ResponseModel/CompanyTransferExecuteResModel.dart';
import '../Data/BodyModel/UpdateUserLocationBodyModel.dart';
import '../Data/BodyModel/UpdateFcmTokenBodyModel.dart';
import '../Data/ResponseModel/FriendLocationSharingStatusResModel.dart';
import '../Data/ResponseModel/FriendLocationResModel.dart';
import 'package:hive/hive.dart';
import '../Data/BodyModel/CreateOrderBodyModel.dart';
import '../Data/ResponseModel/CreateOrderResModel.dart';
import '../Data/BodyModel/GoogleSignInBodyModel.dart';
import '../Data/ResponseModel/GoogleSignInResModel.dart';
import '../Data/BodyModel/VerifyPaymentBodyModel.dart';
import '../Data/ResponseModel/VerifyPaymentResModel.dart';
import '../Data/BodyModel/LocationSharingActionBodyModel.dart';
import '../Data/ResponseModel/LocationSharingActionResModel.dart';

class Authservice {
  final ApiStateNetwork api;
  final Dio? dio;
  Authservice(this.api, {this.dio});

  Future<LoginResModel> loginData({required email, required password}) async {
    try {
      final body = LoginBodyModel(email: email, password: password);
      final response = await api.login(body);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<GoogleSignInResModel> googleSignUpData({
    required String idToken,
  }) async {
    try {
      final body = GoogleSignInBodyModel(idToken: idToken);
      final response = await api.googleSignUp(body);
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
    String? parentPhone,
    String? dob,
  }) async {
    try {
      final body = RegisterBodyModel(
        email: email,
        password: password,
        name: name,
        phone: phone,
        role: role,
        parentPhone: parentPhone,
        dob: dob,
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
    int? page,
    int? limit,
  }) async {
    try {
      final response = await api.getAddNetworkSearch(
        search,
        page: page,
        limit: limit,
      );

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

  Future<MatchContactsResModel> addManualContactData(
    ManualContactBodyModel body,
  ) async {
    try {
      final response = await api.addManualContact(body);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<MatchContactsResModel> getMatchContactsData({String? search}) async {
    try {
      final response = await api.getMatchContacts(search);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<DeleteContactResModel> deleteContacts(List<String> phones) async {
    try {
      return await api.deleteContact(DeleteContactBodyModel(phones: phones));
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

  Future<FriendLocationResModel> getLocation({required String id}) async {
    try {
      final response = await api.getLocation(id);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<FriendLocationSharingStatusResModel>
  getFriendLocationSharingStatusData(String id) async {
    try {
      final response = await api.getFriendLocationSharingStatus(id);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> updateUserLocationData({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final body = UpdateUserLocationBodyModel(
        location: LocationPoint(
          type: "Point",
          coordinates: [longitude, latitude], // Longitude first per GeoJSON
        ),
      );
      final response = await api.updateUserLocation(body);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> updateFcmTokenData(String? fcmToken) async {
    try {
      final body = UpdateFcmTokenBodyModel(fcmToken: fcmToken);
      final response = await api.updateFcmToken(body);
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

  Future<LocationSharingActionResModel> locationSharingActionData({
    bool? locationAccessDisable,
    bool? locationAccessRenew,
  }) async {
    try {
      final body = LocationSharingActionBodyModel(
        locationAccessDisable: locationAccessDisable,
        locationAccessRenew: locationAccessRenew,
      );
      final response = await api.locationSharingAction(body);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<LocationSharingReceivedResModel> getLocationSharingReceived(
    String? search,
  ) async {
    try {
      final response = await api.getLocationSharingReceived(search);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<GetLawContentResModel> getLawContent() async {
    try {
      final response = await api.getLawContent();
      if (response is GetLawContentResModel) {
        return response;
      } else if (response is Map<String, dynamic>) {
        return GetLawContentResModel.fromJson(response);
      } else if (response is String) {
        return getLawContentResModelFromJson(response);
      }
      return GetLawContentResModel(success: false, data: []);
    } catch (e) {
      rethrow;
    }
  }

  Future<GetLawContentResModel> getLawContentByState({
    required String state,
    required String category,
    required String type,
  }) async {
    try {
      final response = await api.getLawContentByState(state, category, type);
      if (response is GetLawContentResModel) {
        return response;
      } else if (response is Map<String, dynamic>) {
        return GetLawContentResModel.fromJson(response);
      } else if (response is String) {
        return getLawContentResModelFromJson(response);
      }
      return GetLawContentResModel(success: false, data: []);
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

  Future<BusinessProfileResModel> updateBusinessProfileData(
    BusinessProfileBodyModel body,
  ) async {
    try {
      final response = await api.updateBusinessProfile(body);
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

  Future<TriggerSosResModel> triggerSosData(TriggerSosBodyModel body) async {
    try {
      final response = await api.triggerSos(body);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<GetBussinessProfileModel> getBussinessProfileData() async {
    try {
      final response = await api.getBussinessProfile();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<CreateJobPostResModel> createJobPostData(
    CreateJobPostBodyModel body,
  ) async {
    try {
      final response = await api.createJobPost(body);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<CreateBusinessOpportunityResModel> createBusinessOpportunityData(
    CreateBusinessOpportunityBodyModel body,
  ) async {
    try {
      final response = await api.createBusinessOpportunity(body);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<CreateBusinessOpportunityResModel> updateBusinessOpportunityData(
    CreateBusinessOpportunityBodyModel body,
  ) async {
    try {
      final response = await api.updateBusinessOpportunity(body);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<CreateBusinessOpportunityResModel> deleteBusinessOpportunityData(
    String id,
  ) async {
    try {
      final response = await api.deleteBusinessOpportunity(id);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<GetBusinessOpportunitiesResModel> getBusinessOpportunitiesData({
    int? page,
    int? limit,
    String? search,
    String? pincode,
  }) async {
    try {
      final response = await api.getBusinessOpportunities(
        search,
        page,
        limit,
        pincode,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<CreateOpportunityReportResModel> createOpportunityReportData(
    CreateOpportunityReportBodyModel body,
  ) async {
    try {
      final response = await api.createOpportunityReport(body);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<GetMyCompanyJobPostsResModel> getMyCompanyJobPostsData({
    int? page,
    int? limit,
    String? search,
    String? companyId,
  }) async {
    try {
      final response = await api.getMyCompanyJobPosts(
        page,
        limit,
        search,
        companyId,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<UpdateJobPostingResModel> updateJobPosting(
    UpdateJobPostingBodyModel body,
  ) async {
    try {
      final response = await api.updateJobPosting(body);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<DeleteJobPostResModel> deleteJobPostData(String id) async {
    try {
      final response = await api.deleteJobPost(id);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<GetMyBusinessOpportunitiesResModel> getMyBusinessOpportunitiesData({
    int? page,
    int? limit,
    String? search,
    String? companyId,
  }) async {
    try {
      final response = await api.getMyBusinessOpportunities(
        page,
        limit,
        search,
        companyId,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<UpdateConsentsResModel> updateConsentsData(
    UpdateConsentsBodyModel body,
  ) async {
    try {
      final response = await api.updateConsents(body);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<SubmitGrievanceResModel> submitGrievanceData(
    SubmitGrievanceBodyModel body,
  ) async {
    try {
      final response = await api.submitGrievance(body);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<RequestDataSummaryResModel> requestDataSummaryData(
    RequestDataSummaryBodyModel body,
  ) async {
    try {
      final response = await api.requestDataSummary(body);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<GetMyJobApplicationsResModel> getMyJobApplicationsData() async {
    try {
      final response = await api.getMyJobApplications();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<SendDeletionOtpResModel> sendDeleteAccountOtpData() async {
    try {
      final response = await api.sendDeleteAccountOtp();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<DeleteUserAccountResModel> deleteUserAccountData(
    DeleteUserAccountBodyModel body,
  ) async {
    try {
      final response = await api.deleteUserAccount(body);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ApplyJobProfileResModel> applyJobProfileData({
    required String postId,
    required String name,
    required String email,
    required String phone,
    String? comment,
    File? resume,
  }) async {
    try {
      final response = await api.applyJobProfile(
        postId,
        name,
        email,
        phone,
        comment,
        resume,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<SubmitFeedbackResModel> submitFeedbackData(
    SubmitFeedbackBodyModel body,
  ) async {
    try {
      final response = await api.submitFeedback(body);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<CompanyTransferSendOtpResModel> sendCompanyTransferOtpData(
    CompanyTransferSendOtpBodyModel body,
  ) async {
    try {
      final response = await api.sendCompanyTransferOtp(body);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<CompanyTransferLookupResModel> lookupTransferReceiverData(
    String phone,
  ) async {
    try {
      final response = await api.lookupTransferReceiver(phone);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<CompanyTransferExecuteResModel> executeCompanyTransferData(
    CompanyTransferExecuteBodyModel body,
  ) async {
    try {
      final response = await api.executeCompanyTransfer(body);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<CreateOrderResModel> createPaymentOrder({
    num amount = 1,
    String planName = "Company Subscription",
    String? token,
  }) async {
    try {
      final body = CreateOrderBodyModel(amount: amount, planName: planName);
      final client = dio ?? Dio();
      final effectiveToken =
          token ??
          (Hive.isBoxOpen("userdata")
              ? Hive.box("userdata").get("token")
              : null);

      final baseUrl = client.options.baseUrl.isNotEmpty
          ? client.options.baseUrl
          : "https://api.tracklovedones.com";

      final response = await client.post(
        "$baseUrl/api/v1/payment/create-order",
        data: body.toJson(),
        options: Options(
          headers: {
            "Content-Type": "application/json",
            if (effectiveToken != null && effectiveToken.toString().isNotEmpty)
              "Authorization": "Bearer $effectiveToken",
          },
        ),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return CreateOrderResModel.fromJson(data);
      }
      return CreateOrderResModel.fromJson({});
    } catch (e) {
      rethrow;
    }
  }

  Future<VerifyPaymentResModel> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    String? token,
  }) async {
    try {
      final body = VerifyPaymentBodyModel(
        razorpayOrderId: razorpayOrderId,
        razorpayPaymentId: razorpayPaymentId,
        razorpaySignature: razorpaySignature,
      );
      final client = dio ?? Dio();
      final effectiveToken =
          token ??
          (Hive.isBoxOpen("userdata")
              ? Hive.box("userdata").get("token")
              : null);

      final baseUrl = client.options.baseUrl.isNotEmpty
          ? client.options.baseUrl
          : "https://api.tracklovedones.com";

      final response = await client.post(
        "$baseUrl/api/v1/payment/verify",
        data: body.toJson(),
        options: Options(
          headers: {
            "Content-Type": "application/json",
            if (effectiveToken != null && effectiveToken.toString().isNotEmpty)
              "Authorization": "Bearer $effectiveToken",
          },
        ),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return VerifyPaymentResModel.fromJson(data);
      }
      return VerifyPaymentResModel.fromJson({});
    } catch (e) {
      rethrow;
    }
  }

  Future<GetNotificationListModel> getNotificationListData({
    required int page,
    required int limit,
  }) async {
    try {
      final response = await api.getNotificationList(page, limit);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> readSingleNotificationData(String id) async {
    try {
      final response = await api.readSingleNotification(id);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> readAllNotificationsData() async {
    try {
      final response = await api.readAllNotifications();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<GetDashboardModel> getDashboardData() async {
    try {
      final response = await api.getDashboardData();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<SendNotificatonResModel> sendNotificationByIdData({
    required String id,
  }) async {
    try {
      final response = await api.sendNotificationById(id);
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
