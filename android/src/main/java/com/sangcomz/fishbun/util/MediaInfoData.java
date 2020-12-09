package com.sangcomz.fishbun.util;

import android.content.Context;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Handler;
import android.os.Looper;
import android.provider.MediaStore;

import java.io.ByteArrayOutputStream;
import java.util.HashMap;

public class MediaInfoData {
    public interface MediaInfoDataListener {
        void mediaInfoDataDidFinish(HashMap hashMap);
    }

    private String identify;
    private Context context;
    private MediaInfoDataListener listener;
    public void setListener(MediaInfoDataListener listener) {
        this.listener = listener;
    }

    public MediaInfoData(String identify, Context context) {
        this.context = context;
        this.identify = identify;
    }

    public void execute() {
        new Thread(new Runnable() {
            @Override
            public void run() {
                String size = "0";
                String width = "0";
                String height = "0";
                try {
                    Uri uri = MediaStore.Files.getContentUri("external");
                    String selection = MediaStore.MediaColumns._ID + "=" + identify;
                    Cursor c = context.getContentResolver().query(uri, null, selection, null, null);
                    if (c != null) {
                        try {
                            if (c.moveToFirst()) {
                               String fileType = c.getString(c.getColumnIndex(MediaStore.MediaColumns.MIME_TYPE));
                                if (fileType.contains("video")) {
                                    Bitmap bitmap = MediaStore.Video.Thumbnails.getThumbnail(context.getContentResolver(), Long.parseLong(identify), MediaStore.Images.Thumbnails.MINI_KIND, null);
                                    width = bitmap.getWidth() + "";
                                    height = bitmap.getHeight() + "";
                                    size = bitmap.getAllocationByteCount() + "";
                                    bitmap.recycle();
                                }else if (fileType.contains("image")) {
                                    Bitmap bitmap = MediaStore.Images.Thumbnails.getThumbnail(context.getContentResolver(), Long.parseLong(identify), MediaStore.Images.Thumbnails.MINI_KIND, null);
                                    width = bitmap.getWidth() + "";
                                    height = bitmap.getHeight() + "";
                                    size = bitmap.getAllocationByteCount() + "";
                                    bitmap.recycle();
                                }else {
                                    size = c.getString(c.getColumnIndex(MediaStore.MediaColumns.SIZE));
                                    width = c.getString(c.getColumnIndex(MediaStore.MediaColumns.WIDTH));
                                    height = c.getString(c.getColumnIndex(MediaStore.MediaColumns.HEIGHT));
                                }
                            }
                        } catch (Exception e) {
                            e.printStackTrace();
                        }finally {
                            c.close();
                        }
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                }
                final HashMap hashMap = new HashMap();
                hashMap.put("size", size);
                hashMap.put("width", width);
                hashMap.put("height", height);
                hashMap.put("identifier", identify);

                if (Looper.myLooper() != Looper.getMainLooper()) {
                    Handler mainThread = new Handler(Looper.getMainLooper());
                    mainThread.post(new Runnable() {
                        @Override
                        public void run() {
                            if (listener != null) {
                                listener.mediaInfoDataDidFinish(hashMap);
                            }
                        }
                    });
                }else {
                    if (listener != null) {
                        listener.mediaInfoDataDidFinish(hashMap);
                    }
                }
            }
        }).start();
    }

}
