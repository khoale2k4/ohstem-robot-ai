package com.ohstem.robot_ai_temp

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "ai_model_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "initializeModel" -> {
                    val modelPath = call.argument<String>("modelPath")
                    val inputSize = call.argument<Int>("inputSize")
                    val confidence = call.argument<Double>("confidenceThreshold")
                    val iou = call.argument<Double>("iouThreshold")

                    // TODO: Xử lý khởi tạo mô hình tại đây nếu cần
                    println("Native model initialized: $modelPath, inputSize=$inputSize, conf=$confidence, iou=$iou")

                    result.success(true)
                }

                "processImage" -> {
                    // TODO: Đây là nơi xử lý ảnh native (nếu bạn truyền ảnh base64, byte[]...)
                    println("Received image processing request from Flutter")

                    // Giả sử bạn trả kết quả nhận diện là list object rỗng
                    val dummyResult = listOf<Map<String, Any>>()
                    result.success(dummyResult)
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
