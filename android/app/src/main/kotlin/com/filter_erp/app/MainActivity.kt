package com.filter_erp.app

import android.app.ActivityOptions
import android.app.PendingIntent
import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
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
                    val caption = call.argument<String>("caption") ?: "Here is your invoice"
                    val business = call.argument<Boolean>("business") == true
                    if (path.isNullOrBlank() || phone.isNullOrBlank()) {
                        result.error("bad_args", "path and phone required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        result.success(sharePdfToWhatsApp(path, phone, caption, business))
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
        // Click-to-chat opens unsaved numbers. Package is pinned so the browser page does not show.
        val intent = Intent(
            Intent.ACTION_VIEW,
            Uri.parse("https://wa.me/$phone?text=$encoded"),
        ).apply {
            setPackage(pkg)
            addCategory(Intent.CATEGORY_DEFAULT)
            addCategory(Intent.CATEGORY_BROWSABLE)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        return try {
            startActivity(intent)
            true
        } catch (_: ActivityNotFoundException) {
            false
        }
    }

    private fun sharePdfToWhatsApp(
        path: String,
        phone: String,
        caption: String,
        business: Boolean,
    ): Boolean {
        val file = File(path)
        if (!file.exists()) {
            throw IllegalArgumentException("PDF file is missing")
        }
        val pkg = whatsAppPackage(business)
        if (!isWhatsAppInstalled(business)) return false
        val uri = FileProvider.getUriForFile(
            this,
            "$packageName.whatsappshare",
            file,
        )
        val digits = phone.filter { it.isDigit() }
        if (digits.isEmpty()) return false
        val jid = "$digits@s.whatsapp.net"
        val message = caption.trim().ifEmpty { "Here is your invoice" }
        grantUriPermission(pkg, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)

        // Click-to-chat opens unsaved numbers and prefills the caption.
        // The PDF is sent on a second intent once that chat exists. A plain
        // delayed startActivity is blocked once WhatsApp is in front, so the
        // share is a PendingIntent created while this app is still foreground.
        val openedChat = openUnsavedChat(pkg, digits, message)
        val share = pdfShareIntent(pkg, uri, jid, message)
        if (!openedChat) {
            return try {
                startActivity(share)
                true
            } catch (_: ActivityNotFoundException) {
                false
            }
        }
        schedulePdfShare(share)
        return true
    }

    private fun schedulePdfShare(share: Intent) {
        val options = ActivityOptions.makeBasic()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            options.setPendingIntentBackgroundActivityStartMode(
                ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED,
            )
        }
        val pending = PendingIntent.getActivity(
            this,
            41,
            share,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            options.toBundle(),
        )
        Handler(Looper.getMainLooper()).postDelayed({
            try {
                pending.send()
            } catch (_: Exception) {
            }
        }, 900)
    }

    private fun openUnsavedChat(pkg: String, digits: String, caption: String): Boolean {
        val encoded = URLEncoder.encode(caption, "UTF-8").replace("+", "%20")
        val targets = listOf(
            "https://wa.me/$digits?text=$encoded",
            "https://api.whatsapp.com/send?phone=$digits&text=$encoded",
            "whatsapp://send?phone=$digits&text=$encoded",
        )
        for (target in targets) {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(target)).apply {
                setPackage(pkg)
                addCategory(Intent.CATEGORY_DEFAULT)
                addCategory(Intent.CATEGORY_BROWSABLE)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            try {
                startActivity(intent)
                return true
            } catch (_: ActivityNotFoundException) {
            } catch (_: SecurityException) {
            }
        }
        return false
    }

    private fun pdfShareIntent(pkg: String, uri: Uri, jid: String, caption: String): Intent {
        return Intent(Intent.ACTION_SEND).apply {
            type = "application/pdf"
            setPackage(pkg)
            putExtra(Intent.EXTRA_STREAM, uri)
            putExtra(Intent.EXTRA_TEXT, caption)
            putExtra("jid", jid)
            clipData = ClipData.newRawUri("invoice", uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
    }
}
