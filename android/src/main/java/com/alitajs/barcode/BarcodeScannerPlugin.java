package com.alitajs.barcode;

import static android.content.Context.MODE_PRIVATE;

import android.Manifest;
import android.content.Intent;
import android.content.SharedPreferences;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;
import android.util.Log;

import androidx.activity.result.ActivityResult;

import com.alitajs.barcode.zxing.data.ConstantValue;
import com.getcapacitor.JSObject;
import com.getcapacitor.PermissionState;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.ActivityCallback;
import com.getcapacitor.annotation.CapacitorPlugin;
import com.getcapacitor.annotation.Permission;
import com.getcapacitor.annotation.PermissionCallback;


@CapacitorPlugin(name = "BarcodeScanner", permissions = { @Permission(strings = { Manifest.permission.CAMERA }, alias = BarcodeScannerPlugin.PERMISSION_ALIAS_CAMERA) })
public class BarcodeScannerPlugin extends Plugin {

    public static final String PERMISSION_ALIAS_CAMERA = "camera";

    @PluginMethod()
    public void scanCode(PluginCall call) {
        if (getPermissionState(PERMISSION_ALIAS_CAMERA) == PermissionState.GRANTED) {
            Intent intent = new Intent(getActivity(), ScanCodeActivity.class);
            intent.putExtra("onlyFromCamera", false);
            startActivityForResult(call, intent, "handleScanCodeResult");
        } else {
            call.reject("没有摄像头权限", "cameraDenied");
        }
    }

    @ActivityCallback
    private void handleScanCodeResult(PluginCall call, ActivityResult result) {
        JSObject ret = new JSObject();
        Intent intent = result.getData();
        String resultString = intent.getStringExtra("codedContent");
        ret.put("hasContent", resultString != null);
        ret.put("content", resultString);
        call.resolve(ret);
    }

    @PluginMethod
    public void openAppSettings(PluginCall call) {
        Intent intent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", getAppId(), null));
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        startActivityForResult(call, intent, "openSettingsResult");
    }

    @ActivityCallback
    private void openSettingsResult(PluginCall call, ActivityResult result) {
        call.resolve();
    }

    private static final String TAG_PERMISSION = "permission";

    private static final String GRANTED = "granted";
    private static final String DENIED = "denied";
    private static final String ASKED = "asked";
    private static final String NEVER_ASKED = "neverAsked";

    private static final String PERMISSION_NAME = Manifest.permission.CAMERA;

    private JSObject savedReturnObject;

    void _checkPermission(PluginCall call, boolean force) {
        this.savedReturnObject = new JSObject();

        if (getPermissionState(PERMISSION_ALIAS_CAMERA) == PermissionState.GRANTED) {
            // permission GRANTED
            this.savedReturnObject.put(GRANTED, true);
        } else {
            // permission NOT YET GRANTED

            // check if asked before
            boolean neverAsked = isPermissionFirstTimeAsking(PERMISSION_NAME);
            if (neverAsked) {
                this.savedReturnObject.put(NEVER_ASKED, true);
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                // from version Android M on,
                // on runtime,
                // each permission can be temporarily denied,
                // or be denied forever
                if (neverAsked || getActivity().shouldShowRequestPermissionRationale(PERMISSION_NAME)) {
                    // permission never asked before
                    // OR
                    // permission DENIED, BUT not for always
                    // So
                    // can be asked (again)
                    if (force) {
                        // request permission
                        // so a callback can be made from the handleRequestPermissionsResult
                        requestPermissionForAlias(PERMISSION_ALIAS_CAMERA, call, "cameraPermsCallback");
                        return;
                    }
                } else {
                    // permission DENIED
                    // user ALSO checked "NEVER ASK AGAIN"
                    this.savedReturnObject.put(DENIED, true);
                }
            } else {
                // below android M
                // no runtime permissions exist
                // so always
                // permission GRANTED
                this.savedReturnObject.put(GRANTED, true);
            }
        }
        call.resolve(this.savedReturnObject);
    }

    private static final String PREFS_PERMISSION_FIRST_TIME_ASKING = "PREFS_PERMISSION_FIRST_TIME_ASKING";

    private void setPermissionFirstTimeAsking(String permission, boolean isFirstTime) {
        SharedPreferences sharedPreference = getActivity().getSharedPreferences(PREFS_PERMISSION_FIRST_TIME_ASKING, MODE_PRIVATE);
        sharedPreference.edit().putBoolean(permission, isFirstTime).apply();
    }

    private boolean isPermissionFirstTimeAsking(String permission) {
        return getActivity().getSharedPreferences(PREFS_PERMISSION_FIRST_TIME_ASKING, MODE_PRIVATE).getBoolean(permission, true);
    }

    @PermissionCallback
    private void cameraPermsCallback(PluginCall call) {
        if (this.savedReturnObject == null) {
            // No stored plugin call for permissions request result
            return;
        }

        // the user was apparently requested this permission
        // update the preferences to reflect this
        setPermissionFirstTimeAsking(PERMISSION_NAME, false);

        boolean granted = false;
        if (getPermissionState(PERMISSION_ALIAS_CAMERA) == PermissionState.GRANTED) {
            granted = true;
        }

        // indicate that the user has been asked to accept this permission
        this.savedReturnObject.put(ASKED, true);

        if (granted) {
            // permission GRANTED
            Log.d(TAG_PERMISSION, "Asked. Granted");
            this.savedReturnObject.put(GRANTED, true);
        } else {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                if (getActivity().shouldShowRequestPermissionRationale(PERMISSION_NAME)) {
                    // permission DENIED
                    // BUT not for always
                    Log.d(TAG_PERMISSION, "Asked. Denied For Now");
                } else {
                    // permission DENIED
                    // user ALSO checked "NEVER ASK AGAIN"
                    Log.d(TAG_PERMISSION, "Asked. Denied");
                    this.savedReturnObject.put(DENIED, true);
                }
            } else {
                // below android M
                // no runtime permissions exist
                // so always
                // permission GRANTED
                Log.d(TAG_PERMISSION, "Asked. Granted");
                this.savedReturnObject.put(GRANTED, true);
            }
        }
        // resolve saved call
        call.resolve(this.savedReturnObject);
        // release saved vars
        this.savedReturnObject = null;
    }


    @PluginMethod
    public void checkPermission(PluginCall call) {
        Boolean force = call.getBoolean("force", false);

        if (force != null && force) {
            _checkPermission(call, true);
        } else {
            _checkPermission(call, false);
        }
    }
}
