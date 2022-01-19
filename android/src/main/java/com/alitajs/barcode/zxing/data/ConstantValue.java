package com.alitajs.barcode.zxing.data;

import android.os.Environment;

public class ConstantValue {

    public static final String TEMP_PATH = Environment.getExternalStorageDirectory().getAbsolutePath() + "/iWhale";

    public static final String PHOTO_TEMP_PATH = TEMP_PATH + "/temp/";

    /**
     * 多媒体相关常量
     **/
    //启动扫码页面
    public static final int OPEN_SCAN_REQ_CODE = 1004;
    //启动拍照
    public static final int OPEN_CAMER_REQ_CODE = 1005;
    //打开手机相册
    public static final int OPEN_ALBUM_REQ_CODE = 1006;
    //打开GPS
    public static final int OPEN_GPS_REQ_CODE = 1007;

}
