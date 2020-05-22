package com.sangcomz.fishbun.ui.picker;

import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.graphics.drawable.Drawable;
import android.media.MediaMetadataRetriever;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.PopupWindow;
import android.widget.RelativeLayout;
import android.widget.TextView;

import androidx.core.view.ViewCompat;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.example.multi_image_picker.R;
import com.google.android.material.snackbar.Snackbar;
import com.hw.videoprocessor.VideoProcessor;
import com.sangcomz.fishbun.BaseActivity;
import com.sangcomz.fishbun.adapter.view.PickerGridAdapter;
import com.sangcomz.fishbun.bean.Album;
import com.sangcomz.fishbun.bean.Media;
import com.sangcomz.fishbun.define.Define;
import com.sangcomz.fishbun.ui.album.AlbumPickerPopupCallBack;
import com.sangcomz.fishbun.util.RadioWithTextButton;
import com.sangcomz.fishbun.util.SquareFrameLayout;
import com.sangcomz.fishbun.ui.album.AlbumPickerPopup;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.UUID;


public class PickerActivity extends BaseActivity implements View.OnClickListener {
    private static final String TAG = "PickerActivity";

    private Button cancelBtn;
    private RelativeLayout moreContentView;
    private RelativeLayout toolBar;
    private ImageView moreArrowImageView;
    private TextView titleTextView;
    private Button originBtn;
    private Button sendBtn;
    private RecyclerView recyclerView;
    private PickerController pickerController;
    private RelativeLayout compressingView;
    private TextView compressingTextView;
    private Album album;
    private PickerGridAdapter adapter;
    private GridLayoutManager layoutManager;
    private AlbumPickerPopup middlePopup;

    @Override
    protected void onSaveInstanceState(Bundle outState) {
        try {
            outState.putParcelableArrayList(define.SAVE_INSTANCE_NEW_MEDIAS, pickerController.getAddImagePaths());
        } catch (Exception e) {
            Log.d(TAG, e.toString());
        }

        super.onSaveInstanceState(outState);
    }

    @Override
    protected void onRestoreInstanceState(Bundle outState) {
        super.onRestoreInstanceState(outState);
        try {
            ArrayList<Media> addMedias = outState.getParcelableArrayList(define.SAVE_INSTANCE_NEW_MEDIAS);
            setAdapter(fishton.getPickerMedias());
            if (addMedias != null) {
                pickerController.setAddImagePaths(addMedias);
            }
        } catch (Exception e) {
            Log.d(TAG, e.toString());
        }
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_photo_picker);
        initController();
        initValue();
        initView();
        pickerController.displayImage(album.bucketId, fishton.getExceptMimeTypeList(), fishton.getSpecifyFolderList());
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == define.ENTER_DETAIL_REQUEST_CODE && resultCode == RESULT_OK) {
            refreshThumb();
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String permissions[], int[] grantResults) {
        switch (requestCode) {
            case 28: {
                if (grantResults.length > 0) {
                    if (grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                        pickerController.displayImage(album.bucketId, fishton.getExceptMimeTypeList(), fishton.getSpecifyFolderList());
                    } else {
                        finish();
                    }
                }
                break;
            }
        }
    }

    @Override
    public void onClick(View v) {
        if (v != null) {
            if (v.equals(originBtn)) {
                originBtn.setSelected(!originBtn.isSelected());
                Drawable drawable= getResources().getDrawable(originBtn.isSelected() ? R.drawable.radio_checked : R.drawable.radio_unchecked);
                drawable.setBounds(0, 0, drawable.getMinimumWidth(), drawable.getMinimumHeight());
                originBtn.setCompoundDrawables(drawable,null,null,null);
            } else if (v.equals(sendBtn)){
                if (fishton.getSelectedMedias().size() < fishton.getMinCount()) {
                    Snackbar.make(recyclerView, fishton.getMessageNothingSelected(), Snackbar.LENGTH_SHORT).show();
                } else {
                    finishActivity();
                }
            } else if (v.equals(cancelBtn)) {
                finish();
            } else if (v.equals(moreContentView)) {
                ViewCompat.animate(moreArrowImageView).setDuration(300).rotationBy(180).start();
                middlePopup = new AlbumPickerPopup(PickerActivity.this);
                middlePopup.setCallBack(new AlbumPickerPopupCallBack() {
                    @Override
                    public void albumPickerPopupDidSelectAlbum(Album album, int position) {
                        PickerActivity.this.album = album;
                        pickerController.displayImage(album.bucketId, fishton.getExceptMimeTypeList(), fishton.getSpecifyFolderList());
                        titleTextView.setText(album.bucketName);
                    }
                });
                middlePopup.showAsDropDown(toolBar, 0, 0);
                middlePopup.setOnDismissListener(new PopupWindow.OnDismissListener() {
                    @Override
                    public void onDismiss() {
                        ViewCompat.animate(moreArrowImageView).setDuration(300).rotationBy(180).start();
                    }
                });
            }
        }
    }

    private void initValue() {
        Intent intent = getIntent();
        album = intent.getParcelableExtra(Define.BUNDLE_NAME.ALBUM.name());
    }

    private void initController() {
        pickerController = new PickerController(this);
    }

    private void initView() {
        layoutManager = new GridLayoutManager(this, fishton.getPhotoSpanCount(), RecyclerView.VERTICAL, false);
        recyclerView = findViewById(R.id.recycler_picker_list);
        recyclerView.setLayoutManager(layoutManager);

        compressingView = findViewById(R.id.compressing_content_view);
        compressingView.setOnClickListener(this);
        compressingTextView = findViewById(R.id.compressing_text_view);

        originBtn = findViewById(R.id.photo_picker_origin_btn);
        originBtn.setOnClickListener(this);

        sendBtn = findViewById(R.id.photo_picker_send_btn);
        sendBtn.setOnClickListener(this);
        updateSendBtnTitle();

        cancelBtn = findViewById(R.id.photo_picker_back_btn);
        cancelBtn.setOnClickListener(this);

        toolBar = findViewById(R.id.toolbar_picker_bar);

        moreContentView = findViewById(R.id.photo_picker_more_content_view);
        moreContentView.setOnClickListener(this);

        moreArrowImageView = findViewById(R.id.album_pick_down_arrow_image);

        titleTextView = findViewById(R.id.album_pick_title_text_view);
        titleTextView.setText(album.bucketName);
    }

    public void updateSendBtnTitle() {
        if (fishton.getSelectedMedias().size() > 0) {
            sendBtn.setEnabled(true);
            sendBtn.setText(getResources().getText(R.string.done) + "(" + fishton.getSelectedMedias().size() + "/" + fishton.getMaxCount() + ")");
        }else {
            sendBtn.setEnabled(false);
            sendBtn.setText(getResources().getText(R.string.done));
        }
    }

    public void setAdapter(List<Media> result) {
        fishton.setPickerMedias(result);
        if (adapter == null) {
            adapter = new PickerGridAdapter(pickerController);
            adapter.setActionListener(new PickerGridAdapter.OnPhotoActionListener() {
                @Override
                public void onDeselect() {
                    refreshThumb();
                }
            });
        }
        recyclerView.setAdapter(adapter);
        updateSendBtnTitle();
    }

    private void refreshThumb() {
        int firstVisible = layoutManager.findFirstVisibleItemPosition();
        int lastVisible = layoutManager.findLastVisibleItemPosition();
        for (int i = firstVisible; i <= lastVisible; i++) {
            View view = layoutManager.findViewByPosition(i);
            if (view instanceof SquareFrameLayout) {
                SquareFrameLayout item = (SquareFrameLayout) view;
                RadioWithTextButton btnThumbCount = item.findViewById(R.id.btn_thumb_count);
                ImageView imgThumbImage = item.findViewById(R.id.img_thumb_image);
                Media image = (Media) item.getTag();
                if (image != null) {
                    int index = fishton.getSelectedMedias().indexOf(image);
                    if (index != -1) {
                        adapter.updateRadioButton(imgThumbImage, btnThumbCount, String.valueOf(index + 1),true);
                    } else {
                        adapter.updateRadioButton(imgThumbImage, btnThumbCount, "", false);
                        updateSendBtnTitle();
                    }
                }
            }
        }
    }

    private HashMap compressImageAndFinish(Media media, boolean thumb, int quality, int maxHeight, int maxWidth) {
        HashMap<String, Object> map = new HashMap<>();
        String fileName = UUID.randomUUID().toString() + ".jpg";
        String filePath = "";
        Uri identify = Uri.parse(media.getIdentifier());
        try {
            InputStream is = getContentResolver().openInputStream(identify);
            File tmpPicParentDir = new File(getCacheDir().getAbsolutePath() + "/muti_image_pick/");
            if (!tmpPicParentDir.exists()) {
                tmpPicParentDir.mkdirs();
            }
            File tmpPic = new File(getCacheDir().getAbsolutePath() + "/muti_image_pick/" + fileName);
            if (tmpPic.exists()) {
                tmpPic.delete();
            }
            filePath = tmpPic.getAbsolutePath();
            HashMap hashMap = transImage(is, tmpPic, thumb ? maxWidth : -1, thumb ? maxHeight : -1, thumb ? quality : 100);
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

    public HashMap transImage(InputStream fromFile, File toFile, int width, int height, int quality) {
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

    public static HashMap getLocalVideoBitmap(Media media, String savePath) {
        HashMap result = new HashMap();
        Bitmap bitmap = null;
        MediaMetadataRetriever retriever = new MediaMetadataRetriever();
        try {
            retriever.setDataSource(media.getOriginPath());
            int duration = Integer.parseInt(media.getDuration());
            bitmap = retriever.getFrameAtTime(duration > 2000 ? 2000 * 1000 : duration * 1000 );
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

    public void finishActivity() {
        compressingView.setVisibility(View.VISIBLE);
        compressingTextView.setText(originBtn.isSelected() ? "拷贝中..." : "压缩中...");
        final boolean thumb = !originBtn.isSelected();
        final int quality = fishton.getQuality();
        final int maxHeight = fishton.getMaxHeight();
        final int maxWidth = fishton.getMaxWidth();
        new Thread(new Runnable() {
            @Override
            public void run() {
                final ArrayList<HashMap> result = new ArrayList<>();
                for (int i = 0; i < fishton.getSelectedMedias().size(); i++) {
                    Media media = fishton.getSelectedMedias().get(i);
                    if ("video".equals(media.getFileType())) {
                        String uuid = UUID.randomUUID().toString();
                        String videoName = uuid + ".mp4";
                        String imgName = uuid + ".jpg";
                        String cacheDir = getExternalCacheDir().getAbsolutePath() + "/multi_image_pick/thumb/";
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
                        HashMap picInfo = getLocalVideoBitmap(media, tmpPic.getAbsolutePath());
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
                            VideoProcessor.processor(PickerActivity.this).input(media.getOriginPath()).outHeight(outHeight).outWidth(outWidth).
                                    output(tmpVideo.getAbsolutePath()).dropFrames(true).frameRate(30).bitrate(32000).process();
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
                        result.add(compressImageAndFinish(media, thumb, quality, maxHeight, maxWidth));
                    }
                }
                if (Looper.myLooper() != Looper.getMainLooper()) {
                    Handler mainThread = new Handler(Looper.getMainLooper());
                    mainThread.post(new Runnable() {
                        @Override
                        public void run() {
                            compressingView.setVisibility(View.INVISIBLE);
                            Intent i = new Intent();
                            i.putExtra(Define.INTENT_SERIAL_NUM, UUID.randomUUID().toString());
                            i.putExtra(Define.INTENT_RESULT, result);
                            setResult(RESULT_OK, i);
                            finish();
                        }
                    });
                }
            }
        }).start();
    }

}
