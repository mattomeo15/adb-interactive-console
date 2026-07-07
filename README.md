# adb-interactive-console

A lightweight, native Windows batch-based Text User Interface (TUI) designed to make Android Debug Bridge (ADB) device management interactive, fast, and completely menu-driven over your local wireless network.

> 💡 **Origin Story:** This tool was originally built to take the headache out of managing and running ADB commands on a **Google Chromecast with Google TV**, where typing complex wireless pairing commands, IP addresses, and ports manually is incredibly tedious. It has since been adapted into a universal tool for any wireless Android device!

## 🚀 Features
* **Wireless-First Workflow:** Optimized specifically to streamline connecting and managing devices over Wi-Fi without dealing with messy USB cables.
* **Interactive Terminal Menu:** Clean, keyboard-driven navigation completely within the Windows Command Prompt.
* **Streamlined Commands:** Execute complex wireless ADB commands with simple menu choices—no need to memorize port syntax or pairing flows.
* **Lightweight:** Zero heavy dependencies or installations required; runs entirely natively on Windows.

## 🛠️ Prerequisites & Compatibility
This console was developed and tested using the following environment:
* **Operating System:** Windows 10 / 11
* **ADB Version:** `1.0.41` (SDK Platform-Tools `Version 37.0.0` or higher)
* **Android Device:** Must be connected to the same Wi-Fi network as your PC, with **Wireless Debugging** enabled in Developer Options (e.g., Google Chromecast, Android Phone, or Tablet).

## 📦 Installation & Usage

### Method 1: Pre-Packaged Zip (Easiest)
1. Go to the **Releases** section of this GitHub repository and download the pre-bundled archive.
2. Extract the `.zip` file to a convenient location on your PC. This archive includes both the `adb-interactive-console` script and the exact matching official Google SDK Platform-Tools binaries.
3. Open the extracted folder and double-click `adb_interactive_console.bat` to launch!

### Method 2: Manual Setup
1. Download the latest official **SDK Platform-Tools for Windows** directly from Google:  
   👉 [Android SDK Platform-Tools Official Release](https://developer.android.com/tools/releases/platform-tools)  
   *(Extract the downloaded `.zip` folder to a convenient location on your PC)*
2. Download `adb_interactive_console.bat` from this repository.
3. Drop the `adb_interactive_console.bat` file **directly into the extracted folder** (right next to `adb.exe`).
4. Ensure your Android device and PC are on the same Wi-Fi network and look up your Wireless Debugging IP/Port/Pairing code on your device.
5. Double-click the `.bat` file to launch!

## 📄 License
This project is open-source. Feel free to modify, expand, and adapt it to your own Android workflows.
