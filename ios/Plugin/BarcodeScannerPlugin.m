#import <Foundation/Foundation.h>
#import <Capacitor/Capacitor.h>

// Define the plugin using the CAP_PLUGIN Macro, and
// each method the plugin supports using the CAP_PLUGIN_METHOD macro.
CAP_PLUGIN(BarcodeScannerPlugin, "BarcodeScanner",
           CAP_PLUGIN_METHOD(echo, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(prepare, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(hideBackground, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(showBackground, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(startScan, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(stopScan, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(checkPermission, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(openAppSettings, CAPPluginReturnPromise);
)
