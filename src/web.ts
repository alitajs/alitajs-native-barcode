import { WebPlugin } from '@capacitor/core';

import type {
  BarcodeScannerPlugin,
  ScanResult,
  CheckPermissionOptions,
  CheckPermissionResult,
} from './definitions';

export class BarcodeScannerWeb
  extends WebPlugin
  implements BarcodeScannerPlugin {
  async checkPermission(
    _options: CheckPermissionOptions,
  ): Promise<CheckPermissionResult> {
    throw this.unimplemented('Not implemented on web.');
  }

  async openAppSettings(): Promise<void> {
    throw this.unimplemented('Not implemented on web.');
  }

  async scanCode(): Promise<ScanResult> {
    throw this.unimplemented('Not implemented on web.');
  }
}
