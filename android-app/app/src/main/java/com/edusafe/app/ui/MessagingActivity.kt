package com.edusafe.app.ui

import android.os.Bundle
import android.widget.ArrayAdapter
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.edusafe.app.api.*
import com.edusafe.app.databinding.ActivityMessagingBinding
import com.edusafe.app.utils.TokenManager
import kotlinx.coroutines.launch

class MessagingActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMessagingBinding
    private lateinit var tokenManager: TokenManager
    private var users = listOf<User>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMessagingBinding.inflate(layoutInflater)
        setContentView(binding.root)

        tokenManager = TokenManager(this)
        val auth = "Bearer ${tokenManager.getToken()}"

        binding.btnBack.setOnClickListener { finish() }

        // Load users
        lifecycleScope.launch {
            try {
                val res = ApiClient.instance.getUsers(auth)
                if (res.isSuccessful && res.body()?.data != null) {
                    users = res.body()!!.data!!.users
                    val names = users.map { "${it.username} (${it.role})" }
                    binding.spinnerReceiver.adapter = ArrayAdapter(
                        this@MessagingActivity,
                        android.R.layout.simple_spinner_dropdown_item,
                        names
                    )
                }
            } catch (e: Exception) {
                Toast.makeText(this@MessagingActivity, "Gagal load users: ${e.message}", Toast.LENGTH_LONG).show()
            }
        }

        // Kirim pesan
        binding.btnSend.setOnClickListener {
            val idx = binding.spinnerReceiver.selectedItemPosition
            val msg = binding.etMessage.text.toString().trim()
            if (idx < 0 || msg.isEmpty()) {
                Toast.makeText(this, "Pilih user & isi pesan", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            lifecycleScope.launch {
                try {
                    val res = ApiClient.instance.sendMessage(auth, SendMessageRequest(users[idx].id, msg))
                    if (res.isSuccessful) {
                        Toast.makeText(this@MessagingActivity, "Pesan terenkripsi terkirim!", Toast.LENGTH_SHORT).show()
                        binding.etMessage.text?.clear()
                        loadHistory(auth)
                    } else {
                        Toast.makeText(this@MessagingActivity, "Gagal kirim", Toast.LENGTH_SHORT).show()
                    }
                } catch (e: Exception) {
                    Toast.makeText(this@MessagingActivity, "Error: ${e.message}", Toast.LENGTH_LONG).show()
                }
            }
        }

        loadHistory(auth)
    }

    private fun loadHistory(auth: String) {
        lifecycleScope.launch {
            try {
                val res = ApiClient.instance.getMessages(auth)
                if (res.isSuccessful && res.body()?.data != null) {
                    val sb = StringBuilder()
                    for (m in res.body()!!.data!!.messages) {
                        sb.append("${m.senderName} → ${m.receiverName}\n")
                        sb.append("🔒 ${m.encryptedMessage.take(60)}...\n")
                        sb.append("${m.createdAt}\n\n")
                    }
                    binding.tvHistory.text = if (sb.isEmpty()) "Belum ada pesan." else sb.toString()
                }
            } catch (e: Exception) {
                binding.tvHistory.text = "Error: ${e.message}"
            }
        }
    }
}