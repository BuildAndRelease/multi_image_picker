package com.sangcomz.fishbun.ui.album;

import android.content.ContentResolver;
import android.content.Context;
import android.database.Cursor;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Build;
import android.provider.MediaStore;

import com.sangcomz.fishbun.MimeType;
import com.sangcomz.fishbun.bean.Album;
import com.sangcomz.fishbun.ext.MimeTypeExt;
import com.sangcomz.fishbun.permission.PermissionCheck;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

public class AlbumPickerPopupController {
    private AlbumPickerPopup albumPickerPopup;
    private ContentResolver resolver;
    private Context context;

    AlbumPickerPopupController(AlbumPickerPopup albumPickerPopup, Context context) {
        this.albumPickerPopup = albumPickerPopup;
        this.resolver = context.getContentResolver();
    }

    boolean checkPermission() {
        PermissionCheck permissionCheck = new PermissionCheck(context);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            return permissionCheck.CheckStoragePermission();
        } else {
            return true;
        }
    }

    void getAlbumList(String allViewTitle, List<MimeType> exceptMimeTypeList, List<String> specifyFolderList) {
        new AlbumPickerPopupController.LoadAlbumList(allViewTitle, exceptMimeTypeList, specifyFolderList).execute();
    }

    private class LoadAlbumList extends AsyncTask<Void, Void, List<Album>> {
        String allViewTitle;
        List<MimeType> exceptMimeTypeList;
        List<String> specifyFolderList;

        LoadAlbumList(String allViewTitle, List<MimeType> exceptMimeTypeList, List<String> specifyFolderList) {
            this.allViewTitle = allViewTitle;
            this.exceptMimeTypeList = exceptMimeTypeList;
            this.specifyFolderList = specifyFolderList;
        }

        @Override
        protected List<Album> doInBackground(Void... params) {
            HashMap<Long, Album> albumHashMap = new HashMap<>();
            final String orderBy = MediaStore.Images.Media._ID + " DESC";
            String[] projection = new String[]{
                    MediaStore.Images.Media._ID,
                    MediaStore.Images.Media.BUCKET_DISPLAY_NAME,
                    MediaStore.Images.Media.MIME_TYPE,
                    MediaStore.Images.Media.BUCKET_ID};

            Cursor c = resolver.query(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, projection, null, null, orderBy);

            int totalCounter = 0;
            if (c != null) {
                int bucketMimeType = c.getColumnIndex(MediaStore.Images.Media.MIME_TYPE);
                int bucketColumn = c.getColumnIndex(MediaStore.Images.Media.BUCKET_DISPLAY_NAME);
                int bucketColumnId = c.getColumnIndex(MediaStore.Images.Media.BUCKET_ID);

                if (!isNotContainsSpecifyFolderList(specifyFolderList, allViewTitle)) {
                    albumHashMap.put((long) 0, new Album(0, allViewTitle, null, 0));
                }

                while (c.moveToNext()) {
                    String mimeType = c.getString(bucketMimeType);
                    String folderName = c.getString(bucketColumn);
                    int count = c.getCount();
                    if (count <= 0 || isExceptMemeType(exceptMimeTypeList, mimeType) || isNotContainsSpecifyFolderList(specifyFolderList, folderName)) continue;

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
        protected void onPostExecute(List<Album> albumList) {
            super.onPostExecute(albumList);
            albumPickerPopup.setAlbumList(albumList);
        }
    }


    private boolean isExceptMemeType(List<MimeType> mimeTypes, String mimeType) {
        for (MimeType type : mimeTypes) {
            if (MimeTypeExt.equalsMimeType(type, mimeType))
                return true;
        }
        return false;
    }

    private boolean isNotContainsSpecifyFolderList(List<String> specifyFolderList, String displayBundleName) {
        if (specifyFolderList.isEmpty()) return false;
        return !specifyFolderList.contains(displayBundleName);
    }

}
