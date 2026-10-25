#pragma once

#include <windows.h>
#include <mmdeviceapi.h>
#include <atomic>

namespace cardsp {

class DeviceNotifications final : public IMMNotificationClient {
public:
    DeviceNotifications() = default;

    ULONG STDMETHODCALLTYPE AddRef() override;
    ULONG STDMETHODCALLTYPE Release() override;

    HRESULT STDMETHODCALLTYPE QueryInterface(
        REFIID iid, void** object) override;

    HRESULT STDMETHODCALLTYPE OnDeviceStateChanged(
        LPCWSTR deviceId, DWORD newState) override;

    HRESULT STDMETHODCALLTYPE OnDeviceAdded(
        LPCWSTR deviceId) override;

    HRESULT STDMETHODCALLTYPE OnDeviceRemoved(
        LPCWSTR deviceId) override;

    HRESULT STDMETHODCALLTYPE OnDefaultDeviceChanged(
        EDataFlow flow, ERole role, LPCWSTR deviceId) override;

    HRESULT STDMETHODCALLTYPE OnPropertyValueChanged(
        LPCWSTR deviceId, const PROPERTYKEY key) override;

private:
    std::atomic<ULONG> references_{1};
};

}
