package com.sangcomz.fishbun

import android.content.Context
import android.graphics.Color
import android.graphics.drawable.Drawable
import com.example.multi_image_picker.R
import com.sangcomz.fishbun.adapter.GlideAdapter
import com.sangcomz.fishbun.bean.Media
import java.util.ArrayList

/**
 * Created by seokwon.jeong on 04/01/2018.
 */
class Fishton {
    var imageAdapter: GlideAdapter? = null
    var pickerMedias: List<Media> = ArrayList();

    var quality : Int = 1
    var maxHeight : Int = 300
    var maxWidth : Int = 300
    var maxCount: Int = 0
    var minCount: Int = 0
    var exceptMimeTypeList = emptyList<MimeType>()
    var selectedMedias = ArrayList<Media>()
    var preSelectedMedias = ArrayList<String>()
    var isThumb : Boolean = true;

    var messageNothingSelected: String? = null
    var messageLimitReached: String? = null
    var titleAlbumAllView: String? = null
    var titleActionBar: String? = null

    var drawableHomeAsUpIndicator: Drawable? = null
    var drawableDoneButton: Drawable? = null
    var drawableThumbButton: Drawable? = null
    var drawableOriginButton: Drawable? = null
    var drawableAllDoneButton: Drawable? = null

    var colorSelectCircleStroke: Int = 0
    var colorDeSelectCircleStroke: Int = 0

    init {
        init()
    }

    fun refresh() = init()

    private fun init() {
        imageAdapter = null

        //BaseParams
        maxCount = 10
        quality = 1
        minCount = 1
        exceptMimeTypeList = emptyList()
        selectedMedias = ArrayList()
        preSelectedMedias = ArrayList()


        drawableHomeAsUpIndicator = null
        drawableDoneButton = null
        drawableAllDoneButton = null
        drawableOriginButton = null
        drawableThumbButton = null

        colorSelectCircleStroke = Color.parseColor("#00BA5A")
        colorDeSelectCircleStroke = Color.parseColor("#FFFFFF")
    }

    fun setDefaultMessage(context: Context) {
        messageNothingSelected = messageNothingSelected ?: context.getString(R.string.msg_no_selected)
        messageLimitReached = messageLimitReached ?: context.getString(R.string.msg_full_image)
        titleAlbumAllView = titleAlbumAllView ?: context.getString(R.string.str_all_view)
        titleActionBar = titleActionBar ?: context.getString(R.string.album)
    }

    fun mediaIndexOfFirstPreSelectMedia(): Int {
        if (preSelectedMedias.size > 0) {
            for (i in 0..pickerMedias.size) {
                if (pickerMedias[i].identifier.equals(preSelectedMedias[0])) {
                    return i;
                }
            }
        }
        return 0
    }

    private object FishtonHolder {
        val INSTANCE = Fishton()
    }

    companion object {
        @JvmStatic
        fun getInstance() = FishtonHolder.INSTANCE
    }
}