#![cfg(target_os = "android")]

use jni::objects::JObject;
use jni::JNIEnv;

wry::android_binding! { com_hussnain5455, godot_wry }

#[no_mangle]
pub unsafe extern "system" fn Java_com_hussnain5455_godot_1wry_WryActivity_initializeWry(
    mut env: JNIEnv,
    activity: JObject,
) {
    let jvm = env.get_java_vm().expect("Failed to get JavaVM");
    let vm_ptr = jvm.get_java_vm_pointer();
    let activity_raw = activity.as_raw();
    
    ndk_context::initialize_android_context(vm_ptr as *mut std::ffi::c_void, activity_raw as *mut std::ffi::c_void);
    
    let looper = wry::prelude::ndk::looper::ThreadLooper::for_thread()
        .unwrap_or_else(|| wry::prelude::ndk::looper::ThreadLooper::prepare());
        
    let activity_ref = env.new_global_ref(&activity).expect("Failed to create GlobalRef");
    
    wry::android_setup(
        "com/hussnain5455/godot_wry",
        env,
        &looper,
        activity_ref,
    );
}
