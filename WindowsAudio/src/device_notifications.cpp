#include "cardsp/device_notifications.hpp"

#include <iostream>

namespace cardsp {

ULONG STDMETHODCALLTYPE DeviceNotifications::AddRef() {
    return ++references_;
}

ULONG STDMETHODCALLTYPE DeviceNotifications::Release() {
    const ULONG count = --references_;
    if (count == 0) {
        delete this;
    }
    return count;
}

HRESULT STDMETHODCALLTYPE DeviceNotifications::QueryInterface(
    REFIID iid, void** object) {

    if (!object) return E_POINTER;
    *object = nullptr;

    if (iid == __uuidof(IUnknown) ||
        iid == __uuidof(IMMNotificationClient)) {
        *object = static_cast<IMMNotificationClient*>(this);
        AddRef();
        return S_OK;
    }

    return E_NOINTERFACE;
}

HRESULT STDMETHODCALLTYPE DeviceNotifications::OnDeviceStateChanged(
    LPCWSTR deviceId, DWORD newState) {

    std::wcout << L"[Audio] State changed: "
               << (deviceId ? deviceId : L"(unknown)")
               << L" state=" << newState << L"\n";
    return S_OK;
}

HRESULT STDMETHODCALLTYPE DeviceNotifications::OnDeviceAdded(
    LPCWSTR deviceId) {

    std::wcout << L"[Audio] Added: "
               << (deviceId ? deviceId : L"(unknown)") << L"\n";
    return S_OK;
}

HRESULT STDMETHODCALLTYPE DeviceNotifications::OnDeviceRemoved(
    LPCWSTR deviceId) {

    std::wcout << L"[Audio] Removed: "
               << (deviceId ? deviceId : L"(unknown)") << L"\n";
    return S_OK;
}

HRESULT STDMETHODCALLTYPE DeviceNotifications::OnDefaultDeviceChanged(
    EDataFlow flow, ERole role, LPCWSTR deviceId) {

    std::wcout << L"[Audio] Default changed: "
               << (flow == eRender ? L"Playback" : L"Recording")
               << L" role=" << static_cast<int>(role)
               << L" id=" << (deviceId ? deviceId : L"(none)")
               << L"\n";
    return S_OK;
}

HRESULT STDMETHODCALLTYPE DeviceNotifications::OnPropertyValueChanged(
    LPCWSTR, const PROPERTYKEY) {
    return S_OK;
}

}
