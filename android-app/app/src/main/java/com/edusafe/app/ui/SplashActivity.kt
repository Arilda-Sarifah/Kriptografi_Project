package com.edusafe.app.ui

import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.appcompat.app.AppCompatActivity
import com.edusafe.app.databinding.ActivitySplashBinding
import com.edusafe.app.utils.TokenManager

class SplashActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val binding = ActivitySplashBinding.inflate(layoutInflater)
        setContentView(binding.root)

        Handler(Looper.getMainLooper()).postDelayed({
            val token = TokenManager(this).getToken()
            val next = if (token != null) DashboardActivity::class.java else LoginActivity::class.java
            startActivity(Intent(this, next))
            finish()
        }, 1500)
    }
}