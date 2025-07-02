#ifndef IMAGEMANAGER_H
#define IMAGEMANAGER_H

#pragma once

#include <QObject>
#include <QStringList>
#include <QMap>

class ImageManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString currentImage READ currentImage NOTIFY currentImageChanged)

public:
    explicit ImageManager(QObject *parent = nullptr);

    Q_INVOKABLE void loadFromFolder(const QString &folderPath);
    Q_INVOKABLE void markCurrent(bool isGood);
    Q_INVOKABLE void next();
    Q_INVOKABLE void previous();

    QString currentImage() const;

signals:
    void currentImageChanged();

private:
    QStringList imageList;
    QMap<QString, bool> markMap;
    int currentIndex = 0;
};

#endif // IMAGEMANAGER_H
