package com.sangcomz.fishbun.ui.picker;

import android.app.Activity;
import android.content.ContentResolver;
import android.database.Cursor;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Environment;
import android.provider.MediaStore;

import androidx.annotation.NonNull;

import com.sangcomz.fishbun.MimeType;
import com.sangcomz.fishbun.bean.Media;
import com.sangcomz.fishbun.ext.MimeTypeExt;
import com.sangcomz.fishbun.util.DisplayImage;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

/**
 * Created by sangc on 2015-11-05.
 */
public class PickerController implements DisplayImage.DisplayImageListener {
    private PickerActivity pickerActivity;
    private ArrayList<Media> addImagePaths = new ArrayList<>();
    private long bucketId;
    private List<MimeType> exceptMimeType;
    private List<String> specifyFolderList;
    PickerController(PickerActivity pickerActivity) {
        this.pickerActivity = pickerActivity;
    }

    public void setToolbarTitle(int total) {
        pickerActivity.updateSendBtnTitle();
    }

    protected ArrayList<Media> getAddImagePaths() {
        return addImagePaths;
    }

    public void setAddImagePaths(ArrayList<Media> addImagePaths) {
        this.addImagePaths = addImagePaths;
    }

    void displayImage(Long bucketId, List<MimeType> exceptMimeType, List<String> specifyFolderList) {
        this.bucketId = bucketId;
        this.exceptMimeType = exceptMimeType;
        this.specifyFolderList = specifyFolderList;
        DisplayImage displayImage = new DisplayImage(bucketId, exceptMimeType, specifyFolderList, pickerActivity);
        displayImage.setListener(this);
        displayImage.execute();
    }

    @Override
    public void OnDisplayImageDidSelectFinish(ArrayList medias) {
        pickerActivity.setAdapter(medias);
    }
}
