package com.sangcomz.fishbun.define;

public class Define {
    public final int PERMISSION_STORAGE = 28;
    public final int PERMISSION_CAMERA = 29;
    public final int ENTER_DETAIL_REQUEST_CODE = 130;
    public final int FINISH_DETAIL_REQUEST_CODE = 131;

    public final static String INTENT_PATH = "intent_path";
    public final static String INTENT_THUMB = "intent_thumb";
    public final static String INTENT_QUALITY = "intent_quality";
    public final static String INTENT_MAXHEIGHT = "intent_maxHeight";
    public final static String INTENT_MAXWIDTH = "intent_maxWidth";
    public final static String INTENT_RESULT = "result";
    public final String INTENT_ADD_PATH = "intent_add_path";
    public final String INTENT_POSITION = "intent_position";

    public final String SAVE_INSTANCE_ALBUM_LIST = "instance_album_list";
    public final String SAVE_INSTANCE_ALBUM_THUMB_LIST = "instance_album_thumb_list";

    public final String SAVE_INSTANCE_NEW_MEDIAS = "instance_new_medias";
    public final String SAVE_INSTANCE_SAVED_MEDIAS = "instance_saved_media";

    public enum BUNDLE_NAME {
        POSITION,
        ALBUM,
    }
}
