package com.edusafe.app.ui

import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.edusafe.app.api.*
import com.edusafe.app.databinding.ActivityRegisterBinding
import com.edusafe.app.utils.DongleHelper
import kotlinx.coroutines.launch

class RegisterActivity : AppCompatActivity() {

    private lateinit var binding: ActivityRegisterBinding
    private lateinit var dongleHelper: DongleHelper

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityRegisterBinding.inflate(layoutInflater)
        setContentView(binding.root)

        dongleHelper = DongleHelper(this)

        binding.btnRegister.setOnClickListener {
            val username = binding.etUsername.text.toString().trim()
            val password = binding.etPassword.text.toString()
            val confirm = binding.etConfirmPassword.text.toString()
            val role = if (binding.rbDosen.isChecked) "dosen" else "mahasiswa"

            if (username.isEmpty() || password.isEmpty()) {
                Toast.makeText(this, "Isi semua field", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            if (password != confirm) {
                Toast.makeText(this, "Password tidak cocok", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            if (password.length < 6) {
                Toast.makeText(this, "Password minimal 6 karakter", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }

            lifecycleScope.launch {
                try {
                    val res = ApiClient.instance.register(
                        RegisterRequest(username, password, role)
                    )
                    if (res.isSuccessful && res.body()?.status == "success") {
                        val data = res.body()!!.data!!
                        val saved = dongleHelper.saveDongleToDownload(data.dongleContent)
                        val msg = if (saved)
                            "Registrasi sukses!\nDongle disimpan di folder Download.\nPINDAHKAN ke flashdisk sebelum login."
                        else
                            "Registrasi sukses tapi gagal simpan dongle.\nSimpan manual: ${data.dongleContent}"
                        Toast.makeText(this@RegisterActivity, msg, Toast.LENGTH_LONG).show()
                        startActivity(Intent(this@RegisterActivity, LoginActivity::class.java))
                        finish()
                    } else {
                        Toast.makeText(this@RegisterActivity,
                            res.body()?.message ?: "Registrasi gagal", Toast.LENGTH_LONG).show()
                    }
                } catch (e: Exception) {
                    Toast.makeText(this@RegisterActivity, "Error: ${e.message}", Toast.LENGTH_LONG).show()
                }
            }
        }

        binding.tvGoLogin.setOnClickListener { finish() }
    }
}