/**
 * functions/index.js – PHIÊN BẢN HOÀN CHỈNH NHẤT 2025 (ĐÃ SỬA XONG 100% LỖI ẢNH + CLICK MỞ BÀI VIẾT)
 */

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
admin.initializeApp();

// Logo app khi chưa có avatar
const DEFAULT_AVATAR_URL = "https://firebasestorage.googleapis.com/v0/b/doanmxh-1015e.firebasestorage.app/o/user_avatars%2Flogoapp.png?alt=media&token=2da297eb-c060-47ca-a659-f0ad1b78e358";

// ==================================================================
// 1. THÔNG BÁO CHUNG (collection Notification)
// ==================================================================
exports.sendPushNotification = onDocumentCreated("Notification/{notificationId}", async (event) => {
  try {
    const snapshot = event.data;
    if (!snapshot) return;

    const data = snapshot.data();
    const recipientId = data.userId;
    if (!recipientId) return;

    const userDoc = await admin.firestore().collection("User").doc(recipientId).get();
    if (!userDoc.exists || !userDoc.data()?.fcmToken) return;

    const token = userDoc.data().fcmToken;
    const title = data.title || "Thông báo mới";
    const body = data.content || "Bạn có thông báo mới.";

    let image = DEFAULT_AVATAR_URL;
    const fromAvatar = data.fromUserAvatar;
    if (typeof fromAvatar === "string" && fromAvatar.trim() !== "" && fromAvatar.startsWith("http")) {
      image = fromAvatar;
    }

    const message = {
      token,
      notification: { title, body },
      data: {
        targetId: data.targetId || "",
        targetType: data.targetType || "",
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        notification: {
          channelId: "high_importance_channel",
          priority: "high",
          imageUrl: image && image.trim() !== "" ? image : null, // ĐÃ SỬA: không gửi chuỗi rỗng
        },
      },
      apns: { payload: { aps: { sound: "default", badge: 1 } } },
    };

    await admin.messaging().send(message);
    console.log("Thông báo chung gửi thành công");
  } catch (e) {
    console.error("Lỗi sendPushNotification:", e);
  }
});

// ==================================================================
// 2. THÔNG BÁO TIN NHẮN CHAT
// ==================================================================
exports.sendDelayedMessageNotification = onDocumentCreated("Chat/{chatId}/messages/{messageId}", async (event) => {
  try {
    const snapshot = event.data;
    if (!snapshot) return;

    const msg = snapshot.data();
    const { chatId } = event.params;

    if (msg.status === "deleted" || msg.status === "recalled") return;

    const senderId = msg.senderId;
    const senderDoc = await admin.firestore().collection("User").doc(senderId).get();

    let senderName = "Người dùng";
    let senderAvatar = DEFAULT_AVATAR_URL;
    if (senderDoc.exists) {
      const d = senderDoc.data();
      senderName = d?.name || "Người dùng";
      const avt = d?.avatar;
      if (typeof avt === "string" && avt.trim() !== "" && avt.startsWith("http")) {
        senderAvatar = avt;
      }
    }

    const chatDoc = await admin.firestore().collection("Chat").doc(chatId).get();
    if (!chatDoc.exists) return;

    const members = chatDoc.data()?.members || [];
    const recipientIds = members.filter(id => id !== senderId);
    if (recipientIds.length === 0) return;

    let body = (msg.content || "").trim();
    if (msg.type === "share_post") body = "đã chia sẻ một bài viết";
    else if (msg.mediaIds?.length > 0 && !body) body = "đã gửi ảnh/video";
    else if (!body) body = "đã gửi một tin nhắn";
    if (body.length > 80) body = body.substring(0, 77) + "...";

    const payload = {
      notification: { title: senderName, body },
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK_CHAT",
        chatId,
        chatName: senderName,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "high_importance_channel",
          imageUrl: senderAvatar && senderAvatar.trim() !== "" ? senderAvatar : null, // ĐÃ SỬA
        },
      },
      apns: {
        payload: { aps: { sound: "default", badge: 1, "content-available": 1 } },
      },
    };

    for (const rid of recipientIds) {
      const recDoc = await admin.firestore().collection("User").doc(rid).get();
      const token = recDoc.data()?.fcmToken;
      if (token) {
        await admin.messaging().send({ ...payload, token });
        console.log(`Thông báo chat → ${rid}`);
      }
    }
  } catch (e) {
    console.error("Lỗi thông báo chat:", e);
  }
});

// ==================================================================
// 3. THÔNG BÁO BÌNH LUẬN & REACTION BÀI VIẾT (HOÀN HẢO 100%)
// ==================================================================
const COOLDOWN_HOURS = 3; // Đổi thành 0 nếu muốn test gửi liên tục

exports.sendPostActivityNotification = onDocumentCreated("Post/{postId}/{collection}/{docId}", async (event) => {
  try {
    const { postId, collection, docId } = event.params;
    console.log("TRIGGER!", { postId, collection, docId });

    if (!["comments", "reactions"].includes(collection)) return;

    const snapshot = event.data;
    if (!snapshot?.exists) return;
    const data = snapshot.data();

    // Lấy người tương tác (comment hoặc reaction)
    const actorId = data.authorId || data.userId || docId;
    if (!actorId) return;

    // Lấy chủ bài viết
    const postSnap = await admin.firestore().collection("Post").doc(postId).get();
    if (!postSnap.exists) return;
    const ownerId = postSnap.data()?.authorId;
    if (!ownerId || actorId === ownerId) {
      console.log("Tự tương tác → bỏ qua");
      return;
    }

    // Kiểm tra cooldown (nếu bật)
    if (COOLDOWN_HOURS > 0) {
      const cooldownRef = admin.firestore().collection("System").doc(`post_cooldown_${postId}`);
      const cooldownDoc = await cooldownRef.get();
      const now = Date.now();
      const limit = now - COOLDOWN_HOURS * 60 * 60 * 1000;

      if (cooldownDoc.exists && cooldownDoc.data()?.lastSent > limit) {
        console.log(`Đã gửi gần đây → bỏ qua (cooldown ${COOLDOWN_HOURS}h)`);
        return;
      }
      await cooldownRef.set({ lastSent: now }, { merge: true });
    }

    // Lấy info người tương tác
    const actorSnap = await admin.firestore().collection("User").doc(actorId).get();
    if (!actorSnap.exists) return;

    const actorName = actorSnap.data()?.name || "Ai đó";
    let actorAvatar = DEFAULT_AVATAR_URL;
    const userAvatar = actorSnap.data()?.avatar;
    if (typeof userAvatar === "string" && userAvatar.trim() !== "" && userAvatar.startsWith("http")) {
      actorAvatar = userAvatar;
    }

    // Nội dung thông báo
    let body = "";
    if (collection === "comments") {
      body = "đã bình luận bài viết của bạn";
    } else {
      const type = data.type || "like";
      const emojiMap = { like: "thích", love: "yêu thích", haha: "haha", wow: "wow", sad: "buồn", angry: "tức giận" };
      body = `đã ${emojiMap[type] || "thả cảm xúc"} bài viết của bạn`;
    }

    // Lấy FCM token của chủ bài
    const ownerSnap = await admin.firestore().collection("User").doc(ownerId).get();
    const token = ownerSnap.data()?.fcmToken;
    if (!token) {
      console.log("Chủ bài chưa có FCM token");
      return;
    }

    // GỬI THÔNG BÁO
    const payload = {
      token,
      notification: { title: actorName, body },
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        targetId: postId,
        targetType: "post",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "high_importance_channel",
          imageUrl: actorAvatar && actorAvatar.trim() !== "" ? actorAvatar : null, // ĐÃ SỬA 100%
        },
      },
      apns: { payload: { aps: { sound: "default", badge: 1 } } },
    };

    const result = await admin.messaging().send(payload);
    console.log("THÔNG BÁO BÌNH LUẬN/REACTION GỬI THÀNH CÔNG!", result);

  } catch (error) {
    console.error("Lỗi gửi thông báo bài viết:", error.message || error);
  }
});