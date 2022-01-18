import React, { FC, useEffect } from 'react';
import { BarcodeScanner, ScanResult } from '@alitajs/barcode';
import styles from './index.less';

interface HomePageProps {}

/** 
    prepare(): Promise<void>;
    hideBackground(): Promise<void>;
    showBackground(): Promise<void>;
    startScan(options?: ScanOptions): Promise<ScanResult>;
    stopScan(options?: StopScanOptions): Promise<void>;
    checkPermission(options?: CheckPermissionOptions): Promise<CheckPermissionResult>;
    openAppSettings(): Promise<void>;
*/

const HomePage: FC<HomePageProps> = () => {
  const [scanResult, setScanResult] = React.useState<ScanResult>();
  useEffect(() => {
    // BarcodeScanner.prepare();
  }, []);
  const startScan = async () => {
    try {
      const permissionStatus = await BarcodeScanner.checkPermission();
      if (permissionStatus.granted) {
        const result = await BarcodeScanner.scanCode({});
        setScanResult(result);
      }
    } catch (error) {}
  };
  return (
    <div className={styles.center}>
      <div>
        <button onClick={startScan}>startScan</button>
      </div>
      <div>
        <code>{scanResult?.content}</code>
      </div>
    </div>
  );
};

export default HomePage;
