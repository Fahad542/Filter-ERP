package com.filter_erp.app

import android.content.ClipData
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.net.URLEncoder

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.filter_erp.app/whatsapp_share",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "sharePdf" -> {
                    val path = call.argument<String>("path")
                    val phone = call.argument<String>("phone")
                    if (path.isNullOrBlank() || phone.isNullOrBlank()) {
                        result.error("bad_args", "path and phone required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        result.success(sharePdfToWhatsApp(path, phone))
                    } catch (e: Exception) {
                        result.error("share_failed", e.message, null)
                    }
                }
                "openChat" -> {
                    val phone = call.argument<String>("phone")
                    val text = call.argument<String>("text") ?: ""
                    val business = call.argument<Boolean>("business") == true
                    if (phone.isNullOrBlank()) {
                        result.error("bad_args", "phone required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        result.success(openWhatsAppChat(phone, text, business))
                    } catch (e: Exception) {
                        result.error("open_failed", e.message, null)
                    }
                }
                "isAppInstalled" -> {
                    val business = call.argument<Boolean>("business") == true
                    result.success(isWhatsAppInstalled(business))
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun whatsAppPackage(business: Boolean): String =
        if (business) "com.whatsapp.w4b" else "com.whatsapp"

    private fun isWhatsAppInstalled(business: Boolean): Boolean {
        return try {
            packageManager.getPackageInfo(whatsAppPackage(business), 0)
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
    }

    /**
     * Opens the selected WhatsApp client only (personal vs Business).
     * Does not fall back to the other app — caller shows an error if false.
     */
    private fun openWhatsAppChat(phone: String, text: String, business: Boolean): Boolean {
        val pkg = whatsAppPackage(business)
        if (!isWhatsAppInstalled(business)) return false

        val encoded = URLEncoder.encode(text, "UTF-8").replace("+", "%20")
        val candidates = listOf(
            Uri.parse("https://api.whatsapp.com/send?phone=$phone&text=$encoded"),
            Uri.parse("https://wa.me/$phone?text=$encoded"),
            Uri.parse("whatsapp://send?phone=$phone&text=$encoded"),
        )

        for (uri in candidates) {
            val intent = Intent(Intent.ACTION_VIEW, uri).apply {
                setPackage(pkg)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                return true
            }
        }
        return false
    }

    private fun sharePdfToWhatsApp(path: String, phone: String): Boolean {
        val file = File(path)
        if (!file.exists()) {
            throw IllegalArgumentException("PDF file is missing")
        }
        val uri = FileProvider.getUriForFile(
            this,
            "$packageName.whatsappshare",
            file,
        )
        val jid = "$phone@s.whatsapp.net"
        val packages = listOf("com.whatsapp", "com.whatsapp.w4b")
        for (pkg in packages) {
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = "application/pdf"
                setPackage(pkg)
                putExtra(Intent.EXTRA_STREAM, uri)
                putExtra("jid", jid)
                clipData = ClipData.newRawUri("invoice", uri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            if (intent.resolveActivity(packageManager) == null) continue
            grantUriPermission(pkg, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
            startActivity(intent)
            return true
        }
        return false
    }
}
