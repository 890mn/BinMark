#include "ImageManager.h"
#include <QDir>
#include <QDebug>

ImageManager::ImageManager(QObject *parent) : QObject(parent) {}

void ImageManager::loadFromFolder(const QString &folderPath)
{
    QDir dir(folderPath);
    QStringList filters = {"*.png", "*.jpg", "*.jpeg", "*.bmp"};
    imageList = dir.entryList(filters, QDir::Files, QDir::Name);
    for (auto &img : imageList)
        img = dir.absoluteFilePath(img);

    currentIndex = 0;
    emit currentImageChanged();
}

void ImageManager::markCurrent(bool isGood)
{
    if (currentIndex >= 0 && currentIndex < imageList.size())
        markMap[imageList[currentIndex]] = isGood;
}

void ImageManager::next()
{
    if (currentIndex + 1 < imageList.size()) {
        ++currentIndex;
        emit currentImageChanged();
    }
}

void ImageManager::previous()
{
    if (currentIndex > 0) {
        --currentIndex;
        emit currentImageChanged();
    }
}

QString ImageManager::currentImage() const
{
    if (currentIndex >= 0 && currentIndex < imageList.size())
        return imageList[currentIndex];
    return {};
}
