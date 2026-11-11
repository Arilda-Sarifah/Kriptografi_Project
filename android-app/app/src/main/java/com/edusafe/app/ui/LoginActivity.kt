package com.edusafe.app.ui

import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.edusafe.app.api.*
import com.edusafe.app.databinding.ActivityLoginBinding
import com.edusafe.app.utils.BiometricHelper
import com.edusafe.app.utils.DongleHelper
import com.edusafe.app.utils.TokenManager
import kotlinx.coroutines.launch

class LoginActivity : AppCompatActivity() {

    private lateinit var binding: ActivityLoginBinding
    private lateinit var dongleHelper: DongleHelper
    private lateinit var biometricHelper: BiometricHelper
    private lateinit var tokenManager: TokenManager
    private var dongleContent: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityLoginBinding.inflate(layoutInflater)
        setContentView(binding.root)

        dongleHelper = DongleHelper(this)
        biometricHelper = BiometricHelper(this)
        tokenManager = TokenManager(this)

        binding.btnBiometricLogin.isEnabled = false

        binding.btnScanDongle.setOnClickListener {
            val content = dongleHelper.readDongle()
            if (content == null) {
                Toast.makeText(this, "Dongle tidak ditemukan. Colokkan flashdisk dongle.", Toast.LENGTH_LONG).show()
                binding.btnBiometricLogin.isEnabled = false
            } else {
                dongleContent = content
                Toast.makeText(this, "✓ Dongle terverifikasi. Silakan login biometrik.", Toast.LENGTH_SHORT).show()
                binding.btnBiometricLogin.isEnabled = true
            }
        }

        binding.btnBiometricLogin.setOnClickListener {
            if (dongleContent == null) {
                Toast.makeText(this, "Scan dongle terlebih dahulu!", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            val username = binding.etUsername.text.toString().trim()
            if (username.isEmpty()) {
                Toast.makeText(this, "Isi username dulu", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            if (!biometricHelper.isBiometricAvailable()) {
                Toast.makeText(this, "Biometric tidak tersedia di perangkat", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }

            lifecycleScope.launch {
                try {
                    val res = ApiClient.instance.verifyDongle(
                        VerifyDongleRequest(username, dongleContent!!)
                    )
                    if (!res.isSuccessful) {
                        Toast.makeText(this@LoginActivity, "Dongle tidak valid di server", Toast.LENGTH_LONG).show()
                        return@launch
                    }
                    biometricHelper.showBiometricPrompt(
                        title = "Verifikasi Biometrik",
                        subtitle = "Sentuh sensor sidik jari untuk login",
                        onSuccess = { performLogin(username) },
                        onError = { err ->
                            Toast.makeText(this@LoginActivity, "Biometric gagal: $err", Toast.LENGTH_SHORT).show()
                        }
                    )
                } catch (e: Exception) {
                    Log.e("LoginActivity", "Error verify dongle", e)
                    Toast.makeText(this@LoginActivity, "Error: ${e.message}", Toast.LENGTH_LONG).show()
                }
            }
        }

        binding.tvGoRegister.setOnClickListener {
            startActivity(Intent(this, RegisterActivity::class.java))
        }
    }

    private fun performLogin(username: String) {
        val password = binding.etPassword.text.toString()
        if (password.isEmpty()) {
            Toast.makeText(this, "Password wajib diisi", Toast.LENGTH_SHORT).show()
            return
        }
        lifecycleScope.launch {
            try {
                val res = ApiClient.instance.login(
                    LoginRequest(username, password, dongleContent!!)
                )
                if (res.isSuccessful && res.body()?.status == "success") {
                    val data = res.body()!!.data!!
                    tokenManager.saveToken(data.token)
                    tokenManager.saveUsername(username)
                    tokenManager.saveRole(data.user.role)
                    Toast.makeText(this@LoginActivity, "Login berhasil!", Toast.LENGTH_SHORT).show()
                    startActivity(Intent(this@LoginActivity, DashboardActivity::class.java))
                    finish()
                } else {
                    Toast.makeText(this@LoginActivity,
                        res.body()?.message ?: "Login gagal", Toast.LENGTH_LONG).show()
                }
            } catch (e: Exception) {
                Toast.makeText(this@LoginActivity, "Error: ${e.message}", Toast.LENGTH_LONG).show()
            }
        }
    }
}