package com.sangcomz.fishbun.adapter

import android.net.Uri
import android.view.LayoutInflater
import android.view.ViewGroup
import android.widget.LinearLayout
import androidx.recyclerview.widget.RecyclerView
import com.example.multi_image_picker.R
import com.sangcomz.fishbun.Fishton
import com.sangcomz.fishbun.bean.Album
import com.sangcomz.fishbun.util.getDimension
import kotlinx.android.synthetic.main.album_item.view.*

interface AlbumListItemSelectListener {
    fun albumListItemSelect(adapter : AlbumListAdapter, album: Album, position: Int)
}

class AlbumListAdapter : RecyclerView.Adapter<AlbumListAdapter.ViewHolder>() {
    private val fishton = Fishton.getInstance()
    var itemSelectListener : AlbumListItemSelectListener? = null

    var albumList = emptyList<Album>()
        set(value) {
            field = value
        }

    fun setOnItemSelectListener(listener: AlbumListItemSelectListener) {
        this.itemSelectListener = listener;
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        return ViewHolder(parent, parent.context.getDimension(R.dimen.album_thum_size))
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        var uri: Uri = Uri.EMPTY
        try {
            uri = Uri.parse(albumList[position].thumbnailPath)
        }catch (e: Exception) {
            uri = Uri.EMPTY
        }
        fishton.imageAdapter?.loadImage(holder.imgALbumThumb, uri)

        holder.itemView.tag = albumList[position]
        holder.txtAlbumName.text = albumList[position].bucketName
        holder.txtAlbumCount.text = "(" + albumList[position].counter.toString() +")"

        holder.itemView.setOnClickListener {
            itemSelectListener?.albumListItemSelect(this, albumList[position], position);
        }
    }

    override fun getItemCount(): Int = albumList.size

    class ViewHolder(parent: ViewGroup, albumSize: Int) : RecyclerView.ViewHolder(
            LayoutInflater.from(parent.context).inflate(R.layout.album_item, parent, false)) {
        val imgALbumThumb = itemView.img_album_thumb
        val txtAlbumName = itemView.txt_album_name
        val txtAlbumCount = itemView.txt_album_count

        init {
            imgALbumThumb.layoutParams = LinearLayout.LayoutParams(albumSize, albumSize)
        }
    }
}