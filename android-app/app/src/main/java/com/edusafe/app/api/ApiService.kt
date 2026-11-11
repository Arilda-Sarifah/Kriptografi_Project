package com.edusafe.app.api

import okhttp3.MultipartBody
import okhttp3.RequestBody
import retrofit2.Response
import retrofit2.http.*

interface ApiService {

    @POST("register.php")
    suspend fun register(@Body body: RegisterRequest): Response<ApiResponse<RegisterResponse>>

    @POST("login.php")
    suspend fun login(@Body body: LoginRequest): Response<ApiResponse<LoginResponse>>

    @POST("verify_dongle.php")
    suspend fun verifyDongle(@Body body: VerifyDongleRequest): Response<ApiResponse<Any>>

    @GET("get_users.php")
    suspend fun getUsers(@Header("Authorization") auth: String): Response<ApiResponse<UsersResponse>>

    @GET("get_messages.php")
    suspend fun getMessages(@Header("Authorization") auth: String): Response<ApiResponse<MessagesResponse>>

    @POST("send_message.php")
    suspend fun sendMessage(
        @Header("Authorization") auth: String,
        @Body body: SendMessageRequest
    ): Response<ApiResponse<Any>>

    @GET("get_files.php")
    suspend fun getFiles(@Header("Authorization") auth: String): Response<ApiResponse<FilesResponse>>

    @Multipart
    @POST("upload_file.php")
    suspend fun uploadFile(
        @Header("Authorization") auth: String,
        @Part file: MultipartBody.Part
    ): Response<ApiResponse<Any>>

    @GET("get_certificates.php")
    suspend fun getCertificates(@Header("Authorization") auth: String): Response<ApiResponse<CertificatesResponse>>

    @Multipart
    @POST("generate_certificate.php")
    suspend fun generateCertificate(
        @Header("Authorization") auth: String,
        @Part("student_name") studentName: RequestBody,
        @Part("course_name") courseName: RequestBody,
        @Part("hidden_message") hiddenMessage: RequestBody,
        @Part image: MultipartBody.Part
    ): Response<ApiResponse<Any>>
}