package com.sangcomz.fishbun.ui.camera;

import android.content.ContentValues;
import android.content.Intent;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.provider.MediaStore;
import android.view.View;
import android.view.Window;

import androidx.appcompat.app.AppCompatActivity;

import com.cjt2325.cameralibrary.JCameraView;
import com.cjt2325.cameralibrary.listener.ClickListener;
import com.cjt2325.cameralibrary.listener.ErrorListener;
import com.cjt2325.cameralibrary.listener.JCameraListener;
import com.example.multi_image_picker.R;
import com.sangcomz.fishbun.util.Define;

import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.HashMap;

public class CameraActivity extends AppCompatActivity {
    private JCameraView jCameraView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            getWindow().requestFeature(Window.FEATURE_CONTENT_TRANSITIONS);
        }
        setContentView(R.layout.activity_camera);

        int themeColor = 0xFF00CC00;
        try {
            themeColor = getIntent().getIntExtra("themeColor",0xFF00CC00);
        } catch (Exception e) {
            e.printStackTrace();
        }

        jCameraView = (JCameraView) findViewById(R.id.jcameraview);
        jCameraView.setSaveVideoPath(getCacheDir().getAbsolutePath() + "/multi_image_pick/thumb");
        jCameraView.setFeatures(JCameraView.BUTTON_STATE_BOTH);
        jCameraView.setThemeColor(themeColor);
        jCameraView.setTip("轻触拍照，长按摄像");
        jCameraView.setMediaQuality(JCameraView.MEDIA_QUALITY_MIDDLE);
        jCameraView.setErrorLisenter(new ErrorListener() {
            @Override
            public void onError() {
                Intent intent = new Intent();
                setResult(103, intent);
                finish();
            }

            @Override
            public void AudioPermissionError() {
                Intent intent = new Intent();
                setResult(104, intent);
                finish();
            }
        });
        jCameraView.setJCameraLisenter(new JCameraListener() {
            @Override
            public void captureSuccess(Bitmap bitmap) {
                HashMap map = new HashMap();
                map.put("width", (float)bitmap.getWidth());
                map.put("height", (float)bitmap.getHeight());
                String path = saveBitmap(getCacheDir().getAbsolutePath() + "/multi_image_pick/thumb/", bitmap);
                String fileName = "image";
                try {
                    String[] pathSplits = path.split("/");
                    fileName = pathSplits[pathSplits.length - 1];
                }catch (Exception e) {
                    e.printStackTrace();
                }
                map.put("identifier", path);
                map.put("filePath", path);
                map.put("name", fileName);
                map.put("fileType", "image/jpg");
                MediaStore.Images.Media.insertImage(getContentResolver(), bitmap, fileName, fileName);
                Intent intent = new Intent();
                intent.putExtra(Define.INTENT_RESULT, map);
                setResult(Define.ENTER_TAKE_RESULT_CODE, intent);
                finish();
            }

            @Override
            public void recordSuccess(String url, Bitmap firstFrame, float duration) {
                HashMap map = new HashMap();
                map.put("width", (float)firstFrame.getHeight());
                map.put("height", (float)firstFrame.getWidth());
                map.put("identifier", url);
                map.put("filePath", url);
                map.put("name", url);
                map.put("duration", duration);
                map.put("fileType", "video/mp4");

                String path = saveBitmap(getCacheDir().getAbsolutePath() + "/multi_image_pick/thumb/", firstFrame);
                map.put("thumbPath", path);
                map.put("thumbName", path);
                map.put("thumbHeight", (float)firstFrame.getHeight());
                map.put("thumbWidth", (float)firstFrame.getWidth());

                saveVideo(new File(url));

                Intent intent = new Intent();
                intent.putExtra(Define.INTENT_RESULT, map);
                setResult(Define.ENTER_TAKE_RESULT_CODE, intent);
                finish();
            }
        });

        jCameraView.setLeftClickListener(new ClickListener() {
            @Override
            public void onClick() {
                CameraActivity.this.finish();
            }
        });
    }

    @Override
    protected void onStart() {
        super.onStart();
        //全屏显示
        if (Build.VERSION.SDK_INT >= 19) {
            View decorView = getWindow().getDecorView();
            decorView.setSystemUiVisibility(
                    View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                            | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                            | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                            | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                            | View.SYSTEM_UI_FLAG_FULLSCREEN
                            | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);
        } else {
            View decorView = getWindow().getDecorView();
            int option = View.SYSTEM_UI_FLAG_FULLSCREEN;
            decorView.setSystemUiVisibility(option);
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        jCameraView.onResume();
    }

    @Override
    protected void onPause() {
        super.onPause();
        jCameraView.onPause();
    }

    public String saveVideo(File f) {
        ContentValues values = new ContentValues(2);
        values.put(MediaStore.Video.Media.MIME_TYPE, "video/mp4");
        Uri uri = getContentResolver().insert(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, values);

        try {
            InputStream is = new FileInputStream(f);
            OutputStream os = getContentResolver().openOutputStream(uri);
            byte[] buffer = new byte[4096]; // tweaking this number may increase performance
            int len;
            while ((len = is.read(buffer)) != -1){
                os.write(buffer, 0, len);
            }
            os.flush();
            is.close();
            os.close();
        } catch (Exception e) {
            e.printStackTrace();
        }

        sendBroadcast(new Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE, uri));
        return uri.toString();
    }

    public String saveBitmap(String dir, Bitmap b) {
        long dataTake = System.currentTimeMillis();
        String jpegName = dir + "picture_" + dataTake + ".jpg";
        try {
            File directory = new File(dir);
            if (!directory.exists()) {
                directory.mkdirs();
            }
            FileOutputStream fout = new FileOutputStream(jpegName);
            BufferedOutputStream bos = new BufferedOutputStream(fout);
            b.compress(Bitmap.CompressFormat.JPEG, 100, bos);
            bos.flush();
            bos.close();
            return jpegName;
        } catch (Exception e) {
            e.printStackTrace();
            return "";
        }
    }
}
