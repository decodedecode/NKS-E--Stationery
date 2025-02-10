package com.example.nks;  // Keep your package name the same

import android.os.Bundle;  // Add this import
import com.google.firebase.FirebaseApp;  // Add this import for Firebase initialization
import io.flutter.embedding.android.FlutterActivity;

public class MainActivity extends FlutterActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        FirebaseApp.initializeApp(this);  // Initialize Firebase
    }
}

