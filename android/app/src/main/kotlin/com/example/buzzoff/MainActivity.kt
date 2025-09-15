package com.example.buzzoff

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.animation.AnimatorSet
import android.animation.ObjectAnimator
import android.os.Build
import android.os.Bundle
import android.view.animation.AccelerateDecelerateInterpolator
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        val splashScreen = installSplashScreen()
        super.onCreate(savedInstanceState)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            splashScreen.setOnExitAnimationListener { splashScreenViewProvider ->
                val view = splashScreenViewProvider.view

                val fadeOut = ObjectAnimator.ofFloat(view, "alpha", 1f, 0f).apply {
                    duration = 250L
                    interpolator = AccelerateDecelerateInterpolator()
                }
                val scaleX = ObjectAnimator.ofFloat(view, "scaleX", 1f, 0.94f).apply {
                    duration = 300L
                    interpolator = AccelerateDecelerateInterpolator()
                }
                val scaleY = ObjectAnimator.ofFloat(view, "scaleY", 1f, 0.94f).apply {
                    duration = 300L
                    interpolator = AccelerateDecelerateInterpolator()
                }

                AnimatorSet().apply {
                    playTogether(fadeOut, scaleX, scaleY)
                    addListener(object : AnimatorListenerAdapter() {
                        override fun onAnimationEnd(animation: Animator) {
                            splashScreenViewProvider.remove()
                        }
                    })
                    start()
                }
            }
        }
    }
}
