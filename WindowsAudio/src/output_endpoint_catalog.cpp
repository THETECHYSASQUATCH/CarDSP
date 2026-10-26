#include "cardsp/output_endpoint_catalog.hpp"

#include <functiondiscoverykeys_devpkey.h>
#include <propvarutil.h>

#include <utility>

namespace cardsp {

HRESULT OutputEndpointCatalog::GetDefaultId(
    std::wstring& id) {

    id.clear();

    Microsoft::WRL::ComPtr<IMMDeviceEnumerator> enumerator;

    HRESULT hr = CoCreateInstance(
        __uuidof(MMDeviceEnumerator),
        nullptr,
        CLSCTX_ALL,
        IID_PPV_ARGS(&enumerator));

    if (FAILED(hr)) return hr;

    Microsoft::WRL::ComPtr<IMMDevice> device;

    hr = enumerator->GetDefaultAudioEndpoint(
        eRender, eMultimedia, &device);

    if (FAILED(hr)) return hr;

    LPWSTR rawId = nullptr;

    hr = device->GetId(&rawId);

    if (SUCCEEDED(hr)) {
        id = rawId;
        CoTaskMemFree(rawId);
    }

    return hr;
}

HRESULT OutputEndpointCatalog::Enumerate(
    std::vector<OutputEndpointInfo>& endpoints) {

    endpoints.clear();

    Microsoft::WRL::ComPtr<IMMDeviceEnumerator> enumerator;

    HRESULT hr = CoCreateInstance(
        __uuidof(MMDeviceEnumerator),
        nullptr,
        CLSCTX_ALL,
        IID_PPV_ARGS(&enumerator));

    if (FAILED(hr)) return hr;

    std::wstring defaultId;
    GetDefaultId(defaultId);

    Microsoft::WRL::ComPtr<IMMDeviceCollection> collection;

    hr = enumerator->EnumAudioEndpoints(
        eRender,
        DEVICE_STATE_ACTIVE,
        &collection);

    if (FAILED(hr)) return hr;

    UINT count = 0;

    hr = collection->GetCount(&count);
    if (FAILED(hr)) return hr;

    for (UINT i = 0; i < count; ++i) {

        Microsoft::WRL::ComPtr<IMMDevice> device;

        hr = collection->Item(i, &device);
        if (FAILED(hr)) return hr;

        LPWSTR rawId = nullptr;

        hr = device->GetId(&rawId);
        if (FAILED(hr)) return hr;

        OutputEndpointInfo endpoint;
        endpoint.id = rawId;
        endpoint.isDefault = endpoint.id == defaultId;

        CoTaskMemFree(rawId);

        Microsoft::WRL::ComPtr<IPropertyStore> properties;

        hr = device->OpenPropertyStore(
            STGM_READ,
            &properties);

        if (FAILED(hr)) return hr;

        PROPVARIANT value;
        PropVariantInit(&value);

        hr = properties->GetValue(
            PKEY_Device_FriendlyName,
            &value);

        if (SUCCEEDED(hr) &&
            value.vt == VT_LPWSTR &&
            value.pwszVal) {
            endpoint.name = value.pwszVal;
        } else {
            endpoint.name = L"Unnamed Audio Device";
        }

        PropVariantClear(&value);

        endpoints.push_back(std::move(endpoint));
    }

    return S_OK;
}

}
