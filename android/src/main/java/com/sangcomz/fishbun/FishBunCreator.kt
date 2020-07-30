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
class FishBunCreator(private val fishBun: FishBun, private val fishton: Fishton) : BaseProperty, CustomizationProperty {
    private var requestCode = 27

    override fun setThumb(thumb: Boolean): FishBunCreator = this.apply {
        fishton.isThumb = thumb;
    }

    override fun setPreSelectMedias(preSelectMedias: ArrayList<String>): FishBunCreator = this.apply {
        fishton.preSelectedMedias = preSelectMedias
    }

    override fun setPreSelectMedia(preSelectMedia: String): FishBunCreator = this.apply {
        fishton.preSelectedMedia = preSelectMedia
    }

    override fun setSelectedMedias(selectedMedias: ArrayList<Media>): FishBunCreator = this.apply {
        fishton.selectedMedias = selectedMedias
    }

    override fun setMaxHeight(maxHeigth: Int): FishBunCreator = this.apply {
        fishton.maxHeight = if (maxHeigth < 0) 300 else maxHeigth
    }

    override fun setMaxWidth(maxWidth: Int): FishBunCreator = this.apply {
        fishton.maxWidth = if (maxWidth < 0) 300 else maxWidth
    }

    override fun setMaxCount(count: Int): FishBunCreator = this.apply {
        fishton.maxCount = if (count <= 0) 1 else count
    }

    override fun setMinCount(count: Int): FishBunCreator = this.apply {
        fishton.minCount = if (count <= 0) 1 else count
    }

    override fun setRequestCode(requestCode: Int): FishBunCreator = this.apply {
        this.requestCode = requestCode
    }

    override fun textOnNothingSelected(message: String?): FishBunCreator = this.apply {
        fishton.messageNothingSelected = message
    }

    override fun textOnImagesSelectionLimitReached(message: String?): FishBunCreator = this.apply {
        fishton.messageLimitReached = message
    }

    override fun setAllViewTitle(allViewTitle: String?): FishBunCreator = this.apply {
        fishton.titleAlbumAllView = allViewTitle
    }

    override fun setActionBarTitle(actionBarTitle: String?): FishBunCreator = this.apply {
        fishton.titleActionBar = actionBarTitle
    }

    override fun setHomeAsUpIndicatorDrawable(icon: Drawable?): FishBunCreator = this.apply {
        fishton.drawableHomeAsUpIndicator = icon
    }

    override fun setDoneButtonDrawable(icon: Drawable?): FishBunCreator = this.apply {
        fishton.drawableDoneButton = icon
    }

    override fun setAllDoneButtonDrawable(icon: Drawable?): FishBunCreator = this.apply {
        fishton.drawableAllDoneButton = icon
    }

    override fun exceptMimeType(exceptMimeTypeList: List<MimeType>) = this.apply {
        fishton.exceptMimeTypeList = exceptMimeTypeList
    }

    override fun setSelectCircleStrokeColor(strokeColor: Int): FishBunCreator = this.apply {
        fishton.colorSelectCircleStroke = strokeColor
    }

    override fun startAlbum() {
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

