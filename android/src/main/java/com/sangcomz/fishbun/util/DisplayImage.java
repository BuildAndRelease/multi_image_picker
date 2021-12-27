package com.sangcomz.fishbun.util;

import android.content.ContentResolver;
import android.content.Context;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.media.ExifInterface;
import android.media.MediaMetadataRetriever;
import android.net.Uri;
import android.os.Handler;
import android.os.Looper;
import android.provider.MediaStore;
import android.text.TextUtils;
import androidx.annotation.NonNull;

import com.sangcomz.fishbun.bean.Media;

import org.w3c.dom.Text;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;

public class DisplayImage {

    public interface DisplayImageListener {
        void OnDisplayImageDidSelectFinish(ArrayList medias);
    }
    private Long bucketId;
    private ContentResolver resolver;
    private String expectType;
    private DisplayImageListener listener;
    private MediaMetadataRetriever retriever = new MediaMetadataRetriever();

    private Context context;
    private int limit = -1;
    private int offset = -1;
    private ArrayList<String> selectMedias = new ArrayList<>();
    private boolean requestHashMap = false;
    private boolean isInvertedPhotos = false;
    private boolean requestVideoDimen = false;
    private boolean fetchSpecialPhotos = false;

    public void setLimit(int limit) {
        this.limit = limit;
    }
    public void setOffset(int offset) {
        this.offset = offset;
    }
    public void setRequestVideoDimen(boolean requestVideoDimen) {
        this.requestVideoDimen = requestVideoDimen;
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

    public DisplayImage(Long bucketId, ArrayList<String> selectMedias, String expectType, Context context) {
        this.bucketId = bucketId;
        this.selectMedias = selectMedias;
        this.expectType = expectType;
        this.resolver = context.getContentResolver();
        this.context = context;
        this.fetchSpecialPhotos = selectMedias != null && !selectMedias.isEmpty();
    }

    public void execute() {
        output.clear();
        new Thread(new Runnable() {
            @Override
            public void run() {
                final ArrayList result = getAllMediaThumbnailsPath(bucketId);
                if (Looper.myLooper() != Looper.getMainLooper()) {
                    Handler mainThread = new Handler(Looper.getMainLooper());
                    mainThread.post(new Runnable() {
                        @Override
                        public void run() {
                            if (listener != null) {
                                listener.OnDisplayImageDidSelectFinish(result);
                            }
                        }
                    });
                }else {
                    if (listener != null) {
                        listener.OnDisplayImageDidSelectFinish(result);
                    }
                }
            }
        }).start();
    }

    @NonNull
    private ArrayList getAllMediaThumbnailsPath(long id) {
        String bucketId = String.valueOf(id);
        String sort = MediaStore.Files.FileColumns._ID + " DESC ";
        if (limit >= 0 && offset >= 0) {
            sort = sort + " LIMIT " + limit + " OFFSET " + offset;
        }

        Uri mediaUri = MediaStore.Files.getContentUri("external");
        String selection = MediaStore.Files.FileColumns.MEDIA_TYPE + "="
                + MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE
                + " OR "
                + MediaStore.Files.FileColumns.MEDIA_TYPE + "="
                + MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO;
        Cursor c;
        try {
            if ("0".equals(bucketId)) {
                if (fetchSpecialPhotos) {
                    selection = "(" + selection + ") AND " + MediaStore.MediaColumns._ID + " in (" + TextUtils.join(",", selectMedias) + ")";
                }
                c = resolver.query(mediaUri, null, selection, null, sort);
            }else {
                selection = "(" + selection + ") AND " + MediaStore.MediaColumns.BUCKET_ID + " = ?";
                if (fetchSpecialPhotos) {
                    selection = selection + " AND " + MediaStore.MediaColumns._ID + " in (" + TextUtils.join(",", selectMedias) + ")";
                }
                String[] selectionArgs = {bucketId};
                c = resolver.query(mediaUri, null, selection, selectionArgs, sort);
            }
        } catch (Exception e) {
            e.printStackTrace();
            return new ArrayList();
        }
        ArrayList medias = new ArrayList<>();
        if (c != null) {
            try {
                if (c.moveToFirst()) {
                    int MIME_TYPE = c.getColumnIndex(MediaStore.Files.FileColumns.MIME_TYPE);
                    int BUCKET_DISPLAY_NAME = c.getColumnIndex(MediaStore.Files.FileColumns.BUCKET_DISPLAY_NAME);
                    int DATA = c.getColumnIndex(MediaStore.Files.FileColumns.DATA);
                    int DISPLAY_NAME = c.getColumnIndex(MediaStore.Files.FileColumns.DISPLAY_NAME);
                    int WIDTH = c.getColumnIndex(MediaStore.Files.FileColumns.WIDTH);
                    int HEIGHT = c.getColumnIndex(MediaStore.Files.FileColumns.HEIGHT);
                    int FILESIZE = c.getColumnIndex(MediaStore.Files.FileColumns.SIZE);
                    int _ID = c.getColumnIndex(MediaStore.Files.FileColumns._ID);

                    String bucketName = c.getString(BUCKET_DISPLAY_NAME);
                    int index = 0;
                    do {
                        try {
                            String mimeType = c.getString(MIME_TYPE);
                            int fileSize = c.getInt(FILESIZE);
                            if (mimeType.contains("image") && fileSize > 1024*1024*100) continue;
                            String imgId = c.getString(_ID);
                            String filePath = c.getString(DATA);
                            String displayName = c.getString(DISPLAY_NAME);
                            float width = 0;
                            float height = 0;
                            try {
                                width = c.getFloat(HEIGHT);
                                 height = c.getFloat(WIDTH);
                            } catch (Exception e) {
                                e.printStackTrace();
                            }
                            paramTransferQuene(index, imgId, bucketId, bucketName, filePath, mimeType, height, width, displayName, fileSize);
                            index++;
                        } catch (Exception e) {
                            e.printStackTrace();
                        }
                    } while (c.moveToNext());

                    do {
                        Iterator<Thread> iterable = workThreads.iterator();
                        while (iterable.hasNext()) {
                            if (iterable.next().getState() == Thread.State.TERMINATED) {
                                iterable.remove();
                            }
                        }
                        if (workThreads.size() == 0) {
                            break;
                        }else {
                            Thread.sleep(10);
                        }
                    }while (true);

                    medias = sortOutput();
                }
            } catch (Exception e) {
                e.printStackTrace();
            }finally {
                if (!c.isClosed()) c.close();
            }
        }
        return medias;
    }

    private ArrayList<Thread> workThreads = new ArrayList<>();
    private HashMap<Integer, Object> output = new HashMap();
    private synchronized void addOutputResult(int index, Object object) {
        output.put(index, object);
    }
    private void paramTransferQuene(final int index, final String imgId, final String bucketId,final  String bucketName, final String filePath, final String mimeType, final float height, final float width, final String displayName, final int fileSize) {
        if (workThreads.size() >= 10) {
            do {
                Iterator<Thread> iterable = workThreads.iterator();
                while (iterable.hasNext()) {
                    if (iterable.next().getState() == Thread.State.TERMINATED) {
                        iterable.remove();
                    }
                }
                if (workThreads.size() < 10) {
                    break;
                }
            }while (true);
        }
        Thread thread = new Thread(new Runnable() {
            @Override
            public void run() {
                if (requestHashMap) {
                    HashMap hashMap = addMedia(imgId, filePath, mimeType, height, width, displayName, fileSize);
                    if (hashMap != null) addOutputResult(index, hashMap);
                }else {
                    Media media = addMedia(imgId, bucketId, bucketName, filePath, mimeType, height, width, displayName, fileSize);
                    if (media != null) addOutputResult(index, media);
                }
            }
        });
        workThreads.add(thread);
        thread.start();
    }

    private ArrayList sortOutput() {
        ArrayList result = new ArrayList();
        Integer[] keysArray = output.keySet().toArray(new Integer[0]);
        Arrays.sort(keysArray);
        if (isInvertedPhotos) {
            for (int i = keysArray.length - 1; i >= 0; i--) {
                Object object = output.get(keysArray[i]);
                if (object != null) result.add(object);
            }
        }else {
            for (int i = 0; i < keysArray.length; i++) {
                Object object = output.get(keysArray[i]);
                if (object != null) result.add(object);
            }
        }
        return result;
    }

    private Media addMedia(String imgId, String bucketId, String bucketName, String filePath, String mimeType, float height, float width, String displayName, int fileSize) {
        if (!isExpectType(mimeType)) return null;
        Media media = new Media();
        media.setFileType(mimeType);
        media.setBucketId(bucketId);
        media.setBucketName(bucketName);
        media.setOriginName(displayName);
        media.setOriginPath(filePath);
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
            media.setOriginHeight(height + "");
            media.setOriginWidth(width + "");
            media.setDuration("0");
        }
        media.setIdentifier(imgId);
        media.setMimeType(mimeType);
        media.setFileSize(fileSize + "");
        media.setMediaId(imgId);
        return media;
    }

    private HashMap addMedia(String imgId, String filePath, String mimeType, float height, float width, String displayName, int fileSize) {
        if (!isExpectType(mimeType)) return null;
        HashMap media = new HashMap();
        try {
            media.put("identifier", imgId);
            media.put("filePath", filePath);
            if (mimeType.contains("video")) {
                if (requestVideoDimen) {
                    retriever.setDataSource(filePath);
                    Bitmap bitmap = retriever.getFrameAtTime(0);
                    media.put("width", bitmap.getWidth() * 1.0);
                    media.put("height", bitmap.getHeight() * 1.0);
                }else {
                    media.put("width", 0.0);
                    media.put("height", 0.0);
                }
                Uri uri = Uri.withAppendedPath(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, imgId);
                Cursor cursor = context.getContentResolver().query(uri, null, null, null, null);
                if (cursor.moveToFirst()) {
                    media.put("duration", cursor.getFloat(cursor.getColumnIndex(MediaStore.Video.VideoColumns.DURATION))/1000);
                }else {
                    media.put("duration", 0.0);
                }
                cursor.close();
            }else {
                double imageWidth = width;
                double imageHeight = height;
                try {
                    BitmapFactory.Options opts = new BitmapFactory.Options();
                    opts.inJustDecodeBounds = true;
                    BitmapFactory.decodeFile(filePath, opts);
                    imageWidth = opts.outWidth > 0 ? (opts.outWidth * 1.0) : imageWidth;
                    imageHeight = opts.outHeight > 0 ? (opts.outHeight * 1.0) : imageHeight;
                }catch (Exception e) {
                    e.printStackTrace();
                }
                if (fetchSpecialPhotos && !mimeType.contains("gif")) {
                    ExifInterface ei = new ExifInterface(filePath);
                    int orientation = ei.getAttributeInt(ExifInterface.TAG_ORIENTATION,
                            ExifInterface.ORIENTATION_UNDEFINED);
                    if (orientation == ExifInterface.ORIENTATION_ROTATE_90 || orientation == ExifInterface.ORIENTATION_ROTATE_270) {
                        media.put("width", imageHeight);
                        media.put("height",imageWidth);
                    }else {
                        media.put("width", imageWidth);
                        media.put("height",imageHeight);
                    }
                }else {
                    media.put("width", imageWidth);
                    media.put("height",imageHeight);
                }
                media.put("duration", 0.0);
            }
            media.put("name", displayName);
            media.put("fileType", mimeType);
            media.put("fileSize", fileSize + "");
            media.put("thumbPath", "");
            media.put("thumbName", "");
            media.put("thumbHeight", 0.0);
            media.put("thumbWidth", 0.0);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return media;
    }

    private boolean isExpectType(String mimeType){
        try {
            if (expectType.equalsIgnoreCase("all")) return true;
            if (TextUtils.isEmpty(expectType)) return false;
            if (TextUtils.isEmpty(mimeType)) return false;
            return mimeType.contains(expectType);
        }catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }
}