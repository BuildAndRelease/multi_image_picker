package com.sangcomz.fishbun.util;
import android.net.Uri;
import android.widget.PopupWindow;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import android.content.Context;
import android.graphics.drawable.ColorDrawable;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.View.OnTouchListener;
import android.view.ViewGroup.LayoutParams;
import android.widget.LinearLayout;
import android.widget.ListView;
import android.widget.PopupWindow;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.RelativeLayout;
import android.widget.TextView;

import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.sangcomz.fishbun.Fishton;
import com.sangcomz.fishbun.R;
import com.sangcomz.fishbun.adapter.view.AlbumListAdapter;
import com.sangcomz.fishbun.bean.Album;
import com.sangcomz.fishbun.define.Define;

public class TopMiddlePopup extends PopupWindow {
    private Context myContext;
    protected Define define = new Define();
    protected Fishton fishton;

    private LayoutInflater inflater = null;
    private View myMenuView;

    private TopMiddlePopupController albumController;
    private List<Album> albumList = Collections.emptyList();
    private RecyclerView recyclerAlbumList;
    private RelativeLayout relAlbumEmpty;
    private AlbumListAdapter adapter;

    public TopMiddlePopup(Context context) {
        this.myContext = context;
        inflater = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        myMenuView = inflater.inflate(R.layout.activity_photo_album, null);
        relAlbumEmpty = myMenuView.findViewById(R.id.rel_album_empty);
        albumController = new TopMiddlePopupController(this, context);
        fishton = Fishton.getInstance();
//        if (albumController.checkPermission())
            albumController.getAlbumList(fishton.getTitleAlbumAllView(),
                    fishton.getExceptMimeTypeList(),
                    fishton.getSpecifyFolderList());
        setPopup();
    }

    private void initRecyclerView() {
        recyclerAlbumList = myMenuView.findViewById(R.id.recycler_album_list);

        GridLayoutManager layoutManager;
        if (UiUtil.isLandscape(myContext))
            layoutManager = new GridLayoutManager(myContext, fishton.getAlbumLandscapeSpanCount());
        else
            layoutManager = new GridLayoutManager(myContext, fishton.getAlbumPortraitSpanCount());

        if (recyclerAlbumList != null) {
            recyclerAlbumList.setLayoutManager(layoutManager);
        }
    }

    private void setAlbumListAdapter() {
        if (adapter == null) {
            adapter = new AlbumListAdapter();
        }
        adapter.setAlbumList(albumList);
        recyclerAlbumList.setAdapter(adapter);
        adapter.notifyDataSetChanged();
    }

    protected void setAlbumList(List<Album> albumList) {
        this.albumList = albumList;
        if (albumList.size() > 0) {
            relAlbumEmpty.setVisibility(View.GONE);
            initRecyclerView();
            setAlbumListAdapter();
        } else {
            relAlbumEmpty.setVisibility(View.VISIBLE);
        }
    }

    private void refreshList(int position, ArrayList<Uri> imagePath) {
        if (imagePath.size() > 0) {
            if (position == 0) {
                albumController.getAlbumList(fishton.getTitleAlbumAllView(), fishton.getExceptMimeTypeList(), fishton.getSpecifyFolderList());
            } else {
                albumList.get(0).counter += imagePath.size();
                albumList.get(position).counter += imagePath.size();

                albumList.get(0).thumbnailPath = imagePath.get(imagePath.size() - 1).toString();
                albumList.get(position).thumbnailPath = imagePath.get(imagePath.size() - 1).toString();

                adapter.notifyItemChanged(0);
                adapter.notifyItemChanged(position);
            }
        }
    }

    /**
     * 设置popup的样式
     */
    private void setPopup() {
        // 设置AccessoryPopup的view
        this.setContentView(myMenuView);
        // 设置AccessoryPopup弹出窗体的宽度
        this.setWidth(LayoutParams.MATCH_PARENT);
        // 设置AccessoryPopup弹出窗体的高度
        this.setHeight(LayoutParams.WRAP_CONTENT);
        // 设置AccessoryPopup弹出窗体可点击
        this.setFocusable(true);
        // 设置AccessoryPopup弹出窗体的动画效果
        this.setAnimationStyle(R.style.AnimTop);
        // 实例化一个ColorDrawable颜色为半透明
        ColorDrawable dw = new ColorDrawable(0x33000000);
        // 设置SelectPicPopupWindow弹出窗体的背景
        this.setBackgroundDrawable(dw);

        myMenuView.setOnTouchListener(new OnTouchListener() {

            @Override
            public boolean onTouch(View v, MotionEvent event) {
//                int height = popupLL.getBottom();
//                int left = popupLL.getLeft();
//                int right = popupLL.getRight();
//                System.out.println("--popupLL.getBottom()--:"+ popupLL.getBottom());
//                int y = (int) event.getY();
//                int x = (int) event.getX();
//                if (event.getAction() == MotionEvent.ACTION_UP) {
//                    if (y > height || x < left || x > right) {
//                        System.out.println("---点击位置在列表下方--");
//                        dismiss();
//                    }
//                }
                return true;
            }
        });
    }

    /**
     * 显示弹窗界面
     *
     * @param view
     */
    public void show(View view) {
//        if (myIsDirty) {
//            myIsDirty = false;
//            adapter = new PopupAdapter(myContext, myItems, myType);
//            myLv.setAdapter(adapter);
//        }

        showAsDropDown(view, 0, 0);
    }

}