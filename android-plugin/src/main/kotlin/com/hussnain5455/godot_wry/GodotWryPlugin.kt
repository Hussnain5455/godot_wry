package com.hussnain5455.godot_wry

import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.UsedByGodot

class GodotWryPlugin(godot: Godot) : GodotPlugin(godot) {
    override fun getPluginName() = "GodotWryPlugin"
    
    @UsedByGodot
    fun getPluginVersion(): String {
        return "1.0.0"
    }
}
