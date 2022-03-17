package com.fanbook.multi_picker.meishe.media_select.fragment;


import android.content.Intent;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentActivity;
import androidx.viewpager.widget.ViewPager;

import com.example.multi_image_picker.R;
import com.fanbook.multi_picker.meishe.media_edit.EditVideoActivity;
import com.fanbook.multi_picker.meishe.media_select.adapter.TabFragmentAdapter;
import com.google.android.material.tabs.TabLayout;

import java.util.ArrayList;
import java.util.List;

public class AlbumFragment extends Fragment implements View.OnClickListener {

    private TabLayout mediaCategoryTabLayout;
    private ViewPager mediaCategoryViewPager;

    private List<Fragment> mFragmentArrays = new ArrayList<>();
    private List<String> mTabs = new ArrayList<>();
    private View albumView;

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        albumView = inflater.inflate(R.layout.fragment_action_album, container, false);
        initView(albumView, inflater);
        return albumView;
    }

    private void initView(View albumView, LayoutInflater inflater) {
        albumView.findViewById(R.id.btn_close).setOnClickListener(this);
        albumView.findViewById(R.id.btn_test_next).setOnClickListener(this);

        mediaCategoryTabLayout = albumView.findViewById(R.id.tl_media_category);
        mediaCategoryViewPager = albumView.findViewById(R.id.vp_media_category);
        mediaCategoryTabLayout.removeAllTabs();
        mediaCategoryViewPager.removeAllViews();
        if (mFragmentArrays != null) {
            mFragmentArrays.clear();
            mTabs.clear();
        }
        mTabs.add("全部");
        mTabs.add("视频");
        mTabs.add("图片");

        mFragmentArrays.add(new AlbumAllFragment());
        mFragmentArrays.add(new AlbumVideoFragment());
        mFragmentArrays.add(new AlbumPhotoFragment());


        mediaCategoryViewPager.setAdapter(new TabFragmentAdapter(getFragmentManager(), mFragmentArrays, mTabs));
        mediaCategoryTabLayout.setupWithViewPager(mediaCategoryViewPager);
        for (int i = 0; i < mTabs.size(); i++) {
            View view = inflater.inflate(R.layout.album_category_tab_item, null);
            TextView title = view.findViewById(R.id.tab_title);
            title.setText(mTabs.get(i));
            mediaCategoryTabLayout.getTabAt(i).setCustomView(view);
        }
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
    }

    @Override
    public void onClick(View view) {
        FragmentActivity currentActivity = getActivity();
        if (currentActivity == null) return;
        if (view.getId() == R.id.btn_close) {
            currentActivity.finish();
        } else if (view.getId() == R.id.btn_test_next) {
            startActivity(new Intent(currentActivity, EditVideoActivity.class));
        }
    }
}
