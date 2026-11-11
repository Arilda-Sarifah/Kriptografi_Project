package com.edusafe.app.api

import com.google.gson.annotations.SerializedName

// ====== RESPONSE UMUM ======
data class ApiResponse<T>(
    val status: String,
    val message: String,
    val data: T?
)

// ====== AUTH ======
data class RegisterRequest(
    val username: String,
    val password: String,
    val role: String
)

data class RegisterResponse(
    @SerializedName("user_id") val userId: Int,
    val username: String,
    val role: String,
    @SerializedName("dongle_file_name") val dongleFileName: String,
    @SerializedName("dongle_content") val dongleContent: String
)

data class LoginRequest(
    val username: String,
    val password: String,
    @SerializedName("dongle_content") val dongleContent: String
)

data class LoginResponse(
    val token: String,
    val user: User
)

data class User(
    val id: Int,
    val username: String,
    val role: String
)

data class VerifyDongleRequest(
    val username: String,
    @SerializedName("dongle_content") val dongleContent: String
)

// ====== MESSAGING ======
data class SendMessageRequest(
    @SerializedName("receiver_id") val receiverId: Int,
    val message: String
)

data class MessagesResponse(
    val messages: List<Message>
)

data class Message(
    val id: Int,
    @SerializedName("sender_id") val senderId: Int,
    @SerializedName("receiver_id") val receiverId: Int,
    @SerializedName("sender_name") val senderName: String,
    @SerializedName("receiver_name") val receiverName: String,
    @SerializedName("encrypted_message") val encryptedMessage: String,
    @SerializedName("created_at") val createdAt: String
)

data class UsersResponse(
    val users: List<User>
)

// ====== FILES ======
data class FilesResponse(
    val files: List<ExamFile>
)

data class ExamFile(
    val id: Int,
    val filename: String,
    @SerializedName("original_filename") val originalFilename: String,
    @SerializedName("uploader_name") val uploaderName: String?,
    @SerializedName("size_kb") val sizeKb: Double,
    @SerializedName("created_at") val createdAt: String
)

// ====== CERTIFICATES ======
data class CertificatesResponse(
    val certificates: List<Certificate>
)

data class Certificate(
    val id: Int,
    @SerializedName("student_name") val studentName: String,
    @SerializedName("course_name") val courseName: String,
    @SerializedName("stego_image_url") val stegoImageUrl: String,
    @SerializedName("original_image_url") val originalImageUrl: String,
    @SerializedName("creator_name") val creatorName: String?,
    @SerializedName("created_at") val createdAt: String
)