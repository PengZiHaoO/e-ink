package com.focuscard.focus_card

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.BatteryManager
import io.flutter.plugin.common.MethodChannel

/**
 * 姿态监听（T9）：TYPE_GRAVITY 判 face-down / face-up，滞回防抖，
 * 转换时经 channel 递 {posture, charging} 给 Flutter 规则机。
 * 普通传感器，零权限；app 前台才注册（onResume/onPause）。
 */
class PostureListener(
    private val context: Context,
    private val channel: MethodChannel,
) : SensorEventListener {

    private val sensorManager =
        context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val gravity = sensorManager.getDefaultSensor(Sensor.TYPE_GRAVITY)

    /** 滞回：faceUp = gz < -6m/s²，faceDown = gz > +6m/s²（中间带保持旧值） */
    private var last: String = "unknown"

    fun start() {
        gravity?.let {
            sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_UI)
        }
    }

    fun stop() = sensorManager.unregisterListener(this)

    override fun onSensorChanged(event: SensorEvent) {
        if (event.sensor.type != Sensor.TYPE_GRAVITY) return
        val gz = event.values[2]
        val now = when {
            gz < -6f -> "faceUp"
            gz > 6f -> "faceDown"
            else -> return // 滞回带：不更新
        }
        if (now == last) return
        last = now
        channel.invokeMethod("onPosture", mapOf(
            "posture" to now,
            "charging" to isCharging(),
        ))
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    private fun isCharging(): Boolean {
        val ifilter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        val battery = context.registerReceiver(null, ifilter)
        return battery?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ==
            BatteryManager.BATTERY_STATUS_CHARGING
    }
}
