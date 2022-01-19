export interface BarcodeScannerPlugin {
  checkPermission(
    options?: CheckPermissionOptions,
  ): Promise<CheckPermissionResult>;
  openAppSettings(): Promise<void>;
  scanCode(): Promise<ScanResult>;
}

export interface ScanResult {
  /**
   * This indicates whether or not the scan resulted in readable content.
   *
   * @since 1.0.0
   */
  hasContent: boolean;

  /**
   * This holds the content of the barcode if available.
   *
   * @since 1.0.0
   */
  content?: string;
}

export interface CheckPermissionOptions {
  /**
   * If this is set to `true`, the user will be prompted for the permission.
   * The prompt will only show if the permission was not yet granted and also not denied completely yet.
   * For more information see: https://github.com/capacitor-community/barcode-scanner#permissions
   *
   * @default false
   * @since 1.0.0
   */
  force?: boolean;
}

export interface CheckPermissionResult {
  /**
   * When set to `true`, the ermission is granted.
   */
  granted?: boolean;

  /**
   * When set to `true`, the permission is denied and cannot be prompted for.
   * The `openAppSettings` method should be used to let the user grant the permission.
   *
   * @since 1.0.0
   */
  denied?: boolean;

  /**
   * When this is set to `true`, the user was just prompted the permission.
   * Ergo: a dialog, asking the user to grant the permission, was shown.
   *
   * @since 1.0.0
   */
  asked?: boolean;

  /**
   * When this is set to `true`, the user has never been prompted the permission.
   *
   * @since 1.0.0
   */
  neverAsked?: boolean;

  /**
   * iOS only
   * When this is set to `true`, the permission cannot be requested for some reason.
   *
   * @since 1.0.0
   */
  restricted?: boolean;

  /**
   * iOS only
   * When this is set to `true`, the permission status cannot be retrieved.
   *
   * @since 1.0.0
   */
  unknown?: boolean;
}

export interface ScanCodeError {
  /**
   * Error message
   *
   * @since 1.0.0
   */
  errorMessage: string;
  /**
   * Error code
   *
   * @since 1.0.0
   */
  code: 'cancel' | 'cameraDenied';
}
