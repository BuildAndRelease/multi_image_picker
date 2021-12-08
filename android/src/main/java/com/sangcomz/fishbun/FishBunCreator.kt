package com.sangcomz.fishbun

import android.content.Intent
import android.graphics.drawable.Drawable
import com.sangcomz.fishbun.bean.Album
import com.sangcomz.fishbun.bean.Media
import com.sangcomz.fishbun.ui.detail.DetailActivity
import com.sangcomz.fishbun.ui.picker.PickerActivity
import com.sangcomz.fishbun.util.Define

/**
 * Created by sangcomz on 17/05/2017.
 */
class FishBunCreator(private val fishBun: FishBun, private val fishton: Fishton) {
    private var requestCode = 27

    fun setThumb(thumb: Boolean): FishBunCreator = this.apply {
        fishton.isThumb = thumb;
    }

    fun setHiddenThumb(hiddenThumb: Boolean): FishBunCreator = this.apply {
        fishton.hiddenThumb = hiddenThumb;
    }

    fun setPreSelectMedias(preSelectMedias: ArrayList<String>): FishBunCreator = this.apply {
        fishton.preSelectedMedias = preSelectMedias
    }

    fun setPreSelectMedia(preSelectMedia: String): FishBunCreator = this.apply {
        fishton.preSelectedMedia = preSelectMedia
    }

    fun setMaxCount(count: Int): FishBunCreator = this.apply {
        fishton.maxCount = if (count <= 0) 1 else count
    }

    fun setRequestCode(requestCode: Int): FishBunCreator = this.apply {
        this.requestCode = requestCode
    }

    fun textOnNothingSelected(message: String?): FishBunCreator = this.apply {
        fishton.messageNothingSelected = message
    }

    fun textOnImagesSelectionLimitReached(message: String?): FishBunCreator = this.apply {
        fishton.messageLimitReached = message
    }

    fun setAllViewTitle(allViewTitle: String?): FishBunCreator = this.apply {
        fishton.titleAlbumAllView = allViewTitle
    }

    fun setActionBarTitle(actionBarTitle: String?): FishBunCreator = this.apply {
        fishton.titleActionBar = actionBarTitle
    }

     fun setHomeAsUpIndicatorDrawable(icon: Drawable?): FishBunCreator = this.apply {
        fishton.drawableHomeAsUpIndicator = icon
    }

    fun setDoneButtonDrawable(icon: Drawable?): FishBunCreator = this.apply {
        fishton.drawableDoneButton = icon
    }

    fun setAllDoneButtonDrawable(icon: Drawable?): FishBunCreator = this.apply {
        fishton.drawableAllDoneButton = icon
    }

    fun setSelectType(selectType: String) = this.apply {
        fishton.selectType = selectType
    }

    fun setShowMediaType(showMediaType : String) = this.apply {
        fishton.showMediaType = showMediaType
    }

    fun setDoneButtonText(doneButtonText: String) = this.apply {
        fishton.doneButtonText = doneButtonText
    }

    fun setSelectCircleStrokeColor(strokeColor: Int): FishBunCreator = this.apply {
        fishton.colorSelectCircleStroke = strokeColor
    }

    fun startAlbum() {
        val fishBunContext = fishBun.fishBunContext
        val context = fishBunContext.getContext()

        if (fishton.imageAdapter == null) throw NullPointerException("ImageAdapter is Null")

        with(fishton) {
            setDefaultMessage(context)
        }

        if (fishton.preSelectedMedia.isNotEmpty()) {
            val i = Intent(context, DetailActivity::class.java)
            fishBunContext.startActivityForResult(i, requestCode)
        }else{
            val intent: Intent = Intent(context, PickerActivity::class.java).apply {
                putExtra(Define.BUNDLE_NAME.ALBUM.name, Album(0, fishton.titleAlbumAllView, null, 0))
                putExtra(Define.BUNDLE_NAME.POSITION.name, 0)
            }
            fishBunContext.startActivityForResult(intent, requestCode)
        }

    }

}

