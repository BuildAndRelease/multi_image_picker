package com.fanbook.multi_picker.meishe.media_edit.adapter;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.example.multi_image_picker.R;
import com.fanbook.multi_picker.meishe.media_edit.interfaces.OnItemClickListener;
import com.fanbook.multi_picker.meishe.media_edit.model.EditOption;

import java.util.ArrayList;

public class EditVideoOptionsAdapter extends RecyclerView.Adapter<EditVideoOptionsAdapter.OptionsViewHolder> {

    private final ArrayList<EditOption> mEditOptions = new ArrayList<>();
    private final Context mContext;
    private OnItemClickListener mOnItemClickListener;

    public EditVideoOptionsAdapter(Context context) {
        mContext = context;
        initOptions();
    }

    private void initOptions() {
        // TODO
        mEditOptions.add(new EditOption("剪辑", ""));
        mEditOptions.add(new EditOption("音乐", ""));
        mEditOptions.add(new EditOption("文字", ""));
        mEditOptions.add(new EditOption("贴纸", ""));
        mEditOptions.add(new EditOption("滤镜", ""));
        mEditOptions.add(new EditOption("标记", ""));
    }

    public void setOnItemClickListener(OnItemClickListener onItemClickListener) {
        mOnItemClickListener = onItemClickListener;
    }

    @NonNull
    @Override
    public OptionsViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View optionItemView = LayoutInflater.from(mContext).inflate(R.layout.item_edit_option, parent, false);
        return new OptionsViewHolder(optionItemView);
    }

    @Override
    public void onBindViewHolder(@NonNull OptionsViewHolder holder, final int position) {
        // TODO
//        holder.optionIcon.setImageResource();
        holder.optionTitle.setText(mEditOptions.get(position).getTitle());
        holder.optionItem.setTag(position);
        if (mOnItemClickListener != null) {
            holder.optionItem.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View view) {
                    mOnItemClickListener.onItemClick(view, (Integer) view.getTag());
                }
            });
        }
    }

    @Override
    public int getItemCount() {
        return mEditOptions.size();
    }

    protected static class OptionsViewHolder extends RecyclerView.ViewHolder {
        LinearLayout optionItem;
        ImageView optionIcon;
        TextView optionTitle;

        public OptionsViewHolder(View itemView) {
            super(itemView);
            optionItem = itemView.findViewById(R.id.ll_option_item);
            optionIcon = itemView.findViewById(R.id.iv_option_icon);
            optionTitle = itemView.findViewById(R.id.tv_option_title);
        }
    }

}
