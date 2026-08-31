package com.nxtbit.emobies_24

import android.graphics.Color
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.widget.ScrollView
import android.widget.TextView
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import java.io.PrintWriter
import java.io.StringWriter

class MainActivity: FlutterActivity() {
    private val watchdogHandler = Handler(Looper.getMainLooper())
    private var watchdogRunnable: Runnable? = null
    private var firstFrameRendered = false

    override fun onCreate(savedInstanceState: Bundle?) {
        val appCrash = EmobiesApplication.crashInfo
        if (appCrash != null) {
            showCrashScreen(appCrash)
            return
        }

        EmobiesApplication.writeCrashFile("PROBE: before super.onCreate() at ${System.currentTimeMillis()}")

        try {
            super.onCreate(savedInstanceState)
        } catch (t: Throwable) {
            val sw = StringWriter()
            t.printStackTrace(PrintWriter(sw))
            showCrashScreen("ACTIVITY CRASH:\n\n$t\n\n$sw")
            return
        }

        EmobiesApplication.writeCrashFile("PROBE: after super.onCreate() at ${System.currentTimeMillis()}")

        // Watchdog: if Flutter hasn't rendered anything in 6 seconds, show diagnostic screen.
        // Cancelled automatically in onFlutterUiDisplayed() once the first frame is on screen.
        watchdogRunnable = Runnable {
            if (!isFinishing && !firstFrameRendered) {
                val msg = "WATCHDOG TIMEOUT\n\n" +
                    "Flutter engine did not render within 6 seconds.\n" +
                    "This usually means main() threw before runApp(), " +
                    "or the engine failed to attach.\n\n" +
                    "Check: Supabase init, dart-define values, or a native plugin crash.\n\n" +
                    "flutterEngine attached: ${flutterEngine != null}"
                EmobiesApplication.writeCrashFile(msg)
                showCrashScreen(msg)
            }
        }
        watchdogHandler.postDelayed(watchdogRunnable!!, 1000)
    }

    override fun onFlutterUiDisplayed() {
        super.onFlutterUiDisplayed()
        firstFrameRendered = true
        watchdogRunnable?.let { watchdogHandler.removeCallbacks(it) }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        try {
            super.configureFlutterEngine(flutterEngine)
        } catch (t: Throwable) {
            val sw = StringWriter()
            t.printStackTrace(PrintWriter(sw))
            showCrashScreen("ENGINE CONFIG CRASH:\n\n$t\n\n$sw")
        }
    }

    override fun onDestroy() {
        watchdogRunnable?.let { watchdogHandler.removeCallbacks(it) }
        super.onDestroy()
    }

    private fun showCrashScreen(message: String) {
        val tv = TextView(this).apply {
            text = message
            setTextColor(Color.RED)
            setBackgroundColor(Color.WHITE)
            textSize = 10f
            setPadding(24, 24, 24, 24)
        }
        val scroll = ScrollView(this)
        scroll.addView(tv)
        setContentView(scroll)
    }
}
