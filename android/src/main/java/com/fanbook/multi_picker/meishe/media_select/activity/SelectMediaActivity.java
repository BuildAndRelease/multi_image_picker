package com.fanbook.multi_picker.meishe.media_select.activity;


import android.annotation.SuppressLint;
import android.os.Bundle;
import android.view.MenuItem;
import android.view.MotionEvent;
import android.view.View;

import androidx.viewpager.widget.ViewPager;

import com.example.multi_image_picker.R;
import com.fanbook.multi_picker.BaseActivity;
import com.fanbook.multi_picker.meishe.common.views.NoAnimationViewPager;
import com.fanbook.multi_picker.meishe.media_select.fragment.AlbumFragment;
import com.fanbook.multi_picker.meishe.media_select.fragment.TakePhotoFragment;
import com.fanbook.multi_picker.meishe.media_select.fragment.TakeVideoFragment;
import com.fanbook.multi_picker.meishe.media_select.adapter.MediaPagerAdapter;
import com.google.android.material.bottomnavigation.BottomNavigationView;

public class SelectMediaActivity extends BaseActivity {

    private MenuItem menuItem;

    private NoAnimationViewPager mediaActionViewPager;
    private BottomNavigationView mediaNavigationView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        overridePendingTransition(R.anim.slide_in_from_bottom, 0);
        setContentView(R.layout.activity_select_media);

//        ActivityUtils.StatusBarLightMode(this);
//        ActivityUtils.setStatusBarColor(this, R.color.common_color);//设置状态栏颜色
        initView();

    }

    @SuppressLint("ClickableViewAccessibility")
    private void initView() {
        mediaActionViewPager = findViewById(R.id.vp_select_media_action);
        mediaNavigationView = findViewById(R.id.navigation_media_action);

        //默认 >3 的选中效果会影响ViewPager的滑动切换时的效果，故利用反射去掉
//        BottomNavigationViewHelper.disableShiftMode(navigation);

        MediaPagerAdapter adapter = new MediaPagerAdapter(getSupportFragmentManager());

        adapter.addFragment(new AlbumFragment());
        adapter.addFragment(new TakePhotoFragment());
        adapter.addFragment(new TakeVideoFragment());
        mediaActionViewPager.setAdapter(adapter);
        mediaActionViewPager.setCurrentItem(0);

        //缓存3个页面，来解决点击“我的”回来，首页空白的问题，
        // 存在的问题，如果有的页面不需要缓存该如何自动刷新，可以利用eventbus传参来进行该页面的操作
        //viewpager.setOffscreenPageLimit(3);

        mediaNavigationView.setOnNavigationItemSelectedListener(new BottomNavigationView.OnNavigationItemSelectedListener() {
            @Override
            public boolean onNavigationItemSelected(MenuItem item) {

                int itemId = item.getItemId();
                if (itemId == R.id.action_album) {
                    mediaActionViewPager.setCurrentItem(0);
                    return true;
                } else if (itemId == R.id.action_take_photo) {
                    mediaActionViewPager.setCurrentItem(1);
                    return true;
                } else if (itemId == R.id.action_take_video) {
                    mediaActionViewPager.setCurrentItem(2);
                    return true;
                }
                return false;
            }
        });

        mediaActionViewPager.addOnPageChangeListener(new ViewPager.OnPageChangeListener() {
            @Override
            public void onPageScrolled(int position, float positionOffset, int positionOffsetPixels) {

            }

            @Override
            public void onPageSelected(int position) {
                if (menuItem != null) {
                    menuItem.setChecked(false);
                } else {
                    mediaNavigationView.getMenu().getItem(0).setChecked(false);
                }
                menuItem = mediaNavigationView.getMenu().getItem(position);
                menuItem.setChecked(true);
            }

            @Override
            public void onPageScrollStateChanged(int state) {
            }
        });

        mediaActionViewPager.setOnTouchListener(new View.OnTouchListener() {
            @Override
            public boolean onTouch(View v, MotionEvent event) {
                return true;
            }
        });

    }

    @Override
    public void finish() {
        super.finish();
        overridePendingTransition(0, R.anim.slide_out_from_bottom);
    }
}
