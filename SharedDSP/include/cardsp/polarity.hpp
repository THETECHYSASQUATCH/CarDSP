#pragma once

namespace cardsp {

class Polarity {
public:
    void setInverted(bool inverted) noexcept {
        inverted_ = inverted;
    }

    bool inverted() const noexcept {
        return inverted_;
    }

    float process(float sample) const noexcept {
        return inverted_ ? -sample : sample;
    }

private:
    bool inverted_ = false;
};

} // namespace cardsp
