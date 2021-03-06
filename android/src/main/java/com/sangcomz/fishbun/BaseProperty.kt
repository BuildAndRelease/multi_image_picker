package com.sangcomz.fishbun

import com.sangcomz.fishbun.bean.Media

/**
 * Created by sangcomz on 13/05/2017.
 */
interface BaseProperty {
    fun setPreSelectMedia(preSelectMedia: String): FishBunCreator

    fun setPreSelectMedias(preSelectMedias: ArrayList<String>): FishBunCreator

    fun setSelectedMedias(selectedMedias: ArrayList<Media>): FishBunCreator

    fun setMaxCount(count: Int): FishBunCreator

    fun setThumb(thumb: Boolean): FishBunCreator

    fun setRequestCode(requestCode: Int): FishBunCreator

    fun setDoneButtonText(doneButtonText: String): FishBunCreator

    fun setSelectType(selectType: String): FishBunCreator

    fun startAlbum()
}