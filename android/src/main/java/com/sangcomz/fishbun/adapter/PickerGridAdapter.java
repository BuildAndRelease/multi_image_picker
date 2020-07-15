package com.sangcomz.fishbun.adapter;

import android.content.Context;
import android.graphics.Color;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.core.view.ViewCompat;
import androidx.recyclerview.widget.RecyclerView;

import com.example.multi_image_picker.R;
import com.google.android.material.snackbar.Snackbar;
import com.sangcomz.fishbun.Fishton;
import com.sangcomz.fishbun.bean.Media;
import com.sangcomz.fishbun.ui.picker.PickerController;
import com.sangcomz.fishbun.util.RadioWithTextButton;

import org.w3c.dom.Text;

import java.util.ArrayList;


public class PickerGridAdapter extends RecyclerView.Adapter<RecyclerView.ViewHolder> {
    private Fishton fishton;
    private PickerController pickerController;
    public PickerGridAdapter(PickerController pickerController) {
        this.pickerController = pickerController;
        this.fishton = Fishton.getInstance();
    }

    @Override
    public RecyclerView.ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.thumb_item, parent, false);
        return new ViewHolderImage(view);
    }

    @Override
    public int getItemCount() {
        return fishton.getPickerMedias() == null ? 0 : fishton.getPickerMedias().size();
    }

    @Override
    public void onBindViewHolder(final RecyclerView.ViewHolder holder, final int position) {
        final int imagePos = position;
        final ViewHolderImage vh = (ViewHolderImage) holder;
        final Media media = fishton.getPickerMedias().get(imagePos);
        vh.item.setTag(media);
        vh.btnThumbCount.unselect();
        vh.btnThumbCount.setCircleColor(fishton.getColorSelectCircleStroke());
        vh.btnThumbCount.setTextColor(Color.WHITE);
        vh.btnThumbCount.setStrokeColor(fishton.getColorDeSelectCircleStroke());

        if ((fishton.getSelectedMedias().size() >= fishton.getMaxCount() || fishton.isContainVideo()) && !fishton.getSelectedMedias().contains(media)) {
            vh.banCoverView.setVisibility(View.VISIBLE);
        }else {
            vh.banCoverView.setVisibility(View.INVISIBLE);
        }

        if (media.getFileType().contains("video")) {
            vh.gifInfoContentView.setVisibility(View.INVISIBLE);
            vh.videoInfoContentView.setVisibility(View.VISIBLE);
            try {
                int duration = Integer.parseInt(media.getDuration());
                vh.videoInfoDurationTextView.setText(String.format("%02d", duration/60) + ":" + String.format("%02d", duration%60));
            } catch (Exception e) {
                vh.videoInfoDurationTextView.setText("00:00");
            }
        }else {
            vh.videoInfoContentView.setVisibility(View.INVISIBLE);
            if (media.getFileType().contains("gif")) {
                vh.gifInfoContentView.setVisibility(View.VISIBLE);
            }else {
                vh.gifInfoContentView.setVisibility(View.INVISIBLE);
            }
        }

        int selectedIndex = fishton.getSelectedMedias().indexOf(media);
        if (selectedIndex != -1) {
            vh.btnThumbCount.setText(String.valueOf(selectedIndex + 1));
            vh.coverView.setAlpha(0.3f);
        }
        if (media != null && vh.imgThumbImage != null && Fishton.getInstance().getImageAdapter() != null) {
            Fishton.getInstance().getImageAdapter().loadImage(vh.imgThumbImage, media);
        }

        vh.btnThumbCount.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (fishton.getSelectedMedias().contains(media)) {
                    ArrayList<Media> pickedImages = fishton.getSelectedMedias();
                    RadioWithTextButton btnThumbCount = vh.item.findViewById(R.id.btn_thumb_count);
                    View coverView = vh.item.findViewById(R.id.conver_view);
                    pickedImages.remove(media);
                    btnThumbCount.unselect();
                    ViewCompat.animate(coverView).setDuration(100).alpha(0.0f);
                    pickerController.onSelectCountDidChange();
//                    if (pickedImages.size() == (fishton.getMaxCount() - 1) || pickedImages.size() == 0) {
                        notifyDataSetChanged();
//                    }
                }else if (media.getFileType().contains("video") && fishton.isContainPic()) {
                    Snackbar.make(vh.item, "不能同时选择视频和照片", Snackbar.LENGTH_SHORT).show();
                } else if (media.getFileType().contains("video") && fishton.getSelectedMedias().size() > 0) {
                    Snackbar.make(vh.item, "一次只能选择一个视频", Snackbar.LENGTH_SHORT).show();
                } else if (media.getFileType().contains("video") && Integer.parseInt(media.getDuration()) > 301) {
                    Snackbar.make(vh.item, "视屏长度不能超过5分钟", Snackbar.LENGTH_SHORT).show();
                } else if (media.getFileType().contains("image") && fishton.isContainVideo()) {
                    Snackbar.make(vh.item, "不能同时选择视频和照片", Snackbar.LENGTH_SHORT).show();
                } else if (Float.parseFloat(media.getFileSize()) > 1024 * 1024 * 8) {
                    Snackbar.make(vh.item, "不能选择超过8M的图片", Snackbar.LENGTH_SHORT).show();
                } else if (fishton.getMaxCount() == fishton.getSelectedMedias().size()) {
                    Snackbar.make(vh.item, "选择数量超过最大限制", Snackbar.LENGTH_SHORT).show();
                } else {
                    ArrayList<Media> pickedImages = fishton.getSelectedMedias();
                    RadioWithTextButton btnThumbCount = vh.item.findViewById(R.id.btn_thumb_count);
                    View coverView = vh.item.findViewById(R.id.conver_view);
                    pickedImages.add(media);
                    btnThumbCount.setText(String.valueOf(pickedImages.size()));
                    ViewCompat.animate(coverView).setDuration(100).alpha(0.3f);
                    pickerController.onSelectCountDidChange();
                    if (pickedImages.size() >= fishton.getMaxCount() || fishton.isContainVideo()) {
                        notifyDataSetChanged();
                    }
                }
            }
        });
        vh.imgThumbImage.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                pickerController.onSelectItem(imagePos);
            }
        });
    }

    public class ViewHolderImage extends RecyclerView.ViewHolder {
        View item;
        ImageView imgThumbImage;
        RadioWithTextButton btnThumbCount;
        View coverView;
        View banCoverView;
        LinearLayout videoInfoContentView;
        TextView videoInfoDurationTextView;
        LinearLayout gifInfoContentView;
        TextView gifInfoTextView;

        public ViewHolderImage(View view) {
            super(view);
            item = view;
            imgThumbImage = view.findViewById(R.id.img_thumb_image);
            btnThumbCount = view.findViewById(R.id.btn_thumb_count);
            coverView = view.findViewById(R.id.conver_view);
            banCoverView = view.findViewById(R.id.ban_cover_view);
            videoInfoContentView = view.findViewById(R.id.video_thumb_info_view);
            videoInfoDurationTextView = view.findViewById(R.id.video_thumb_duration_info_view);
            gifInfoContentView = view.findViewById(R.id.gif_thumb_info_view);
            gifInfoTextView = view.findViewById(R.id.gif_thumb_info_text_view);
        }
    }
}
