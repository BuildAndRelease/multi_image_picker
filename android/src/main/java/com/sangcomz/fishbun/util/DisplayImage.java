package com.sangcomz.fishbun.util;

import android.content.ContentResolver;
import android.content.Context;
import android.database.Cursor;
import android.media.MediaMetadataRetriever;
import android.net.Uri;
import android.os.AsyncTask;
import android.provider.MediaStore;

import androidx.annotation.NonNull;

import com.sangcomz.fishbun.MimeType;
import com.sangcomz.fishbun.bean.Media;

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
    private int pageSize = -1;
    private int pageNum = -1;
    private boolean requestHashMap = false;

    public void setPageNum(int pageNum) {
        this.pageNum = pageNum;
    }
    public void setPageSize(int pageSize) {
        this.pageSize = pageSize;
    }
    public void setRequestHashMap(boolean requestHashMap) {
        this.requestHashMap = requestHashMap;
    }
    public void setListener(DisplayImageListener listener) {
        this.listener = listener;
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
        String sort = MediaStore.Files.FileColumns._ID + " DESC ";
        if (pageNum > 0 && pageSize > 0) {
            sort = sort + " LIMIT " + pageSize + " OFFSET " + (pageNum - 1) * pageSize;
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
        ArrayList<Media> medias = new ArrayList<>();
        MediaMetadataRetriever retriever = new MediaMetadataRetriever();
        if (c != null) {
            try {
                if (c.moveToFirst()) {
                    do {
                        Media media = new Media();
                        String mimeType = c.getString(c.getColumnIndex(MediaStore.Files.FileColumns.MIME_TYPE));
                        String buckName = c.getString(c.getColumnIndex(MediaStore.Files.FileColumns.BUCKET_DISPLAY_NAME));
                        if (isExceptMemeType(exceptMimeTypeList, mimeType)) continue;
                        String originPath = c.getString(c.getColumnIndex(MediaStore.Files.FileColumns.DATA));
                        String originName = c.getString(c.getColumnIndex(MediaStore.Files.FileColumns.DISPLAY_NAME));
                        String originWidth = c.getString(c.getColumnIndex(MediaStore.Files.FileColumns.WIDTH));
                        String originHeight = c.getString(c.getColumnIndex(MediaStore.Files.FileColumns.HEIGHT));
                        String duration = "0";
                        String imgId = c.getString(c.getColumnIndex(MediaStore.MediaColumns._ID));
                        String identifier = "";
                        if (mimeType.startsWith("image")) {
                            identifier = Uri.withAppendedPath(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, imgId).toString();
                            media.setFileType("image");
                        }else if (mimeType.startsWith("video")) {
                            Uri uri = Uri.withAppendedPath(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, imgId);
                            retriever.setDataSource(context, uri);
                            String time = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION);
                            duration = Long.parseLong(time)/1000 + "";
                            identifier = uri.toString();
                            media.setFileType("video");
                        }else {
                            identifier = Uri.withAppendedPath(MediaStore.Files.getContentUri("external"), imgId).toString();
                            media.setFileType("file");
                        }
                        media.setBucketId(bucketId);
                        media.setBucketName(buckName);
                        media.setOriginName(originName);
                        media.setOriginHeight(originHeight);
                        media.setOriginWidth(originWidth);
                        media.setOriginPath(originPath);
                        media.setDuration(duration);
                        media.setIdentifier(identifier);
                        media.setMimeType(mimeType);
                        media.setMediaId(imgId);
                        medias.add(media);
                    } while (c.moveToNext());
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