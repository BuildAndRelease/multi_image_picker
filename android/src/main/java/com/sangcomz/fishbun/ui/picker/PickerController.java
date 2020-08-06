package com.sangcomz.fishbun.ui.picker;

import android.content.Intent;

import com.sangcomz.fishbun.MimeType;
import com.sangcomz.fishbun.bean.Media;
import com.sangcomz.fishbun.util.Define;
import com.sangcomz.fishbun.ui.detail.DetailActivity;
import com.sangcomz.fishbun.util.DisplayImage;

import java.util.ArrayList;
import java.util.List;

/**
 * Created by sangc on 2015-11-05.
 */
public class PickerController implements DisplayImage.DisplayImageListener {
    private PickerActivity pickerActivity;
    private ArrayList<Media> addImagePaths = new ArrayList<>();
    PickerController(PickerActivity pickerActivity) {
        this.pickerActivity = pickerActivity;
    }

    public void onSelectCountDidChange() {
        pickerActivity.updateSendBtnTitle();
    }

    public void onSelectItem(int selectIndex) {
        Intent i = new Intent(pickerActivity, DetailActivity.class);
        i.putExtra(Define.BUNDLE_NAME.POSITION.name(), selectIndex);
        pickerActivity.startActivityForResult(i, Define.ENTER_DETAIL_RESULT_CODE);
    }

    protected ArrayList<Media> getAddImagePaths() {
        return addImagePaths;
    }

    public void setAddImagePaths(ArrayList<Media> addImagePaths) {
        this.addImagePaths = addImagePaths;
    }

    void displayImage(Long bucketId, List<MimeType> exceptMimeType) {
        DisplayImage displayImage = new DisplayImage(bucketId, null, exceptMimeType, pickerActivity);
        displayImage.setInvertedPhotos(true);
        displayImage.setListener(this);
        displayImage.execute();
    }

    @Override
    public void OnDisplayImageDidSelectFinish(ArrayList medias) {
        pickerActivity.updatePhotoAlbumMedia(medias);
    }
}
