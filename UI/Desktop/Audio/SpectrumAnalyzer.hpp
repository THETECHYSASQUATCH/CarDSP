#pragma once

#include <QObject>
#include <QVariantList>
#include <QVector>
#include <vector>

class SpectrumAnalyzer : public QObject {
    Q_OBJECT

    Q_PROPERTY(
        QVariantList bands
        READ bands
        NOTIFY bandsChanged
    )

public:
    explicit SpectrumAnalyzer(QObject* parent = nullptr);

    QVariantList bands() const;

public slots:
    void processSamples(
        const QVector<float>& samples,
        int sampleRate
    );

signals:
    void bandsChanged();

private:
    std::vector<float> buffer_;
    QVariantList bands_;
};
