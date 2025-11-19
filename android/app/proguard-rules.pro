# ------------------- Flutter Wrapper (bắt buộc) -------------------
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ------------------- Firebase (rất quan trọng) -------------------
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Đặc biệt giữ lại Firebase Messaging service (nếu không sẽ không nhận được thông báo khi app bị kill)
-keep class com.google.firebase.messaging.FirebaseMessagingService { *; }
-keep class com.google.firebase.iid.FirebaseInstanceIdService { *; }

# ------------------- Kotlin -------------------
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings { <fields>; }
-keepclassmembers class kotlin.Metadata { public <methods>; }

# ------------------- ZEGO (rất quan trọng – tên package mới) -------------------
# Từ năm 2024-2025 ZEGO đã đổi package từ im.zego sang com.zego
-keep class com.zego.** { *; }
-keep class im.zego.** { *; }        # giữ lại cả cái cũ phòng trường hợp SDK cũ
-dontwarn com.zego.**
-dontwarn im.zego.**

# ------------------- Các plugin hay dùng -------------------
# flutter_local_notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# image_compress
-keep class com.fluttercandies.flutter_image_compress.** { *; }

# audioplayers
-keep class xyz.luan.audioplayers.** { *; }

# path_provider, shared_preferences, etc (nếu dùng)
-keep class com.example.** { *; }  # giữ lại package của bạn nếu có native code

# ------------------- Giữ lại các class có @Keep (nếu bạn tự viết native) -------------------
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Giữ lại các class được đánh dấu @Keep
-keep,allowobfuscation @interface androidx.annotation.Keep
-keep @androidx.annotation.Keep class *
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}