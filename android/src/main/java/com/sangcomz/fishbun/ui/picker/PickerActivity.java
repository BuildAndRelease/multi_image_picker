package com.sangcomz.fishbun.ui.picker;

import android.content.Intent;
import android.graphics.Color;
import android.graphics.PorterDuff;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.GradientDrawable;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.view.Window;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.PopupWindow;
import android.widget.RelativeLayout;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;
import androidx.core.view.ViewCompat;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.example.multi_image_picker.R;
import com.google.android.material.snackbar.Snackbar;
import com.sangcomz.fishbun.Fishton;
import com.sangcomz.fishbun.adapter.PickerGridAdapter;
import com.sangcomz.fishbun.bean.Album;
import com.sangcomz.fishbun.bean.Media;
import com.sangcomz.fishbun.util.Define;
import com.sangcomz.fishbun.ui.album.AlbumPickerPopup;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

public class PickerActivity extends AppCompatActivity implements View.OnClickListener {
    private static final String TAG = "PickerActivity";
    private Fishton fishton;
    private Album album;

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

    @Override
    protected void onSaveInstanceState(Bundle outState) {
        try {
            outState.putParcelableArrayList(Define.SAVE_INSTANCE_NEW_MEDIAS, pickerController.getAddImagePaths());
        } catch (Exception e) {
            Log.d(TAG, e.toString());
        }

        super.onSaveInstanceState(outState);
    }

    @Override
    protected void onRestoreInstanceState(Bundle outState) {
        super.onRestoreInstanceState(outState);
        try {
            ArrayList<Media> addMedias = outState.getParcelableArrayList(Define.SAVE_INSTANCE_NEW_MEDIAS);
            updatePhotoAlbumMedia(fishton.getPickerMedias());
            if (addMedias != null) {
                pickerController.setAddImagePaths(addMedias);
            }
        } catch (Exception e) {
            Log.d(TAG, e.toString());
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            getWindow().requestFeature(Window.FEATURE_CONTENT_TRANSITIONS);
        }
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_photo_picker);
        initController();
        initValue();
        initView();
        pickerController.displayImage(album.bucketId, fishton.getShowMediaType());
        compressingView.setVisibility(View.VISIBLE);
        compressingTextView.setText("图片加载中...");
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == Define.ENTER_DETAIL_RESULT_CODE) {
            if (resultCode == RESULT_CANCELED) {
                updateSendBtnTitle();
                recyclerView.getAdapter().notifyDataSetChanged();
                originBtn.setSelected(!fishton.isThumb());
                Drawable drawable;
                if (fishton.isThumb()) {
                    drawable = getResources().getDrawable(R.drawable.ic_baseline_radio_button_unchecked_24);
                }else {
                    drawable = getResources().getDrawable(R.drawable.ic_baseline_radio_button_checked_24);
                    drawable.setColorFilter(fishton.getColorSelectCircleStroke(), PorterDuff.Mode.SRC_IN);
                }
                drawable.setBounds(0, 0, drawable.getMinimumWidth(), drawable.getMinimumHeight());
                originBtn.setCompoundDrawables(drawable,null,null,null);
            }else if (resultCode == Define.FINISH_DETAIL_RESULT_CODE){
                Serializable result = data.getSerializableExtra(Define.INTENT_RESULT);
                Intent i = new Intent();
                i.putExtra(Define.INTENT_RESULT, result);
                setResult(RESULT_OK, i);
                finish();
            }
        }
    }

    @Override
    public void onBackPressed() {
        List<Media> selectMedias = fishton.getSelectedMedias();
        ArrayList<HashMap<String, String>> selectMediaInfos = new ArrayList<>();
        for (Media media : selectMedias) {
            HashMap<String, String> mediaInfo = new HashMap<>();
            mediaInfo.put("identify", media.getIdentifier());
            mediaInfo.put("fileType", media.getFileType());
            selectMediaInfos.add(mediaInfo);
        }
        Intent i = new Intent();
        i.putExtra(Define.INTENT_RESULT, selectMediaInfos);
        i.putExtra(Define.INTENT_THUMB, fishton.isThumb());
        setResult(RESULT_CANCELED, i);
        finish();
    }

    @Override
    public void onClick(View v) {
        if (v != null) {
            if (v.equals(originBtn)) {
                originBtn.setSelected(!originBtn.isSelected());
                Drawable drawable;
                if (originBtn.isSelected()) {
                    drawable = getResources().getDrawable(R.drawable.ic_baseline_radio_button_checked_24);
                    drawable.setColorFilter(fishton.getColorSelectCircleStroke(), PorterDuff.Mode.SRC_IN);
                }else {
                    drawable = getResources().getDrawable(R.drawable.ic_baseline_radio_button_unchecked_24);
                }
                drawable.setBounds(0, 0, drawable.getMinimumWidth(), drawable.getMinimumHeight());
                originBtn.setCompoundDrawables(drawable,null,null,null);
                fishton.setThumb(!originBtn.isSelected());
            } else if (v.equals(sendBtn)){
                if (fishton.getSelectedMedias().size() < 1) {
                    Snackbar.make(recyclerView, fishton.getMessageNothingSelected(), Snackbar.LENGTH_SHORT).show();
                } else {
                    boolean thumb = fishton.isThumb();
                    List<Media> selectMedias = fishton.getSelectedMedias();
                    List<String> identifiers = new ArrayList<>();
                    for (int i = 0; i < selectMedias.size(); i++) {
                        identifiers.add(selectMedias.get(i).getIdentifier());
                    }
                    HashMap result = new HashMap();
                    result.put("identifiers", identifiers);
                    result.put("thumb", thumb);
                    Intent i = new Intent();
                    i.putExtra(Define.INTENT_RESULT, result);
                    setResult(Define.FINISH_DETAIL_RESULT_CODE, i);
                    finish();
                }
            } else if (v.equals(cancelBtn)) {
                List<Media> selectMedias = fishton.getSelectedMedias();
                ArrayList<HashMap<String, String>> selectMediaInfos = new ArrayList<>();
                for (Media media : selectMedias) {
                    HashMap<String, String> mediaInfo = new HashMap<>();
                    mediaInfo.put("identify", media.getIdentifier());
                    mediaInfo.put("fileType", media.getFileType());
                    selectMediaInfos.add(mediaInfo);
                }
                Intent i = new Intent();
                i.putExtra(Define.INTENT_RESULT, selectMediaInfos);
                i.putExtra(Define.INTENT_THUMB, fishton.isThumb());
                setResult(RESULT_CANCELED, i);
                finish();
            } else if (v.equals(moreContentView)) {
                ViewCompat.animate(moreArrowImageView).setDuration(300).rotationBy(180).start();
                AlbumPickerPopup middlePopup = new AlbumPickerPopup(PickerActivity.this);
                middlePopup.setCallBack(new AlbumPickerPopup.AlbumPickerPopupCallBack() {
                    @Override
                    public void albumPickerPopupDidSelectAlbum(Album album, int position) {
                        PickerActivity.this.album = album;
                        pickerController.displayImage(album.bucketId, fishton.getShowMediaType());
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
        fishton = Fishton.getInstance();
    }

    private void initController() {
        pickerController = new PickerController(this);
    }

    private void initView() {
        GridLayoutManager layoutManager = new GridLayoutManager(this, 4, RecyclerView.VERTICAL, false);
        recyclerView = findViewById(R.id.recycler_picker_list);
        recyclerView.setLayoutManager(layoutManager);

        compressingView = findViewById(R.id.compressing_content_view);
        compressingView.setOnClickListener(this);
        compressingTextView = findViewById(R.id.compressing_text_view);

        originBtn = findViewById(R.id.photo_picker_origin_btn);
        originBtn.setVisibility(fishton.getHiddenThumb() ? View.INVISIBLE : View.VISIBLE);
        Drawable drawable;
        if (fishton.isThumb()) {
            drawable = getResources().getDrawable(R.drawable.ic_baseline_radio_button_unchecked_24);
        }else {
            drawable = getResources().getDrawable(R.drawable.ic_baseline_radio_button_checked_24);
            drawable.setColorFilter(fishton.getColorSelectCircleStroke(), PorterDuff.Mode.SRC_IN);
        }
        drawable.setBounds(0, 0, drawable.getMinimumWidth(), drawable.getMinimumHeight());
        originBtn.setCompoundDrawables(drawable,null,null,null);
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
            GradientDrawable drawable=new GradientDrawable();
            drawable.setShape(GradientDrawable.RECTANGLE);
            drawable.setGradientType(GradientDrawable.RADIAL_GRADIENT);
            drawable.setCornerRadius(8);
            drawable.setColor(fishton.getColorSelectCircleStroke());
            drawable.setAlpha(255);
            sendBtn.setEnabled(true);
            sendBtn.setBackground(drawable);
            sendBtn.setText(fishton.getDoneButtonText().isEmpty() ? getResources().getText(R.string.done) : fishton.getDoneButtonText() + "(" + fishton.getSelectedMedias().size() + ")");
            sendBtn.setTextColor(Color.argb(255, 255, 255, 255));
        }else {
            GradientDrawable drawable=new GradientDrawable();
            drawable.setShape(GradientDrawable.RECTANGLE);
            drawable.setGradientType(GradientDrawable.RADIAL_GRADIENT);
            drawable.setCornerRadius(8);
            drawable.setColor(fishton.getColorSelectCircleStroke());
            drawable.setAlpha(125);
            sendBtn.setEnabled(false);
            sendBtn.setBackground(drawable);
            sendBtn.setText(fishton.getDoneButtonText().isEmpty() ? getResources().getText(R.string.done) : fishton.getDoneButtonText());
            sendBtn.setTextColor(Color.argb(125, 255, 255, 255));
        }
    }

    public void updatePhotoAlbumMedia(List<Media> result) {
        compressingView.setVisibility(View.INVISIBLE);
        fishton.setPickerMedias(result);
        PickerGridAdapter adapter = new PickerGridAdapter(pickerController);
        recyclerView.setAdapter(adapter);
        recyclerView.scrollToPosition(adapter.getItemCount()-1);
        updateSendBtnTitle();
    }
}
