package com.edusafe.app.utils

import android.content.Context
import android.os.Environment
import android.util.Log
import java.io.File

class DongleHelper(private val context: Context) {

    companion object {
        const val DONGLE_FILENAME = "edusafe_dongle.key"
        private const val TAG = "DongleHelper"
    }

    fun readDongle(): String? {
        try {
            // Cek /storage/ untuk flashdisk USB OTG
            val storageDir = File("/storage")
            if (storageDir.exists() && storageDir.isDirectory) {
                storageDir.listFiles()?.forEach { mount ->
                    val name = mount.name.lowercase()
                    if (name == "emulated" || name == "self" || name.contains("sdcard0")) return@forEach
                    val dongleFile = File(mount, DONGLE_FILENAME)
                    if (dongleFile.exists()) {
                        Log.d(TAG, "Dongle found: ${dongleFile.absolutePath}")
                        return dongleFile.readText().trim()
                    }
                }
            }
            // Fallback: Download & app files dir
            val fallbackPaths = listOf(
                File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), DONGLE_FILENAME),
                File(Environment.getExternalStorageDirectory(), DONGLE_FILENAME),
                File(context.getExternalFilesDir(null), DONGLE_FILENAME)
            )
            fallbackPaths.forEach { f ->
                if (f.exists()) {
                    Log.d(TAG, "Dongle (fallback): ${f.absolutePath}")
                    return f.readText().trim()
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error reading dongle", e)
        }
        return null
    }

    fun saveDongleToDownload(content: String): Boolean {
        return try {
            val dir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            if (!dir.exists()) dir.mkdirs()
            val file = File(dir, DONGLE_FILENAME)
            file.writeText(content)
            Log.d(TAG, "Dongle saved to: ${file.absolutePath}")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to save dongle", e)
            false
        }
    }
}