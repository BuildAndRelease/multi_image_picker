package com.sangcomz.fishbun

import android.net.Uri

/**
 * Created by sangcomz on 13/05/2017.
 */
interface BaseProperty {
    fun setSelectedImages(selectedImages: ArrayList<Uri>): FishBunCreator

    fun setMaxCount(count: Int): FishBunCreator

    fun setMinCount(count: Int): FishBunCreator

    fun setMaxHeight(maxHeigth: Int): FishBunCreator

    fun setMaxWidth(maxWidth: Int): FishBunCreator

    fun setQuality(qualityOfThumb: Int): FishBunCreator

    fun setRequestCode(requestCode: Int): FishBunCreator

    fun exceptMimeType(exceptMimeTypeList: List<MimeType>): FishBunCreator

    fun startAlbum()
}