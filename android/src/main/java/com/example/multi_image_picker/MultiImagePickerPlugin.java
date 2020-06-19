package com.example.multi_image_picker;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.graphics.drawable.Drawable;
import android.os.Build;

import androidx.core.content.ContextCompat;

import com.sangcomz.fishbun.FishBun;
import com.sangcomz.fishbun.FishBunCreator;
import com.sangcomz.fishbun.MimeType;
import com.sangcomz.fishbun.adapter.GlideAdapter;
import com.sangcomz.fishbun.bean.Media;
import com.sangcomz.fishbun.util.Define;
import com.sangcomz.fishbun.util.PermissionCheck;
import com.sangcomz.fishbun.util.DisplayImage;
import com.sangcomz.fishbun.util.MediaCompress;
import com.sangcomz.fishbun.util.MediaThumbData;

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
    private static final String PICK_IMAGES = "pickImages";
    private static final String MAX_IMAGES = "maxImages";
    private static final String MAX_HEIGHT = "maxHeight";
    private static final String MAX_WIDTH = "maxWidth";
    private static final String IDENTIFY = "identifier";
    private static final String FILE_TYPE = "fileType";
    private static final String LIMIT = "limit";
    private static final String OFFSET = "offset";
    private static final String QUALITY_OF_IMAGE = "qualityOfImage";
    private static final String SELECTED_ASSETS = "selectedAssets";
    private static final String ANDROID_OPTIONS = "androidOptions";
    private static final int REQUEST_CODE_CHOOSE = 1001;
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

    boolean checkPermission() {
        PermissionCheck permissionCheck = new PermissionCheck(activity);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            return permissionCheck.CheckStoragePermission() && permissionCheck.CheckCameraPermission();
        } else {
            return true;
        }
    }

    @Override
    public void onMethodCall(final MethodCall call, final Result result) {
        try {
            if (checkPermission()) {
                switch (call.method) {
                    case PICK_IMAGES: {
                        if (currentPickerResult != null) {
                            currentPickerResult.error("TIME OUT NEW PICKER COME IN", "", null);
                        }
                        currentPickerResult = result;
                        final HashMap<String, String> options = call.argument(ANDROID_OPTIONS);
                        int maxImages = call.argument(MAX_IMAGES);
                        int maxHeight = call.argument(MAX_HEIGHT);
                        int maxWidth = call.argument(MAX_WIDTH);
                        int qualityOfThumb = call.argument(QUALITY_OF_IMAGE);
                        ArrayList<String> selectMedias = call.argument(SELECTED_ASSETS);
                        presentPicker(maxImages, qualityOfThumb, maxHeight, maxWidth, selectMedias, options);
                        break;
                    }
                    case FETCH_MEDIA_INFO: {
                        ArrayList mimeTypeList = new ArrayList();
                        mimeTypeList.add(MimeType.GIF);
                        mimeTypeList.add(MimeType.WEBP);
                        int limit = call.argument(LIMIT);
                        int offset = call.argument(OFFSET);
                        DisplayImage displayImage = new DisplayImage((long) 0, mimeTypeList, activity);
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
                        break;
                    }
                    case FETCH_MEDIA_THUMB_DATA: {
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
                        break;
                    }
                    case REQUEST_MEDIA_DATA: {
                        boolean thumb = call.argument("thumb");
                        int quality = call.argument("qualityOfImage");
                        int maxHeight = call.argument("maxHeight");
                        int maxWidth = call.argument("maxWidth");
                        List<String> selectMedias = call.argument("selectedAssets");
                        MediaCompress mediaCompress = new MediaCompress(thumb, quality, maxHeight, maxWidth, new ArrayList<Media>(), selectMedias, activity);
                        mediaCompress.setListener(new MediaCompress.MediaCompressListener() {
                            @Override
                            public void mediaCompressDidFinish(ArrayList<HashMap> results) {
                                result.success(results);
                            }
                        });
                        mediaCompress.execute();
                        break;
                    }
                }
            }else {
                result.error("PERMISSION_PERMANENTLY_DENIED", "NO PERMISSION", null);
            }
        } catch (Exception e) {
            result.error(e.getMessage(), e.getCause().toString(), null);
        }
    }

    private void presentPicker(int maxImages, int qualityOfThumb, int maxHeight, int maxWidth, ArrayList<String> selectMedias, HashMap<String, String> options) {
        String actionBarTitle = options.get("actionBarTitle");
        String allViewTitle =  options.get("allViewTitle");
        String selectCircleStrokeColor = options.get("selectCircleStrokeColor");
        String selectionLimitReachedText = options.get("selectionLimitReachedText");
        String textOnNothingSelected = options.get("textOnNothingSelected");
        String backButtonDrawable = options.get("backButtonDrawable");
        String okButtonDrawable = options.get("okButtonDrawable");

        ArrayList mimeTypeList = new ArrayList();
        mimeTypeList.add(MimeType.GIF);
        mimeTypeList.add(MimeType.WEBP);
        FishBunCreator fishBun = FishBun.with(MultiImagePickerPlugin.this.activity)
                .setImageAdapter(new GlideAdapter())
                .setMaxCount(maxImages)
                .setQuality(qualityOfThumb)
                .setMaxHeight(maxHeight)
                .setMaxWidth(maxWidth)
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
        if (requestCode == REQUEST_CODE_CHOOSE && resultCode == Activity.RESULT_CANCELED) {
            if (currentPickerResult != null) {
                currentPickerResult.error("CANCELLED", "The user has cancelled the selection", null);
                currentPickerResult = null;
            }
            return false;
        } else if (requestCode == REQUEST_CODE_CHOOSE && resultCode == Activity.RESULT_OK) {
            if (currentPickerResult != null) {
                ArrayList result = data.getParcelableArrayListExtra(Define.INTENT_RESULT);
                currentPickerResult.success(result);
                currentPickerResult = null;
            }
            return true;
        } else if (requestCode == REQUEST_CODE_CHOOSE && resultCode == Define.FINISH_DETAIL_REQUEST_CODE) {
            if (currentPickerResult != null) {
                ArrayList result = data.getParcelableArrayListExtra(Define.INTENT_RESULT);
                currentPickerResult.success(result);
                currentPickerResult = null;
            }
            return true;
        }else {
            if (currentPickerResult != null) {
                currentPickerResult.success(Collections.emptyList());
                currentPickerResult = null;
            }
            return false;
        }
    }
}
