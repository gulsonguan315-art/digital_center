#include "flutter_window.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"

namespace {
constexpr UINT kRemoteSystemCommandMessage = WM_APP + 1;
constexpr WPARAM kRemoteCommandHome = 1;
constexpr WPARAM kRemoteCommandVolumeUp = 2;
constexpr WPARAM kRemoteCommandVolumeDown = 3;
}  // namespace

FlutterWindow* FlutterWindow::active_instance_ = nullptr;

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());
  remote_key_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "gulson/remote_system_keys",
          &flutter::StandardMethodCodec::GetInstance());
  InstallKeyboardHook();

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    // Intentionally left empty to allow Dart layer (window_manager) 
    // to have full control over window visibility and prevent race conditions.
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  RemoveKeyboardHook();
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case kRemoteSystemCommandMessage:
      switch (wparam) {
        case kRemoteCommandHome:
          DispatchRemoteSystemCommand("home");
          return 0;
        case kRemoteCommandVolumeUp:
          DispatchRemoteSystemCommand("volumeUp");
          return 0;
        case kRemoteCommandVolumeDown:
          DispatchRemoteSystemCommand("volumeDown");
          return 0;
      }
      break;
    case WM_APPCOMMAND: {
      const int command = GET_APPCOMMAND_LPARAM(lparam);
      switch (command) {
        case APPCOMMAND_BROWSER_HOME:
          DispatchRemoteSystemCommand("home");
          return 1;
        case APPCOMMAND_VOLUME_UP:
          DispatchRemoteSystemCommand("volumeUp");
          return 1;
        case APPCOMMAND_VOLUME_DOWN:
          DispatchRemoteSystemCommand("volumeDown");
          return 1;
      }
      break;
    }
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

void FlutterWindow::DispatchRemoteSystemCommand(const std::string& command) {
  if (!remote_key_channel_) {
    return;
  }

  remote_key_channel_->InvokeMethod(
      "remoteSystemKey",
      std::make_unique<flutter::EncodableValue>(command));
}

LRESULT CALLBACK FlutterWindow::KeyboardHookProc(int n_code, WPARAM wparam,
                                                 LPARAM lparam) noexcept {
  if (n_code < 0 || lparam == 0) {
    return CallNextHookEx(nullptr, n_code, wparam, lparam);
  }

  const auto* key_info = reinterpret_cast<KBDLLHOOKSTRUCT*>(lparam);
  if (key_info == nullptr) {
    return CallNextHookEx(nullptr, n_code, wparam, lparam);
  }

  if (key_info->vkCode != VK_VOLUME_UP && key_info->vkCode != VK_VOLUME_DOWN) {
    return CallNextHookEx(nullptr, n_code, wparam, lparam);
  }

  if (active_instance_ == nullptr ||
      !active_instance_->ShouldInterceptSystemVolumeKey()) {
    return CallNextHookEx(nullptr, n_code, wparam, lparam);
  }

  if (wparam == WM_KEYDOWN || wparam == WM_SYSKEYDOWN) {
    const HWND window_handle = active_instance_->GetHandle();
    if (window_handle != nullptr) {
      const WPARAM command = key_info->vkCode == VK_VOLUME_UP
                                 ? kRemoteCommandVolumeUp
                                 : kRemoteCommandVolumeDown;
      PostMessage(window_handle, kRemoteSystemCommandMessage, command, 0);
    }
  }

  return 1;
}

void FlutterWindow::InstallKeyboardHook() {
  active_instance_ = this;
  if (keyboard_hook_ != nullptr) {
    return;
  }

  keyboard_hook_ = SetWindowsHookEx(WH_KEYBOARD_LL, KeyboardHookProc,
                                    GetModuleHandle(nullptr), 0);
}

void FlutterWindow::RemoveKeyboardHook() {
  if (keyboard_hook_ != nullptr) {
    UnhookWindowsHookEx(keyboard_hook_);
    keyboard_hook_ = nullptr;
  }
  if (active_instance_ == this) {
    active_instance_ = nullptr;
  }
}

bool FlutterWindow::ShouldInterceptSystemVolumeKey() {
  const HWND handle = GetHandle();
  return handle != nullptr && GetForegroundWindow() == handle;
}
