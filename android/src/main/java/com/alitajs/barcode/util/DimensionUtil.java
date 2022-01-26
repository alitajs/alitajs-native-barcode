package com.alitajs.barcode.util;

import android.content.res.Resources;

public class DimensionUtil {
    public static int dpToPx(int dp) {
        return (int)(dp * Resources.getSystem().getDisplayMetrics().density);
    }
}
