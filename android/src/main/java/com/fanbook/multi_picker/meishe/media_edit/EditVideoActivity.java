package com.fanbook.multi_picker.meishe.media_edit;


import android.os.Bundle;
import android.view.View;
import android.widget.Toast;

import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.example.multi_image_picker.R;
import com.fanbook.multi_picker.BaseActivity;
import com.fanbook.multi_picker.meishe.media_edit.adapter.EditVideoOptionsAdapter;
import com.fanbook.multi_picker.meishe.media_edit.interfaces.OnItemClickListener;

public class EditVideoActivity extends BaseActivity implements View.OnClickListener {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_edit_media);
        initViews();
    }

    private void initViews() {
        findViewById(R.id.btn_back).setOnClickListener(this);
        RecyclerView recyclerView = findViewById(R.id.rv_edit_options);
        recyclerView.setLayoutManager(new LinearLayoutManager(this, RecyclerView.HORIZONTAL, false));
        EditVideoOptionsAdapter optionsAdapter = new EditVideoOptionsAdapter(this);
        recyclerView.setAdapter(optionsAdapter);
        optionsAdapter.setOnItemClickListener(new OnItemClickListener() {
            @Override
            public void onItemClick(View view, int position) {
                Toast.makeText(EditVideoActivity.this, "click:" + position, Toast.LENGTH_LONG).show();
            }
        });

    }

    @Override
    public void onClick(View view) {
        if (view.getId() == R.id.btn_back) {
            finish();
        }
    }
}