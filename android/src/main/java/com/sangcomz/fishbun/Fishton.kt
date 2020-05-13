package com.sangcomz.fishbun

import android.content.Context
import android.graphics.Color
import android.graphics.drawable.Drawable
import android.net.Uri
import com.example.multi_image_picker.R
import com.sangcomz.fishbun.adapter.image.ImageAdapter
import com.sangcomz.fishbun.util.getDimension
import java.util.ArrayList

/**
 * Created by seokwon.jeong on 04/01/2018.
 */
class Fishton {
    var imageAdapter: ImageAdapter? = null
    var pickerImages: List<Uri>? = null

    var quality : Int = 1
    var maxHeight : Int = 300
    var maxWidth : Int = 300
    var maxCount: Int = 0
    var minCount: Int = 0
    var exceptMimeTypeList = emptyList<MimeType>()
    var selectedImages = ArrayList<Uri>()

    var specifyFolderList = emptyList<String>()
    var photoSpanCount: Int = 0
    var albumPortraitSpanCount: Int = 0
    var albumLandscapeSpanCount: Int = 0

    var isButton: Boolean = false
    var isThumb:Boolean = true

    var colorActionBar: Int = 0
    var colorActionBarTitle: Int = 0
    var colorStatusBar: Int = 0

    var isStatusBarLight: Boolean = false
    var isCamera: Boolean = false

    var albumThumbnailSize: Int = 0

    var messageNothingSelected: String? = null
    var messageLimitReached: String? = null
    var titleAlbumAllView: String? = null
    var titleActionBar: String? = null

    var drawableHomeAsUpIndicator: Drawable? = null
    var drawableDoneButton: Drawable? = null
    var drawableThumbButton: Drawable? = null
    var drawableOriginButton: Drawable? = null
    var drawableAllDoneButton: Drawable? = null
    var isUseAllDoneButton: Boolean = false

    var strDoneMenu: String? = null
    var strAllDoneMenu: String? = null

    var colorTextMenu: Int = 0

    var isUseDetailView: Boolean = false

    var colorSelectCircleStroke: Int = 0
    var colorDeSelectCircleStroke: Int = 0

    init {
        init()
    }

    fun refresh() = init()

    private fun init() {
        //Adapter
        imageAdapter = null

        //BaseParams
        maxCount = 10
        quality = 1
        minCount = 1
        exceptMimeTypeList = emptyList()
        selectedImages = ArrayList()

        //CustomizationParams
        specifyFolderList = emptyList()
        photoSpanCount = 3
        albumPortraitSpanCount = 1
        albumLandscapeSpanCount = 2

        isButton = false
        isThumb = true;

        colorActionBar = Color.parseColor("#2E2E2E")
        colorActionBarTitle = Color.parseColor("#FFFFFF")
        colorStatusBar = Color.parseColor("#2E2E2E")

        isStatusBarLight = false
        isCamera = false

        albumThumbnailSize = Integer.MAX_VALUE

        drawableHomeAsUpIndicator = null
        drawableDoneButton = null
        drawableAllDoneButton = null
        drawableOriginButton = null
        drawableThumbButton = null

        strDoneMenu = null
        strAllDoneMenu = null

        colorTextMenu = Integer.MAX_VALUE

        isUseAllDoneButton = false
        isUseDetailView = true

        colorSelectCircleStroke = Color.parseColor("#00BA5A")
        colorDeSelectCircleStroke = Color.parseColor("#FFFFFF")
    }

    fun setDefaultMessage(context: Context) {
        messageNothingSelected =
            messageNothingSelected ?: context.getString(R.string.msg_no_selected)

        messageLimitReached =
            messageLimitReached ?: context.getString(R.string.msg_full_image)

        titleAlbumAllView =
            titleAlbumAllView ?: context.getString(R.string.str_all_view)

        titleActionBar =
            titleActionBar ?: context.getString(R.string.album)
    }

    fun setMenuTextColor() {
        if (drawableDoneButton != null
            || drawableAllDoneButton != null
            || strDoneMenu == null
            || colorTextMenu != Integer.MAX_VALUE)
            return

        colorTextMenu = if (isStatusBarLight) Color.BLACK else colorTextMenu
    }

    fun setDefaultDimen(context: Context) {
        albumThumbnailSize =
            if (albumThumbnailSize == Int.MAX_VALUE) {
                context.getDimension(R.dimen.album_thum_size)
            } else {
                albumThumbnailSize
            }
    }

    private object FishtonHolder {
        val INSTANCE = Fishton()
    }

    companion object {
        @JvmStatic
        fun getInstance() = FishtonHolder.INSTANCE
    }
}