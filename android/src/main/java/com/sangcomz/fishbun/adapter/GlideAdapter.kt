package com.sangcomz.fishbun.adapter

import android.graphics.drawable.Drawable
import android.net.Uri
import android.widget.ImageView
import com.bumptech.glide.Glide
import com.bumptech.glide.load.DataSource
import com.bumptech.glide.load.DecodeFormat
import com.bumptech.glide.load.engine.GlideException
import com.bumptech.glide.request.RequestListener
import com.bumptech.glide.request.RequestOptions
import com.bumptech.glide.request.target.Target
import com.example.multi_image_picker.R
import com.sangcomz.fishbun.bean.Media

/**
 * Created by sangcomz on 23/07/2017.
 */

class GlideAdapter {
    fun loadImage(imageView: ImageView, media: Media) {
        val options = RequestOptions().apply {
            centerCrop()
            format(DecodeFormat.PREFER_RGB_565)
        }

        Glide
                .with(imageView.context)
                .load(media.originPath)
                .listener(object: RequestListener<Drawable> {
                    override fun onLoadFailed(e: GlideException?, model: Any?, target: com.bumptech.glide.request.target.Target<Drawable>?, isFirstResource: Boolean): Boolean {
                        imageView.scaleType = ImageView.ScaleType.CENTER_INSIDE;
                        imageView.setImageResource(R.drawable.ic_photo_error_16dp)
                        return true
                    }

                    override fun onResourceReady(resource: Drawable?, model: Any?, target: Target<Drawable>?, dataSource: DataSource?, isFirstResource: Boolean): Boolean {
                        return false
                    }
                })
                .apply(options)
                .override(imageView.width, imageView.height)
                .thumbnail(0.25f)
                .into(imageView)
    }

    fun loadImage(imageView: ImageView, uri: Uri) {
        val options = RequestOptions().apply {
            centerCrop()
            format(DecodeFormat.PREFER_RGB_565)
        }
        Glide
                .with(imageView.context)
                .load(uri)
                .listener(object: RequestListener<Drawable> {
                    override fun onLoadFailed(e: GlideException?, model: Any?, target: com.bumptech.glide.request.target.Target<Drawable>?, isFirstResource: Boolean): Boolean {
                        imageView.scaleType = ImageView.ScaleType.CENTER_INSIDE;
                        imageView.setImageResource(R.drawable.ic_photo_error_16dp)
                        return true
                    }

                    override fun onResourceReady(resource: Drawable?, model: Any?, target: Target<Drawable>?, dataSource: DataSource?, isFirstResource: Boolean): Boolean {
                        return false
                    }
                })
                .apply(options)
                .override(imageView.width, imageView.height)
                .thumbnail(0.25f)
                .into(imageView)
    }

    fun loadDetailImage(imageView: ImageView, media: Media) {
        val options = RequestOptions().centerInside()
        Glide
                .with(imageView.context)
                .load(media.originPath)
                .listener(object: RequestListener<Drawable> {
                    override fun onLoadFailed(e: GlideException?, model: Any?, target: com.bumptech.glide.request.target.Target<Drawable>?, isFirstResource: Boolean): Boolean {
                        imageView.scaleType = ImageView.ScaleType.CENTER_INSIDE;
                        imageView.setImageResource(R.drawable.ic_photo_error_64dp)
                        return true
                    }

                    override fun onResourceReady(resource: Drawable?, model: Any?, target: Target<Drawable>?, dataSource: DataSource?, isFirstResource: Boolean): Boolean {
                        return false
                    }
                })
                .apply(options)
                .into(imageView)
    }

}
