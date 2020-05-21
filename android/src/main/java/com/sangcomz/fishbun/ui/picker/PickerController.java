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
import com.sangcomz.fishbun.ext.MimeTypeExt;
import com.sangcomz.fishbun.util.CameraUtil;

import java.util.ArrayList;
import java.util.List;

/**
 * Created by sangc on 2015-11-05.
 */
public class PickerController {
    private PickerActivity pickerActivity;
    private ArrayList<Uri> addImagePaths = new ArrayList<>();
    private ContentResolver resolver;
    private CameraUtil cameraUtil = new CameraUtil();
    private String pathDir = "";

    PickerController(PickerActivity pickerActivity) {
        this.pickerActivity = pickerActivity;
        resolver = pickerActivity.getContentResolver();
    }

    public void takePicture(Activity activity, String saveDir) {
        cameraUtil.takePicture(activity, saveDir);
    }

    public void setToolbarTitle(int total) {
        pickerActivity.updateSendBtnTitle();
    }

    String getSavePath() {
        return cameraUtil.getSavePath();
    }

    void setSavePath(String savePath) {
        cameraUtil.setSavePath(savePath);
    }

    public void setAddImagePath(Uri imagePath) {
        this.addImagePaths.add(imagePath);
    }

    protected ArrayList<Uri> getAddImagePaths() {
        return addImagePaths;
    }

    public void setAddImagePaths(ArrayList<Uri> addImagePaths) {
        this.addImagePaths = addImagePaths;
    }

    void displayImage(Long bucketId, List<MimeType> exceptMimeType, List<String> specifyFolderList) {
        new DisplayImage(bucketId, exceptMimeType, specifyFolderList).execute();
    }

    private class DisplayImage extends AsyncTask<Void, Void, List<Uri>> {
        private Long bucketId;
        List<MimeType> exceptMimeType;
        List<String> specifyFolderList;

        DisplayImage(Long bucketId, List<MimeType> exceptMimeType, List<String> specifyFolderList) {
            this.bucketId = bucketId;
            this.exceptMimeType = exceptMimeType;
            this.specifyFolderList = specifyFolderList;
        }

        @Override
        protected List<Uri> doInBackground(Void... params) {
            List<Uri> medias = getAllVideoThumbnailsPath(bucketId, new ArrayList<MimeType>(), specifyFolderList);
            medias.addAll(getAllMediaThumbnailsPath(bucketId, exceptMimeType, specifyFolderList));
            return medias;
        }

        @Override
        protected void onPostExecute(List<Uri> result) {
            super.onPostExecute(result);
            pickerActivity.setAdapter(result);
        }
    }

    @NonNull
    private List<Uri> getAllMediaThumbnailsPath(long id, List<MimeType> exceptMimeTypeList, List<String> specifyFolderList) {
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
        ArrayList<Uri> imageUris = new ArrayList<>();
        if (c != null) {
            try {
                if (c.moveToFirst()) {
                    setPathDir(c.getString(c.getColumnIndex(MediaStore.Images.Media.DATA)), c.getString(c.getColumnIndex(MediaStore.Images.Media.DISPLAY_NAME)));
                    do {
                        String mimeType = c.getString(c.getColumnIndex(MediaStore.Images.Media.MIME_TYPE));
                        String folderName = c.getString(c.getColumnIndex(MediaStore.Images.Media.BUCKET_DISPLAY_NAME));
                        if (isExceptMemeType(exceptMimeTypeList, mimeType) || isNotContainsSpecifyFolderList(specifyFolderList, folderName)) continue;
                        int imgId = c.getInt(c.getColumnIndex(MediaStore.MediaColumns._ID));
                        Uri path = Uri.withAppendedPath(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, "" + imgId);
                        imageUris.add(path);
                    } while (c.moveToNext());
                }
                c.close();
            } catch (Exception e) {
                if (!c.isClosed()) c.close();
            }
        }
        return imageUris;
    }

    @NonNull
    private List<Uri> getAllVideoThumbnailsPath(long id, List<MimeType> exceptMimeTypeList, List<String> specifyFolderList) {
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
        ArrayList<Uri> videoUris = new ArrayList<>();
        if (c != null) {
            try {
                if (c.moveToFirst()) {
                    setPathDir(c.getString(c.getColumnIndex(MediaStore.Video.Media.DATA)), c.getString(c.getColumnIndex(MediaStore.Video.Media.DISPLAY_NAME)));
                    do {
                        String mimeType = c.getString(c.getColumnIndex(MediaStore.Video.Media.MIME_TYPE));
                        String folderName = c.getString(c.getColumnIndex(MediaStore.Video.Media.BUCKET_DISPLAY_NAME));
                        if (isExceptMemeType(exceptMimeTypeList, mimeType) || isNotContainsSpecifyFolderList(specifyFolderList, folderName)) continue;
                        int imgId = c.getInt(c.getColumnIndex(MediaStore.MediaColumns._ID));
                        Uri path = Uri.withAppendedPath(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, "" + imgId);
                        videoUris.add(path);
                    } while (c.moveToNext());
                }
                c.close();
            } catch (Exception e) {
                if (!c.isClosed()) c.close();
            }
        }
        return videoUris;
    }

    private void setPathDir(String path, String fileName) {
        pathDir = path.replace("/" + fileName, "");
    }

    String getPathDir(Long bucketId) {
        if (pathDir.equals("") || bucketId == 0)
            pathDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM + "/Camera").getAbsolutePath();
        return pathDir;
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
