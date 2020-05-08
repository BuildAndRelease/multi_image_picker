package com.sangcomz.fishbun.ui.picker;

import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.res.ColorStateList;
import android.graphics.drawable.Drawable;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.text.SpannableString;
import android.text.style.ForegroundColorSpan;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.RadioButton;
import android.widget.RelativeLayout;

import androidx.annotation.RequiresApi;
import androidx.appcompat.app.ActionBar;
import androidx.appcompat.widget.Toolbar;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.google.android.material.snackbar.Snackbar;
import com.sangcomz.fishbun.BaseActivity;
import com.sangcomz.fishbun.R;
import com.sangcomz.fishbun.adapter.view.PickerGridAdapter;
import com.sangcomz.fishbun.bean.Album;
import com.sangcomz.fishbun.define.Define;
import com.sangcomz.fishbun.permission.PermissionCheck;
import com.sangcomz.fishbun.util.RadioWithTextButton;
import com.sangcomz.fishbun.util.SingleMediaScanner;
import com.sangcomz.fishbun.util.SquareFrameLayout;
import com.sangcomz.fishbun.util.UiUtil;

import java.io.File;
import java.util.ArrayList;
import java.util.List;


public class PickerActivity extends BaseActivity implements View.OnClickListener {

    private static final String TAG = "PickerActivity";

    private Button cancelBtn;
    private RelativeLayout moreContentView;
    private ImageView moreArrowImageView;
    private Button originBtn;
    private Button sendBtn;
    private RecyclerView recyclerView;
    private PickerController pickerController;
    private Album album;
    private int position;
    private PickerGridAdapter adapter;
    private GridLayoutManager layoutManager;

    private void initValue() {
        Intent intent = getIntent();
        album = intent.getParcelableExtra(Define.BUNDLE_NAME.ALBUM.name());
        position = intent.getIntExtra(Define.BUNDLE_NAME.POSITION.name(), -1);
    }

    @Override
    protected void onSaveInstanceState(Bundle outState) {
        try {
            outState.putString(define.SAVE_INSTANCE_SAVED_IMAGE, pickerController.getSavePath());
            outState.putParcelableArrayList(define.SAVE_INSTANCE_NEW_IMAGES, pickerController.getAddImagePaths());
        } catch (Exception e) {
            Log.d(TAG, e.toString());
        }

        super.onSaveInstanceState(outState);
    }

    @Override
    protected void onRestoreInstanceState(Bundle outState) {
        super.onRestoreInstanceState(outState);
        try {
            ArrayList<Uri> addImages = outState.getParcelableArrayList(define.SAVE_INSTANCE_NEW_IMAGES);
            String savedImage = outState.getString(define.SAVE_INSTANCE_SAVED_IMAGE);
            setAdapter(fishton.getPickerImages());
            if (addImages != null) {
                pickerController.setAddImagePaths(addImages);
            }
            if (savedImage != null) {
                pickerController.setSavePath(savedImage);
            }
        } catch (Exception e) {
            Log.d(TAG, e.toString());
        }
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_photo_picker);
        initController();
        initValue();
        initView();
        if (pickerController.checkPermission())
            pickerController.displayImage(album.bucketId, fishton.getExceptMimeTypeList(), fishton.getSpecifyFolderList());
    }

    @Override
    public void onBackPressed() {
        transImageFinish(position);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == define.TAKE_A_PICK_REQUEST_CODE) {
            if (resultCode == RESULT_OK) {
                File savedFile = new File(pickerController.getSavePath());
                new SingleMediaScanner(this, savedFile);
                adapter.addImage(Uri.fromFile(savedFile));
            } else {
                new File(pickerController.getSavePath()).delete();
            }
        } else if (requestCode == define.ENTER_DETAIL_REQUEST_CODE) {
            if (resultCode == RESULT_OK) {
                if (fishton.isAutomaticClose() && fishton.getSelectedImages().size() == fishton.getMaxCount())
                    finishActivity();
                refreshThumb();
            }
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String permissions[], int[] grantResults) {
        switch (requestCode) {
            case 28: {
                if (grantResults.length > 0) {
                    if (grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                        pickerController.displayImage(album.bucketId, fishton.getExceptMimeTypeList(), fishton.getSpecifyFolderList());
                    } else {
                        new PermissionCheck(this).showPermissionDialog();
                        finish();
                    }
                }
                break;
            }
            case 29: {
                if (grantResults.length > 0) {
                    if (grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                        pickerController.takePicture(this, pickerController.getPathDir(album.bucketId));
                    } else {
                        new PermissionCheck(this).showPermissionDialog();
                    }
                }
                break;
            }
        }
    }
//
//    @Override
//    public boolean onCreateOptionsMenu(Menu menu) {
//        // Inflate the menu; this adds items to the action bar if it is present.
//        getMenuInflater().inflate(R.menu.menu_photo_album, menu);
//        MenuItem menuDoneItem = menu.findItem(R.id.action_done);
//        MenuItem menuThumbItem = menu.findItem(R.id.action_thumb);
//
//        if (fishton.getDrawableDoneButton() != null) {
//            menuDoneItem.setIcon(fishton.getDrawableDoneButton());
//        } else if (fishton.getStrDoneMenu() != null) {
//            if (fishton.getColorTextMenu() != Integer.MAX_VALUE) {
//                SpannableString spanString = new SpannableString(fishton.getStrDoneMenu());
//                spanString.setSpan(new ForegroundColorSpan(fishton.getColorTextMenu()), 0, spanString.length(), 0); //fi
//                menuDoneItem.setTitle(spanString);
//            } else {
//                menuDoneItem.setTitle(fishton.getStrDoneMenu());
//            }
//            menuDoneItem.setIcon(null);
//        }
//
//        if (fishton.isThumb()) {
//            if (fishton.getDrawableThumbButton() != null) {
//                menuThumbItem.setIcon(fishton.getDrawableThumbButton());
//            }else {
//                menuThumbItem.setTitle(R.string.thumb);
//            }
//        }else {
//            if (fishton.getDrawableOriginButton() != null) {
//                menuThumbItem.setIcon(fishton.getDrawableOriginButton());
//            }else {
//                menuThumbItem.setTitle(R.string.origin);
//            }
//        }
//        return true;
//    }
//
//    @Override
//    public boolean onOptionsItemSelected(MenuItem item) {
//        int id = item.getItemId();
//        if (id == android.R.id.home) {
//            transImageFinish(position);
//        }
//        return super.onOptionsItemSelected(item);
//    }

    @Override
    public void onClick(View v) {
        if (v != null) {
            if (v.equals(originBtn)) {
                originBtn.setSelected(!originBtn.isSelected());
                Drawable drawable= getResources().getDrawable(originBtn.isSelected() ? R.drawable.radio_checked : R.drawable.radio_unchecked);
                drawable.setBounds(0, 0, drawable.getMinimumWidth(), drawable.getMinimumHeight());
                originBtn.setCompoundDrawables(drawable,null,null,null);
                fishton.setThumb(!originBtn.isSelected());
            } else if (v.equals(sendBtn)){
                if (fishton.getSelectedImages().size() < fishton.getMinCount()) {
                    Snackbar.make(recyclerView, fishton.getMessageNothingSelected(), Snackbar.LENGTH_SHORT).show();
                } else {
                    finishActivity();
                }
            } else if (v.equals(cancelBtn)) {
                finish();
            } else if (v.equals(moreContentView)) {

            }
        }
    }

    private void initController() {
        pickerController = new PickerController(this);
    }

    private void initView() {
        recyclerView = findViewById(R.id.recycler_picker_list);
        layoutManager = new GridLayoutManager(this, fishton.getPhotoSpanCount(), RecyclerView.VERTICAL, false);
        recyclerView.setLayoutManager(layoutManager);

        originBtn = findViewById(R.id.photo_picker_origin_btn);
        originBtn.setOnClickListener(this);

        sendBtn = findViewById(R.id.photo_picker_send_btn);
        sendBtn.setOnClickListener(this);
        updateSendBtnTitle();

        cancelBtn = findViewById(R.id.photo_picker_back_btn);
        cancelBtn.setOnClickListener(this);

        moreContentView = findViewById(R.id.photo_picker_more_content_view);
        moreContentView.setOnClickListener(this);

        moreArrowImageView = findViewById(R.id.album_pick_down_arrow_image);

//        initToolBar();
    }

    public void updateSendBtnTitle() {
        if (fishton.getSelectedImages().size() > 0) {
            sendBtn.setEnabled(true);
            sendBtn.setText(getResources().getText(R.string.done) + "(" + fishton.getSelectedImages().size() + "/" + fishton.getMaxCount() + ")");
        }else {
            sendBtn.setEnabled(false);
            sendBtn.setText(getResources().getText(R.string.done));
        }
    }

//    private void initToolBar() {
//        Toolbar toolbar = findViewById(R.id.toolbar_picker_bar);
//        setSupportActionBar(toolbar);
//        toolbar.setBackgroundColor(fishton.getColorActionBar());
//        toolbar.setTitleTextColor(fishton.getColorActionBarTitle());
//        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
//            UiUtil.setStatusBarColor(this, fishton.getColorStatusBar());
//        }
//        ActionBar bar = getSupportActionBar();
//        if (bar != null) {
//            bar.setDisplayHomeAsUpEnabled(true);
//            if (fishton.getDrawableHomeAsUpIndicator() != null)
//                getSupportActionBar().setHomeAsUpIndicator(fishton.getDrawableHomeAsUpIndicator());
//        }
//
//        if (fishton.isStatusBarLight() && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
//            toolbar.setSystemUiVisibility(View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR);
//        }
//    }

    public void setAdapter(List<Uri> result) {
        fishton.setPickerImages(result);
        if (adapter == null) {
            adapter = new PickerGridAdapter(pickerController, pickerController.getPathDir(album.bucketId));
            adapter.setActionListener(new PickerGridAdapter.OnPhotoActionListener() {
                @Override
                public void onDeselect() {
                    refreshThumb();
                }
            });
        }
        recyclerView.setAdapter(adapter);
        updateSendBtnTitle();
    }

    private void refreshThumb() {
        int firstVisible = layoutManager.findFirstVisibleItemPosition();
        int lastVisible = layoutManager.findLastVisibleItemPosition();
        for (int i = firstVisible; i <= lastVisible; i++) {
            View view = layoutManager.findViewByPosition(i);
            if (view instanceof SquareFrameLayout) {
                SquareFrameLayout item = (SquareFrameLayout) view;
                RadioWithTextButton btnThumbCount = item.findViewById(R.id.btn_thumb_count);
                ImageView imgThumbImage = item.findViewById(R.id.img_thumb_image);
                Uri image = (Uri) item.getTag();
                if (image != null) {
                    int index = fishton.getSelectedImages().indexOf(image);
                    if (index != -1) {
                        adapter.updateRadioButton(imgThumbImage, btnThumbCount, String.valueOf(index + 1),true);
                    } else {
                        adapter.updateRadioButton(imgThumbImage, btnThumbCount, "", false);
                        updateSendBtnTitle();
                    }
                }

            }
        }
    }

    void transImageFinish(int position) {
        Define define = new Define();
        Intent i = new Intent();
        i.putParcelableArrayListExtra(define.INTENT_ADD_PATH, pickerController.getAddImagePaths());
        i.putExtra(define.INTENT_POSITION, position);
        setResult(define.TRANS_IMAGES_RESULT_CODE, i);
        finish();
    }

    public void finishActivity() {
        Intent i = new Intent();
        setResult(RESULT_OK, i);
        if (fishton.isStartInAllView()) {
            i.putParcelableArrayListExtra(Define.INTENT_PATH, fishton.getSelectedImages());
            i.putExtra(Define.INTENT_THUMB, fishton.isThumb());
            i.putExtra(Define.INTENT_QUALITY, fishton.getQualityOfThumb());
        }
        finish();
    }
}
