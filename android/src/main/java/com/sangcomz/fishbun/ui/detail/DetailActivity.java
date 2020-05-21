package com.sangcomz.fishbun.ui.detail;

import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.Window;
import android.widget.Button;
import android.widget.Toast;

import androidx.core.content.ContextCompat;
import androidx.viewpager.widget.ViewPager;

import com.example.multi_image_picker.R;
import com.google.android.material.snackbar.Snackbar;
import com.sangcomz.fishbun.BaseActivity;
import com.sangcomz.fishbun.adapter.view.DetailViewPagerAdapter;
import com.sangcomz.fishbun.bean.Media;
import com.sangcomz.fishbun.define.Define;
import com.sangcomz.fishbun.util.RadioWithTextButton;

import java.util.UUID;

public class DetailActivity extends BaseActivity implements View.OnClickListener, ViewPager.OnPageChangeListener {
    private static final String TAG = "DetailActivity";

    private int initPosition;
    private RadioWithTextButton btnDetailCount;
    private ViewPager vpDetailPager;
    private Button btnDetailBack;

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
        vpDetailPager.setAdapter(adapter);
        vpDetailPager.setCurrentItem(initPosition);
        vpDetailPager.addOnPageChangeListener(this);
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

    }

    void finishActivity() {
        Intent i = new Intent();
        i.putExtra(Define.INTENT_SERIAL_NUM, UUID.randomUUID().toString());
        setResult(RESULT_OK, i);
        finish();
    }
}
