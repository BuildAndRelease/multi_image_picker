package com.fanbook.multi_picker.meishe.media_select.adapter;

import android.view.ViewGroup;

import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentManager;
import androidx.fragment.app.FragmentPagerAdapter;

import java.util.List;

public class TabFragmentAdapter extends FragmentPagerAdapter {
    private final List<Fragment> mFragmentList;
    private final List<String> mTabTitle;

    public TabFragmentAdapter(FragmentManager fm, List<Fragment> fragmentList, List<String> tabTitle) {
        super(fm);
        this.mFragmentList=fragmentList;
        this.mTabTitle=tabTitle;
    }

    @Override
    public Fragment getItem(int position) {
        return mFragmentList.get(position);
    }

    @Override
    public int getCount() {
        return mFragmentList.size();
    }

    @Override
    public CharSequence getPageTitle(int position) {
        return mTabTitle.get(position % mTabTitle.size());
    }

    @Override
    public void destroyItem(ViewGroup container, int position, Object object) {
        super.destroyItem(container, position, object);
    }
}