package com.sangcomz.fishbun.ui.detail;

import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.Window;
import android.widget.Button;
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
import com.sangcomz.fishbun.util.RadioWithTextButton;

import org.jetbrains.annotations.NotNull;

import java.util.UUID;

public class DetailActivity extends BaseActivity implements View.OnClickListener, ViewPager.OnPageChangeListener, DetailViewPagerAdapter.OnVideoPlayActionListener {
    private static final String TAG = "DetailActivity";

    private int initPosition;
    private RadioWithTextButton btnDetailCount;
    private ViewPager vpDetailPager;
    private Button btnDetailBack;
    private VideoView currentPlayVideoView;

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
        btnDetailCount.unselect();
        btnDetailCount.setTextColor(fishton.getColorActionBarTitle());
        btnDetailCount.setCircleColor(fishton.getColorSelectCircleStroke());
        btnDetailCount.setStrokeColor(fishton.getColorDeSelectCircleStroke());
        btnDetailCount.setOnClickListener(this);
        btnDetailBack.setOnClickListener(this);
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
    }

    public void updateRadioButton(RadioWithTextButton v, String text) {
        if (fishton.getMaxCount() == 1)
            v.setDrawable(ContextCompat.getDrawable(v.getContext(), R.drawable.ic_done_white_24dp));
        else
            v.setText(text);
    }

    @Override
    public void onBackPressed() {
        finishActivity();
    }

    @Override
    public void onClick(View v) {
        if (fishton.getPickerMedias() == null) return;
        int id = v.getId();
        if (id == R.id.btn_detail_count) {
            Media media = fishton.getPickerMedias().get(vpDetailPager.getCurrentItem());
            if ("video".equals(media.getFileType()) && Integer.parseInt(media.getDuration()) > 60000) {
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
                Log.i(TAG,"---->onPageScrollStateChanged无动作");
                break;
            case ViewPager.SCROLL_STATE_DRAGGING:
                //点击、滑屏
                Log.i(TAG,"---->onPageScrollStateChanged点击、滑屏");
                if (currentPlayVideoView != null) {
                    currentPlayVideoView.performClick();
                }
                break;
            case ViewPager.SCROLL_STATE_SETTLING:
                //释放
                Log.i(TAG,"---->onPageScrollStateChanged释放");
                break;
        }
    }

    void finishActivity() {
        currentPlayVideoView = null;
        Intent i = new Intent();
        i.putExtra(Define.INTENT_SERIAL_NUM, UUID.randomUUID().toString());
        setResult(RESULT_OK, i);
        finish();
    }

    @Override
    public void onVideoDidPlayer(@NotNull VideoView videoView) {
        currentPlayVideoView = videoView;
    }
}
