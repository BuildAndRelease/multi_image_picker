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
import com.sangcomz.fishbun.ui.detail.DetailActivity;
import com.sangcomz.fishbun.util.EndlessRecyclerOnScrollListener;
import com.sangcomz.fishbun.util.MediaCompress;
import com.sangcomz.fishbun.util.RadioWithTextButton;
import com.sangcomz.fishbun.util.SquareFrameLayout;
import com.sangcomz.fishbun.ui.album.AlbumPickerPopup;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

public class PickerActivity extends BaseActivity implements View.OnClickListener, MediaCompress.MediaCompressListener {
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
        compressingView.setVisibility(View.VISIBLE);
        compressingTextView.setText("图片加载中...");
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == define.ENTER_DETAIL_REQUEST_CODE) {
            if (resultCode == RESULT_OK) {
                refreshThumb();
            }else if (resultCode == define.FINISH_DETAIL_REQUEST_CODE){
                ArrayList result = data.getParcelableArrayListExtra(Define.INTENT_RESULT);
                Intent i = new Intent();
                i.putExtra(Define.INTENT_RESULT, result);
                setResult(RESULT_OK, i);
                finish();
            }
        }
    }

    @Override
    public void onClick(View v) {
        if (v != null) {
            if (v.equals(originBtn)) {
                originBtn.setSelected(!originBtn.isSelected());
                Drawable drawable = getResources().getDrawable(originBtn.isSelected() ? R.drawable.radio_checked : R.drawable.radio_unchecked);
                drawable.setBounds(0, 0, drawable.getMinimumWidth(), drawable.getMinimumHeight());
                originBtn.setCompoundDrawables(drawable,null,null,null);
                fishton.setThumb(!originBtn.isSelected());
            } else if (v.equals(sendBtn)){
                if (fishton.getSelectedMedias().size() < fishton.getMinCount()) {
                    Snackbar.make(recyclerView, fishton.getMessageNothingSelected(), Snackbar.LENGTH_SHORT).show();
                } else {
                    compressingView.setVisibility(View.VISIBLE);
                    compressingTextView.setText(fishton.isThumb() ? "压缩中..." : "拷贝中...");
                    boolean thumb = fishton.isThumb();
                    int quality = fishton.getQuality();
                    int maxHeight = fishton.getMaxHeight();
                    int maxWidth = fishton.getMaxWidth();
                    List<Media> selectMedias = fishton.getSelectedMedias();
                    MediaCompress mediaCompress = new MediaCompress(thumb, quality, maxHeight, maxWidth, selectMedias, new ArrayList<String>(), this);
                    mediaCompress.setListener(this);
                    mediaCompress.execute();
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

    @Override
    protected void onDestroy() {
        super.onDestroy();
        Log.d(TAG, "onDestory");
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
        compressingView.setVisibility(View.INVISIBLE);
        fishton.setPickerMedias(result);
        if (adapter == null) {
            adapter = new PickerGridAdapter(pickerController);
            adapter.setActionListener(new PickerGridAdapter.OnPhotoActionListener() {
                @Override
                public void onDeselect() {
                    refreshThumb();
                }
            });
            recyclerView.setAdapter(adapter);
        }else {
            adapter.notifyDataSetChanged();
        }
        updateSendBtnTitle();
        if (fishton.getPreSelectedMedias().size() > 0) {
            Intent i = new Intent(this, DetailActivity.class);
            i.putExtra(Define.BUNDLE_NAME.POSITION.name(), fishton.mediaIndexOfFirstPreSelectMedia());
            startActivityForResult(i, new Define().ENTER_DETAIL_REQUEST_CODE);
            fishton.getPreSelectedMedias().clear();
        }
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

        originBtn.setSelected(!fishton.isThumb());
        Drawable drawable = getResources().getDrawable(fishton.isThumb() ?  R.drawable.radio_unchecked : R.drawable.radio_checked);
        drawable.setBounds(0, 0, drawable.getMinimumWidth(), drawable.getMinimumHeight());
        originBtn.setCompoundDrawables(drawable,null,null,null);
    }

    @Override
    public void mediaCompressDidFinish(ArrayList<HashMap> result) {
        compressingView.setVisibility(View.INVISIBLE);
        Intent i = new Intent();
        i.putExtra(Define.INTENT_RESULT, result);
        setResult(RESULT_OK, i);
        finish();
    }
}
