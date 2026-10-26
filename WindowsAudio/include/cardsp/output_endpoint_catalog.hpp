#pragma once

#include <windows.h>
#include <mmdeviceapi.h>
#include <wrl/client.h>

#include <string>
#include <vector>

namespace cardsp {

struct OutputEndpointInfo {
    std::wstring id;
    std::wstring name;
    bool isDefault = false;
};

class OutputEndpointCatalog {
public:
    HRESULT Enumerate(
        std::vector<OutputEndpointInfo>& endpoints);

    HRESULT GetDefaultId(std::wstring& id);
};

}
