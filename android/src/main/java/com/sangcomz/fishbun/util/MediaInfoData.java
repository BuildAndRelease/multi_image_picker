package com.sangcomz.fishbun.util;

import android.content.Context;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.media.MediaMetadataRetriever;
import android.net.Uri;
import android.os.AsyncTask;
import android.provider.MediaStore;

import com.sangcomz.fishbun.bean.Media;

import java.io.File;
import java.io.FileOutputStream;
import java.util.HashMap;
import java.util.UUID;

public class MediaInfoData extends AsyncTask<Void, Void, HashMap> {
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

    @Override
    protected HashMap doInBackground(Void... voids) {
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
                        size = c.getString(c.getColumnIndex(MediaStore.MediaColumns.SIZE));
                        width = c.getString(c.getColumnIndex(MediaStore.MediaColumns.WIDTH));
                        height = c.getString(c.getColumnIndex(MediaStore.MediaColumns.HEIGHT));
                        c.close();
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    c.close();
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        HashMap hashMap = new HashMap();
        hashMap.put("size", size);
        hashMap.put("width", width);
        hashMap.put("height", height);
        hashMap.put("identifier", identify);
        return hashMap;
    }

    @Override
    protected void onPostExecute(HashMap hashMap) {
        super.onPostExecute(hashMap);
        if (listener != null) {
            listener.mediaInfoDataDidFinish(hashMap);
        }
    }
}
