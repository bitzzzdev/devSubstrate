# Privacy Policy

Effective Date: [EFFECTIVE DATE]  
Project: devSubstrate / Substrate Data Automation  
Data Controller: [COMPANY NAME]  
Contact: [CONTACT EMAIL]  

---

## 1. Overview and Core Privacy Principle

The `devSubstrate` project and its companion tools (including shell automation scripts and the Substrate Accessibility Service) operate under a strict **zero-telemetry, local-first** architecture.

We do not operate remote user tracking services, do not collect personal analytics, do not log device identifiers to central servers, and do not sell user data.

---

## 2. Information Handled by Software Components

### 2.1 Local Command-Line and Shell Automation Scripts
- **Execution Context**: Scripts run locally on your host computer (via ADB) or on your Android device (via Termux).
- **Data Inspected**: Package names, process identifiers (PIDs), and application user identifiers (UIDs) stored locally on your connected device.
- **Storage and Transmission**: UID lookups and AppOps settings are evaluated in memory and discarded upon execution termination. No telemetry payloads are transmitted to external servers.

### 2.2 On-Device Accessibility Service (`BackgroundDataAutomationService`)
- **Scope of Permission**: The service utilizes Android's `AccessibilityService` API solely to locate the system "Background data" switch within the native Android Settings application.
- **No Data Retention**: The service does not log, extract, store, or transmit screen contents, keystrokes, personal messages, or user credentials.
- **No Network Transmission**: The accessibility service contains no internet access permissions (`android.permission.INTERNET` is omitted from the manifest).

### 2.3 System Private DNS Configurations
- If you apply the optional encrypted DNS configuration (`dns.adguard-dns.com`), DNS lookup requests from your device are resolved via the third-party resolver according to their independent privacy standards. We do not intermediate or monitor this traffic.

---

## 3. Third-Party Subprocessors and Services

This project does not transmit personal data to third-party subprocessors, advertising networks, or analytics providers.

Hosting for the repository and documentation is provided via GitHub (Microsoft Corporation). Interacting with the public repository (issues, pull requests, clones) is subject to the GitHub Privacy Statement.

---

## 4. User Rights and Data Deletion

Because our utilities run locally on your hardware and we do not maintain a central database or user accounts:
- You retain complete ownership and control over your hardware, device logs, and system settings.
- Reverting changes made by the scripts is accomplished directly via the provided `-- resume` and `-- revert` commands or by uninstalling the accessibility package.
- If you communicate with maintainers via [CONTACT EMAIL] or GitHub issues, you have the right to request deletion of that correspondence under GDPR Article 17 or CCPA regulations.

---

## 5. Children's Privacy

The software is intended for software developers and system administrators. It is not directed to individuals under the age of 16, and we do not knowingly solicit or collect personal information from children.

---

## 6. Updates to This Policy

We may update this Privacy Policy from time to time to reflect operational, legal, or regulatory modifications. Any changes will be published directly to this repository with an updated effective date.

---

## 7. Contact Information

For inquiries regarding this Privacy Policy or data protection practices:
- Email: [CONTACT EMAIL]
- Physical Address: [PHYSICAL ADDRESS]
- Data Protection Contact: [DPO CONTACT]
