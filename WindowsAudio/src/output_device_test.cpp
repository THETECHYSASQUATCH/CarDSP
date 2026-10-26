#include "cardsp/output_endpoint_catalog.hpp"

#include <windows.h>
#include <iostream>
#include <vector>

int wmain() {
    HRESULT hr = CoInitializeEx(
        nullptr, COINIT_MULTITHREADED);

    if (FAILED(hr)) {
        std::wcerr << L"COM initialization failed: "
                   << std::hex << hr << L"\n";
        return 1;
    }

    cardsp::OutputEndpointCatalog catalog;
    std::vector<cardsp::OutputEndpointInfo> endpoints;

    hr = catalog.Enumerate(endpoints);

    if (FAILED(hr)) {
        std::wcerr << L"Enumeration failed: "
                   << std::hex << hr << L"\n";
        CoUninitialize();
        return 1;
    }

    std::wcout << L"\nCarDSP Audio Output Discovery\n";
    std::wcout << L"============================\n";

    for (const auto& endpoint : endpoints) {
        std::wcout << L"\nDevice: " << endpoint.name;
        std::wcout << L"\nDefault: "
                   << (endpoint.isDefault ? L"Yes" : L"No");
        std::wcout << L"\nID: " << endpoint.id << L"\n";
    }

    std::wcout << L"\nTotal playback devices: "
               << endpoints.size() << L"\n";

    CoUninitialize();
    return 0;
}
