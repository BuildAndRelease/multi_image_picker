package com.sangcomz.fishbun.adapter.image

import android.net.Uri
import android.widget.ImageView
import com.sangcomz.fishbun.bean.Media

/**
 * Created by sangcomz on 23/07/2017.
 */

interface ImageAdapter {
    fun loadImage(target: ImageView, media: Media)
    fun loadDetailImage(target: ImageView, media: Media)
    fun loadImage(target: ImageView, uri: Uri)
    fun loadDetailImage(target: ImageView, uri: Uri)
}
