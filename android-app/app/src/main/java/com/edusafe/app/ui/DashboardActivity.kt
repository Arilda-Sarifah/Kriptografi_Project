package com.edusafe.app.ui

import android.content.Intent
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import com.edusafe.app.databinding.ActivityDashboardBinding
import com.edusafe.app.utils.TokenManager

class DashboardActivity : AppCompatActivity() {

    private lateinit var binding: ActivityDashboardBinding
    private lateinit var tokenManager: TokenManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityDashboardBinding.inflate(layoutInflater)
        setContentView(binding.root)

        tokenManager = TokenManager(this)
        val username = tokenManager.getUsername() ?: "User"
        val role = tokenManager.getRole() ?: "mahasiswa"

        binding.tvWelcome.text = "Selamat datang, $username ($role)"

        binding.cardMessaging.setOnClickListener {
            startActivity(Intent(this, MessagingActivity::class.java))
        }
        binding.cardFile.setOnClickListener {
            startActivity(Intent(this, FileUploadActivity::class.java))
        }
        binding.cardCertificate.setOnClickListener {
            startActivity(Intent(this, CertificateActivity::class.java))
        }
        binding.btnLogout.setOnClickListener {
            tokenManager.clear()
            startActivity(Intent(this, LoginActivity::class.java))
            finish()
        }
    }
}