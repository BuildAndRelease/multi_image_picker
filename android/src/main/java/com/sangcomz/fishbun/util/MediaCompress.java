package com.sangcomz.fishbun.util;

import android.content.Context;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.media.MediaMetadataRetriever;
import android.net.Uri;
import android.os.Handler;
import android.os.Looper;
import android.provider.MediaStore;

import com.hw.videoprocessor.VideoProcessor;
import com.sangcomz.fishbun.bean.Media;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.UUID;

import top.zibin.luban.Luban;

public class MediaCompress {

    public interface MediaCompressListener {
        void mediaCompressDidFinish(ArrayList<HashMap> result);
    }

    private boolean thumb = false;
    private List<Media> selectMedias = new ArrayList<>();
    private Context context;
    private MediaCompressListener listener;
    public void setListener(MediaCompressListener listener) {
        this.listener = listener;
    }

    public MediaCompress(boolean thumb, List<String> selectMediaIdentifiers, Context context) {
        this.thumb = thumb;
        this.context = context;
        if (selectMediaIdentifiers != null && selectMediaIdentifiers.size() > 0) {
            for (String identify : selectMediaIdentifiers) {
                Uri uri = MediaStore.Files.getContentUri("external");
                String selection = MediaStore.Files.FileColumns._ID + "=" + identify;
                Cursor c = context.getContentResolver().query(uri, null, selection, null, null);
                if (c != null) {
                    try {
                        if (c.moveToFirst()) {
                            Media media = new Media();
                            String mimeType = c.getString(c.getColumnIndex(MediaStore.MediaColumns.MIME_TYPE));
                            String buckName = c.getString(c.getColumnIndex(MediaStore.MediaColumns.BUCKET_DISPLAY_NAME));
                            String originPath = c.getString(c.getColumnIndex(MediaStore.MediaColumns.DATA));
                            String originName = c.getString(c.getColumnIndex(MediaStore.MediaColumns.DISPLAY_NAME));
                            String fileSize = c.getString(c.getColumnIndex(MediaStore.MediaColumns.SIZE));
                            String modifyTimeStamp = c.getString(c.getColumnIndex(MediaStore.MediaColumns.DATE_MODIFIED));
                            double originWidth = c.getFloat(c.getColumnIndex(MediaStore.MediaColumns.WIDTH));
                            double originHeight = c.getFloat(c.getColumnIndex(MediaStore.MediaColumns.HEIGHT));
                            String duration = "0";
                            if (mimeType.contains("video")) {
                                duration = c.getString(c.getColumnIndex(MediaStore.MediaColumns.DURATION));
                            }
                            int imgId = c.getInt(c.getColumnIndex(MediaStore.MediaColumns._ID));
                            media.setBucketId("0");
                            media.setBucketName(buckName);
                            media.setOriginName(originName);
                            media.setOriginHeight(originHeight + "");
                            media.setOriginWidth(originWidth + "");
                            media.setOriginPath(originPath);
                            media.setIdentifier(identify);
                            media.setFileSize(fileSize);
                            media.setModifyTimeStamp(modifyTimeStamp);
                            try {
                                media.setDuration(Long.parseLong(duration)/1000 + "");
                            } catch (Exception e) {
                                media.setDuration("0");
                            }
                            media.setMimeType(mimeType);
                            media.setMediaId("" + imgId);
                            media.setFileType(mimeType);
                            selectMedias.add(media);
                        }
                    } catch (Exception e) {
                        e.printStackTrace();
                    }finally {
                        c.close();
                    }
                }
            }
        }
    }

    public void execute() {
        new Thread(new Runnable() {
            @Override
            public void run() {
                final ArrayList<HashMap> result = new ArrayList<>();
                for (int i = 0; i < selectMedias.size(); i++) {
                    Media media = selectMedias.get(i);
                    if (media.getFileType().contains("video")) {
                        String uuid = media.getIdentifier() + "-" + media.getModifyTimeStamp();
                        String videoName = uuid + ".mp4";
                        String imgName = uuid + ".jpg";
                        String cacheDir = context.getCacheDir().getAbsolutePath() + "/multi_image_pick/thumb/";
                        File targetParentDir = new File(cacheDir);
                        if (!targetParentDir.exists()) {
                            targetParentDir.mkdirs();
                        }
                        File targetPic = new File(cacheDir + imgName);
                        if (targetPic.exists()) {
                            BitmapFactory.Options options = new BitmapFactory.Options();
                            options.inJustDecodeBounds = true;
                            BitmapFactory.decodeFile(targetPic.getAbsolutePath(), options);
                            media.setThumbnailHeight(options.outHeight + "");
                            media.setThumbnailWidth(options.outWidth + "");
                            media.setThumbnailName(imgName);
                            media.setThumbnailPath(targetPic.getAbsolutePath());
                        }else {
                            File tmpPic = new File(cacheDir + imgName + "." + UUID.randomUUID().toString());
                            HashMap picInfo = localVideoThumb(media, tmpPic.getAbsolutePath());
                            tmpPic.renameTo(targetPic);
                            media.setThumbnailHeight((String) picInfo.get("height"));
                            media.setThumbnailWidth((String) picInfo.get("width"));
                            media.setThumbnailName(imgName);
                            media.setThumbnailPath(targetPic.getAbsolutePath());
                        }
                        File targetVideo = new File(cacheDir + videoName);
                        float width = Float.parseFloat(media.getThumbnailWidth());
                        float height = Float.parseFloat(media.getThumbnailHeight());
                        if (!targetVideo.exists()) {
                            File tmpVideo = new File(cacheDir + videoName + "." + UUID.randomUUID().toString());
                            try {
                                VideoProcessor.processor(context).input(media.getOriginPath()).output(tmpVideo.getAbsolutePath()).dropFrames(true).frameRate(30).bitrate(2048000).process();
                                tmpVideo.renameTo(targetVideo);
                            } catch (Exception e) {
                                e.printStackTrace();
                                break;
                            }
                        }
                        HashMap info = new HashMap();
                        info.put("identifier", media.getIdentifier());
                        info.put("filePath", targetVideo.getAbsolutePath());
                        info.put("width", width);
                        info.put("height",height);
                        info.put("name", videoName);
                        info.put("fileType", "video/mp4");
                        info.put("duration", Float.parseFloat(media.getDuration()));
                        info.put("thumbPath", media.getThumbnailPath());
                        info.put("thumbName", media.getThumbnailName());
                        info.put("thumbHeight", Float.parseFloat(media.getThumbnailHeight()));
                        info.put("thumbWidth", Float.parseFloat(media.getThumbnailWidth()));
                        result.add(info);
                    }else {
                        result.add(fetchImageThumb(media, thumb));
                    }
                }

                if (Looper.myLooper() != Looper.getMainLooper()) {
                    Handler mainThread = new Handler(Looper.getMainLooper());
                    mainThread.post(new Runnable() {
                        @Override
                        public void run() {
                            if (listener != null) {
                                listener.mediaCompressDidFinish(result);
                            }
                        }
                    });
                }else {
                    if (listener != null) {
                        listener.mediaCompressDidFinish(result);
                    }
                }
            }
        }).start();
    }

    private HashMap fetchImageThumb(Media media, boolean thumb) {
        String cacheDir = context.getCacheDir().getAbsolutePath();
        String thumbPath = cacheDir + "/multi_image_pick/thumb/";
        if (media.getFileType().contains("gif") || media.getOriginPath().endsWith("gif")) {
            int fileSize = 0;
            try {
                fileSize = Integer.parseInt(media.getFileSize());
            } catch (Exception e) {
                e.printStackTrace();
            }
            if (fileSize > 8 * 1024 * 1024) {
                HashMap<String, Object> map = new HashMap<>();
                map.put("identifier", media.getIdentifier());
                return map;
            } else {
                String fileName = media.getIdentifier() + "-" + media.getModifyTimeStamp() + ".gif";
                String filePath = "";
                try {
                    InputStream is = new FileInputStream(media.getOriginPath());
                    File targetParentDir = new File(thumbPath);
                    if (!targetParentDir.exists()) {
                        targetParentDir.mkdirs();
                    }
                    File targetPic = new File(thumbPath + fileName);
                    File tmpPic = new File(thumbPath + fileName + "." + UUID.randomUUID().toString());
                    filePath = targetPic.getAbsolutePath();
                    if (!tmpPic.exists()) {
                        FileOutputStream os = new FileOutputStream(tmpPic);
                        int bytesRead = 0;
                        byte[] buffer = new byte[8192];
                        while ((bytesRead = is.read(buffer, 0, 8192)) != -1) {
                            os.write(buffer, 0, bytesRead);
                        }
                        os.close();
                        is.close();
                        tmpPic.renameTo(targetPic);
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                }

                HashMap<String, Object> map = new HashMap<>();
                map.put("width", Float.parseFloat(media.getOriginWidth()));
                map.put("height", Float.parseFloat(media.getOriginHeight()));
                map.put("name", fileName);
                map.put("filePath", filePath);
                map.put("checkPath", filePath);
                map.put("identifier", media.getIdentifier());
                map.put("fileType", "image/gif");
                return map;
            }
        }else {
            HashMap<String, Object> map = new HashMap<>();
            String fileName = media.getIdentifier() + "-" + media.getModifyTimeStamp() + "-" + (thumb ? "thumb" : "origin") + ".jpg";
            String filePath = "";
            try {
                File targetParentDir = new File(thumbPath);
                if (!targetParentDir.exists()) {
                    targetParentDir.mkdirs();
                }
                File targetPic = new File(thumbPath + fileName);
                File checkPic = new File(thumbPath + fileName + ".check");
                filePath = targetPic.getAbsolutePath();
                File compressPicFile = null;
                if (targetPic.exists()) {
                    compressPicFile = targetPic;
                }else {
                    if (thumb) {
                        List<File> compressPicFiles = Luban.with(context).load(media.getOriginPath()).ignoreBy(300).get();
                        if (compressPicFiles != null && !compressPicFiles.isEmpty()) {
                            compressPicFile = compressPicFiles.get(0);
                        }
                    }else {
                        File tmpPic = new File(thumbPath + fileName + "." + UUID.randomUUID().toString());
                        compressPicFile = compressImage(new File(media.getOriginPath()), tmpPic, -1, -1, 100);
                    }
                }

                if (compressPicFile != null) {
                    BitmapFactory.Options options = new BitmapFactory.Options();
                    options.inJustDecodeBounds = true;
                    BitmapFactory.decodeFile(targetPic.getAbsolutePath(), options);
                    float imageHeight = options.outHeight;
                    float imageWidth = options.outWidth;

                    if (compressPicFile.exists() && imageHeight * imageWidth > 312*312 && !checkPic.exists()) {
                        compressImage(compressPicFile, checkPic, 312, 312, 100);
                    }else {
                        checkPic = compressPicFile;
                    }

                    if (compressPicFile.getAbsolutePath().startsWith(cacheDir)) {
                        compressPicFile.renameTo(targetPic);
                    }else {
                        copyFile(compressPicFile, targetPic);
                    }
                    long fileSize = targetPic.length();
                    if (thumb) {
                        if (fileSize > 8 * 1024 * 1024) {
                            map.put("identifier", media.getIdentifier());
                            return map;
                        }else {
                            map.put("width", imageWidth);
                            map.put("height", imageHeight);
                        }
                    }else {
                        if (fileSize > 8 * 1024 * 1024) {
                            map.put("identifier", media.getIdentifier());
                            return map;
                        }else {
                            map.put("width", imageWidth);
                            map.put("height", imageHeight);
                        }
                    }
                    map.put("checkPath", checkPic.getAbsolutePath());
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
            map.put("fileType", "image/jpeg");
            return map;
        }
    }
    /**
     * 复制单个文件
     *
     * @param oldFile String 原文件路径+文件名 如：data/user/0/com.test/files/abc.txt
     * @param newFile String 复制后路径+文件名 如：data/user/0/com.test/cache/abc.txt
     * @return <code>true</code> if and only if the file was copied;
     * <code>false</code> otherwise
     */
    public boolean copyFile(File oldFile, File newFile) {
        try {
            if (!oldFile.exists()) {
                return false;
            } else if (!oldFile.isFile()) {
                return false;
            } else if (!oldFile.canRead()) {
                return false;
            }

            FileInputStream fileInputStream = new FileInputStream(oldFile);    //读入原文件
            FileOutputStream fileOutputStream = new FileOutputStream(newFile);
            byte[] buffer = new byte[1024];
            int byteRead;
            while ((byteRead = fileInputStream.read(buffer)) != -1) {
                fileOutputStream.write(buffer, 0, byteRead);
            }
            fileInputStream.close();
            fileOutputStream.flush();
            fileOutputStream.close();
            return true;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    private File compressImage(File fromFile, File toFile, double width, double height, int quality) {
        try {
            InputStream is = new FileInputStream(fromFile);
            Bitmap bitmap = BitmapFactory.decodeStream(is);
            int bitmapWidth = bitmap.getWidth();
            int bitmapHeight = bitmap.getHeight();

            float scaleWidth = -1 == width ? 1 : ((float) width / bitmapWidth);
            float scaleHeight = -1 == height ? 1 : ((float) height / bitmapHeight);
            float scale = scaleWidth > scaleHeight ? scaleHeight : scaleWidth;
            Matrix matrix = new Matrix();
            matrix.postScale(scale, scale);

            Bitmap resizeBitmap = Bitmap.createBitmap(bitmap, 0, 0, bitmapWidth, bitmapHeight, matrix, false);
            if (toFile.exists()) toFile.delete();
            FileOutputStream out = new FileOutputStream(toFile);
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
            is.close();
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        } catch (Exception ex) {
            ex.printStackTrace();
        }
        return toFile;
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

}
