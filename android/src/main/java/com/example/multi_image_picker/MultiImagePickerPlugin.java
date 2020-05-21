package com.example.multi_image_picker;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.graphics.Matrix;
import android.net.Uri;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;

import androidx.core.app.NavUtils;
import androidx.core.content.ContextCompat;
import androidx.exifinterface.media.ExifInterface;

import com.sangcomz.fishbun.FishBun;
import com.sangcomz.fishbun.FishBunCreator;
import com.sangcomz.fishbun.MimeType;
import com.sangcomz.fishbun.adapter.image.impl.GlideAdapter;
import com.sangcomz.fishbun.define.Define;
import com.sangcomz.fishbun.permission.PermissionCheck;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.UUID;

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
    private static final String REQUEST_THUMBNAIL = "requestThumbnail";
    private static final String REQUEST_ORIGINAL = "requestOriginal";
    private static final String REQUEST_METADATA = "requestMetadata";
    private static final String PICK_IMAGES = "pickImages";
    private static final String MAX_IMAGES = "maxImages";
    private static final String MAX_HEIGHT = "maxHeight";
    private static final String MAX_WIDTH = "maxWidth";
    private static final String QUALITY_OF_IMAGE = "qualityOfImage";
    private static final String SELECTED_ASSETS = "selectedAssets";
    private static final String ENABLE_CAMERA = "enableCamera";
    private static final String ANDROID_OPTIONS = "androidOptions";
    private static final int REQUEST_CODE_CHOOSE = 1001;
    private final MethodChannel channel;
    private final Activity activity;
    private final Context context;
    private final BinaryMessenger messenger;
    private static Result pendingResult;
    private static MethodCall methodCall;

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
//        if (!setPendingMethodCallAndResult(call, result)) {
//            finishWithAlreadyActiveError(result);
//            return;
//        }

        setPendingMethodCallAndResult(call, result);
        if (checkPermission()) {
            if (PICK_IMAGES.equals(call.method)) {
                final HashMap<String, String> options = call.argument(ANDROID_OPTIONS);
                int maxImages = this.methodCall.argument(MAX_IMAGES);
                int maxHeight = this.methodCall.argument(MAX_HEIGHT);
                int maxWidth = this.methodCall.argument(MAX_WIDTH);
                int qualityOfThumb = (int) this.methodCall.argument(QUALITY_OF_IMAGE);
                boolean enableCamera = (boolean) this.methodCall.argument(ENABLE_CAMERA);
                ArrayList<String> selectedAssets = this.methodCall.argument(SELECTED_ASSETS);
                presentPicker(maxImages, qualityOfThumb, maxHeight, maxWidth, enableCamera, selectedAssets, options);
            }
        }else {
            finishWithError("PERMISSION_PERMANENTLY_DENIED", "NO PERMISSION");
            return;
        }
    }

    private void presentPicker(int maxImages, int qualityOfThumb, int maxHeight, int maxWidth, boolean enableCamera, ArrayList<String> selectedAssets, HashMap<String, String> options) {
        String actionBarColor = options.get("actionBarColor");
        String statusBarColor = options.get("statusBarColor");
        String lightStatusBar = options.get("lightStatusBar");
        String actionBarTitle = options.get("actionBarTitle");
        String actionBarTitleColor = options.get("actionBarTitleColor");
        String allViewTitle =  options.get("allViewTitle");
        String selectCircleStrokeColor = options.get("selectCircleStrokeColor");
        String selectionLimitReachedText = options.get("selectionLimitReachedText");
        String textOnNothingSelected = options.get("textOnNothingSelected");
        String backButtonDrawable = options.get("backButtonDrawable");
        String okButtonDrawable = options.get("okButtonDrawable");
        ArrayList<Uri> selectedUris = new ArrayList<Uri>();

        for (String path : selectedAssets) {
            selectedUris.add(Uri.parse(path));
        }

        ArrayList mimeTypeList = new ArrayList();
        mimeTypeList.add(MimeType.GIF);
        mimeTypeList.add(MimeType.WEBP);
        FishBunCreator fishBun = FishBun.with(MultiImagePickerPlugin.this.activity)
                .setImageAdapter(new GlideAdapter())
                .setMaxCount(maxImages)
                .setQuality(qualityOfThumb)
                .setMaxHeight(maxHeight)
                .setMaxWidth(maxWidth)
                .setCamera(enableCamera)
                .setRequestCode(REQUEST_CODE_CHOOSE)
                .setSelectedImages(selectedUris)
                .exceptMimeType(mimeTypeList)
                .setIsUseDetailView(true);

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

        if (actionBarColor != null && !actionBarColor.isEmpty()) {
            int color = Color.parseColor(actionBarColor);
            if (statusBarColor != null && !statusBarColor.isEmpty()) {
                int statusBarColorInt = Color.parseColor(statusBarColor);
                if (lightStatusBar != null && !lightStatusBar.isEmpty()) {
                    boolean lightStatusBarValue = lightStatusBar.equals("true");
                    fishBun.setActionBarColor(color, statusBarColorInt, lightStatusBarValue);
                } else {
                    fishBun.setActionBarColor(color, statusBarColorInt);
                }
            } else {
                fishBun.setActionBarColor(color);
            }
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

        if (actionBarTitleColor != null && !actionBarTitleColor.isEmpty()) {
            int color = Color.parseColor(actionBarTitleColor);
            fishBun.setActionBarTitleColor(color);
        }

        if (allViewTitle != null && !allViewTitle.isEmpty()) {
            fishBun.setAllViewTitle(allViewTitle);
        }

        fishBun.startAlbum();
    }

    private static String acitivityResultSerialNum = ""; //防止onActivityResult回调2次
    @Override
    public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode == REQUEST_CODE_CHOOSE && resultCode == Activity.RESULT_CANCELED) {
            finishWithError("CANCELLED", "The user has cancelled the selection");
        } else if (requestCode == REQUEST_CODE_CHOOSE && resultCode == Activity.RESULT_OK) {
            if (acitivityResultSerialNum.equals(data.getStringExtra(Define.INTENT_SERIAL_NUM))) {
                return true;
            }else {
                acitivityResultSerialNum = data.getStringExtra(Define.INTENT_SERIAL_NUM);
            }
            final List<Uri> photos = data.getParcelableArrayListExtra(Define.INTENT_PATH);
            final boolean thumb = data.getBooleanExtra(Define.INTENT_THUMB, false);
            final int quality = data.getIntExtra(Define.INTENT_QUALITY, 1);
            final int maxHeight = data.getIntExtra(Define.INTENT_MAXHEIGHT, 1);
            final int maxWidth = data.getIntExtra(Define.INTENT_MAXWIDTH, 1);
            compressImageAndFinish(photos, thumb, quality, maxHeight, maxWidth);
            return true;
        } else {
            finishWithSuccess(Collections.emptyList());
            clearMethodCallAndResult();
        }
        return false;
    }

    private void compressImageAndFinish(final List<Uri> photos, final boolean thumb, final int quality, final int maxHeight, final int maxWidth) {
        final List<HashMap<String, Object>> result = new ArrayList<>(photos.size());
        for (Uri uri : photos) {
            HashMap<String, Object> map = new HashMap<>();
            String fileName = UUID.randomUUID().toString() + ".jpg";
            String filePath = "";
            try {
                InputStream is = context.getContentResolver().openInputStream(uri);
                File tmpPicParentDir = new File(context.getCacheDir().getAbsolutePath() + "/muti_image_pick/");
                if (!tmpPicParentDir.exists()) {
                    tmpPicParentDir.mkdirs();
                }
                File tmpPic = new File(context.getCacheDir().getAbsolutePath() + "/muti_image_pick/" + fileName);
                if (tmpPic.exists()) {
                    tmpPic.delete();
                }
                filePath = tmpPic.getAbsolutePath();
                HashMap hashMap = transImage(is, tmpPic, thumb ? maxWidth : -1, thumb ? maxHeight : -1, thumb ? quality : 100);
                if (hashMap.containsKey("width") && hashMap.containsKey("height")) {
                    map.put("width", hashMap.get("width"));
                    map.put("height", hashMap.get("height"));
                }else {
                    continue;
                }
            } catch (Exception e) {
                e.printStackTrace();
                continue;
            }

            map.put("name", fileName);
            map.put("filePath", filePath);
            map.put("identifier", uri.toString());
            result.add(map);
        }
        finishWithSuccess(result);
    }

    public HashMap transImage(InputStream fromFile, File toFile, int width, int height, int quality) {
        HashMap result = new HashMap();
        try {
            Bitmap bitmap = BitmapFactory.decodeStream(fromFile);
            int bitmapWidth = bitmap.getWidth();
            int bitmapHeight = bitmap.getHeight();

            float scaleWidth = -1 == width ? 1 : ((float) width / bitmapWidth);
            float scaleHeight = -1 == width ? 1 : ((float) height / bitmapHeight);
            float scale = scaleWidth > scaleHeight ? scaleHeight : scaleWidth;
            Matrix matrix = new Matrix();
            matrix.postScale(scale, scale);
            result.put("width", (bitmapWidth * scale));
            result.put("height", (bitmapHeight * scale));

            Bitmap resizeBitmap = Bitmap.createBitmap(bitmap, 0, 0, bitmapWidth, bitmapHeight, matrix, false);
            File myCaptureFile = toFile;
            if (myCaptureFile.exists()) myCaptureFile.delete();
            FileOutputStream out = new FileOutputStream(myCaptureFile);
            if(resizeBitmap.compress(Bitmap.CompressFormat.JPEG, quality, out)){
                out.flush();
                out.close();
            }
            if(!bitmap.isRecycled()){
                bitmap.recycle();//记得释放资源，否则会内存溢出
            }
            if(!resizeBitmap.isRecycled()){
                resizeBitmap.recycle();
            }
        } catch (FileNotFoundException e) {
            e.printStackTrace();
            result.clear();
        } catch (Exception ex) {
            ex.printStackTrace();
            result.clear();
        }
        return result;
    }

    private void finishWithSuccess(List imagePathList) {
        if (this.pendingResult != null)
            this.pendingResult.success(imagePathList);
        clearMethodCallAndResult();
    }

    private void finishWithAlreadyActiveError(MethodChannel.Result result) {
        if (result != null)
            result.error("already_active", "Image picker is already active", null);
    }

    private void finishWithError(String errorCode, String errorMessage) {
        if (this.pendingResult != null)
            this.pendingResult.error(errorCode, errorMessage, null);
        clearMethodCallAndResult();
    }

    private void clearMethodCallAndResult() {
        this.methodCall = null;
        this.pendingResult = null;
    }

    private boolean setPendingMethodCallAndResult(MethodCall methodCall, MethodChannel.Result result) {
        if (this.pendingResult != null) {
            this.pendingResult.error("new call coming", "Image picker come new picker", null);
            clearMethodCallAndResult();
        }
        this.methodCall = methodCall;
        this.pendingResult = result;
        return true;
    }
}
