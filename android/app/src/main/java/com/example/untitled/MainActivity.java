package com.example.untitled;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.Intent;
import android.os.Build;


public class MainActivity extends FlutterActivity {
    private static final String CHANNEL_NAME = "background_channel";
    private FlutterEngine flutterEngine;

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        this.flutterEngine = flutterEngine;
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL_NAME)
                .setMethodCallHandler((call, result) -> {
                    if (call.method.equals("initialize")) {
                        initializeBackgroundService();
                        result.success(null);
                    } else if (call.method.equals("start")) {
                        startBackgroundService();
                        result.success(null);
                    } else if (call.method.equals("stop")) {
                        stopBackgroundService();
                        result.success(null);
                    } else {
                        result.notImplemented();
                    }
                });
    }

    private void initializeBackgroundService() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel("hush", "Hush", NotificationManager.IMPORTANCE_HIGH);
            NotificationManager manager = getSystemService(NotificationManager.class);
            if (manager != null) {
                manager.createNotificationChannel(channel);
            }
        }
    }

    private void startBackgroundService() {
        MethodChannel methodChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "com.example/background_service");
        methodChannel.invokeMethod("startBackgroundService", null);
    }

    private void stopBackgroundService() {
        MethodChannel methodChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "com.example/background_service");
        methodChannel.invokeMethod("stopBackgroundService", null);
    }
}

