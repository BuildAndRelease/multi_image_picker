package com.sangcomz.fishbun.util;

import android.content.Context;
import android.database.Cursor;
import android.net.Uri;
import android.os.AsyncTask;
import android.provider.MediaStore;

public class MediaInfoData extends AsyncTask<Void, Void, String> {
    public interface MediaInfoDataListener {
        void mediaInfoDataDidFinish(String size);
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
    protected String doInBackground(Void... voids) {
        String size = "0";
        try {
            Uri uri = MediaStore.Files.getContentUri("external");
            String selection = MediaStore.MediaColumns._ID + "=" + identify;
            Cursor c = context.getContentResolver().query(uri, null, selection, null, null);
            if (c != null) {
                try {
                    if (c.moveToFirst()) {
                        size = c.getString(c.getColumnIndex(MediaStore.MediaColumns.SIZE));
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
        return size;
    }

    @Override
    protected void onPostExecute(String size) {
        super.onPostExecute(size);
        if (listener != null) {
            listener.mediaInfoDataDidFinish(size);
        }
    }
}
