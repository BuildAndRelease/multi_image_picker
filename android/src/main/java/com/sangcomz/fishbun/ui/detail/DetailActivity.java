package com.sangcomz.fishbun.ui.detail;

import android.content.Intent;
import android.graphics.drawable.Drawable;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.Window;
import android.widget.Button;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;
import android.widget.VideoView;

import androidx.core.content.ContextCompat;
import androidx.viewpager.widget.ViewPager;

import com.example.multi_image_picker.R;
import com.google.android.material.snackbar.Snackbar;
import com.sangcomz.fishbun.BaseActivity;
import com.sangcomz.fishbun.adapter.view.DetailViewPagerAdapter;
import com.sangcomz.fishbun.bean.Media;
import com.sangcomz.fishbun.define.Define;
import com.sangcomz.fishbun.util.MediaCompress;
import com.sangcomz.fishbun.util.RadioWithTextButton;

import org.jetbrains.annotations.NotNull;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.UUID;

public class DetailActivity extends BaseActivity implements View.OnClickListener, ViewPager.OnPageChangeListener, DetailViewPagerAdapter.OnVideoPlayActionListener, MediaCompress.MediaCompressListener {
    private static final String TAG = "DetailActivity";

    private int initPosition;
    private RadioWithTextButton btnDetailCount;
    private ViewPager vpDetailPager;
    private Button btnDetailBack;
    private VideoView currentPlayVideoView;
    private Button originBtn;
    private Button sendBtn;
    private RelativeLayout compressingView;
    private TextView compressingTextView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            getWindow().requestFeature(Window.FEATURE_CONTENT_TRANSITIONS);
        }
        setContentView(R.layout.activity_detail_actiivy);
        initValue();
        initView();
        initAdapter();
    }

    private void initValue() {
        Intent intent = getIntent();
        initPosition = intent.getIntExtra(Define.BUNDLE_NAME.POSITION.name(), -1);
    }

    private void initView() {
        btnDetailCount = findViewById(R.id.btn_detail_count);
        vpDetailPager = findViewById(R.id.vp_detail_pager);
        btnDetailBack = findViewById(R.id.btn_detail_back);
        originBtn = findViewById(R.id.photo_preview_origin_btn);
        sendBtn = findViewById(R.id.photo_preview_send_btn);
        compressingView = findViewById(R.id.compressing_content_view);
        compressingTextView = findViewById(R.id.compressing_text_view);
        btnDetailCount.unselect();
        btnDetailCount.setTextColor(fishton.getColorActionBarTitle());
        btnDetailCount.setCircleColor(fishton.getColorSelectCircleStroke());
        btnDetailCount.setStrokeColor(fishton.getColorDeSelectCircleStroke());
        btnDetailCount.setOnClickListener(this);
        btnDetailBack.setOnClickListener(this);
        originBtn.setOnClickListener(this);
        sendBtn.setOnClickListener(this);
        compressingView.setOnClickListener(this);
        originBtn.setSelected(!fishton.isThumb());
        Drawable drawable = getResources().getDrawable(fishton.isThumb() ?  R.drawable.radio_unchecked : R.drawable.radio_checked);
        drawable.setBounds(0, 0, drawable.getMinimumWidth(), drawable.getMinimumHeight());
        originBtn.setCompoundDrawables(drawable,null,null,null);
        updateSendBtnTitle();
    }

    private void initAdapter() {
        if (fishton.getPickerMedias() == null) {
            Toast.makeText(this, R.string.msg_error, Toast.LENGTH_SHORT).show();
            finish();
            return;
        }

        onCheckStateChange(fishton.getPickerMedias().get(initPosition));

        DetailViewPagerAdapter adapter = new DetailViewPagerAdapter((LayoutInflater) getSystemService(LAYOUT_INFLATER_SERVICE), fishton.getPickerMedias());
        adapter.setActionListener(this);
        vpDetailPager.setAdapter(adapter);
        vpDetailPager.setCurrentItem(initPosition);
        vpDetailPager.addOnPageChangeListener(this);
        vpDetailPager.setOffscreenPageLimit(5);
    }

    public void onCheckStateChange(Media media) {
        boolean isContained = fishton.getSelectedMedias().contains(media);
        if (isContained) {
            updateRadioButton(btnDetailCount, String.valueOf(fishton.getSelectedMedias().indexOf(media) + 1));
        } else {
            btnDetailCount.unselect();
        }
        updateSendBtnTitle();
    }

    public void updateRadioButton(RadioWithTextButton v, String text) {
        if (fishton.getMaxCount() == 1)
            v.setDrawable(ContextCompat.getDrawable(v.getContext(), R.drawable.ic_done_white_24dp));
        else
            v.setText(text);
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

    @Override
    protected void onDestroy() {
        super.onDestroy();
        Log.d(TAG, "onDestory");
    }

    @Override
    public void onBackPressed() {
        currentPlayVideoView = null;
        finish();
    }

    @Override
    public void onClick(View v) {
        if (fishton.getPickerMedias() == null) return;
        int id = v.getId();
        if (id == R.id.btn_detail_count) {
            Media media = fishton.getPickerMedias().get(vpDetailPager.getCurrentItem());
            if ("video".equals(media.getFileType()) && Integer.parseInt(media.getDuration()) > 60) {
                Toast.makeText(this, "视屏长度不能超过60秒", Toast.LENGTH_SHORT).show();
                return;
            }
            if (fishton.getSelectedMedias().contains(media)) {
                fishton.getSelectedMedias().remove(media);
                onCheckStateChange(media);
            } else {
                if (fishton.getSelectedMedias().size() == fishton.getMaxCount()) {
                    Snackbar.make(v, fishton.getMessageLimitReached(), Snackbar.LENGTH_SHORT).show();
                } else {
                    fishton.getSelectedMedias().add(media);
                    onCheckStateChange(media);
                }
            }
        } else if (id == R.id.btn_detail_back) {
            finishActivity();
        } else if (id == R.id.photo_preview_send_btn) {
            if (fishton.getSelectedMedias().size() < fishton.getMinCount()) {
                Toast.makeText(this, fishton.getMessageNothingSelected(), Toast.LENGTH_SHORT).show();
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
        } else if (id == R.id.photo_preview_origin_btn) {
            originBtn.setSelected(!originBtn.isSelected());
            Drawable drawable = getResources().getDrawable(originBtn.isSelected() ? R.drawable.radio_checked : R.drawable.radio_unchecked);
            drawable.setBounds(0, 0, drawable.getMinimumWidth(), drawable.getMinimumHeight());
            originBtn.setCompoundDrawables(drawable,null,null,null);
            fishton.setThumb(!originBtn.isSelected());
        }
    }

    @Override
    public void onPageScrolled(int position, float positionOffset, int positionOffsetPixels) {

    }

    @Override
    public void onPageSelected(int position) {
        if (fishton.getPickerMedias() != null){
            onCheckStateChange(fishton.getPickerMedias().get(position));
        }
    }

    @Override
    public void onPageScrollStateChanged(int state) {
        switch (state){
            case ViewPager.SCROLL_STATE_IDLE:
                break;
            case ViewPager.SCROLL_STATE_DRAGGING:
                if (currentPlayVideoView != null) {
                    currentPlayVideoView.performClick();
                }
                break;
            case ViewPager.SCROLL_STATE_SETTLING:
                break;
        }
    }

    void finishActivity() {
        currentPlayVideoView = null;
        Intent i = new Intent();
        setResult(RESULT_OK, i);
        finish();
    }

    @Override
    public void onVideoDidPlayer(@NotNull VideoView videoView) {
        currentPlayVideoView = videoView;
    }

    @Override
    public void mediaCompressDidFinish(ArrayList<HashMap> result) {
        compressingView.setVisibility(View.INVISIBLE);
        Intent i = new Intent();
        i.putExtra(Define.INTENT_RESULT, result);
        setResult(define.FINISH_DETAIL_REQUEST_CODE, i);
        finish();
    }
}
