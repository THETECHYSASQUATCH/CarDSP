#include <windows.h>
#include <mmdeviceapi.h>
#include <functiondiscoverykeys_devpkey.h>
#include <wrl/client.h>

#include <iostream>
#include <string>

using Microsoft::WRL::ComPtr;

void enumerate(EDataFlow flow, const wchar_t* category) {
    ComPtr<IMMDeviceEnumerator> enumerator;
    HRESULT hr = CoCreateInstance(
        __uuidof(MMDeviceEnumerator), nullptr,
        CLSCTX_ALL, IID_PPV_ARGS(&enumerator)
    );
    if (FAILED(hr)) {
        std::wcerr << L"Device enumerator failed: 0x"
                   << std::hex << static_cast<unsigned long>(hr) << L"\n";
        return;
    }

    ComPtr<IMMDeviceCollection> collection;
    hr = enumerator->EnumAudioEndpoints(
        flow, DEVICE_STATE_ACTIVE, &collection
    );
    if (FAILED(hr)) {
        std::wcerr << L"Endpoint enumeration failed.\n";
        return;
    }

    UINT count = 0;
    collection->GetCount(&count);

    std::wcout << L"\n" << category << L" (" << count << L")\n";

    for (UINT i = 0; i < count; ++i) {
        ComPtr<IMMDevice> device;
        if (FAILED(collection->Item(i, &device))) continue;

        LPWSTR id = nullptr;
        if (FAILED(device->GetId(&id))) continue;

        ComPtr<IPropertyStore> properties;
        PROPVARIANT name;
        PropVariantInit(&name);

        std::wstring displayName = L"Unnamed device";

        if (SUCCEEDED(device->OpenPropertyStore(STGM_READ, &properties)) &&
            SUCCEEDED(properties->GetValue(PKEY_Device_FriendlyName, &name)) &&
            name.vt == VT_LPWSTR && name.pwszVal) {
            displayName = name.pwszVal;
        }

        std::wcout << L"[" << i << L"] " << displayName << L"\n";
        std::wcout << L"    ID: " << id << L"\n";

        PropVariantClear(&name);
        CoTaskMemFree(id);
    }
}

void showDefaultDevice(EDataFlow flow, const wchar_t* label) {
    ComPtr<IMMDeviceEnumerator> enumerator;

    HRESULT hr = CoCreateInstance(
        __uuidof(MMDeviceEnumerator),
        nullptr,
        CLSCTX_ALL,
        IID_PPV_ARGS(&enumerator)
    );

    if (FAILED(hr)) return;

    ComPtr<IMMDevice> device;

    hr = enumerator->GetDefaultAudioEndpoint(
        flow, eMultimedia, &device
    );

    if (FAILED(hr)) {
        std::wcout << label << L": Not available\n";
        return;
    }

    ComPtr<IPropertyStore> properties;

    if (FAILED(device->OpenPropertyStore(STGM_READ, &properties))) return;

    PROPVARIANT name;
    PropVariantInit(&name);

    hr = properties->GetValue(PKEY_Device_FriendlyName, &name);

    if (SUCCEEDED(hr) && name.vt == VT_LPWSTR && name.pwszVal) {
        std::wcout << label << L": " << name.pwszVal << L"\n";
    }

    PropVariantClear(&name);
}
int wmain() {
    HRESULT hr = CoInitializeEx(nullptr, COINIT_MULTITHREADED);
    if (FAILED(hr)) {
        std::wcerr << L"COM initialization failed.\n";
        return 1;
    }

    std::wcout << L"CarDSP Windows Audio Device Discovery\n";

    enumerate(eRender, L"Playback devices (loopback sources)");
    enumerate(eCapture, L"Recording devices (physical inputs)");

    std::wcout << L"\nAutomatic device selection\n";
    showDefaultDevice(eRender, L"Default loopback source");
    showDefaultDevice(eCapture, L"Default physical input");
    CoUninitialize();
    return 0;
}

