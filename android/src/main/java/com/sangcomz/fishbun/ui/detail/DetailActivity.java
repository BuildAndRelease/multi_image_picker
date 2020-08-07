package com.sangcomz.fishbun.ui.detail;

import android.content.Intent;
import android.graphics.Color;
import android.graphics.PorterDuff;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.GradientDrawable;
import android.os.Build;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.Window;
import android.widget.Button;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;
import android.widget.VideoView;

import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.ContextCompat;
import androidx.viewpager.widget.ViewPager;

import com.example.multi_image_picker.R;
import com.google.android.material.snackbar.Snackbar;
import com.sangcomz.fishbun.Fishton;
import com.sangcomz.fishbun.MimeType;
import com.sangcomz.fishbun.adapter.DetailViewPagerAdapter;
import com.sangcomz.fishbun.bean.Media;
import com.sangcomz.fishbun.util.Define;
import com.sangcomz.fishbun.util.DisplayImage;
import com.sangcomz.fishbun.util.MediaCompress;
import com.sangcomz.fishbun.util.RadioWithTextButton;
import com.sangcomz.fishbun.util.UiUtil;

import org.jetbrains.annotations.NotNull;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

public class DetailActivity extends AppCompatActivity implements View.OnClickListener, ViewPager.OnPageChangeListener, DetailViewPagerAdapter.OnVideoPlayActionListener, MediaCompress.MediaCompressListener {
    private static final String TAG = "DetailActivity";

    private int initPosition;
    private Fishton fishton;
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
        if (initPosition == -1) {
            ArrayList mimeTypeList = new ArrayList();
            mimeTypeList.add(MimeType.WEBP);
            DisplayImage displayImage = new DisplayImage((long) 0, null, mimeTypeList, this);
            displayImage.setListener(new DisplayImage.DisplayImageListener() {
                @Override
                public void OnDisplayImageDidSelectFinish(ArrayList medias) {
                    fishton.setPickerMedias(medias);
                    initPosition = fishton.mediaIndexOfFirstPreSelectMedia();
                    initAdapter();
                }
            });
            displayImage.execute();
        }else {
            initAdapter();
        }
    }

    private void initValue() {
        Intent intent = getIntent();
        initPosition = intent.getIntExtra(Define.BUNDLE_NAME.POSITION.name(), -1);
        fishton = Fishton.getInstance();
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
        btnDetailCount.setTextColor(Color.WHITE);
        btnDetailCount.setCircleColor(fishton.getColorSelectCircleStroke());
        btnDetailCount.setStrokeColor(fishton.getColorDeSelectCircleStroke());
        btnDetailCount.setOnClickListener(this);
        btnDetailBack.setOnClickListener(this);
        originBtn.setOnClickListener(this);
        sendBtn.setOnClickListener(this);
        compressingView.setOnClickListener(this);
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
            GradientDrawable drawable=new GradientDrawable();
            drawable.setShape(GradientDrawable.RECTANGLE);
            drawable.setGradientType(GradientDrawable.RADIAL_GRADIENT);
            drawable.setCornerRadius(5);
            drawable.setColor(fishton.getColorSelectCircleStroke());
            drawable.setAlpha(255);
            sendBtn.setEnabled(true);
            sendBtn.setBackground(drawable);
            sendBtn.setText(getResources().getText(R.string.done) + "(" + fishton.getSelectedMedias().size() + ")");
            sendBtn.setTextColor(Color.argb(255, 255, 255, 255));
        }else {
            GradientDrawable drawable=new GradientDrawable();
            drawable.setShape(GradientDrawable.RECTANGLE);
            drawable.setGradientType(GradientDrawable.RADIAL_GRADIENT);
            drawable.setCornerRadius(5);
            drawable.setColor(fishton.getColorSelectCircleStroke());
            drawable.setAlpha(125);
            sendBtn.setEnabled(false);
            sendBtn.setBackground(drawable);
            sendBtn.setText(getResources().getText(R.string.done));
            sendBtn.setTextColor(Color.argb(125, 255, 255, 255));
        }
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
            if (media.getFileType().contains("video") && Integer.parseInt(media.getDuration()) > 301) {
                Snackbar.make(btnDetailCount, "视屏长度不能超过5分钟", Snackbar.LENGTH_SHORT).show();
            } else if (media.getFileType().contains("image") && Float.parseFloat(media.getFileSize()) > 1024 * 1024 * 8) {
                Snackbar.make(btnDetailCount, "不能分享超过8M的文件", Snackbar.LENGTH_SHORT).show();
            } else if (fishton.getMaxCount() == fishton.getSelectedMedias().size() && !fishton.getSelectedMedias().contains(media)) {
                Snackbar.make(btnDetailCount, "选择数量超过最大限制", Snackbar.LENGTH_SHORT).show();
            } else {
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
            }
        } else if (id == R.id.btn_detail_back) {
            finishActivity();
        } else if (id == R.id.photo_preview_send_btn) {
            if (fishton.getSelectedMedias().size() < fishton.getMinCount()) {
                Toast.makeText(this, fishton.getMessageNothingSelected(), Toast.LENGTH_SHORT).show();
            } else {
//                compressingView.setVisibility(View.VISIBLE);
//                compressingTextView.setText(fishton.isThumb() ? "压缩中..." : "处理中...");
                boolean thumb = fishton.isThumb();
                List<Media> selectMedias = fishton.getSelectedMedias();
//                MediaCompress mediaCompress = new MediaCompress(thumb, selectMedias, new ArrayList<String>(), this);
//                mediaCompress.setListener(this);
//                mediaCompress.execute();
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
        } else if (id == R.id.photo_preview_origin_btn) {
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
    public void onVideoDidPlayer(@NotNull VideoView videoView) {
        currentPlayVideoView = videoView;
    }

    @Override
    public void mediaCompressDidFinish(ArrayList<HashMap> result) {
        compressingView.setVisibility(View.INVISIBLE);
        Intent i = new Intent();
        i.putExtra(Define.INTENT_RESULT, result);
        setResult(Define.FINISH_DETAIL_RESULT_CODE, i);
        finish();
    }
}
