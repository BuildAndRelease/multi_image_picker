package com.sangcomz.fishbun.util;

import android.content.Context;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.media.MediaMetadataRetriever;
import android.net.Uri;
import android.os.AsyncTask;
import android.provider.MediaStore;

import com.hw.videoprocessor.VideoProcessor;
import com.sangcomz.fishbun.MimeType;
import com.sangcomz.fishbun.bean.Media;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.UUID;

public class MediaCompress extends AsyncTask<Void, Void, ArrayList<HashMap>> {

    public interface MediaCompressListener {
        void mediaCompressDidFinish(ArrayList<HashMap> result);
    }

    private boolean thumb = false;
    private int quality = 80;
    private int maxHeight = 1024;
    private int maxWidth = 768;
    private List<Media> selectMedias = new ArrayList<>();
    private List<String> selectMediaIdentifiers = new ArrayList<>();
    private Context context;
    private MediaCompressListener listener;
    public void setListener(MediaCompressListener listener) {
        this.listener = listener;
    }

    public MediaCompress(boolean thumb, int quality, int maxHeight, int maxWidth, List<Media> selectMedias, List<String> selectMediaIdentifiers, Context context) {
        this.thumb = thumb;
        this.quality = quality;
        this.maxHeight = maxHeight;
        this.maxWidth = maxWidth;
        this.context = context;
        this.selectMediaIdentifiers = selectMediaIdentifiers;
        if (selectMediaIdentifiers != null && selectMediaIdentifiers.size() > 0) {
            for (String identify : selectMediaIdentifiers) {
                Cursor c = context.getContentResolver().query(Uri.parse(identify), null, null, null, null);
                if (c != null) {
                    try {
                        if (c.moveToFirst()) {
                            Media media = new Media();
                            String mimeType = c.getString(c.getColumnIndex(MediaStore.MediaColumns.MIME_TYPE));
                            String buckName = c.getString(c.getColumnIndex(MediaStore.Images.Media.BUCKET_DISPLAY_NAME));
                            String originPath = c.getString(c.getColumnIndex(MediaStore.Images.Media.DATA));
                            String originName = c.getString(c.getColumnIndex(MediaStore.Images.Media.DISPLAY_NAME));
                            String originWidth = c.getString(c.getColumnIndex(MediaStore.Images.Media.WIDTH));
                            String originHeight = c.getString(c.getColumnIndex(MediaStore.Images.Media.HEIGHT));
                            int imgId = c.getInt(c.getColumnIndex(MediaStore.MediaColumns._ID));
                            media.setBucketId("0");
                            media.setBucketName(buckName);
                            media.setOriginName(originName);
                            media.setOriginHeight(originHeight);
                            media.setOriginWidth(originWidth);
                            media.setOriginPath(originPath);
                            media.setIdentifier(identify);
                            media.setMimeType(mimeType);
                            media.setMediaId("" + imgId);
                            media.setFileType("image");
                            selectMedias.add(media);
                            c.close();
                        }
                    } catch (Exception e) {
                        e.printStackTrace();
                        c.close();
                    }
                }
            }
        }
        this.selectMedias = selectMedias;
    }

    @Override
    protected ArrayList<HashMap> doInBackground(Void... voids) {
        ArrayList<HashMap> result = new ArrayList<>();
        for (int i = 0; i < selectMedias.size(); i++) {
            Media media = selectMedias.get(i);
            if ("video".equals(media.getFileType())) {
                String uuid = UUID.randomUUID().toString();
                String videoName = uuid + ".mp4";
                String imgName = uuid + ".jpg";
                String cacheDir = context.getExternalCacheDir().getAbsolutePath() + "/multi_image_pick/thumb/";
                File tmpPicParentDir = new File(cacheDir);
                if (!tmpPicParentDir.exists()) {
                    tmpPicParentDir.mkdirs();
                }
                File tmpPic = new File(cacheDir + imgName);
                if (tmpPic.exists()) {
                    tmpPic.delete();
                }
                File tmpVideo = new File(cacheDir + videoName);
                if (tmpVideo.exists()) {
                    tmpVideo.delete();
                }
                HashMap picInfo = localVideoThumb(media, tmpPic.getAbsolutePath());
                media.setThumbnailHeight((String) picInfo.get("height"));
                media.setThumbnailWidth((String) picInfo.get("width"));
                media.setThumbnailName(imgName);
                media.setThumbnailPath(tmpPic.getAbsolutePath());
                try {
                    float width = Float.parseFloat(media.getThumbnailWidth());
                    float height = Float.parseFloat(media.getThumbnailHeight());
                    float scaleWidth = ((float) maxWidth / width);
                    float scaleHeight = ((float) maxHeight / height);
                    float scale = scaleWidth > scaleHeight ? scaleHeight : scaleWidth;
                    int outWidth = (int) (width * scale);
                    int outHeight = (int) (height * scale);
                    VideoProcessor.processor(context).input(Uri.parse(media.getIdentifier())).outHeight(outHeight).outWidth(outWidth).
                            output(tmpVideo.getAbsolutePath()).dropFrames(true).frameRate(30).bitrate(128000).process();
                    HashMap info = new HashMap();
                    info.put("identifier", media.getIdentifier());
                    info.put("filePath", tmpVideo.getAbsolutePath());
                    info.put("width", (float)outWidth);
                    info.put("height",(float)outHeight);
                    info.put("name", videoName);
                    info.put("fileType", "video");
                    info.put("thumbPath", media.getThumbnailPath());
                    info.put("thumbName", media.getThumbnailName());
                    info.put("thumbHeight", Float.parseFloat(media.getThumbnailHeight()));
                    info.put("thumbWidth", Float.parseFloat(media.getThumbnailWidth()));
                    result.add(info);
                } catch (Exception e) {
                    HashMap info = new HashMap();
                    info.put("error", media.toString());
                    result.add(info);
                    e.printStackTrace();
                }
            }else {
                result.add(fetchImageThumb(media, thumb, quality, maxHeight, maxWidth));
            }
        }
        return result;
    }

    private HashMap fetchImageThumb(Media media, boolean thumb, int quality, int maxHeight, int maxWidth) {
        HashMap<String, Object> map = new HashMap<>();
        String fileName = UUID.randomUUID().toString() + ".jpg";
        String filePath = "";
        Uri identify = Uri.parse(media.getIdentifier());
        try {
            InputStream is = context.getContentResolver().openInputStream(identify);
            File tmpPicParentDir = new File(context.getCacheDir().getAbsolutePath() + "/muti_image_pick/");
            if (!tmpPicParentDir.exists()) {
                tmpPicParentDir.mkdirs();
            }
            File tmpPic = new File(context.getCacheDir().getAbsolutePath() + "/muti_image_pick/" + fileName);
            if (tmpPic.exists()) {
                tmpPic.delete();
            }
            filePath = tmpPic.getAbsolutePath();
            HashMap hashMap = compressImage(is, tmpPic, thumb ? maxWidth : -1, thumb ? maxHeight : -1, thumb ? quality : 100);
            if (hashMap.containsKey("width") && hashMap.containsKey("height")) {
                map.put("width", hashMap.get("width"));
                map.put("height", hashMap.get("height"));
            }else {
                return map;
            }
        } catch (Exception e) {
            e.printStackTrace();
            return map;
        }

        map.put("name", fileName);
        map.put("filePath", filePath);
        map.put("identifier", media.getIdentifier());
        map.put("fileType", "image");
        return map;
    }

    private HashMap compressImage(InputStream fromFile, File toFile, int width, int height, int quality) {
        HashMap result = new HashMap();
        try {
            Bitmap bitmap = BitmapFactory.decodeStream(fromFile);
            int bitmapWidth = bitmap.getWidth();
            int bitmapHeight = bitmap.getHeight();

            float scaleWidth = -1 == width ? 1 : ((float) width / bitmapWidth);
            float scaleHeight = -1 == width ? 1 : ((float) height / bitmapHeight);
            float scale = scaleWidth > scaleHeight ? scaleHeight : scaleWidth;
            Matrix matrix = new Matrix();
            matrix.postScale(scale, scale);
            result.put("width", (bitmapWidth * scale));
            result.put("height", (bitmapHeight * scale));

            Bitmap resizeBitmap = Bitmap.createBitmap(bitmap, 0, 0, bitmapWidth, bitmapHeight, matrix, false);
            File myCaptureFile = toFile;
            if (myCaptureFile.exists()) myCaptureFile.delete();
            FileOutputStream out = new FileOutputStream(myCaptureFile);
            if(resizeBitmap.compress(Bitmap.CompressFormat.JPEG, quality, out)){
                out.flush();
                out.close();
            }
            if(!bitmap.isRecycled()){
                bitmap.recycle();//记得释放资源，否则会内存溢出
            }
            if(!resizeBitmap.isRecycled()){
                resizeBitmap.recycle();
            }
        } catch (FileNotFoundException e) {
            e.printStackTrace();
            result.clear();
        } catch (Exception ex) {
            ex.printStackTrace();
            result.clear();
        }
        return result;
    }

    public HashMap localVideoThumb(Media media, String savePath) {
        HashMap result = new HashMap();
        Bitmap bitmap = null;
        MediaMetadataRetriever retriever = new MediaMetadataRetriever();
        try {
            retriever.setDataSource(media.getOriginPath());
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
    protected void onPostExecute(ArrayList<HashMap> media) {
        super.onPostExecute(media);
        if (listener != null) {
            listener.mediaCompressDidFinish(media);
        }
    }
}
