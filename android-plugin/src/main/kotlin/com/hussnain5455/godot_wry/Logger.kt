package com.hussnain5455.godot_wry

import android.util.Log

object Logger {
    fun debug(tag: String, msg: String) {
        Log.d(tag, msg)
    }

    fun debug(msg: String) {
        Log.d("GodotWry", msg)
    }

    fun warn(tag: String, msg: String) {
        Log.w(tag, msg)
    }

    fun warn(msg: String) {
        Log.w("GodotWry", msg)
    }

    fun info(tag: String, msg: String) {
        Log.i(tag, msg)
    }

    fun info(msg: String) {
        Log.i("GodotWry", msg)
    }

    fun error(tag: String, msg: String, throwable: Throwable?) {
        Log.e(tag, msg, throwable)
    }

    fun error(tag: String, msg: String) {
        Log.e(tag, msg)
    }

    fun error(msg: String) {
        Log.e("GodotWry", msg)
    }

    fun tags(tag: String): String {
        return "GodotWry-$tag"
    }
}
