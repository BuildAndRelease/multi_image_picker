package com.example.multi_image_picker;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.os.Build;
import android.provider.MediaStore;
import android.text.TextUtils;

import androidx.core.content.ContextCompat;

import com.sangcomz.fishbun.FishBun;
import com.sangcomz.fishbun.FishBunCreator;
import com.sangcomz.fishbun.MimeType;
import com.sangcomz.fishbun.adapter.GlideAdapter;
import com.sangcomz.fishbun.bean.Media;
import com.sangcomz.fishbun.ui.camera.CameraActivity;
import com.sangcomz.fishbun.util.Define;
import com.sangcomz.fishbun.util.MediaInfoData;
import com.sangcomz.fishbun.util.PermissionCheck;
import com.sangcomz.fishbun.util.DisplayImage;
import com.sangcomz.fishbun.util.MediaCompress;
import com.sangcomz.fishbun.util.MediaThumbData;

import java.lang.reflect.Array;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;


/**
 * MultiImagePickerPlugin
 */
public class MultiImagePickerPlugin implements  MethodCallHandler, PluginRegistry.ActivityResultListener {
    private static final String CHANNEL_NAME = "multi_image_picker";
    private static final String FETCH_MEDIA_THUMB_DATA = "fetchMediaThumbData";
    private static final String FETCH_MEDIA_INFO = "fetchMediaInfo";
    private static final String REQUEST_MEDIA_DATA = "requestMediaData";
    private static final String REQUEST_TAKE_PICTURE = "requestTakePicture";
    private static final String REQUEST_FILE_SIZE = "requestFileSize";
    private static final String REQUEST_FILE_DIMEN = "requestFileDimen";
    private static final String REQUEST_THUMB_DIRECTORY = "requestThumbDirectory";
    private static final String PICK_IMAGES = "pickImages";
    private static final String MAX_IMAGES = "maxImages";
    private static final String MAX_HEIGHT = "maxHeight";
    private static final String MAX_WIDTH = "maxWidth";
    private static final String THUMB = "thumb";
    private static final String IDENTIFY = "identifier";
    private static final String FILE_TYPE = "fileType";
    private static final String LIMIT = "limit";
    private static final String OFFSET = "offset";
    private static final String SELECTED_ASSETS = "selectedAssets";
    private static final String DEFAULT_ASSETS = "defaultAsset";
    private static final String ANDROID_OPTIONS = "androidOptions";
    private static final String THEME_COLOR = "themeColor";
    private static final int REQUEST_CODE_CHOOSE = 1001;
    private static final int REQUEST_CODE_TAKE = 1002;
    private final MethodChannel channel;
    private final Activity activity;
    private final Context context;
    private final BinaryMessenger messenger;
    private static Result currentPickerResult;

    public MultiImagePickerPlugin(Activity activity, Context context, MethodChannel channel, BinaryMessenger messenger) {
        this.activity = activity;
        this.context = context;
        this.channel = channel;
        this.messenger = messenger;
    }

    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), CHANNEL_NAME);
        MultiImagePickerPlugin instance = new MultiImagePickerPlugin(registrar.activity(), registrar.context(), channel, registrar.messenger());
        registrar.addActivityResultListener(instance);
        channel.setMethodCallHandler(instance);
    }

    boolean checkPermission(boolean checkCamera, boolean checkRecord, boolean checkStorage) {
        PermissionCheck permissionCheck = new PermissionCheck(activity);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            boolean result = true;
            if (checkCamera) {
                result = result && permissionCheck.CheckCameraPermission();
            }
            if (checkRecord) {
                result = result && permissionCheck.CheckRecordAudioPermission();
            }
            if (checkStorage) {
                result = result && permissionCheck.CheckStoragePermission();
            }
            return result;
        } else {
            return true;
        }
    }

    @Override
    public void onMethodCall(final MethodCall call, final Result result) {
        try {
            switch (call.method) {
                case PICK_IMAGES: {
                    if (checkPermission(false, false, true)) {
                        if (currentPickerResult != null) {
                            currentPickerResult.error("TIME OUT NEW PICKER COME IN", "", null);
                        }
                        currentPickerResult = result;
                        final HashMap<String, String> options = call.argument(ANDROID_OPTIONS);
                        int maxImages = call.argument(MAX_IMAGES);
                        boolean thumb = call.argument(THUMB);
                        ArrayList<String> selectMedias = call.argument(SELECTED_ASSETS);
                        selectMedias = selectMedias == null ? new ArrayList<String>() : selectMedias;
                        String defaultAsset = call.argument(DEFAULT_ASSETS);
                        defaultAsset = TextUtils.isEmpty(defaultAsset) ? "" : defaultAsset;
                        presentPicker(maxImages, thumb, defaultAsset, selectMedias, options);
                    }else {
                        if (currentPickerResult != null) {
                            currentPickerResult.error("PERMISSION_PERMANENTLY_DENIED", "NO PERMISSION", null);
                            currentPickerResult = null;
                        }else {
                            result.error("PERMISSION_PERMANENTLY_DENIED", "NO PERMISSION", null);
                        }
                    }
                    break;
                }
                case FETCH_MEDIA_INFO: {
                    if (checkPermission(false, false, true)) {
                        ArrayList mimeTypeList = new ArrayList();
                        mimeTypeList.add(MimeType.WEBP);
                        int limit = call.argument(LIMIT);
                        int offset = call.argument(OFFSET);
                        ArrayList<String> selectMedias = call.argument(SELECTED_ASSETS);
                        selectMedias = selectMedias == null ? new ArrayList<String>() : selectMedias;
                        DisplayImage displayImage = new DisplayImage((long) 0, selectMedias, mimeTypeList, activity);
                        displayImage.setRequestHashMap(true);
                        displayImage.setLimit(limit);
                        displayImage.setOffset(offset);
                        displayImage.setListener(new DisplayImage.DisplayImageListener() {
                            @Override
                            public void OnDisplayImageDidSelectFinish(ArrayList medias) {
                                result.success(medias);
                            }
                        });
                        displayImage.execute();
                    }else {
                        result.error("PERMISSION_PERMANENTLY_DENIED", "NO PERMISSION", null);
                    }
                    break;
                }
                case REQUEST_TAKE_PICTURE: {
                    if (checkPermission(true, true, true)) {
                        if (currentPickerResult != null) {
                            currentPickerResult.error("TIME OUT NEW PICKER COME IN", "", null);
                        }
                        String color = call.argument(THEME_COLOR);
                        int themeColor = color == null || color.isEmpty() ? 0xFF00CC00 : Color.parseColor(color);
                        currentPickerResult = result;
                        Intent i = new Intent(activity, CameraActivity.class);
                        i.putExtra(THEME_COLOR, themeColor);
                        activity.startActivityForResult(i, REQUEST_CODE_TAKE);
                    }else  {
                        if (currentPickerResult != null) {
                            currentPickerResult.error("PERMISSION_PERMANENTLY_DENIED", "NO PERMISSION", null);
                            currentPickerResult = null;
                        }else {
                            result.error("PERMISSION_PERMANENTLY_DENIED", "NO PERMISSION", null);
                        }
                    }
                    break;
                }
                case FETCH_MEDIA_THUMB_DATA: {
                    if (checkPermission(false, false, true)) {
                        String identify = call.argument(IDENTIFY);
                        String fileType = call.argument(FILE_TYPE);
                        MediaThumbData mediaThumbData = new MediaThumbData(identify, fileType, activity);
                        mediaThumbData.setListener(new MediaThumbData.MediaThumbDataListener() {
                            @Override
                            public void mediaThumbDataDidFinish(byte[] bytes) {
                                result.success(bytes);
                            }
                        });
                        mediaThumbData.execute();
                    }else {
                        result.error("PERMISSION_PERMANENTLY_DENIED", "NO PERMISSION", null);
                    }
                    break;
                }
                case REQUEST_FILE_SIZE: {
                    if (checkPermission( false, false, true)) {
                        String identify = call.argument(IDENTIFY);
                        MediaInfoData mediaInfoData = new MediaInfoData(identify, activity);
                        mediaInfoData.setListener(new MediaInfoData.MediaInfoDataListener() {
                            @Override
                            public void mediaInfoDataDidFinish(HashMap hashMap) {
                                result.success(hashMap.get("size"));
                            }
                        });
                        mediaInfoData.execute();
                    }else {
                        result.error("PERMISSION_PERMANENTLY_DENIED", "NO PERMISSION", null);
                    }
                    break;
                }
                case REQUEST_FILE_DIMEN: {
                    if (checkPermission( false, false, true)) {
                        String identify = call.argument(IDENTIFY);
                        MediaInfoData mediaInfoData = new MediaInfoData(identify, activity);
                        mediaInfoData.setListener(new MediaInfoData.MediaInfoDataListener() {
                            @Override
                            public void mediaInfoDataDidFinish(HashMap hashMap) {
                                result.success(hashMap);
                            }
                        });
                        mediaInfoData.execute();
                    }else {
                        result.error("PERMISSION_PERMANENTLY_DENIED", "NO PERMISSION", null);
                    }
                    break;
                }
                case REQUEST_THUMB_DIRECTORY: {
                    result.success(context.getCacheDir().getAbsolutePath() + "/multi_image_pick/thumb/");
                    break;
                }
                case REQUEST_MEDIA_DATA: {
                    if (checkPermission(false, false, true)) {
                        boolean thumb = call.argument("thumb");
                        List<String> selectMedias = call.argument("selectedAssets");
                        MediaCompress mediaCompress = new MediaCompress(thumb, new ArrayList<Media>(), selectMedias, activity);
                        mediaCompress.setListener(new MediaCompress.MediaCompressListener() {
                            @Override
                            public void mediaCompressDidFinish(ArrayList<HashMap> results) {
                                result.success(results);
                            }
                        });
                        mediaCompress.execute();
                    }else {
                        result.error("PERMISSION_PERMANENTLY_DENIED", "NO PERMISSION", null);
                    }
                    break;
                }
            }
        } catch (Exception e) {
            if (currentPickerResult != null) {
                currentPickerResult.error(e.getMessage(), e.toString(), null);
                currentPickerResult = null;
            }else {
                result.error(e.getMessage(), e.toString(), null);
            }
        }
    }

    private void presentPicker(int maxImages, boolean thumb, String defaultAsset, ArrayList<String> selectMedias, HashMap<String, String> options) {
        String actionBarTitle = options.get("actionBarTitle");
        String allViewTitle =  options.get("allViewTitle");
        String selectCircleStrokeColor = options.get("selectCircleStrokeColor");
        String selectionLimitReachedText = options.get("selectionLimitReachedText");
        String textOnNothingSelected = options.get("textOnNothingSelected");
        String backButtonDrawable = options.get("backButtonDrawable");
        String okButtonDrawable = options.get("okButtonDrawable");

        ArrayList mimeTypeList = new ArrayList();
        mimeTypeList.add(MimeType.WEBP);
        FishBunCreator fishBun = FishBun.with(MultiImagePickerPlugin.this.activity)
                .setImageAdapter(new GlideAdapter())
                .setMaxCount(maxImages)
                .setThumb(thumb)
                .setPreSelectMedia(defaultAsset)
                .setPreSelectMedias(selectMedias)
                .setRequestCode(REQUEST_CODE_CHOOSE)
                .exceptMimeType(mimeTypeList);

        if (!textOnNothingSelected.isEmpty()) {
            fishBun.textOnNothingSelected(textOnNothingSelected);
        }

        if (!backButtonDrawable.isEmpty()) {
            int id = context.getResources().getIdentifier(backButtonDrawable, "drawable", context.getPackageName());
            fishBun.setHomeAsUpIndicatorDrawable(ContextCompat.getDrawable(context, id));
        }

        if (!okButtonDrawable.isEmpty()) {
            int id = context.getResources().getIdentifier(okButtonDrawable, "drawable", context.getPackageName());
            fishBun.setDoneButtonDrawable(ContextCompat.getDrawable(context, id));
        }

        if (actionBarTitle != null && !actionBarTitle.isEmpty()) {
            fishBun.setActionBarTitle(actionBarTitle);
        }

        if (selectionLimitReachedText != null && !selectionLimitReachedText.isEmpty()) {
            fishBun.textOnImagesSelectionLimitReached(selectionLimitReachedText);
        }

        if (selectCircleStrokeColor != null && !selectCircleStrokeColor.isEmpty()) {
            fishBun.setSelectCircleStrokeColor(Color.parseColor(selectCircleStrokeColor));
        }

        if (allViewTitle != null && !allViewTitle.isEmpty()) {
            fishBun.setAllViewTitle(allViewTitle);
        }

        fishBun.startAlbum();
    }

    @Override
    public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
        try {
            if (requestCode == REQUEST_CODE_CHOOSE) {
                if (resultCode == Activity.RESULT_OK) {
                    if (currentPickerResult != null) {
                        ArrayList result = data.getParcelableArrayListExtra(Define.INTENT_RESULT);
                        currentPickerResult.success(result != null ? result : Collections.EMPTY_LIST);
                        currentPickerResult = null;
                    }
                }else if (resultCode == Define.FINISH_DETAIL_RESULT_CODE) {
                    if (currentPickerResult != null) {
                        ArrayList result = data.getParcelableArrayListExtra(Define.INTENT_RESULT);
                        currentPickerResult.success(result);
                        currentPickerResult = null;
                    }
                }else if (resultCode == Activity.RESULT_CANCELED) {
                    if (currentPickerResult != null) {
                        ArrayList result = data != null ? data.getParcelableArrayListExtra(Define.INTENT_RESULT) : new ArrayList();
                        Boolean thumb = data != null ? data.getBooleanExtra(Define.INTENT_THUMB, true) : true;
                        HashMap <String, Object> t = new HashMap<>();
                        t.put("assets", result);
                        t.put("thumb", thumb);
                        currentPickerResult.error("CANCELLED", "", t);
                        currentPickerResult = null;
                    }
                }else {
                    if (currentPickerResult != null) {
                        currentPickerResult.error("CANCELLED", "", new ArrayList<>());
                        currentPickerResult = null;
                    }
                }
                return true;
            } else if (requestCode == REQUEST_CODE_TAKE) {
                if (resultCode == Define.ENTER_TAKE_RESULT_CODE) {
                    if (currentPickerResult != null) {
                        HashMap result = (HashMap) data.getSerializableExtra(Define.INTENT_RESULT);
                        currentPickerResult.success(result);
                        currentPickerResult = null;
                    }
                }else {
                    if (currentPickerResult != null) {
                        currentPickerResult.error("CANCELLED", "", new HashMap<>());
                        currentPickerResult = null;
                    }
                }
                return true;
            }else {
                if (currentPickerResult != null) {
                    currentPickerResult.success(new Object());
                    currentPickerResult = null;
                }
                return true;
            }
        } catch (Exception e) {
            if (currentPickerResult != null) {
                currentPickerResult.error("CANCELLED", "", new ArrayList<>());
                currentPickerResult = null;
            }
            return true;
        }
    }
}
