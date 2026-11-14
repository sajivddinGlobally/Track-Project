// To parse this JSON data, do
//
//     final getDashboardModel = getDashboardModelFromJson(jsonString);

import 'dart:convert';

GetDashboardModel getDashboardModelFromJson(String str) => GetDashboardModel.fromJson(json.decode(str));

String getDashboardModelToJson(GetDashboardModel data) => json.encode(data.toJson());

class GetDashboardModel {
    bool? success;
    String? message;
    Data? data;

    GetDashboardModel({
        this.success,
        this.message,
        this.data,
    });

    factory GetDashboardModel.fromJson(Map<String, dynamic> json) => GetDashboardModel(
        success: json["success"],
        message: json["message"],
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": data?.toJson(),
    };
}

class Data {
    AlertsAndTasks? alertsAndTasks;
    RecentTimeline? recentTimeline;
    NetworkOverview? networkOverview;
    PerformanceInsights? performanceInsights;

    Data({
        this.alertsAndTasks,
        this.recentTimeline,
        this.networkOverview,
        this.performanceInsights,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        alertsAndTasks: json["alertsAndTasks"] == null ? null : AlertsAndTasks.fromJson(json["alertsAndTasks"]),
        recentTimeline: json["recentTimeline"] == null ? null : RecentTimeline.fromJson(json["recentTimeline"]),
        networkOverview: json["networkOverview"] == null ? null : NetworkOverview.fromJson(json["networkOverview"]),
        performanceInsights: json["performanceInsights"] == null ? null : PerformanceInsights.fromJson(json["performanceInsights"]),
    );

    Map<String, dynamic> toJson() => {
        "alertsAndTasks": alertsAndTasks?.toJson(),
        "recentTimeline": recentTimeline?.toJson(),
        "networkOverview": networkOverview?.toJson(),
        "performanceInsights": performanceInsights?.toJson(),
    };
}

class AlertsAndTasks {
    int? total;
    int? connectionRequests;
    int? systemAlerts;
    List<SystemAlertItem>? systemAlertItems;
    LocationPermissionAlert? locationPermissionAlert;

    AlertsAndTasks({
        this.total,
        this.connectionRequests,
        this.systemAlerts,
        this.systemAlertItems,
        this.locationPermissionAlert,
    });

    factory AlertsAndTasks.fromJson(Map<String, dynamic> json) => AlertsAndTasks(
        total: json["total"] is int ? json["total"] : int.tryParse(json["total"]?.toString() ?? ''),
        connectionRequests: json["connectionRequests"] is int ? json["connectionRequests"] : int.tryParse(json["connectionRequests"]?.toString() ?? ''),
        systemAlerts: json["systemAlerts"] is int ? json["systemAlerts"] : int.tryParse(json["systemAlerts"]?.toString() ?? ''),
        systemAlertItems: json["systemAlertItems"] == null
            ? []
            : List<SystemAlertItem>.from(
                (json["systemAlertItems"] as List).map(
                  (x) => SystemAlertItem.fromJson(
                    x is Map ? Map<String, dynamic>.from(x) : <String, dynamic>{},
                  ),
                ),
              ),
        locationPermissionAlert: json["locationPermissionAlert"] == null
            ? null
            : LocationPermissionAlert.fromJson(
                json["locationPermissionAlert"] is Map
                    ? Map<String, dynamic>.from(json["locationPermissionAlert"] as Map)
                    : <String, dynamic>{},
              ),
    );

    Map<String, dynamic> toJson() => {
        "total": total,
        "connectionRequests": connectionRequests,
        "systemAlerts": systemAlerts,
        "systemAlertItems": systemAlertItems == null
            ? []
            : List<dynamic>.from(systemAlertItems!.map((x) => x.toJson())),
        "locationPermissionAlert": locationPermissionAlert?.toJson(),
    };
}

class SystemAlertItem {
    String? type;
    String? message;
    String? friendId;
    String? friendName;
    int? minutesRemaining;
    bool? isExpiring;
    bool? isExpired;
    bool? canRenew;
    DateTime? expiresAt;

    SystemAlertItem({
        this.type,
        this.message,
        this.friendId,
        this.friendName,
        this.minutesRemaining,
        this.isExpiring,
        this.isExpired,
        this.canRenew,
        this.expiresAt,
    });

    factory SystemAlertItem.fromJson(Map<String, dynamic> json) => SystemAlertItem(
        type: json["type"]?.toString(),
        message: json["message"]?.toString(),
        friendId: json["friendId"]?.toString(),
        friendName: json["friendName"]?.toString(),
        minutesRemaining: json["minutesRemaining"] is int
            ? json["minutesRemaining"]
            : int.tryParse(json["minutesRemaining"]?.toString() ?? ''),
        isExpiring: json["isExpiring"] == true || json["isExpiring"] == 'true',
        isExpired: json["isExpired"] == true || json["isExpired"] == 'true',
        canRenew: json["canRenew"] == true || json["canRenew"] == 'true',
        expiresAt: json["expiresAt"] == null
            ? null
            : DateTime.tryParse(json["expiresAt"].toString()),
    );

    Map<String, dynamic> toJson() => {
        "type": type,
        "message": message,
        "friendId": friendId,
        "friendName": friendName,
        "minutesRemaining": minutesRemaining,
        "isExpiring": isExpiring,
        "isExpired": isExpired,
        "canRenew": canRenew,
        "expiresAt": expiresAt?.toIso8601String(),
    };
}

class LocationPermissionAlert {
    bool? isExpiring;
    bool? isExpired;
    String? message;
    String? friendName;
    int? minutesRemaining;
    bool? canRenew;

    LocationPermissionAlert({
        this.isExpiring,
        this.isExpired,
        this.message,
        this.friendName,
        this.minutesRemaining,
        this.canRenew,
    });

    factory LocationPermissionAlert.fromJson(Map<String, dynamic> json) =>
        LocationPermissionAlert(
            isExpiring: json["isExpiring"] == true || json["isExpiring"] == 'true',
            isExpired: json["isExpired"] == true || json["isExpired"] == 'true',
            message: json["message"]?.toString(),
            friendName: json["friendName"]?.toString(),
            minutesRemaining: json["minutesRemaining"] is int
                ? json["minutesRemaining"]
                : int.tryParse(json["minutesRemaining"]?.toString() ?? ''),
            canRenew: json["canRenew"] == true || json["canRenew"] == 'true',
        );

    Map<String, dynamic> toJson() => {
        "isExpiring": isExpiring,
        "isExpired": isExpired,
        "message": message,
        "friendName": friendName,
        "minutesRemaining": minutesRemaining,
        "canRenew": canRenew,
    };
}

class NetworkOverview {
    int? totalConnections;
    int? acceptedFriends;
    int? connectionRequests;
    int? sentRequests;

    NetworkOverview({
        this.totalConnections,
        this.acceptedFriends,
        this.connectionRequests,
        this.sentRequests,
    });

    factory NetworkOverview.fromJson(Map<String, dynamic> json) => NetworkOverview(
        totalConnections: json["totalConnections"] is int ? json["totalConnections"] : int.tryParse(json["totalConnections"]?.toString() ?? ''),
        acceptedFriends: json["acceptedFriends"] is int ? json["acceptedFriends"] : int.tryParse(json["acceptedFriends"]?.toString() ?? ''),
        connectionRequests: json["connectionRequests"] is int ? json["connectionRequests"] : int.tryParse(json["connectionRequests"]?.toString() ?? ''),
        sentRequests: json["sentRequests"] is int ? json["sentRequests"] : int.tryParse(json["sentRequests"]?.toString() ?? ''),
    );

    Map<String, dynamic> toJson() => {
        "totalConnections": totalConnections,
        "acceptedFriends": acceptedFriends,
        "connectionRequests": connectionRequests,
        "sentRequests": sentRequests,
    };
}

class PerformanceInsights {
    String? period;
    int? totalConnections;
    List<ByDay>? byDay;

    PerformanceInsights({
        this.period,
        this.totalConnections,
        this.byDay,
    });

    factory PerformanceInsights.fromJson(Map<String, dynamic> json) => PerformanceInsights(
        period: json["period"]?.toString(),
        totalConnections: json["totalConnections"] is int ? json["totalConnections"] : int.tryParse(json["totalConnections"]?.toString() ?? ''),
        byDay: json["byDay"] == null ? [] : List<ByDay>.from((json["byDay"] as List).map((x) => ByDay.fromJson(x is Map<String, dynamic> ? x : {}))),
    );

    Map<String, dynamic> toJson() => {
        "period": period,
        "totalConnections": totalConnections,
        "byDay": byDay == null ? [] : List<dynamic>.from(byDay!.map((x) => x.toJson())),
    };
}

class ByDay {
    String? day;
    int? count;

    ByDay({
        this.day,
        this.count,
    });

    factory ByDay.fromJson(Map<String, dynamic> json) => ByDay(
        day: json["day"]?.toString(),
        count: json["count"] is int ? json["count"] : int.tryParse(json["count"]?.toString() ?? ''),
    );

    Map<String, dynamic> toJson() => {
        "day": day,
        "count": count,
    };
}

class RecentTimeline {
    int? count;
    List<Item>? items;

    RecentTimeline({
        this.count,
        this.items,
    });

    factory RecentTimeline.fromJson(Map<String, dynamic> json) => RecentTimeline(
        count: json["count"] is int ? json["count"] : int.tryParse(json["count"]?.toString() ?? ''),
        items: json["items"] == null ? [] : List<Item>.from((json["items"] as List).map((x) => Item.fromJson(x is Map<String, dynamic> ? x : {}))),
    );

    Map<String, dynamic> toJson() => {
        "count": count,
        "items": items == null ? [] : List<dynamic>.from(items!.map((x) => x.toJson())),
    };
}

class Item {
    String? type;
    String? status;
    String? title;
    DateTime? occurredAt;

    Item({
        this.type,
        this.status,
        this.title,
        this.occurredAt,
    });

    factory Item.fromJson(Map<String, dynamic> json) => Item(
        type: json["type"]?.toString(),
        status: json["status"]?.toString(),
        title: json["title"]?.toString(),
        occurredAt: json["occurredAt"] == null ? null : DateTime.tryParse(json["occurredAt"].toString()),
    );

    Map<String, dynamic> toJson() => {
        "type": type,
        "status": status,
        "title": title,
        "occurredAt": occurredAt?.toIso8601String(),
    };
}
