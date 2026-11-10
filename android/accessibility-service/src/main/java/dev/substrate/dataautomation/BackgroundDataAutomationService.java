package dev.substrate.dataautomation;

import android.accessibilityservice.AccessibilityService;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.accessibility.AccessibilityEvent;
import android.view.accessibility.AccessibilityNodeInfo;
import java.util.Arrays;
import java.util.List;

/**
 * BackgroundDataAutomationService: Java implementation of the Accessibility Service
 * that automatically navigates to App Info settings and disables the "Background data" toggle.
 */
public class BackgroundDataAutomationService extends AccessibilityService {

    private static final String TAG = "SubstrateDataAuto";

    private static final List<String> DATA_MENU_KEYWORDS = Arrays.asList(
        "Mobile data & Wi-Fi",
        "Mobile data",
        "Data usage",
        "Data & Wi-Fi",
        "Mobile data usage",
        "Cellular data"
    );

    private static final List<String> BG_DATA_KEYWORDS = Arrays.asList(
        "Background data",
        "Allow background data usage",
        "Allow background data"
    );

    private final Handler handler = new Handler(Looper.getMainLooper());
    private long lastActionTimestamp = 0;
    private boolean isProcessingSubMenu = false;

    @Override
    public void onAccessibilityEvent(AccessibilityEvent event) {
        if (event == null) return;

        int eventType = event.getEventType();
        if (eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED &&
            eventType != AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED) {
            return;
        }

        long currentTime = System.currentTimeMillis();
        if (currentTime - lastActionTimestamp < 600) {
            return;
        }

        AccessibilityNodeInfo rootNode = getRootInActiveWindow();
        if (rootNode == null) return;

        try {
            if (processBackgroundDataToggle(rootNode)) {
                lastActionTimestamp = currentTime;
                return;
            }

            if (!isProcessingSubMenu && processAppInfoScreen(rootNode)) {
                lastActionTimestamp = currentTime;
            }
        } catch (Exception e) {
            Log.e(TAG, "Error in accessibility event processing: " + e.getMessage(), e);
        }
    }

    private boolean processAppInfoScreen(AccessibilityNodeInfo rootNode) {
        for (String keyword : DATA_MENU_KEYWORDS) {
            List<AccessibilityNodeInfo> matchingNodes = rootNode.findAccessibilityNodeInfosByText(keyword);
            if (matchingNodes != null && !matchingNodes.isEmpty()) {
                for (AccessibilityNodeInfo node : matchingNodes) {
                    AccessibilityNodeInfo target = findClickableTarget(node);
                    if (target != null) {
                        Log.i(TAG, "Navigating into data menu: " + keyword);
                        boolean clicked = target.performAction(AccessibilityNodeInfo.ACTION_CLICK);
                        if (clicked) {
                            isProcessingSubMenu = true;
                            handler.postDelayed(() -> isProcessingSubMenu = false, 5000);
                            return true;
                        }
                    }
                }
            }
        }
        return false;
    }

    private boolean processBackgroundDataToggle(AccessibilityNodeInfo rootNode) {
        for (String keyword : BG_DATA_KEYWORDS) {
            List<AccessibilityNodeInfo> matchingNodes = rootNode.findAccessibilityNodeInfosByText(keyword);
            if (matchingNodes != null && !matchingNodes.isEmpty()) {
                for (AccessibilityNodeInfo node : matchingNodes) {
                    AccessibilityNodeInfo switchNode = findSwitchNearNode(node);
                    if (switchNode != null && switchNode.isCheckable()) {
                        if (switchNode.isChecked()) {
                            Log.i(TAG, "Found active Background Data switch for '" + keyword + "'. Toggling OFF.");
                            boolean clicked = switchNode.performAction(AccessibilityNodeInfo.ACTION_CLICK);
                            if (clicked) {
                                completeAndNavigateBack();
                                return true;
                            }
                        } else {
                            Log.i(TAG, "Background Data switch for '" + keyword + "' is already OFF.");
                            completeAndNavigateBack();
                            return true;
                        }
                    }
                }
            }
        }
        return false;
    }

    private void completeAndNavigateBack() {
        isProcessingSubMenu = false;
        handler.postDelayed(() -> {
            performGlobalAction(GLOBAL_ACTION_BACK);
            handler.postDelayed(() -> performGlobalAction(GLOBAL_ACTION_BACK), 400);
        }, 500);
    }

    private AccessibilityNodeInfo findClickableTarget(AccessibilityNodeInfo node) {
        AccessibilityNodeInfo current = node;
        while (current != null) {
            if (current.isClickable()) {
                return current;
            }
            current = current.getParent();
        }
        return null;
    }

    private AccessibilityNodeInfo findSwitchNearNode(AccessibilityNodeInfo node) {
        if (node.getClassName() != null && node.getClassName().toString().contains("Switch")) {
            return node;
        }

        AccessibilityNodeInfo parent = node.getParent();
        if (parent == null) return null;

        int childCount = parent.getChildCount();
        for (int i = 0; i < childCount; i++) {
            AccessibilityNodeInfo child = parent.getChild(i);
            if (child == null) continue;
            if (child.getClassName() != null && child.getClassName().toString().contains("Switch")) {
                return child;
            }
            if (child.isCheckable()) {
                return child;
            }
        }

        AccessibilityNodeInfo grandParent = parent.getParent();
        if (grandParent == null) return null;

        int grandChildCount = grandParent.getChildCount();
        for (int i = 0; i < grandChildCount; i++) {
            AccessibilityNodeInfo child = grandParent.getChild(i);
            if (child == null) continue;
            AccessibilityNodeInfo switchInTree = searchSwitchRecursively(child, 3);
            if (switchInTree != null) {
                return switchInTree;
            }
        }

        return null;
    }

    private AccessibilityNodeInfo searchSwitchRecursively(AccessibilityNodeInfo node, int maxDepth) {
        if (node == null || maxDepth <= 0) return null;
        if (node.getClassName() != null && node.getClassName().toString().contains("Switch")) {
            return node;
        }
        if (node.isCheckable()) {
            return node;
        }
        int count = node.getChildCount();
        for (int i = 0; i < count; i++) {
            AccessibilityNodeInfo child = node.getChild(i);
            if (child == null) continue;
            AccessibilityNodeInfo result = searchSwitchRecursively(child, maxDepth - 1);
            if (result != null) return result;
        }
        return null;
    }

    @Override
    public void onInterrupt() {
        Log.w(TAG, "BackgroundDataAutomationService interrupted.");
        isProcessingSubMenu = false;
    }

    @Override
    protected void onServiceConnected() {
        super.onServiceConnected();
        Log.i(TAG, "BackgroundDataAutomationService connected and ready.");
    }
}
