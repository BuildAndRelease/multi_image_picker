@file:JvmName("UiUtil")

package com.sangcomz.fishbun.util

import android.content.Context
import android.content.res.Configuration
import android.content.res.Resources
import android.graphics.Bitmap
import android.graphics.drawable.BitmapDrawable
import androidx.annotation.DimenRes

/**
 * Created by sangc on 2015-11-20.
 */

fun Context.isLandscape() = resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE

inline fun <T : Context> T.isLandscape(block: () -> Unit) = if (isLandscape()) block() else Unit

fun Context.getDimension(@DimenRes id: Int) = resources.getDimension(id).toInt()

fun Resources.getDrawableFromBitmap(bitmap: Bitmap?) = bitmap?.let {
    BitmapDrawable(this, it)
}
