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
import com.edusafe.app.databinding.ActivityFileUploadBinding
import com.edusafe.app.utils.TokenManager
import kotlinx.coroutines.launch
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.MultipartBody
import okhttp3.RequestBody.Companion.asRequestBody
import java.io.File
import java.io.FileOutputStream

class FileUploadActivity : AppCompatActivity() {

    private lateinit var binding: ActivityFileUploadBinding
    private lateinit var tokenManager: TokenManager
    private var selectedUri: Uri? = null

    private val pickFileLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (result.resultCode == Activity.RESULT_OK) {
            selectedUri = result.data?.data
            selectedUri?.let {
                binding.tvFileName.text = getFileName(it)
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityFileUploadBinding.inflate(layoutInflater)
        setContentView(binding.root)
        tokenManager = TokenManager(this)

        binding.btnBack.setOnClickListener { finish() }

        binding.btnPickFile.setOnClickListener {
            val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
                type = "*/*"
                putExtra(Intent.EXTRA_MIME_TYPES, arrayOf(
                    "application/pdf", "application/msword",
                    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                    "text/plain"
                ))
            }
            pickFileLauncher.launch(intent)
        }

        binding.btnUpload.setOnClickListener {
            val uri = selectedUri
            if (uri == null) {
                Toast.makeText(this, "Pilih file dulu", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            uploadFile(uri)
        }

        loadFiles()
    }

    private fun uploadFile(uri: Uri) {
        val auth = "Bearer ${tokenManager.getToken()}"
        lifecycleScope.launch {
            try {
                val file = uriToFile(uri)
                val requestFile = file.asRequestBody("application/octet-stream".toMediaTypeOrNull())
                val body = MultipartBody.Part.createFormData("file", file.name, requestFile)

                val res = ApiClient.instance.uploadFile(auth, body)
                if (res.isSuccessful) {
                    Toast.makeText(this@FileUploadActivity, "File terenkripsi & terupload!", Toast.LENGTH_SHORT).show()
                    binding.tvFileName.text = "Belum ada file dipilih"
                   