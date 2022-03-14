package com.sangcomz.fishbun.util;

import android.content.Context;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.media.ExifInterface;
import android.media.MediaMetadataRetriever;
import android.net.Uri;
import android.os.Handler;
import android.os.Looper;
import android.provider.MediaStore;
import android.text.TextUtils;
import android.util.Pair;
import android.util.Size;

import com.hw.videoprocessor.VideoProcessor;
import com.nemocdz.imagecompress.ImageCompress;
import com.sangcomz.fishbun.bean.Media;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.UUID;

import top.zibin.luban.Luban;

public class MediaCompress {

    public enum Quality {
        VERY_HIGH, HIGH, MEDIUM, LOW, VERY_LOW
    }

    public interface MediaCompressListener {
        void mediaCompressDidFinish(ArrayList<HashMap> result);
    }
    private static int MinVideoBitRate = 2 * 1024 * 1024;
    private static int MinVideoHeight = 640;
    private static int MinVideoWidth = 360;
    private static int MAXPixel = 20000000;
    private boolean thumb = false;
    private List<Media> selectMedias = new ArrayList<>();
    private Context context;
    private MediaCompressListener listener;
    public void setListener(MediaCompressListener listener) {
        this.listener = listener;
    }

    public MediaCompress(boolean thumb, List<String> mediaPaths, String fileType, Context context) {
        this.thumb = thumb;
        this.context = context;
        for (String mediaPath : mediaPaths) {
            Media media = new Media();
            media.setOriginPath(mediaPath);
            media.setFileType(fileType);
            media.setIdentifier("");
            media.setModifyTimeStamp(System.currentTimeMillis() + "");
            selectMedias.add(media);
        }
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
                        result.add(fetchVideoThumb(media));
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

    private HashMap fetchVideoThumb(Media media) {
        String uuid = media.getIdentifier() + "-" + media.getModifyTimeStamp();
        String videoName = uuid + ".mp4";
        String imgName = uuid + ".jpg";
        String cacheDir = context.getCacheDir().getAbsolutePath() + "/multi_image_pick/thumb/";
        File targetParentDir = new File(cacheDir);
        if (!targetParentDir.exists()) {
            targetParentDir.mkdirs();
        }
        File targetPic = new File(cacheDir + imgName);
        File targetVideo = new File(cacheDir + videoName);
        float width = Float.parseFloat(media.getThumbnailWidth());
        float height = Float.parseFloat(media.getThumbnailHeight());
        if (!targetVideo.exists()) {
            File tmpVideo = new File(cacheDir + videoName + "." + UUID.randomUUID().toString());
            try {
                Pair<Integer, Size> pair = getBitrateAndSize(media.getOriginPath());
                Integer compressBitrate = getBitrate(pair.first, Quality.LOW);
                Size compressSize = generateWidthAndHeight(pair.second.getWidth(), pair.second.getHeight());
                if (compressBitrate.intValue() == pair.first.intValue()) {
                    copyFile(new File(media.getOriginPath()), tmpVideo);
                }else {
                    VideoProcessor.processor(context).input(media.getOriginPath()).
                            output(tmpVideo.getAbsolutePath()).dropFrames(true).frameRate(30).
                            outHeight(compressSize.getHeight()).outWidth(compressSize.getWidth()).
                            changeAudioSpeed(false).iFrameInterval(1).
                            bitrate(compressBitrate).process();
                }
                if (tmpVideo.exists()) {
                    moveFile(tmpVideo, targetVideo);
                }else {
                    HashMap info = new HashMap();
                    info.put("identifier", media.getIdentifier());
                    info.put("errorCode", "1");
                    return info;
                }
            } catch (Exception e) {
                e.printStackTrace();
                HashMap info = new HashMap();
                info.put("identifier", media.getIdentifier());
                info.put("errorCode", "1");
                return info;
            }
        }
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
            HashMap picInfo = localVideoThumb(targetVideo.getAbsolutePath(), tmpPic.getAbsolutePath());
            moveFile(tmpPic, targetPic);
            media.setThumbnailHeight((String) picInfo.get("height"));
            media.setThumbnailWidth((String) picInfo.get("width"));
            media.setThumbnailName(imgName);
            media.setThumbnailPath(targetPic.getAbsolutePath());
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
        return info;
    }

    private Size generateWidthAndHeight(int width, int height){
        int newWidth = MinVideoWidth;
        int newHeight = MinVideoHeight;

        if (width >= 1920 || height >= 1920) {
            newWidth = (int)((width * 0.5) / 16) * 16;
            newHeight = (int)((height * 0.5) / 16f) * 16;
        }else if (width >= 1280 || height >= 1280) {
            newWidth = (int)((width * 0.75) / 16) * 16;
            newHeight = (int)((height * 0.75) / 16) * 16;
        }else if (width >= 960 || height >= 960) {
            newWidth = (int)((width * 0.85) / 16) * 16;
            newHeight = (int)((height * 0.85) / 16) * 16;
        }else {
            newWidth = (int)((width * 0.90) / 16) * 16;
            newHeight = (int)((height * 0.90) / 16) * 16;
        }
        return new Size(newWidth, newHeight);
    }

    private Pair<Integer, Size> getBitrateAndSize(String path){
        int bitrate = MinVideoBitRate;
        int width = MinVideoWidth;
        int height = MinVideoHeight;
        MediaMetadataRetriever retriever = new MediaMetadataRetriever();
        try {
            retriever.setDataSource(path);
            height = Integer.parseInt(retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT));
            width = Integer.parseInt(retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH));
            bitrate = Integer.parseInt(retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_BITRATE));
        }catch (Exception e) {
            e.printStackTrace();
        } finally {
            retriever.release();
        }

        return new Pair<>(bitrate, new Size(width, height));
    }

    private int getBitrate(int bitrate, Quality quality){
        if (bitrate <= MinVideoBitRate)
            return bitrate;
        int result = MinVideoBitRate;
        switch (quality) {
            case VERY_LOW: result = (int) (bitrate * 0.08); break;
            case LOW : result = (int) (bitrate * 0.10); break;
            case MEDIUM : result = (int) (bitrate * 0.20); break;
            case HIGH : result = (int) (bitrate * 0.30); break;
            case VERY_HIGH : result = (int) (bitrate * 0.50); break;
            default:
                return MinVideoBitRate;
        }
        return Math.max(MinVideoBitRate, result);
    }

    private HashMap fetchImageThumb(Media media, boolean thumb) {
        long fileSize = 0;
        try {
            fileSize = Long.parseLong(media.getFileSize());
        } catch (Exception e) {
            try {
                fileSize = new File(media.getOriginPath()).length();
            } catch (Exception e1) {
                e1.printStackTrace();
            }
        }

        String cacheDir = context.getCacheDir().getAbsolutePath();
        String thumbPath = cacheDir + "/multi_image_pick/thumb/";
        if (media.getFileType().toLowerCase().contains("gif") || media.getOriginPath().toLowerCase().endsWith("gif")) {
            String fileName = media.getIdentifier() + "-" + media.getModifyTimeStamp() + ".gif";
            String checkFileName = media.getIdentifier() + "-" + media.getModifyTimeStamp() + "-check.gif";
            String filePath = "";
            String checkPath = "";
            try {
                File targetParentDir = new File(thumbPath);
                if (!targetParentDir.exists()) {
                    targetParentDir.mkdirs();
                }
                File targetPic = new File(thumbPath + fileName);
                File checkPic = new File(thumbPath + checkFileName);
                filePath = targetPic.getAbsolutePath();
                checkPath = checkPic.getAbsolutePath();
                if (!targetPic.exists() && !checkPic.exists()) {
                    File tmpPic = new File(thumbPath + fileName + "." + UUID.randomUUID().toString());
                    byte[] fileByteArray = fileToFileByteArray(media.getOriginPath());
                    byte[] resultFileByteArray = ImageCompress.INSTANCE.compressGifDataWithSampleCount(context, fileByteArray, 1);
                    if (tmpPic.exists()) tmpPic.delete();
                    tmpPic.createNewFile();
                    //如果压缩之后图片反而大了，使用原图
                    if(resultFileByteArray.length > fileByteArray.length){
                        fileByteArrayToFile(tmpPic.getAbsolutePath(), fileByteArray);
                    }else{
                        fileByteArrayToFile(tmpPic.getAbsolutePath(), resultFileByteArray);
                    }

                    byte[] checkFileByteArray = ImageCompress.INSTANCE.compressGifDataWithSampleCount(context, fileByteArray, 24);
                    if (checkPic.exists()) checkPic.delete();
                    checkPic.createNewFile();
                    fileByteArrayToFile(checkPic.getAbsolutePath(), checkFileByteArray);

                    if (targetPic.exists()) targetPic.delete();
                    moveFile(tmpPic, targetPic);
                }
            } catch (Exception e) {
                e.printStackTrace();
                HashMap<String, Object> map = new HashMap<>();
                map.put("identifier", media.getIdentifier());
                map.put("errorCode", "1");
                return map;
            }

            BitmapFactory.Options options = new BitmapFactory.Options();
            options.inJustDecodeBounds = true;
            BitmapFactory.decodeFile(filePath, options);
            float imageHeight = options.outHeight;
            float imageWidth = options.outWidth;
            HashMap<String, Object> map = new HashMap<>();
            map.put("width", imageWidth);
            map.put("height", imageHeight);
            map.put("name", fileName);
            map.put("filePath", filePath);
            map.put("checkPath", checkPath);
            map.put("identifier", media.getIdentifier());
            map.put("fileType", "image/gif");
            return map;
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
                    File tmpPic = new File(thumbPath + fileName + "." + UUID.randomUUID().toString());
                    BitmapFactory.Options options = new BitmapFactory.Options();
                    options.inJustDecodeBounds = true;
                    BitmapFactory.decodeFile(media.getOriginPath(), options);
                    float imageHeight = options.outHeight;
                    float imageWidth = options.outWidth;
                    float pixel = imageHeight * imageWidth;
                    if (pixel > MAXPixel) {
                        imageHeight = MAXPixel / pixel * imageHeight;
                        imageWidth = MAXPixel / pixel * imageWidth;
                    }
                    if (thumb) {
                        if (fileSize > 30 * 1024 * 1024 || fileSize <= 300 * 1024 || pixel > MAXPixel) {
                            compressPicFile = compressImage(new File(media.getOriginPath()), tmpPic, imageWidth, imageHeight, 80);
                        }else {
                            List<File> compressPicFiles = Luban.with(context).load(media.getOriginPath()).ignoreBy(300).get();
                            if (compressPicFiles != null && !compressPicFiles.isEmpty()) {
                                compressPicFile = compressPicFiles.get(0);
                            }
                        }
                    }else {
                        compressPicFile = compressImage(new File(media.getOriginPath()), tmpPic, imageWidth, imageHeight, 80);
                    }
                }

                if (compressPicFile != null) {
                    BitmapFactory.Options options = new BitmapFactory.Options();
                    options.inJustDecodeBounds = true;
                    BitmapFactory.decodeFile(compressPicFile.getAbsolutePath(), options);
                    float imageHeight = options.outHeight;
                    float imageWidth = options.outWidth;

                    if (!checkPic.exists()) {
                        if (compressPicFile.exists() && imageHeight * imageWidth > 312*312) {
                            compressImage(compressPicFile, checkPic, 312, 312, 100);
                        }else {
                            copyFile(compressPicFile, checkPic);
                        }
                    }

                    if (media.getOriginPath().equals(compressPicFile.getAbsolutePath())) {
                        copyFile(compressPicFile, targetPic);
                    }else {
                        moveFile(compressPicFile, targetPic);
                    }
                    map.put("width", imageWidth);
                    map.put("height", imageHeight);
                    map.put("checkPath", checkPic.getAbsolutePath());
                }else {
                    map.put("identifier", media.getIdentifier());
                    map.put("errorCode", "1");
                    return map;
                }
            } catch (Exception e) {
                e.printStackTrace();
                map.put("identifier", media.getIdentifier());
                map.put("errorCode", "1");
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
            //如果目标文件存在，就不移动
            if(newFile.exists()) return true;
            if(oldFile.getAbsolutePath().equalsIgnoreCase(newFile.getAbsolutePath())) return true;

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

    public void moveFile(File oldFile, File newFile) {
        //可能存在oldFile和newFile就是同一个文件，不操作
        if(oldFile.getAbsolutePath().equalsIgnoreCase(newFile.getAbsolutePath())) return;

        //如果目标文件存在，就不移动并且删除老文件
        if(newFile.exists()) {
            oldFile.delete();
            return;
        }

        if (!oldFile.renameTo(newFile)) {
            copyFile(oldFile, newFile);
            oldFile.delete();
        }
    }

    public boolean fileByteArrayToFile(String filePath, byte[] byteArray) {
        try{
            BufferedOutputStream bos = new BufferedOutputStream(new FileOutputStream(filePath));
            bos.write(byteArray);
            bos.flush();
            bos.close();
            return true;
        }catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public byte[] fileToFileByteArray(String filePath) {
        File file = new File(filePath);
        int size = (int) file.length();
        byte[] bytes = new byte[size];
        try {
            BufferedInputStream buf = new BufferedInputStream(new FileInputStream(file));
            buf.read(bytes, 0, bytes.length);
            buf.close();
        } catch (FileNotFoundException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        } catch (IOException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
        return bytes;
    }

    private File compressImage(File fromFile, File toFile, double width, double height, int quality) throws Exception {
        if (!fromFile.exists()) return toFile;
        BitmapFactory.Options opts = new BitmapFactory.Options();
        opts.inJustDecodeBounds = false;
        opts.inPreferredConfig = Bitmap.Config.ARGB_8888;
        Bitmap bitmap = BitmapFactory.decodeFile(fromFile.getAbsolutePath(), opts);
        if (bitmap == null) {
            opts.inPreferredConfig = Bitmap.Config.RGB_565;
            bitmap = BitmapFactory.decodeFile(fromFile.getAbsolutePath(), opts);
        }
        if (bitmap == null) {
            opts.inPreferredConfig = Bitmap.Config.ARGB_4444;
            bitmap = BitmapFactory.decodeFile(fromFile.getAbsolutePath(), opts);
        }

        try {
            ExifInterface ei = new ExifInterface(fromFile.getAbsolutePath());
            int orientation = ei.getAttributeInt(ExifInterface.TAG_ORIENTATION,
                    ExifInterface.ORIENTATION_UNDEFINED);
            switch(orientation) {
                case ExifInterface.ORIENTATION_ROTATE_90:
                    bitmap = rotateImage(bitmap, 90);
                    break;
                case ExifInterface.ORIENTATION_ROTATE_180:
                    bitmap = rotateImage(bitmap, 180);
                    break;
                case ExifInterface.ORIENTATION_ROTATE_270:
                    bitmap = rotateImage(bitmap, 270);
                    break;
                case ExifInterface.ORIENTATION_NORMAL:
                default:
                    break;
            }
        }catch (Exception e) {
            e.printStackTrace();
        }

        int bitmapWidth = bitmap.getWidth();
        int bitmapHeight = bitmap.getHeight();

        Bitmap resizeBitmap;
        if ((-1 == width && -1 == height) || (height >= bitmapHeight && width >= bitmapWidth)) {
            resizeBitmap = bitmap;
        }else {
            float scaleWidth = -1 == width ? 1 : ((float) width / bitmapWidth);
            float scaleHeight = -1 == height ? 1 : ((float) height / bitmapHeight);
            float scale = scaleWidth > scaleHeight ? scaleHeight : scaleWidth;
            Matrix matrix = new Matrix();
            matrix.postScale(scale, scale);
            resizeBitmap = Bitmap.createBitmap(bitmap, 0, 0, bitmapWidth, bitmapHeight, matrix, false);
            if(!bitmap.isRecycled()) bitmap.recycle();
        }

        if (toFile.exists()) toFile.delete();

        FileOutputStream out = new FileOutputStream(toFile);
        try {
            resizeBitmap.compress((!TextUtils.isEmpty(opts.outMimeType) && opts.outMimeType.toLowerCase().contains("png")) ? Bitmap.CompressFormat.PNG : Bitmap.CompressFormat.JPEG, quality, out);
        }catch (Exception e) {
            e.printStackTrace();
            toFile.delete();
        } finally {
            out.flush();
            out.close();
        }
//        处理图片原图大小不超过32MB、宽高不超过30000像素且总像素不超过2.5亿像素，
//        处理结果图宽高设置不超过9999像素；针对动图，原图宽 x 高 x 帧数不超过2.5亿像素
        if (!toFile.canRead() && fromFile.length() < 32 * 1024 * 1024) {
            copyFile(fromFile, toFile);
        }
        if(resizeBitmap != null && !resizeBitmap.isRecycled()) resizeBitmap.recycle();

        return toFile;
    }

    public Bitmap rotateImage(Bitmap source, float angle) {
        Matrix matrix = new Matrix();
        matrix.postRotate(angle);
        return Bitmap.createBitmap(source, 0, 0, source.getWidth(), source.getHeight(),
                matrix, true);
    }

    public HashMap localVideoThumb(String videoPath, String savePath) {
        HashMap result = new HashMap();
        Bitmap bitmap = null;
        MediaMetadataRetriever retriever = new MediaMetadataRetriever();
        try {
            retriever.setDataSource(videoPath);
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
