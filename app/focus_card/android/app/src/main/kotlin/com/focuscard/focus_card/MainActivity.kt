package com.focuscard.focus_card

import android.content.Intent
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * 认领意图路由（配合 Manifest 的 MIME + NFC-V tech filter）：
 * 系统 dispatch 被我们认领后，把 {action, uid} 递给 Flutter 侧路由：
 * 未配对→配对流（真实 UID）；已配对同源→屏2 写入；异源→忽略。
 * 冷启动（app 未运行被标签唤起）与热启动（onNewIntent）都覆盖。
 */
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var pending: Intent? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        // 热启动排队意图 + 冷启动 launching intent
        pending?.let { send(it); pending = null }
        intent?.let { if (isNfcIntent(it)) send(it) }
    }

    override fun onNewIntent(intent: Intent) {
        @Suppress("DEPRECATION")
        super.onNewIntent(intent)
        if (isNfcIntent(intent)) {
            if (channel == null) pending = intent else send(intent)
        }
    }

    private fun isNfcIntent(i: Intent): Boolean =
        i.action == NfcAdapter.ACTION_NDEF_DISCOVERED ||
            i.action == NfcAdapter.ACTION_TECH_DISCOVERED

    private fun send(i: Intent) {
        val tag: Tag? = i.getParcelableExtra(NfcAdapter.EXTRA_TAG)
        val uid = tag?.id?.joinToString("") { String.format("%02X", it) } ?: ""
        channel?.invokeMethod("onCardIntent", mapOf(
            "action" to (i.action ?: ""),
            "uid" to uid,
        ))
    }

    companion object {
        private const val CHANNEL = "focus_card/nfc_intent"
    }
}
