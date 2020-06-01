package com.sangcomz.fishbun.util;

import android.content.ContentResolver;
import android.content.Context;
import android.database.Cursor;
import android.net.Uri;
import android.os.AsyncTask;
import android.provider.MediaStore;

import com.sangcomz.fishbun.MimeType;
import com.sangcomz.fishbun.bean.Album;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

public class DisplayAlbum extends AsyncTask<Void, Void, ArrayList<Album>> {

    public interface DisplayAlbumListener {
        void OnDisplayAlbumDidSelectFinish(ArrayList albums);
    }
    private String allViewTitle;
    private List<MimeType> exceptMimeTypeList;
    private ContentResolver resolver;
    private DisplayAlbumListener listener;

    public void setListener(DisplayAlbumListener listener) {
        this.listener = listener;
    }

    public DisplayAlbum(String allViewTitle, List<MimeType> exceptMimeTypeList, Context context) {
        this.allViewTitle = allViewTitle;
        this.exceptMimeTypeList = exceptMimeTypeList;
        this.resolver = context.getContentResolver();
    }

    @Override
    protected ArrayList<Album> doInBackground(Void... params) {
        HashMap<Long, Album> albumHashMap = new HashMap<>();
        int totalCounter = 0;
        String[] projection = new String[]{MediaStore.Images.Media._ID, MediaStore.Images.Media.BUCKET_DISPLAY_NAME, MediaStore.Images.Media.MIME_TYPE, MediaStore.Images.Media.BUCKET_ID};
        Cursor c = resolver.query(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, projection, null, null, null);
        if (c != null) {
            int bucketMimeType = c.getColumnIndex(MediaStore.Images.Media.MIME_TYPE);
            int bucketColumn = c.getColumnIndex(MediaStore.Images.Media.BUCKET_DISPLAY_NAME);
            int bucketColumnId = c.getColumnIndex(MediaStore.Images.Media.BUCKET_ID);
            albumHashMap.put((long) 0, new Album(0, allViewTitle, null, 0));

            while (c.moveToNext()) {
                String mimeType = c.getString(bucketMimeType);
                String folderName = c.getString(bucketColumn);

                int count = c.getCount();
                if (count <= 0 || isExceptMemeType(exceptMimeTypeList, mimeType)) continue;

                totalCounter++;
                long bucketId = c.getInt(bucketColumnId);
                Album album = albumHashMap.get(bucketId);
                if (album == null) {
                    int imgId = c.getInt(c.getColumnIndex(MediaStore.MediaColumns._ID));
                    Uri path = Uri.withAppendedPath(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, "" + imgId);
                    albumHashMap.put(bucketId, new Album(bucketId, folderName, path.toString(), 1));
                    if (albumHashMap.get(0L) != null && albumHashMap.get(0L).thumbnailPath == null)
                        albumHashMap.get(0L).thumbnailPath = path.toString();
                } else {
                    album.counter++;
                }
            }
            Album allAlbum = albumHashMap.get((long) 0);
            if (allAlbum != null) {
                allAlbum.counter = totalCounter;
            }
            c.close();
        }

        String[] videoProjection = new String[]{MediaStore.Video.Media._ID, MediaStore.Video.Media.BUCKET_DISPLAY_NAME, MediaStore.Video.Media.MIME_TYPE, MediaStore.Video.Media.BUCKET_ID};
        Cursor videoCursor = resolver.query(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, videoProjection, null, null, null);
        if (videoCursor != null) {
            int bucketMimeType = videoCursor.getColumnIndex(MediaStore.Video.Media.MIME_TYPE);
            int bucketColumn = videoCursor.getColumnIndex(MediaStore.Video.Media.BUCKET_DISPLAY_NAME);
            int bucketColumnId = videoCursor.getColumnIndex(MediaStore.Video.Media.BUCKET_ID);
            albumHashMap.put((long) 0, new Album(0, allViewTitle, null, 0));

            while (videoCursor.moveToNext()) {
                String mimeType = videoCursor.getString(bucketMimeType);
                String folderName = videoCursor.getString(bucketColumn);

                int count = videoCursor.getCount();
                if (count <= 0 || isExceptMemeType(exceptMimeTypeList, mimeType)) continue;

                totalCounter++;
                long bucketId = videoCursor.getInt(bucketColumnId);
                Album album = albumHashMap.get(bucketId);
                if (album == null) {
                    int imgId = videoCursor.getInt(videoCursor.getColumnIndex(MediaStore.MediaColumns._ID));
                    Uri path = Uri.withAppendedPath(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, "" + imgId);
                    albumHashMap.put(bucketId, new Album(bucketId, folderName, path.toString(), 1));
                    if (albumHashMap.get(0L) != null && albumHashMap.get(0L).thumbnailPath == null)
                        albumHashMap.get(0L).thumbnailPath = path.toString();
                } else {
                    album.counter++;
                }
            }
            Album allAlbum = albumHashMap.get((long) 0);
            if (allAlbum != null) {
                allAlbum.counter = totalCounter;
            }
            videoCursor.close();
        }

        if (totalCounter == 0)
            albumHashMap.clear();

        ArrayList<Album> albumList = new ArrayList<>();
        for (Album album : albumHashMap.values()) {
            if (album.bucketId == 0)
                albumList.add(0, album);
            else
                albumList.add(album);
        }
        return albumList;
    }

    @Override
    protected void onPostExecute(ArrayList<Album> albumList) {
        super.onPostExecute(albumList);
        if (listener != null) {
            listener.OnDisplayAlbumDidSelectFinish(albumList);
        }
    }

    private boolean isExceptMemeType(List<MimeType> mimeTypes, String mimeType) {
        for (MimeType type : mimeTypes) {
            if (MimeTypeExt.equalsMimeType(type, mimeType))
                return true;
        }
        return false;
    }

}
