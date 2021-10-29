package com.sangcomz.fishbun.util;

import android.content.ContentResolver;
import android.content.Context;
import android.database.Cursor;
import android.net.Uri;
import android.os.Handler;
import android.os.Looper;
import android.provider.MediaStore;
import android.text.TextUtils;

import com.sangcomz.fishbun.bean.Album;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

public class DisplayAlbum {

    public interface DisplayAlbumListener {
        void OnDisplayAlbumDidSelectFinish(ArrayList albums);
    }
    private String allViewTitle;
    private String mediaShowType;
    private ContentResolver resolver;
    private DisplayAlbumListener listener;

    public void setListener(DisplayAlbumListener listener) {
        this.listener = listener;
    }

    public DisplayAlbum(String allViewTitle, String mediaShowType, Context context) {
        this.allViewTitle = allViewTitle;
        this.mediaShowType = mediaShowType;
        this.resolver = context.getContentResolver();
    }

    public void execute() {
        new Thread(new Runnable() {
            @Override
            public void run() {
                HashMap<Long, Album> albumHashMap = new HashMap<>();
                Album mainAlbum = new Album(0, allViewTitle, null, 0);
                albumHashMap.put((long) 0, mainAlbum);
                int totalCounter = 0;
                String[] projection = new String[]{MediaStore.Images.Media._ID, MediaStore.Images.Media.BUCKET_DISPLAY_NAME, MediaStore.Images.Media.MIME_TYPE, MediaStore.Images.Media.BUCKET_ID};
                Cursor c = resolver.query(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, projection, null, null, null);
                if (c != null) {
                    int bucketMimeType = c.getColumnIndex(MediaStore.Images.Media.MIME_TYPE);
                    int bucketColumn = c.getColumnIndex(MediaStore.Images.Media.BUCKET_DISPLAY_NAME);
                    int bucketColumnId = c.getColumnIndex(MediaStore.Images.Media.BUCKET_ID);

                    while (c.moveToNext()) {
                        String mimeType = c.getString(bucketMimeType);
                        String folderName = c.getString(bucketColumn);
                        if (c.getCount() <= 0 || !isShowType(mimeType)) continue;

                        totalCounter++;
                        long bucketId = c.getInt(bucketColumnId);
                        Album album = albumHashMap.get(bucketId);
                        if (album == null) {
                            int imgId = c.getInt(c.getColumnIndex(MediaStore.MediaColumns._ID));
                            Uri path = Uri.withAppendedPath(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, "" + imgId);
                            albumHashMap.put(bucketId, new Album(bucketId, folderName, path.toString(), 1));
                            if (TextUtils.isEmpty(mainAlbum.thumbnailPath)) mainAlbum.thumbnailPath = path.toString();
                        } else {
                            album.counter++;
                        }
                    }
                    c.close();
                }

                String[] videoProjection = new String[]{MediaStore.Video.Media._ID, MediaStore.Video.Media.BUCKET_DISPLAY_NAME, MediaStore.Video.Media.MIME_TYPE, MediaStore.Video.Media.BUCKET_ID};
                c = resolver.query(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, videoProjection, null, null, null);
                if (c != null) {
                    int bucketMimeType = c.getColumnIndex(MediaStore.Video.Media.MIME_TYPE);
                    int bucketColumn = c.getColumnIndex(MediaStore.Video.Media.BUCKET_DISPLAY_NAME);
                    int bucketColumnId = c.getColumnIndex(MediaStore.Video.Media.BUCKET_ID);

                    while (c.moveToNext()) {
                        String mimeType = c.getString(bucketMimeType);
                        if (c.getCount() <= 0 || !isShowType(mimeType)) continue;

                        totalCounter++;
                        String folderName = c.getString(bucketColumn);
                        long bucketId = c.getInt(bucketColumnId);
                        Album album = albumHashMap.get(bucketId);
                        if (album == null) {
                            int imgId = c.getInt(c.getColumnIndex(MediaStore.MediaColumns._ID));
                            Uri path = Uri.withAppendedPath(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, "" + imgId);
                            albumHashMap.put(bucketId, new Album(bucketId, folderName, path.toString(), 1));
                            if (TextUtils.isEmpty(mainAlbum.thumbnailPath)) mainAlbum.thumbnailPath = path.toString();
                        } else {
                            album.counter++;
                        }
                    }
                    c.close();
                }
                mainAlbum.counter = totalCounter;

                if (totalCounter == 0)
                    albumHashMap.clear();

                final ArrayList<Album> albumList = new ArrayList<>();
                for (Album tAlbum : albumHashMap.values()) {
                    if (tAlbum.bucketId == 0)
                        albumList.add(0, tAlbum);
                    else
                        albumList.add(tAlbum);
                }

                if (Looper.myLooper() != Looper.getMainLooper()) {
                    Handler mainThread = new Handler(Looper.getMainLooper());
                    mainThread.post(new Runnable() {
                        @Override
                        public void run() {
                            if (listener != null) {
                                listener.OnDisplayAlbumDidSelectFinish(albumList);
                            }
                        }
                    });
                }else {
                    if (listener != null) {
                        listener.OnDisplayAlbumDidSelectFinish(albumList);
                    }
                }
            }
        }).start();
    }

    private boolean isShowType(String mimeType) {
        try {
            if (mediaShowType.equalsIgnoreCase("all")) return true;
            if (TextUtils.isEmpty(mediaShowType)) return false;
            if (TextUtils.isEmpty(mimeType)) return false;
            return mimeType.contains(mediaShowType);
        }catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

}
