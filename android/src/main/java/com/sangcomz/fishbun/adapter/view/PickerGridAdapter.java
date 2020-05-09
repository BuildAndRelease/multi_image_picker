package com.sangcomz.fishbun.adapter.view;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;
import android.provider.OpenableColumns;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.RelativeLayout;

import androidx.core.content.ContextCompat;
import androidx.core.view.ViewCompat;
import androidx.recyclerview.widget.RecyclerView;

import com.example.multi_image_picker.R;
import com.google.android.material.snackbar.Snackbar;
import com.sangcomz.fishbun.Fishton;
import com.sangcomz.fishbun.define.Define;
import com.sangcomz.fishbun.ui.detail.DetailActivity;
import com.sangcomz.fishbun.ui.picker.PickerActivity;
import com.sangcomz.fishbun.ui.picker.PickerController;
import com.sangcomz.fishbun.util.RadioWithTextButton;

import java.util.ArrayList;


public class PickerGridAdapter extends RecyclerView.Adapter<RecyclerView.ViewHolder> {
    private static final int TYPE_HEADER = Integer.MIN_VALUE;

    private Fishton fishton;
    private PickerController pickerController;
    private OnPhotoActionListener actionListener;

    private String saveDir;

    public PickerGridAdapter(PickerController pickerController, String saveDir) {
        this.pickerController = pickerController;
        this.saveDir = saveDir;
        this.fishton = Fishton.getInstance();
    }

    @Override
    public RecyclerView.ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        View view;
        if (viewType == TYPE_HEADER) {
            view = LayoutInflater.from(parent.getContext()).inflate(R.layout.header_item, parent, false);
            return new ViewHolderHeader(view);
        }

        view = LayoutInflater.from(parent.getContext()).inflate(R.layout.thumb_item, parent, false);
        return new ViewHolderImage(view);
    }

    @Override
    public void onBindViewHolder(final RecyclerView.ViewHolder holder, final int position) {
        if (holder instanceof ViewHolderHeader) {
            final ViewHolderHeader vh = (ViewHolderHeader) holder;
            vh.header.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    if (pickerController.checkCameraPermission()) {
                        pickerController.takePicture((Activity) vh.header.getContext(), saveDir);
                    }
                }
            });
        }

        if (holder instanceof ViewHolderImage) {
            final int imagePos;
            if (fishton.isCamera()) imagePos = position - 1;
            else imagePos = position;

            final ViewHolderImage vh = (ViewHolderImage) holder;
            final Uri image = fishton.getPickerImages().get(imagePos);
            final Context context = vh.item.getContext();
            vh.item.setTag(image);
            vh.btnThumbCount.unselect();
            vh.btnThumbCount.setCircleColor(fishton.getColorSelectCircleStroke());
            vh.btnThumbCount.setTextColor(fishton.getColorActionBarTitle());
            vh.btnThumbCount.setStrokeColor(fishton.getColorDeSelectCircleStroke());

            initState(fishton.getSelectedImages().indexOf(image), vh);
            if (image != null && vh.imgThumbImage != null)
                Fishton.getInstance().getImageAdapter().loadImage(vh.imgThumbImage, image);

            vh.btnThumbCount.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    onCheckStateChange(vh.item, image);
                }
            });
            vh.imgThumbImage.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    onCheckStateChange(vh.item, image);
                }
            });

//            vh.imgThumbImage.setOnLongClickListener(new View.OnLongClickListener() {
//                @Override
//                public boolean onLongClick(View v) {
//                    if (fishton.isUseDetailView()) {
//                        if (context instanceof PickerActivity) {
//                            PickerActivity activity = (PickerActivity) context;
//                            Intent i = new Intent(activity, DetailActivity.class);
//                            i.putExtra(Define.BUNDLE_NAME.POSITION.name(), imagePos);
//                            activity.startActivityForResult(i, new Define().ENTER_DETAIL_REQUEST_CODE);
//                        }
//                    }
//                    return true;
//                }
//            });
        }
    }

    private void initState(int selectedIndex, ViewHolderImage vh) {
        if (selectedIndex != -1) {
            updateRadioButton(vh.btnThumbCount, String.valueOf(selectedIndex + 1));
            animScale(vh.coverView, false);
        }
    }

    private void onCheckStateChange(View v, Uri image) {
        ArrayList<Uri> pickedImages = fishton.getSelectedImages();

        boolean isContained = pickedImages.contains(image);
        if (fishton.getMaxCount() == pickedImages.size() && !isContained) {
            Snackbar.make(v, fishton.getMessageLimitReached(), Snackbar.LENGTH_SHORT).show();
            return;
        }
        ImageView imgThumbImage = v.findViewById(R.id.img_thumb_image);
        RadioWithTextButton btnThumbCount = v.findViewById(R.id.btn_thumb_count);
        View coverView = v.findViewById(R.id.conver_view);
        if (isContained) {
            pickedImages.remove(image);
            btnThumbCount.unselect();
            animScale(coverView, true);
        } else {
            pickedImages.add(image);
            updateRadioButton(btnThumbCount, String.valueOf(pickedImages.size()));
            animScale(coverView, false);
        }
        pickerController.setToolbarTitle(pickedImages.size());
    }

    public void updateRadioButton(RadioWithTextButton v, String text) {
        if (fishton.getMaxCount() == 1)
            v.setDrawable(ContextCompat.getDrawable(v.getContext(), R.drawable.ic_done_white_24dp));
        else
            v.setText(text);
    }

    public void updateRadioButton(ImageView imageView, RadioWithTextButton v, String text, boolean isSelected) {
        if (isSelected) {
            if (fishton.getMaxCount() == 1)
                v.setDrawable(ContextCompat.getDrawable(v.getContext(), R.drawable.ic_done_white_24dp));
            else
                v.setText(text);
        } else {
            v.unselect();
        }
    }

    private void animScale(final View view, final boolean callBack) {
        final int duration = 100;
        ViewCompat.animate(view).setDuration(duration).alpha((callBack ? 0.0f : 0.3f)).withEndAction(new Runnable() {
            @Override
            public void run() {
                if (callBack) {
                    actionListener.onDeselect();
                }
            }
        });
    }

    @Override
    public int getItemCount() {
        int count;
        if (fishton.getPickerImages() == null)
            count = 0;
        else
            count = fishton.getPickerImages().size();

        if (fishton.isCamera())
            return count + 1;

        if (fishton.getPickerImages() == null)
            return 0;
        else
            return count;
    }

    @Override
    public int getItemViewType(int position) {
        if (position == 0 && fishton.isCamera()) {
            return TYPE_HEADER;
        }
        return super.getItemViewType(position);
    }

    public void addImage(Uri path) {
        ArrayList<Uri> al = new ArrayList<>();
        if (fishton.getPickerImages() != null){
            al.addAll(fishton.getPickerImages());
        }
        al.add(0, path);
        fishton.setPickerImages(al);

        notifyDataSetChanged();

        pickerController.setAddImagePath(path);
    }

    public void setActionListener(OnPhotoActionListener actionListener) {
        this.actionListener = actionListener;
    }

    public interface OnPhotoActionListener {
        void onDeselect();
    }

    public class ViewHolderImage extends RecyclerView.ViewHolder {
        View item;
        ImageView imgThumbImage;
        RadioWithTextButton btnThumbCount;
        View coverView;

        public ViewHolderImage(View view) {
            super(view);
            item = view;
            imgThumbImage = view.findViewById(R.id.img_thumb_image);
            btnThumbCount = view.findViewById(R.id.btn_thumb_count);
            coverView = view.findViewById(R.id.conver_view);
        }
    }

    public class ViewHolderHeader extends RecyclerView.ViewHolder {
        RelativeLayout header;
        public ViewHolderHeader(View view) {
            super(view);
            header = itemView.findViewById(R.id.rel_header_area);
        }
    }
}
