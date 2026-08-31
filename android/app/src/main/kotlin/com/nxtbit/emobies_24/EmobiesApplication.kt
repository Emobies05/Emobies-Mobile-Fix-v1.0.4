package com.nxtbit.emobies_24

import io.flutter.app.FlutterApplication
import java.io.File

class EmobiesApplication : FlutterApplication() {
    companion object {
        var crashInfo: String? = null

        fun writeCrashFile(content: String) {
            try {
                val dir = File(android.os.Environment.getExternalStorageDirectory(), "")
                val file = File(dir, "emobies_crash.txt")
                file.writeText(content)
            } catch (t: Throwable) {
                // ignore secondary failure
            }
        }
    }

    override fun onCreate() {
        // Catch crashes on any background thread too, not just main thread
        val defaultHandler = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            val info = "UNCAUGHT EXCEPTION on thread ${thread.name}:\n\n$throwable\n\n${throwable.stackTraceToString()}"
            crashInfo = info
            writeCrashFile(info)
            defaultHandler?.uncaughtException(thread, throwable)
        }

        try {
            super.onCreate()
        } catch (t: Throwable) {
            val info = "APPLICATION CRASH:\n\n$t\n\n${t.stackTraceToString()}"
            crashInfo = info
            writeCrashFile(info)
        }
    }
}
