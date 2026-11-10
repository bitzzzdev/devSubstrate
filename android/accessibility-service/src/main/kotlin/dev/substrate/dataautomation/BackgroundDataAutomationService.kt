package dev.substrate.dataautomation

import android.accessibilityservice.AccessibilityService
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

/**
 * BackgroundDataAutomationService: An Android Accessibility Service that automatically
 * inspects system App Info settings and disables the "Background data" toggle for
 * targeted apps.
 *
 * This provides reliable background traffic restriction across OEM skins (ColorOS,
 * MIUI, FuntouchOS, One UI) where NetPolicy blacklists might be ignored or reset.
 */
class BackgroundDataAutomationService : AccessibilityService() {

    companion object {
        private const val TAG = "SubstrateDataAuto"

        private val DATA_MENU_KEYWORDS = listOf(
            "Mobile data & Wi-Fi",
            "Mobile data",
            "Data usage",
            "Data & Wi-Fi",
            "Mobile data usage",
            "Cellular data"
        )

        private val BG_DATA_KEYWORDS = listOf(
            "Background data",
            "Allow background data usage",
            "Allow background data"
        )
    }

    private val handler = Handler(Looper.getMainLooper())
    private var lastActionTimestamp: Long = 0
    private var isProcessingSubMenu: Boolean = false

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        val eventType = event.eventType
        if (eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED &&
            eventType != AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
        ) {
            return
        }

        val currentTime = System.currentTimeMillis()
        if (currentTime - lastActionTimestamp < 600) {
            return
        }

        val rootNode = rootInActiveWindow ?: return

        try {
            // First check if we are already inside the data usage sub-menu
            if (processBackgroundDataToggle(rootNode)) {
                lastActionTimestamp = currentTime
                return
            }

            // Otherwise, check if we are in App Info root and need to enter data sub-menu
            if (!isProcessingSubMenu && processAppInfoScreen(rootNode)) {
                lastActionTimestamp = currentTime
                return
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error processing accessibility tree: ${e.message}", e)
        }
    }

    private fun processAppInfoScreen(rootNode: AccessibilityNodeInfo): Boolean {
        for (keyword in DATA_MENU_KEYWORDS) {
            val matchingNodes = rootNode.findAccessibilityNodeInfosByText(keyword)
            if (!matchingNodes.isNullOrEmpty()) {
                for (node in matchingNodes) {
                    val targetNode = findClickableTarget(node)
                    if (targetNode != null) {
                        Log.i(TAG, "Navigating into data menu: '$keyword'")
                        val clicked = targetNode.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                        if (clicked) {
                            isProcessingSubMenu = true
                            // Reset state flag after timeout if user navigates away
                            handler.postDelayed({ isProcessingSubMenu = false }, 5000)
                            return true
                        }
                    }
                }
            }
        }
        return false
    }

    private fun processBackgroundDataToggle(rootNode: AccessibilityNodeInfo): Boolean {
        for (keyword in BG_DATA_KEYWORDS) {
            val matchingNodes = rootNode.findAccessibilityNodeInfosByText(keyword)
            if (!matchingNodes.isNullOrEmpty()) {
                for (node in matchingNodes) {
                    val switchNode = findSwitchNearNode(node)
                    if (switchNode != null && switchNode.isCheckable) {
                        if (switchNode.isChecked) {
                            Log.i(TAG, "Found active Background Data switch for '$keyword'. Toggling OFF.")
                            val clicked = switchNode.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                            if (clicked) {
                                completeAndNavigateBack()
                                return true
                            }
                        } else {
                            Log.i(TAG, "Background Data switch for '$keyword' is already OFF.")
                            completeAndNavigateBack()
                            return true
                        }
                    }
                }
            }
        }
        return false
    }

    private fun completeAndNavigateBack() {
        isProcessingSubMenu = false
        // Delay slightly so switch animation settles, then press back to return
        handler.postDelayed({
            performGlobalAction(GLOBAL_ACTION_BACK)
            handler.postDelayed({
                performGlobalAction(GLOBAL_ACTION_BACK)
            }, 400)
        }, 500)
    }

    private fun findClickableTarget(node: AccessibilityNodeInfo?): AccessibilityNodeInfo? {
        var current = node
        while (current != null) {
            if (current.isClickable) {
                return current
            }
            current = current.parent
        }
        return null
    }

    private fun findSwitchNearNode(node: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        // 1. Direct match on switch widget
        if (node.className != null && node.className.toString().contains("Switch")) {
            return node
        }

        // 2. Search children of parent
        val parent = node.parent ?: return null
        val childCount = parent.childCount
        for (i in 0 until childCount) {
            val child = parent.getChild(i) ?: continue
            if (child.className != null && child.className.toString().contains("Switch")) {
                return child
            }
            if (child.isCheckable) {
                return child
            }
        }

        // 3. Search grandparent container if layout wraps label and switch in separate viewgroups
        val grandParent = parent.parent ?: return null
        val grandChildCount = grandParent.childCount
        for (i in 0 until grandChildCount) {
            val child = grandParent.getChild(i) ?: continue
            val switchInTree = searchSwitchRecursively(child, maxDepth = 3)
            if (switchInTree != null) {
                return switchInTree
            }
        }

        return null
    }

    private fun searchSwitchRecursively(node: AccessibilityNodeInfo?, maxDepth: Int): AccessibilityNodeInfo? {
        if (node == null || maxDepth <= 0) return null
        if (node.className != null && node.className.toString().contains("Switch")) {
            return node
        }
        if (node.isCheckable) {
            return node
        }
        val count = node.childCount
        for (i in 0 until count) {
            val child = node.getChild(i) ?: continue
            val result = searchSwitchRecursively(child, maxDepth - 1)
            if (result != null) return result
        }
        return null
    }

    override fun onInterrupt() {
        Log.w(TAG, "BackgroundDataAutomationService interrupted.")
        isProcessingSubMenu = false
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.i(TAG, "BackgroundDataAutomationService connected and ready.")
    }
}
