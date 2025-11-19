/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

// Khởi tạo Admin SDK
admin.initializeApp();

/**
 * Trigger: Chạy khi có Document mới trong collection 'Notification'
 * Sử dụng chuẩn v2: onDocumentCreated
 */
exports.sendPushNotification = onDocumentCreated("Notification/{notificationId}", async (event) => {
  try {
    // Trong v2, snapshot nằm trong event.data
    const snapshot = event.data;
    if (!snapshot) {
        console.log("⚠️ Không có dữ liệu snapshot.");
        return;
    }

    const notifData = snapshot.data();
    const notificationId = event.params.notificationId; // Lấy ID từ params

    console.log(`🔔 Có thông báo mới: ${notificationId}`);

    // 1. Lấy userId người nhận
    const recipientId = notifData.userId;
    if (!recipientId) {
      console.log("❌ Không có userId người nhận.");
      return;
    }

    // 2. Tìm Token của người nhận trong bảng User
    const userDoc = await admin.firestore().collection("User").doc(recipientId).get();
    if (!userDoc.exists) {
      console.log(`❌ Không tìm thấy User: ${recipientId}`);
      return;
    }

    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) {
      console.log(`⚠️ User ${recipientId} chưa có Token (chưa đăng nhập trên đt).`);
      return;
    }

    // 3. Chuẩn bị nội dung
    const title = notifData.title || "Thông báo mới";
    const body = notifData.content || "Bạn có thông báo mới.";
    const image = notifData.fromUserAvatar || "";

    // 4. Tạo gói tin gửi đi
    const message = {
      token: fcmToken,
      notification: {
        title: title,
        body: body,
      },
      data: {
        targetId: notifData.targetId || "",
        targetType: notifData.targetType || "",
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      // Cấu hình cho Android (hiện ảnh to)
      android: {
        notification: {
          sound: "default",
          priority: "high",
          channelId: "high_importance_channel",
          ...(image.startsWith("http") && { imageUrl: image }),
        },
      },
      // Cấu hình cho iOS
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    };

    // 5. Gửi ngay lập tức
    const response = await admin.messaging().send(message);
    console.log("✅ Gửi thành công message ID:", response);

  } catch (error) {
    console.error("❌ Lỗi gửi thông báo:", error);
  }
});