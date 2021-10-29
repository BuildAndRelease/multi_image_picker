package com.sangcomz.fishbun.ui.album;
import android.widget.PopupWindow;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import android.content.Context;
import android.graphics.drawable.ColorDrawable;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup.LayoutParams;
import android.widget.Toast;

import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.example.multi_image_picker.R;
import com.sangcomz.fishbun.Fishton;
import com.sangcomz.fishbun.adapter.AlbumListAdapter;
import com.sangcomz.fishbun.adapter.AlbumListItemSelectListener;
import com.sangcomz.fishbun.bean.Album;
import com.sangcomz.fishbun.util.DisplayAlbum;
import com.sangcomz.fishbun.util.UiUtil;

import org.jetbrains.annotations.NotNull;

public class AlbumPickerPopup extends PopupWindow implements DisplayAlbum.DisplayAlbumListener {
    public interface AlbumPickerPopupCallBack {
        void  albumPickerPopupDidSelectAlbum(Album album, int position);
    }

    private Context context;
    private Fishton fishton;
    private LayoutInflater inflater;
    private View myMenuView;
    private AlbumPickerPopupCallBack callBack;
    private List<Album> albumList = Collections.emptyList();
    private RecyclerView recyclerAlbumList;

    public void setCallBack(AlbumPickerPopupCallBack callBack) {
        this.callBack = callBack;
    }

    public AlbumPickerPopup(Context context) {
        this.context = context;
        inflater = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        myMenuView = inflater.inflate(R.layout.activity_photo_album, null);
        initData();
        initView();
    }

    private void initData() {
        fishton = Fishton.getInstance();
        DisplayAlbum displayAlbum = new DisplayAlbum(fishton.getTitleAlbumAllView(), fishton.getShowMediaType(), context);
        displayAlbum.setListener(this);
        displayAlbum.execute();
    }

    private void initView() {
        this.setContentView(myMenuView);
        this.setWidth(LayoutParams.MATCH_PARENT);
        this.setHeight(LayoutParams.WRAP_CONTENT);
        this.setFocusable(true);
        this.setAnimationStyle(R.style.AnimTop);
        ColorDrawable dw = new ColorDrawable(0x33000000);
        this.setBackgroundDrawable(dw);
    }

    private void initRecyclerView() {
        recyclerAlbumList = myMenuView.findViewById(R.id.recycler_album_list);
        GridLayoutManager layoutManager = UiUtil.isLandscape(context) ? new GridLayoutManager(context, 2) : new GridLayoutManager(context, 1);
        if (recyclerAlbumList != null) {
            recyclerAlbumList.setLayoutManager(layoutManager);
        }
    }

    private void setAlbumListAdapter() {
        if (recyclerAlbumList.getAdapter() == null) {
            AlbumListAdapter adapter = new AlbumListAdapter();
            adapter.setOnItemSelectListener(new AlbumListItemSelectListener() {
                @Override
                public void albumListItemSelect(@NotNull AlbumListAdapter adapter, @NotNull Album album, int position) {
                    callBack.albumPickerPopupDidSelectAlbum(album, position);
                    dismiss();
                }
            });
            adapter.setAlbumList(albumList);
            recyclerAlbumList.setAdapter(adapter);
        }else {
            AlbumListAdapter adapter = (AlbumListAdapter) recyclerAlbumList.getAdapter();
            adapter.setAlbumList(albumList);
            adapter.notifyDataSetChanged();
        }
    }

    @Override
    public void OnDisplayAlbumDidSelectFinish(ArrayList albums) {
        this.albumList = albums;
        if (albumList.size() > 0) {
            initRecyclerView();
            setAlbumListAdapter();
        }else {
            Toast.makeText(context, R.string.none_album_string, Toast.LENGTH_SHORT).show();
            dismiss();
        }
    }
}