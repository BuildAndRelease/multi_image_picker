package com.sangcomz.fishbun.util;

import android.content.ContentResolver;
import android.content.Context;
import android.database.Cursor;
import android.net.Uri;
import android.os.AsyncTask;
import android.provider.MediaStore;

import androidx.annotation.NonNull;

import com.sangcomz.fishbun.MimeType;
import com.sangcomz.fishbun.bean.Media;
import com.sangcomz.fishbun.ext.MimeTypeExt;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class DisplayImage extends AsyncTask<Void, Void, List<Media>> {
    public interface DisplayImageListener {
        void OnDisplayImageDidSelectFinish(List<Media> medias);
    }
    private Long bucketId;
    private ContentResolver resolver;
    private List<MimeType> exceptMimeType;
    private List<String> specifyFolderList;
    private DisplayImageListener listener;
    private int pageSize = -1;
    private int pageNum = -1;

    public void setPageNum(int pageNum) {
        this.pageNum = pageNum;
    }

    public void setPageSize(int pageSize) {
        this.pageSize = pageSize;
    }

    public DisplayImage(Long bucketId, List<MimeType> exceptMimeType, List<String> specifyFolderList, Context context) {
        this.bucketId = bucketId;
        this.exceptMimeType = exceptMimeType;
        this.specifyFolderList = specifyFolderList;
        this.resolver = context.getContentResolver();
    }

    public void setListener(DisplayImageListener listener) {
        this.listener = listener;
    }

    @Override
    protected List<Media> doInBackground(Void... params) {
        List<Media> medias = getAllVideoThumbnailsPath(bucketId, new ArrayList<MimeType>(), specifyFolderList);
        medias.addAll(getAllMediaThumbnailsPath(bucketId, exceptMimeType, specifyFolderList));
        Collections.sort(medias);
        if (pageSize > 0 && pageNum > 0) {
            int start = (pageNum - 1) * pageSize;
            int end = pageNum * pageSize;
            if (start >= medias.size()) {
                return new ArrayList();
            }else {
                return medias.subList(start, Math.min(end, medias.size()));
            }
        }else {
            return medias;
        }
    }

    @Override
    protected void onPostExecute(List<Media> result) {
        super.onPostExecute(result);
        if (listener != null) {
            listener.OnDisplayImageDidSelectFinish(result);
        }
    }

    @NonNull
    private List<Media> getAllMediaThumbnailsPath(long id, List<MimeType> exceptMimeTypeList, List<String> specifyFolderList) {
        String selection = MediaStore.MediaColumns.BUCKET_ID + " = ?";
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
                        media.setMediaId("" + imgId);
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
        final String[] columns = {
                MediaStore.Video.Media.MIME_TYPE,
                MediaStore.Video.Media.BUCKET_DISPLAY_NAME,
                MediaStore.Video.Media.DATA,
                MediaStore.Video.Media.DISPLAY_NAME,
                MediaStore.Video.Media.WIDTH,
                MediaStore.Video.Media.HEIGHT,
                MediaStore.Video.Media.DURATION,
                MediaStore.Video.Media._ID
        };

        Uri videos = MediaStore.Video.Media.EXTERNAL_CONTENT_URI;
        Cursor c;
        if (!bucketId.equals("0")) {
            c = resolver.query(videos, columns, selection, selectionArgs, sort);
        } else {
            c = resolver.query(videos, columns, null, null, sort);
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
                        media.setMediaId(videoId + "");
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