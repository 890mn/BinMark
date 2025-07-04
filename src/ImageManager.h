#ifndef IMAGEMANAGER_H
#define IMAGEMANAGER_H

#pragma once

#include <QObject>
#include <QStringList>

class ImageManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString currentImage READ currentImage NOTIFY currentImageChanged)
    Q_PROPERTY(QString lastGoodImage READ lastGoodImage NOTIFY lastGoodImageChanged)

public:
    explicit ImageManager(QObject *parent = nullptr);

    Q_INVOKABLE void loadFromFolder(const QUrl &folderUrl);
    Q_INVOKABLE void markCurrent(bool isGood);
    Q_INVOKABLE void next();
    Q_INVOKABLE void previous();

    QString currentImage() const;
    QString lastGoodImage() const;

signals:
    void currentImageChanged();
    void lastGoodImageChanged();

private:
    QStringList imageList;
    int currentIndex = -1;
    QString m_lastGoodImage;
};

#endif // IMAGEMANAGER_H
