package com.fanbook.multi_picker.meishe.media_select.fragment;


import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentActivity;

import com.example.multi_image_picker.R;


/**
 * 我的
 */
public class TakeVideoFragment extends Fragment implements View.OnClickListener {

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {

        View view = inflater.inflate(R.layout.fragment_action_take_video, container, false);
        initViews(view);
        return view;
    }

    private void initViews(View view) {
        view.findViewById(R.id.btn_close).setOnClickListener(this);
    }

    @Override
    public void onClick(View view) {
        FragmentActivity currentActivity = getActivity();
        if (currentActivity == null) return;
        if (view.getId() == R.id.btn_close) {
            currentActivity.finish();
        }
    }
}
