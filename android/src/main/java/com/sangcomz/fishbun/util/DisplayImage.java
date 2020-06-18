package com.sangcomz.fishbun.util;

import android.content.ContentResolver;
import android.content.Context;
import android.database.Cursor;
import android.media.MediaMetadataRetriever;
import android.net.Uri;
import android.os.AsyncTask;
import android.provider.MediaStore;
import android.util.Log;

import androidx.annotation.NonNull;

import com.sangcomz.fishbun.MimeType;
import com.sangcomz.fishbun.bean.Media;

import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

public class DisplayImage extends AsyncTask<Void, Void, ArrayList> {

    public interface DisplayImageListener {
        void OnDisplayImageDidSelectFinish(ArrayList medias);
    }
    private Long bucketId;
    private ContentResolver resolver;
    private List<MimeType> exceptMimeType;
    private DisplayImageListener listener;
    private Context context;
    private int limit = -1;
    private int offset = -1;
    private boolean requestHashMap = false;
    private boolean isInvertedPhotos = false;

    public void setLimit(int limit) {
        this.limit = limit;
    }
    public void setOffset(int offset) {
        this.offset = offset;
    }
    public void setRequestHashMap(boolean requestHashMap) {
        this.requestHashMap = requestHashMap;
    }
    public void setListener(DisplayImageListener listener) {
        this.listener = listener;
    }
    public void setInvertedPhotos(boolean invertedPhotos) {
        isInvertedPhotos = invertedPhotos;
    }

    public DisplayImage(Long bucketId, List<MimeType> exceptMimeType, Context context) {
        this.bucketId = bucketId;
        this.exceptMimeType = exceptMimeType;
        this.resolver = context.getContentResolver();
        this.context = context;
    }

    @Override
    protected ArrayList doInBackground(Void... params) {
        ArrayList<Media> medias = getAllMediaThumbnailsPath(bucketId, exceptMimeType);
        if (requestHashMap) {
            ArrayList<HashMap> result = new ArrayList<>();
            for (Media media : medias) {
                HashMap info = new HashMap();
                info.put("identifier", media.getIdentifier());
                info.put("filePath", media.getOriginPath());
                info.put("width", Float.parseFloat(media.getOriginWidth()));
                info.put("height",Float.parseFloat(media.getOriginHeight()));
                info.put("duration", Float.parseFloat(media.getDuration()));
                info.put("name", media.getOriginName());
                info.put("fileType", media.getFileType());
                info.put("thumbPath", media.getThumbnailPath());
                info.put("thumbName", media.getThumbnailName());
                info.put("thumbHeight", Float.parseFloat(media.getThumbnailHeight()));
                info.put("thumbWidth", Float.parseFloat(media.getThumbnailWidth()));
                result.add(info);
            }
            return result;
        }else {
            return medias;
        }
    }

    @Override
    protected void onPostExecute(ArrayList result) {
        super.onPostExecute(result);
        if (listener != null) {
            listener.OnDisplayImageDidSelectFinish(result);
        }
    }

    @NonNull
    private ArrayList getAllMediaThumbnailsPath(long id, List<MimeType> exceptMimeTypeList) {
        String bucketId = String.valueOf(id);
        String sort = isInvertedPhotos ? MediaStore.Files.FileColumns._ID + " ASC " : MediaStore.Files.FileColumns._ID + " DESC ";
        if (limit > 0 && offset > 0) {
            sort = sort + " LIMIT " + limit + " OFFSET " + offset;
        }

        Uri images = MediaStore.Files.getContentUri("external");
        String selection = MediaStore.Files.FileColumns.MEDIA_TYPE + "="
                + MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE
                + " OR "
                + MediaStore.Files.FileColumns.MEDIA_TYPE + "="
                + MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO;
        Cursor c;
        if ("0".equals(bucketId)) {
            c = resolver.query(images, null, selection, null, sort);
        }else {
            selection = "(" + selection + ") AND " + MediaStore.MediaColumns.BUCKET_ID + " = ?";
            String[] selectionArgs = {bucketId};
            c = resolver.query(images, null, selection, selectionArgs, sort);
        }
        ArrayList medias = new ArrayList<>();
        MediaMetadataRetriever retriever = new MediaMetadataRetriever();
        if (c != null) {
            try {
                if (c.moveToFirst()) {
                    int MIME_TYPE = c.getColumnIndex(MediaStore.Files.FileColumns.MIME_TYPE);
                    int BUCKET_DISPLAY_NAME = c.getColumnIndex(MediaStore.Files.FileColumns.BUCKET_DISPLAY_NAME);
                    int DATA = c.getColumnIndex(MediaStore.Files.FileColumns.DATA);
                    int DISPLAY_NAME = c.getColumnIndex(MediaStore.Files.FileColumns.DISPLAY_NAME);
                    int WIDTH = c.getColumnIndex(MediaStore.Files.FileColumns.WIDTH);
                    int HEIGHT = c.getColumnIndex(MediaStore.Files.FileColumns.HEIGHT);
                    int _ID = c.getColumnIndex(MediaStore.Files.FileColumns._ID);
                    int DURATION = c.getColumnIndex(MediaStore.Video.VideoColumns.DURATION);
                    if (requestHashMap) {
                        do {
                            HashMap media = new HashMap();
                            String mimeType = c.getString(MIME_TYPE);
                            String imgId = c.getString(_ID);
                            media.put("identifier", imgId);
                            media.put("filePath", c.getString(DATA));
                            media.put("width", Float.parseFloat(c.getString(WIDTH)));
                            media.put("height",Float.parseFloat(c.getString(HEIGHT)));
                            if (mimeType.contains("video")) {
                                Uri uri = Uri.withAppendedPath(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, imgId);
                                Cursor cursor = context.getContentResolver().query(uri, null, null, null, null);
                                if (cursor.moveToFirst()) {
                                    media.put("duration", cursor.getInt(DURATION)/1000);
                                }
                                cursor.close();
                            }else {
                                media.put("duration", 0);
                            }
                            media.put("name", c.getString(DISPLAY_NAME));
                            media.put("fileType", mimeType);
                            media.put("thumbPath", "");
                            media.put("thumbName", "");
                            media.put("thumbHeight", 0.0);
                            media.put("thumbWidth", 0.0);
                            medias.add(media);
                        } while (c.moveToNext());
                    }else {

                        do {
                            Media media = new Media();
                            String mimeType = c.getString(MIME_TYPE);
                            String imgId = c.getString(_ID);
                            if (isExceptMemeType(exceptMimeTypeList, mimeType)) continue;
                            media.setFileType(mimeType);
                            media.setBucketId(bucketId);
                            media.setBucketName(c.getString(BUCKET_DISPLAY_NAME));
                            media.setOriginName(c.getString(DISPLAY_NAME));
                            media.setOriginHeight(c.getString(HEIGHT));
                            media.setOriginWidth(c.getString(WIDTH));
                            media.setOriginPath(c.getString(DATA));
                            if (media.getFileType().contains("video")) {
                                Uri uri = Uri.withAppendedPath(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, imgId);
                                Cursor cursor = context.getContentResolver().query(uri, null, null, null, null);
                                if (cursor.moveToFirst()) {
                                    media.setDuration(cursor.getInt(cursor.getColumnIndex(MediaStore.Video.VideoColumns.DURATION))/1000 + "");
                                }else {
                                    media.setDuration("0");
                                }
                                cursor.close();
                            }else{
                                media.setDuration("0");
                            }
                            media.setIdentifier(imgId);
                            media.setMimeType(mimeType);
                            media.setMediaId(imgId);
                            medias.add(media);
                        } while (c.moveToNext());
                    }
                }
                c.close();
                retriever.release();
            } catch (Exception e) {
                if (!c.isClosed()) c.close();
                retriever.release();
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
}