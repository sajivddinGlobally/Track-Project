import 'dart:io';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:track_loved/core/Data/BodyModel/ForgetPasswordOtpBodyModel.dart';
import 'package:track_loved/core/Data/BodyModel/ForgotPasswordBodyModel.dart';
import 'package:track_loved/core/Data/BodyModel/LoginBodyModel.dart';
import 'package:track_loved/core/Data/BodyModel/OtpVerifyBodyModel.dart';
import 'package:track_loved/core/Data/BodyModel/RegisterBodyModel.dart';
import 'package:track_loved/core/Data/BodyModel/ResetPasswordBodyModel.dart';
import 'package:track_loved/core/Data/ResponseModel/AddNetworkSearchResModel.dart';
import 'package:track_loved/core/Data/ResponseModel/ForgetPasswordResMode.dart';
import 'package:track_loved/core/Data/ResponseModel/ForgotPasswordOtpResModel.dart';
import 'package:track_loved/core/Data/ResponseModel/LoginResModel.dart';
import 'package:track_loved/core/Data/ResponseModel/NetworkRequestResModel.dart';
import 'package:track_loved/core/Data/ResponseModel/OtpVerifyResModel.dart';
import 'package:track_loved/core/Data/ResponseModel/RegisterResModel.dart';
import 'package:track_loved/core/Data/ResponseModel/ResetPasswordResModel.dart';
import 'package:track_loved/core/Data/ResponseModel/getBusinnesProfileModel.dart';
import 'package:track_loved/core/Data/ResponseModel/trackFriendModel.dart';
import '../Data/BodyModel/MatchContactsBodyModel.dart';
import '../Data/BodyModel/ManualContactBodyModel.dart';
import '../Data/BodyModel/UpdateProfileBodyModel.dart';
import '../Data/BodyModel/deleteContactBodyModel.dart';
import '../Data/BodyModel/locationSharingBodyModel.dart';
import '../Data/BodyModel/UpdateLocationBodyModel.dart';
import '../Data/BodyModel/updateJobPostBodyModel.dart';
import '../Data/ResponseModel/MatchContactsResModel.dart';
import '../Data/ResponseModel/acceptResModel.dart';
import '../Data/ResponseModel/deleteContactResModel.dart';
import '../Data/ResponseModel/getDashboardModel.dart';
import '../Data/ResponseModel/getMyProfileModel.dart';
import '../Data/ResponseModel/getNotificationListModel.dart';
import '../Data/ResponseModel/rejectResModel.dart';
import '../Data/ResponseModel/sendNotificatoinResModel.dart';
import '../Data/ResponseModel/sendReqeustResModel.dart';
import '../Data/ResponseModel/updateJobPostResModel.dart';
import '../Data/ResponseModel/updateProfileResModel.dart';
import '../Data/ResponseModel/uploadImageResModel.dart';
import '../Data/ResponseModel/LocationSharingReceivedResModel.dart';
import '../Data/BodyModel/BusinessProfileBodyModel.dart';
import '../Data/ResponseModel/BusinessProfileResModel.dart';
import '../Data/ResponseModel/ChatHistoryResModel.dart';
import '../Data/BodyModel/TriggerSosBodyModel.dart';
import '../Data/ResponseModel/TriggerSosResModel.dart';
import '../Data/BodyModel/CreateJobPostBodyModel.dart';
import '../Data/ResponseModel/CreateJobPostResModel.dart';
import '../Data/BodyModel/CreateBusinessOpportunityBodyModel.dart';
import '../Data/ResponseModel/CreateBusinessOpportunityResModel.dart';
import '../Data/ResponseModel/GetBusinessOpportunitiesResModel.dart';
import '../Data/BodyModel/CreateOpportunityReportBodyModel.dart';
import '../Data/ResponseModel/CreateOpportunityReportResModel.dart';
import '../Data/ResponseModel/GetMyCompanyJobPostsResModel.dart';
import '../Data/ResponseModel/GetMyBusinessOpportunitiesResModel.dart';
import '../Data/BodyModel/UpdateConsentsBodyModel.dart';
import '../Data/ResponseModel/UpdateConsentsResModel.dart';
import '../Data/ResponseModel/DeleteJobPostResModel.dart';
import '../Data/BodyModel/SubmitGrievanceBodyModel.dart';
import '../Data/ResponseModel/SubmitGrievanceResModel.dart';
import '../Data/BodyModel/RequestDataSummaryBodyModel.dart';
import '../Data/ResponseModel/RequestDataSummaryResModel.dart';
import '../Data/ResponseModel/GetMyJobApplicationsResModel.dart';
import '../Data/BodyModel/DeleteUserAccountBodyModel.dart';
import '../Data/ResponseModel/SendDeletionOtpResModel.dart';
import '../Data/ResponseModel/DeleteUserAccountResModel.dart';
import '../Data/ResponseModel/ApplyJobProfileResModel.dart';
import '../Data/BodyModel/SubmitFeedbackBodyModel.dart';
import '../Data/ResponseModel/SubmitFeedbackResModel.dart';
import '../Data/BodyModel/CompanyTransferSendOtpBodyModel.dart';
import '../Data/ResponseModel/CompanyTransferSendOtpResModel.dart';
import '../Data/ResponseModel/CompanyTransferLookupResModel.dart';
import '../Data/BodyModel/CompanyTransferExecuteBodyModel.dart';
import '../Data/ResponseModel/CompanyTransferExecuteResModel.dart';
import '../Data/BodyModel/UpdateUserLocationBodyModel.dart';
import '../Data/BodyModel/UpdateFcmTokenBodyModel.dart';
import '../Data/BodyModel/GoogleSignInBodyModel.dart';
import '../Data/ResponseModel/GoogleSignInResModel.dart';
import '../Data/ResponseModel/FriendLocationSharingStatusResModel.dart';
import '../Data/ResponseModel/FriendLocationResModel.dart';
import '../Data/BodyModel/LocationSharingActionBodyModel.dart';
import '../Data/ResponseModel/LocationSharingActionResModel.dart';

part 'ApiStateNetwork.g.dart';

// @RestApi(baseUrl: "https://loveable-backend-5qi0.onrender.com")
@RestApi(baseUrl: "https://api.tracklovedones.com")
// @RestApi(baseUrl: "https://www.tracklovedones.com")
abstract class ApiStateNetwork {
  factory ApiStateNetwork(Dio dio, {String baseUrl}) = _ApiStateNetwork;

  @POST("/api/v1/auth/login")
  Future<LoginResModel> login(@Body() LoginBodyModel body);

  @POST("/api/v1/auth/google/signup")
  Future<GoogleSignInResModel> googleSignUp(@Body() GoogleSignInBodyModel body);

  @POST("/api/v1/auth/register")
  Future<RegisterResModel> register(@Body() RegisterBodyModel body);

  @POST("/api/v1/auth/verify-otp")
  Future<OtpVerifyResModel> otp(@Body() OtpVerifyBodyModel body);

  @POST("/api/v1/auth/forgot-password")
  Future<ForgetPasswordResModel> forgetPassword(
    @Body() ForgetPasswordBodyModel body,
  );

  @POST("/api/v1/auth/verify-reset-otp")
  Future<ForgetPasswordOtpResModel> forgetPasswordOtp(
    @Body() ForgetPasswordOtpBodyModel body,
  );

  @POST("/api/v1/auth/reset-password")
  Future<ResetPasswordResModel> resetPassword(
    @Body() ResetPasswordBodyModel body,
  );

  @GET("/api/v1/auth/searchUsers")
  Future<AddNetworkSearchResModel> getAddNetworkSearch(
    @Query("search") String search, {
    @Query("page") int? page,
    @Query("limit") int? limit,
  });

  @GET("/api/v1/network/requests")
  Future<NetworkRequestResModel> getNetworkRequest();

  @MultiPart()
  @POST("/api/v1/uploadImage")
  Future<UploadImageResModel> uploadImage(@Part() File? file);

  @GET("/api/v1/auth/get_my_profile")
  Future<GetMyProfileModel> getMyProfile();

  @PATCH("/api/v1/auth/userprofile_update")
  Future<UpdateProfileResModel> updateUserProfile(
    @Body() UpdateProfileBodyModel body,
  );

  @POST("/api/v1/network/contacts/match")
  Future<MatchContactsResModel> matchContacts(
    @Body() MatchContactsBodyModel body,
  );

  @POST("/api/v1/network/contacts/manual")
  Future<MatchContactsResModel> addManualContact(
    @Body() ManualContactBodyModel body,
  );

  @POST("/api/v1/network//request/{id}")
  Future<SendRequest> sendRequest(@Path("id") String id);

  @PATCH("/api/v1/network/request/{id}/reject")
  Future<RejectResModel> rejectRequest(@Path("id") String id);

  @PATCH("/api/v1/network/request/{id}/accept")
  Future<AcceptResModel> acceptRequest(@Path("id") String id);

  @GET("/api/v1/network/friends")
  Future<TrackFriendModel> trackFriend([
    @Query("search") String? search,
    @Query("page") int page = 1,
    @Query("limit") int limit = 10,
  ]);

  @GET("/api/v1/network/friend/{id}/location")
  Future<FriendLocationResModel> getLocation(@Path("id") String id);

  @PATCH("/api/v1/network/friend/{id}/location-sharing")
  Future<dynamic> locationSharing(
    @Path("id") String id,
    @Body() LocationSharingBodyModel body,
  );

  @POST("/api/v1/network/location-sharing/action")
  Future<LocationSharingActionResModel> locationSharingAction(
    @Body() LocationSharingActionBodyModel body,
  );

  @GET("/api/v1/network/friend/{id}/location-sharing")
  Future<FriendLocationSharingStatusResModel> getFriendLocationSharingStatus(
    @Path("id") String id,
  );

  @GET("/api/v1/network/location-sharing/received")
  Future<LocationSharingReceivedResModel> getLocationSharingReceived(
    @Query("search") String? search,
  );

  @GET("/api/v1/network/contacts/match")
  Future<MatchContactsResModel> getMatchContacts([
    @Query("search") String? search,
  ]);

  @POST("/api/v1/sos/update-location")
  Future<dynamic> updateLocation(@Body() UpdateLocationBodyModel body);

  @GET("/api/v1/law-content")
  Future<dynamic> getLawContent();

  @GET("/api/v1/law-content")
  Future<dynamic> getLawContentByState(
    @Query("state") String state,
    @Query("category") String category,
    @Query("type") String type,
  );

  @POST("/api/v1/business/profile")
  Future<BusinessProfileResModel> saveBusinessProfile(
    @Body() BusinessProfileBodyModel body,
  );

  @PATCH("/api/v1/business/profile")
  Future<BusinessProfileResModel> updateBusinessProfile(
    @Body() BusinessProfileBodyModel body,
  );

  @GET("/api/v1/network/chat/messages/{receiverId}")
  Future<ChatHistoryResModel> getChatHistory(
    @Path("receiverId") String receiverId,
  );

  @DELETE("/api/v1/network/contacts")
  Future<DeleteContactResModel> deleteContact(
    @Body() DeleteContactBodyModel body,
  );

  @POST("/api/v1/sos/trigger")
  Future<TriggerSosResModel> triggerSos(@Body() TriggerSosBodyModel body);

  @GET("/api/v1/business/profile")
  Future<GetBussinessProfileModel> getBussinessProfile();

  @POST("/api/v1/business/job-posts")
  Future<CreateJobPostResModel> createJobPost(
    @Body() CreateJobPostBodyModel body,
  );
  @GET("/api/v1/business/my/job-posts")
  Future<GetMyCompanyJobPostsResModel> getMyCompanyJobPosts(
    @Query("page") int? page,
    @Query("limit") int? limit,
    @Query("search") String? search,
    @Query("companyId") String? companyId,
  );

  @PATCH("/api/v1/business/job-posts")
  Future<UpdateJobPostingResModel> updateJobPosting(
    @Body() UpdateJobPostingBodyModel body,
  );

  @DELETE("/api/v1/business/job-posts/{id}")
  Future<DeleteJobPostResModel> deleteJobPost(@Path("id") String id);

  @POST("/api/v1/business/opportunities")
  Future<CreateBusinessOpportunityResModel> createBusinessOpportunity(
    @Body() CreateBusinessOpportunityBodyModel body,
  );

  @PATCH("/api/v1/business/opportunities")
  Future<CreateBusinessOpportunityResModel> updateBusinessOpportunity(
    @Body() CreateBusinessOpportunityBodyModel body,
  );

  @DELETE("/api/v1/business/opportunities/{id}")
  Future<CreateBusinessOpportunityResModel> deleteBusinessOpportunity(
    @Path("id") String id,
  );

  @GET("/api/v1/business/opportunities")
  Future<GetBusinessOpportunitiesResModel> getBusinessOpportunities(
    @Query("search") String? search,
    @Query("page") int? page,
    @Query("limit") int? limit,
    @Query("pincode") String? pincode,
  );

  @POST("/api/v1/business/opportunity-reports")
  Future<CreateOpportunityReportResModel> createOpportunityReport(
    @Body() CreateOpportunityReportBodyModel body,
  );

  @GET("/api/v1/business/my/opportunities")
  Future<GetMyBusinessOpportunitiesResModel> getMyBusinessOpportunities(
    @Query("page") int? page,
    @Query("limit") int? limit,
    @Query("search") String? search,
    @Query("companyId") String? companyId,
  );

  @PATCH("/api/v1/auth/update-consents")
  Future<UpdateConsentsResModel> updateConsents(
    @Body() UpdateConsentsBodyModel body,
  );

  @POST("/api/v1/compliance/grievance/submit")
  Future<SubmitGrievanceResModel> submitGrievance(
    @Body() SubmitGrievanceBodyModel body,
  );

  @POST("/api/v1/auth/request-data-summary")
  Future<RequestDataSummaryResModel> requestDataSummary(
    @Body() RequestDataSummaryBodyModel body,
  );

  @GET("/api/v1/business/job-applications/me")
  Future<GetMyJobApplicationsResModel> getMyJobApplications();

  @POST("/api/v1/auth/delete-account/send-otp")
  Future<SendDeletionOtpResModel> sendDeleteAccountOtp();

  @DELETE("/api/v1/auth/user_delete")
  Future<DeleteUserAccountResModel> deleteUserAccount(
    @Body() DeleteUserAccountBodyModel body,
  );

  @POST("/api/v1/business/job-profile")
  @MultiPart()
  Future<ApplyJobProfileResModel> applyJobProfile(
    @Part(name: "postId") String postId,
    @Part(name: "name") String name,
    @Part(name: "email") String email,
    @Part(name: "phone") String phone,
    @Part(name: "comment") String? comment,
    @Part(name: "resume") File? resume,
  );

  @POST("/api/v1/auth/feedback")
  Future<SubmitFeedbackResModel> submitFeedback(
    @Body() SubmitFeedbackBodyModel body,
  );

  @POST("/api/v1/business/transfer/send-otp")
  Future<CompanyTransferSendOtpResModel> sendCompanyTransferOtp(
    @Body() CompanyTransferSendOtpBodyModel body,
  );

  @GET("/api/v1/business/transfer/lookup-receiver")
  Future<CompanyTransferLookupResModel> lookupTransferReceiver(
    @Query("phone") String phone,
  );

  @POST("/api/v1/business/transfer/execute")
  Future<CompanyTransferExecuteResModel> executeCompanyTransfer(
    @Body() CompanyTransferExecuteBodyModel body,
  );

  @PATCH("/api/v1/auth/userprofile_update")
  Future<dynamic> updateUserLocation(@Body() UpdateUserLocationBodyModel body);

  @PATCH("/api/v1/auth/fcm-token")
  Future<dynamic> updateFcmToken(@Body() UpdateFcmTokenBodyModel body);

  @GET("/api/v1/notifications")
  Future<GetNotificationListModel> getNotificationList(
    @Query("page") int page,
    @Query("limit") int limit,
  );

  @PATCH("/api/v1/notifications/{id}/read")
  Future<dynamic> readSingleNotification(@Path("id") String id);

  @PATCH("/api/v1/notifications/read-all")
  Future<dynamic> readAllNotifications();

  @GET("/api/v1/auth/dashboard")
  Future<GetDashboardModel> getDashboardData();

  @POST("/api/v1/notifications/location-view/{id}")
  Future<SendNotificatonResModel> sendNotificationById(@Path("id") String id);
}
