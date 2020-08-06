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
        String filePath = "";
        String mimeType = "";
        String width = "0";
        String height = "0";
        String identify = "";
        try {
            Uri uri = MediaStore.Files.getContentUri("external");
            String selection = MediaStore.MediaColumns._ID + "=" + identify;
            Cursor c = context.getContentResolver().query(uri, null, selection, null, null);
            if (c != null) {
                try {
                    if (c.moveToFirst()) {
                        identify = c.getString(c.getColumnIndex(MediaStore.MediaColumns._ID));
                        size = c.getString(c.getColumnIndex(MediaStore.MediaColumns.SIZE));
                        filePath = c.getString(c.getColumnIndex(MediaStore.MediaColumns.DATA));
                        mimeType = c.getString(c.getColumnIndex(MediaStore.MediaColumns.MIME_TYPE));
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
        if (mimeType.contains("video")) {
            String uuid = UUID.randomUUID().toString();
            String imgName = uuid + ".jpg";
            String cacheDir = context.getCacheDir().getAbsolutePath() + "/multi_image_pick/thumb/";
            File tmpPicParentDir = new File(cacheDir);
            if (!tmpPicParentDir.exists()) {
                tmpPicParentDir.mkdirs();
            }
            File tmpPic = new File(cacheDir + imgName);
            if (tmpPic.exists()) {
                tmpPic.delete();
            }
            HashMap t = localVideoThumb(filePath, tmpPic.getAbsolutePath());
            width = (String) t.get("width");
            height = (String) t.get("height");
            hashMap.put("fileType", "video");
            hashMap.put("thumbPath", tmpPic.getAbsolutePath());
            hashMap.put("thumbName", imgName);
            hashMap.put("thumbHeight", width);
            hashMap.put("thumbWidth", height);
        }
        hashMap.put("width", width);
        hashMap.put("height", height);
        hashMap.put("identifier", identify);
        return hashMap;
    }

    public HashMap<String, String> localVideoThumb(String filePath, String savePath) {
        HashMap result = new HashMap();
        Bitmap bitmap = null;
        MediaMetadataRetriever retriever = new MediaMetadataRetriever();
        try {
            retriever.setDataSource(filePath);
            bitmap = retriever.getFrameAtTime(0);
            File f = new File(savePath);
            FileOutputStream out = new FileOutputStream(f);
            bitmap.compress(Bitmap.CompressFormat.JPEG, 100, out);
            result.put("width", (bitmap.getWidth() * 1.0) + "");
            result.put("height", (bitmap.getHeight() * 1.0) + "");
            out.flush();
            out.close();
            if(!bitmap.isRecycled()){
                bitmap.recycle();//记得释放资源，否则会内存溢出
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            retriever.release();
        }
        return result;
    }

    @Override
    protected void onPostExecute(HashMap hashMap) {
        super.onPostExecute(hashMap);
        if (listener != null) {
            listener.mediaInfoDataDidFinish(hashMap);
        }
    }
}
