package com.sangcomz.fishbun.util;

import android.content.Context;
import android.graphics.Bitmap;
import android.os.AsyncTask;
import android.provider.MediaStore;

import java.io.ByteArrayOutputStream;

public class MediaThumbData extends AsyncTask<Void, Void, byte[]> {
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

    @Override
    protected byte[] doInBackground(Void... voids) {
        try {
            if (fileType.contains("video")) {
                Bitmap bitmap = MediaStore.Video.Thumbnails.getThumbnail(context.getContentResolver(), Long.parseLong(identify), MediaStore.Images.Thumbnails.MINI_KIND, null);
                ByteArrayOutputStream stream = new ByteArrayOutputStream();
                bitmap.compress(Bitmap.CompressFormat.JPEG, 100, stream);
                byte[] bytes = stream.toByteArray();
                bitmap.recycle();
                stream.close();
                return bytes;
            }else if (fileType.contains("image")) {
                Bitmap bitmap = MediaStore.Images.Thumbnails.getThumbnail(context.getContentResolver(), Long.parseLong(identify), MediaStore.Images.Thumbnails.MINI_KIND, null);
                ByteArrayOutputStream stream = new ByteArrayOutputStream();
                bitmap.compress(Bitmap.CompressFormat.JPEG, 100, stream);
                byte[] bytes = stream.toByteArray();
                bitmap.recycle();
                stream.close();
                return bytes;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    @Override
    protected void onPostExecute(byte[] bytes) {
        super.onPostExecute(bytes);
        if (listener != null) {
            listener.mediaThumbDataDidFinish(bytes);
        }
    }
}
