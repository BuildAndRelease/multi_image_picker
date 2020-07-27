package com.sangcomz.fishbun.adapter

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.RelativeLayout
import android.widget.VideoView
import androidx.viewpager.widget.PagerAdapter
import androidx.viewpager.widget.ViewPager
import com.example.multi_image_picker.R
import com.sangcomz.fishbun.Fishton
import com.sangcomz.fishbun.bean.Media
import kotlinx.android.synthetic.main.detail_item.view.*


/**
 * Created by sangcomz on 15/06/2017.
 */

class DetailViewPagerAdapter(private val inflater: LayoutInflater, private val medias: List<Media>) : PagerAdapter() {
    private val fishton = Fishton.getInstance()
    private var actionListener: OnVideoPlayActionListener? = null

    fun setActionListener(actionListener: OnVideoPlayActionListener) {
        this.actionListener = actionListener
    }
    interface OnVideoPlayActionListener {
        fun onVideoDidPlayer(videoView : VideoView)
    }

    override fun instantiateItem(container: ViewGroup, position: Int): Any {
        val itemView = inflater.inflate(R.layout.detail_item, container, false)
        container.addView(itemView)

        val mVideoView = itemView.video_play_view
        val playBtn = itemView.video_play_btn
        val imageView = itemView.img_detail_image
        val media = medias[position]
        if (media.fileType.contains("video")) {
            imageView.visibility = View.INVISIBLE
            playBtn.visibility = View.VISIBLE
            mVideoView.visibility = View.VISIBLE
            playBtn.setOnClickListener {
                playBtn.visibility = View.INVISIBLE
                if (!mVideoView!!.isPlaying) {
                    mVideoView.start()
                    mVideoView.requestFocus()
                    actionListener?.onVideoDidPlayer(mVideoView)
                }
            }
            mVideoView.setOnClickListener {
                if (mVideoView.isPlaying) {
                    mVideoView.pause()
                }
                playBtn.visibility = View.VISIBLE
            }
            try {
                mVideoView.setVideoPath(media.originPath)
                mVideoView.seekTo(100)
            } catch (e: java.lang.Exception) {
                e.printStackTrace()
            }
        }else {
            imageView!!.scale = 1.0f
            imageView!!.maximumScale = 10.0f
            imageView!!.visibility = View.VISIBLE
            playBtn!!.visibility = View.INVISIBLE
            mVideoView!!.visibility = View.INVISIBLE
            fishton.imageAdapter?.loadDetailImage(imageView, medias[position])
        }

        return itemView
    }

    override fun getCount(): Int = medias.size

    override fun destroyItem(container: ViewGroup, position: Int, targetObject: Any) {
        if (container is ViewPager) {
            container.removeView(targetObject as RelativeLayout)
        }
    }

    override fun isViewFromObject(view: View, targetObject: Any): Boolean {
        return view.equals(targetObject)
    }
}