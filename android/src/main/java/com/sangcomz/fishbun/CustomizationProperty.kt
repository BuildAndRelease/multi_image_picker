package com.sangcomz.fishbun

import android.graphics.drawable.Drawable

/**
 * Created by sangcomz on 13/05/2017.
 */
interface CustomizationProperty {

    fun textOnNothingSelected(message: String?): FishBunCreator

    fun textOnImagesSelectionLimitReached(message: String?): FishBunCreator

    fun setAllViewTitle(allViewTitle: String?): FishBunCreator

    fun setActionBarTitle(actionBarTitle: String?): FishBunCreator

    fun setHomeAsUpIndicatorDrawable(icon: Drawable?): FishBunCreator

    fun setDoneButtonDrawable(icon: Drawable?): FishBunCreator

    fun setAllDoneButtonDrawable(icon: Drawable?): FishBunCreator

    fun setSelectCircleStrokeColor(strokeColor: Int): FishBunCreator

}