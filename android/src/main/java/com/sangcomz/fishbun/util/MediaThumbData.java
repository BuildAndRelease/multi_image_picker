package com.sangcomz.fishbun.util;

import android.content.Context;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.Handler;
import android.os.Looper;
import android.provider.MediaStore;
import android.text.TextUtils;

import java.io.ByteArrayOutputStream;

public class MediaThumbData {
    public interface MediaThumbDataListener {
        void mediaThumbDataDidFinish(byte[] byteBuffer);
    }

    private String identify;
    private String fileType;
    private Context context;
    private MediaThumbDataListener listener;
    public void setListener(MediaThumbDataListener listener) {
        this.listener = listener;
    }

    public MediaThumbData(String identify, String fileType, Context context) {
        this.context = context;
        this.fileType = fileType;
        this.identify = identify;
    }

    public void execute() {
        new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    byte[] bytes = null;
                    String originPath = "";
                    boolean isPNG = !TextUtils.isEmpty(fileType) && fileType.toLowerCase().contains("png");
                    if(TextUtils.isEmpty(fileType) || isPNG) {
                        try {
                            Uri uri = MediaStore.Files.getContentUri("external");
                            String selection = MediaStore.MediaColumns._ID + "=" + identify;
                            Cursor c = context.getContentResolver().query(uri, null, selection, null, null);
                            if (c != null) {
                                try {
                                    if (c.moveToFirst()){
                                        fileType = c.getString(c.getColumnIndex(MediaStore.MediaColumns.MIME_TYPE));
                                        originPath = c.getString(c.getColumnIndex(MediaStore.MediaColumns.DATA));
                                    }
                                } catch (Exception e) {
                                    e.printStackTrace();
                                } finally {
                                    c.close();
                                }
                            }
                        } catch (Exception e) {
                            e.printStackTrace();
                        }
                    }

                    if (fileType.contains("video")) {
                        Bitmap bitmap = MediaStore.Video.Thumbnails.getThumbnail(context.getContentResolver(), Long.parseLong(identify), MediaStore.Images.Thumbnails.MINI_KIND, null);
                        ByteArrayOutputStream stream = new ByteArrayOutputStream();
                        bitmap.compress(Bitmap.CompressFormat.JPEG, 100, stream);
                        bytes = stream.toByteArray();
                        bitmap.recycle();
                        stream.close();
                    }else if (fileType.contains("image")) {
                        Bitmap bitmap;
                        if (!TextUtils.isEmpty(originPath) && isPNG) {
                            bitmap = BitmapFactory.decodeFile(originPath);
                        }else {
                            bitmap = MediaStore.Images.Thumbnails.getThumbnail(context.getContentResolver(), Long.parseLong(identify), MediaStore.Images.Thumbnails.MINI_KIND, null);
                        }
                        ByteArrayOutputStream stream = new ByteArrayOutputStream();
                        bitmap.compress(isPNG ? Bitmap.CompressFormat.PNG : Bitmap.CompressFormat.JPEG, 80, stream);
                        bytes = stream.toByteArray();
                        bitmap.recycle();
                        stream.close();
                    }
                    fetchThumbnailFinish(bytes);
                } catch (Exception e) {
                    e.printStackTrace();
                    fetchThumbnailFinish(null);
                }
            }
        }).start();
    }

    private void fetchThumbnailFinish(final byte[] bytes) {
        if (Looper.myLooper() != Looper.getMainLooper()) {
            Handler mainThread = new Handler(Looper.getMainLooper());
            mainThread.post(new Runnable() {
                @Override
                public void run() {
                    if (listener != null) {
                        listener.mediaThumbDataDidFinish(bytes);
                    }
                }
            });
        }else {
            if (listener != null) {
                listener.mediaThumbDataDidFinish(bytes);
            }
        }
    }
}
