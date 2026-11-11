package com.edusafe.app.ui

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.OpenableColumns
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.edusafe.app.api.ApiClient
import com.edusafe.app.databinding.ActivityCertificateBinding
import com.edusafe.app.utils.TokenManager
import kotlinx.coroutines.launch
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.MultipartBody
import okhttp3.RequestBody.Companion.asRequestBody
import okhttp3.RequestBody.Companion.toRequestBody
import java.io.File
import java.io.FileOutputStream

class CertificateActivity : AppCompatActivity() {

    private lateinit var binding: ActivityCertificateBinding
    private lateinit var tokenManager: TokenManager
    private var selectedUri: Uri? = null

    private val pickImageLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (result.resultCode == Activity.RESULT_OK) {
            selectedUri = result.data?.data
            selectedUri?.let { binding.tvImageName.text = getFileName(it) }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityCertificateBinding.inflate(layoutInflater)
        setContentView(binding.root)
        tokenManager = TokenManager(this)

        binding.btnBack.setOnClickListener { finish() }

        binding.btnPickImage.setOnClickListener {
            val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
                type = "image/*"
                putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("image/jpeg", "image/png"))
            }
            pickImageLauncher.launch(intent)
        }

        binding.btnGenerate.setOnClickListener {
            val student = binding.etStudentName.text.toString().trim()
            val course = binding.etCourseName.text.toString().trim()
            val message = binding.etHiddenMessage.text.toString().trim()
            val uri = selectedUri

            if (student.isEmpty() || course.isEmpty() || message.isEmpty()) {
                Toast.makeText(this, "Isi semua field", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            if (uri == null) {
                Toast.makeText(this, "Pilih gambar template", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            generate(student, course, message, uri)
        }

        loadCertificates()
    }

    private fun generate(student: String, course: String, message: String, uri: Uri) {
        val auth = "Bearer ${tokenManager.getToken()}"
        lifecycleScope.launch {
            try {
                val file = uriToFile(uri)
                val imagePart = MultipartBody.Part.createFormData(
                    "certificate_image", file.name,
                    file.asRequestBody("image/*".toMediaTypeOrNull())
                )
                val studentBody = student.toRequestBody("text/plain".toMediaTypeOrNull())
                val courseBody = course.toRequestBody("text/plain".toMediaTypeOrNull())
                val msgBody = message.toRequestBody("text/plain".toMediaTypeOrNull())

                val res = ApiClient.instance.generateCertificate(auth, studentBody, courseBody, msgBody, imagePart)
                if (res.isSuccessful) {
                    Toast.makeText(this@CertificateActivity, "Sertifikat + pesan tersembunyi dibuat!", Toast.LENGTH_LONG).show()
                    binding.etStudentName.text?.clear()
                    binding.etCourseName.text?.clear()
                    binding.etHiddenMessage.text?.clear()
                    binding.tvImageName.text = "Belum ada gambar"
                    selectedUri = null
                    loadCertificates()
                } else {
                    Toast.makeText(this@CertificateActivity,
                        res.body()?.message ?: "Gagal generate", Toast.LENGTH_LONG).show()
                }
            } catch (e: Exception) {
                Toast.makeText(this@CertificateActivity, "Error: ${e.message}", Toast.LENGTH_LONG).show()
            }
        }
    }

    private fun loadCertificates() {
        val auth = "Bearer ${tokenManager.getToken()}"
        lifecycleScope.launch {
            try {
                val res = ApiClient.instance.getCertificates(auth)
                if (res.isSuccessful && res.body()?.data != null) {
                    val sb = StringBuilder()
                    for (c in res.body()!!.data!!.certificates) {
                        sb.append("🏆 ${c.studentName} - ${c.courseName}\n")
                        sb.append("   ${c.createdAt}\n\n")
                    }
                    binding.tvCertList.text = if (sb.isEmpty()) "Belum ada sertifikat." else sb.toString()
                }
            } catch (e: Exception) {
                binding.tvCertList.text = "Error: ${e.message}"
            }
        }
    }

    private fun getFileName(uri: Uri): String {
        var name = "image.jpg"
        contentResolver.query(uri, null, null, null, null)?.use { cursor ->
            val idx = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (idx >= 0 && cursor.moveToFirst()) name = cursor.getString(idx)
        }
        return name
    }

    private fun uriToFile(uri: Uri): File {
        val name = getFileName(uri)
        val tempFile = File(cacheDir, name)
        contentResolver.openInputStream(uri)?.use { input ->
            FileOutputStream(tempFile).use { output -> input.copyTo(output) }
        }
        return tempFile
    }
}