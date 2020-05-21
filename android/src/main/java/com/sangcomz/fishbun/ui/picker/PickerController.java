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

import java.util.ArrayList;
import java.util.List;

/**
 * Created by sangc on 2015-11-05.
 */
public class PickerController {
    private PickerActivity pickerActivity;
    private ArrayList<Media> addImagePaths = new ArrayList<>();
    private ContentResolver resolver;

    PickerController(PickerActivity pickerActivity) {
        this.pickerActivity = pickerActivity;
        resolver = pickerActivity.getContentResolver();
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
        new DisplayImage(bucketId, exceptMimeType, specifyFolderList).execute();
    }

    private class DisplayImage extends AsyncTask<Void, Void, List<Media>> {
        private Long bucketId;
        List<MimeType> exceptMimeType;
        List<String> specifyFolderList;

        DisplayImage(Long bucketId, List<MimeType> exceptMimeType, List<String> specifyFolderList) {
            this.bucketId = bucketId;
            this.exceptMimeType = exceptMimeType;
            this.specifyFolderList = specifyFolderList;
        }

        @Override
        protected List<Media> doInBackground(Void... params) {
            List<Media> medias = getAllVideoThumbnailsPath(bucketId, new ArrayList<MimeType>(), specifyFolderList);
            medias.addAll(getAllMediaThumbnailsPath(bucketId, exceptMimeType, specifyFolderList));
            return medias;
        }

        @Override
        protected void onPostExecute(List<Media> result) {
            super.onPostExecute(result);
            pickerActivity.setAdapter(result);
        }
    }

    @NonNull
    private List<Media> getAllMediaThumbnailsPath(long id, List<MimeType> exceptMimeTypeList, List<String> specifyFolderList) {
        String selection = MediaStore.Images.Media.BUCKET_ID + " = ?";
        String bucketId = String.valueOf(id);
        String sort = MediaStore.Images.Media._ID + " DESC";
        String[] selectionArgs = {bucketId};

        Uri images = MediaStore.Images.Media.EXTERNAL_CONTENT_URI;
        Cursor c;
        if (!bucketId.equals("0")) {
            c = resolver.query(images, null, selection, selectionArgs, sort);
        } else {
            c = resolver.query(images, null, null, null, sort);
        }
        ArrayList<Media> medias = new ArrayList<>();
        if (c != null) {
            try {
                if (c.moveToFirst()) {
                    do {
                        Media media = new Media();
                        String mimeType = c.getString(c.getColumnIndex(MediaStore.Images.Media.MIME_TYPE));
                        String buckName = c.getString(c.getColumnIndex(MediaStore.Images.Media.BUCKET_DISPLAY_NAME));
                        if (isExceptMemeType(exceptMimeTypeList, mimeType) || isNotContainsSpecifyFolderList(specifyFolderList, buckName)) continue;
                        String originPath = c.getString(c.getColumnIndex(MediaStore.Images.Media.DATA));
                        String originName = c.getString(c.getColumnIndex(MediaStore.Images.Media.DISPLAY_NAME));
                        String originWidth = c.getString(c.getColumnIndex(MediaStore.Images.Media.WIDTH));
                        String originHeight = c.getString(c.getColumnIndex(MediaStore.Images.Media.HEIGHT));
                        int imgId = c.getInt(c.getColumnIndex(MediaStore.MediaColumns._ID));
                        String identifier = Uri.withAppendedPath(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, "" + imgId).toString();
                        media.setBucketId(bucketId);
                        media.setBucketName(buckName);
                        media.setOriginName(originName);
                        media.setOriginHeight(originHeight);
                        media.setOriginWidth(originWidth);
                        media.setOriginPath(originPath);
                        media.setIdentifier(identifier);
                        media.setMimeType(mimeType);
                        media.setFileType("image");
                        medias.add(media);
                    } while (c.moveToNext());
                }
                c.close();
            } catch (Exception e) {
                if (!c.isClosed()) c.close();
            }
        }
        return medias;
    }

    @NonNull
    private List<Media> getAllVideoThumbnailsPath(long id, List<MimeType> exceptMimeTypeList, List<String> specifyFolderList) {
        String selection = MediaStore.Video.Media.BUCKET_ID + " = ?";
        String bucketId = String.valueOf(id);
        String sort = MediaStore.Video.Media._ID + " DESC";
        String[] selectionArgs = {bucketId};

        Uri videos = MediaStore.Video.Media.EXTERNAL_CONTENT_URI;
        Cursor c;
        if (!bucketId.equals("0")) {
            c = resolver.query(videos, null, selection, selectionArgs, sort);
        } else {
            c = resolver.query(videos, null, null, null, sort);
        }
        ArrayList<Media> medias = new ArrayList<>();
        if (c != null) {
            try {
                if (c.moveToFirst()) {
                    do {
                        Media media = new Media();
                        String mimeType = c.getString(c.getColumnIndex(MediaStore.Video.Media.MIME_TYPE));
                        String buckName = c.getString(c.getColumnIndex(MediaStore.Video.Media.BUCKET_DISPLAY_NAME));
                        if (isExceptMemeType(exceptMimeTypeList, mimeType) || isNotContainsSpecifyFolderList(specifyFolderList, buckName)) continue;
                        String originPath = c.getString(c.getColumnIndex(MediaStore.Video.Media.DATA));
                        String originName = c.getString(c.getColumnIndex(MediaStore.Video.Media.DISPLAY_NAME));
                        String originWidth = c.getString(c.getColumnIndex(MediaStore.Video.Media.WIDTH));
                        String originHeight = c.getString(c.getColumnIndex(MediaStore.Video.Media.HEIGHT));
                        String duration = c.getString(c.getColumnIndex(MediaStore.Video.Media.DURATION));
                        int videoId = c.getInt(c.getColumnIndex(MediaStore.MediaColumns._ID));
                        String identifier = Uri.withAppendedPath(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, "" + videoId).toString();
                        media.setBucketId(bucketId);
                        media.setBucketName(buckName);
                        media.setOriginName(originName);
                        media.setOriginHeight(originHeight);
                        media.setOriginWidth(originWidth);
                        media.setOriginPath(originPath);
                        media.setDuration(duration);
                        media.setIdentifier(identifier);
                        media.setMimeType(mimeType);
                        media.setFileType("video");
                        medias.add(media);
                    } while (c.moveToNext());
                }
                c.close();
            } catch (Exception e) {
                if (!c.isClosed()) c.close();
            }
        }
        return medias;
    }

    private boolean isExceptMemeType(List<MimeType> mimeTypes, String mimeType){
        for (MimeType type : mimeTypes) {
            if (MimeTypeExt.equalsMimeType(type, mimeType))
                return true;
        }
        return false;
    }

    private boolean isNotContainsSpecifyFolderList(List<String> specifyFolderList, String displayBundleName) {
        if (specifyFolderList.isEmpty()) return false;
        return !specifyFolderList.contains(displayBundleName);
    }
}
