#include "ImageManager.h"
#include <QDir>
#include <QDebug>
#include <QUrl>

ImageManager::ImageManager(QObject *parent)
    : QObject(parent) {}

void ImageManager::loadFromFolder(const QUrl &folderUrl) {
    QString folderPath = folderUrl.toLocalFile();
    QDir dir(folderPath);

    QStringList filters = { "*.png", "*.jpg", "*.jpeg", "*.bmp" };
    QStringList files = dir.entryList(filters, QDir::Files, QDir::Name);

    imageList.clear();
    for (const QString &file : files)
        imageList << dir.absoluteFilePath(file);

    currentIndex = imageList.isEmpty() ? -1 : 0;

    qDebug() << "[ImageManager] 加载图片数:" << imageList.size();
    emit currentImageChanged();
}

QString ImageManager::currentImage() const {
    if (currentIndex >= 0 && currentIndex < imageList.size())
        return QUrl::fromLocalFile(imageList[currentIndex]).toString();
    return QString();
}

QString ImageManager::lastGoodImage() const {
    if (!m_lastGoodImage.isEmpty())
        return QUrl::fromLocalFile(m_lastGoodImage).toString();
    return QString();
}

void ImageManager::markCurrent(bool isGood) {
    if (currentIndex < 0 || currentIndex >= imageList.size())
        return;

    const QString &img = imageList[currentIndex];

    if (isGood) {
        m_lastGoodImage = img;
        emit lastGoodImageChanged();
        qDebug() << "[ImageManager] 标记好图:" << img;
    } else {
        qDebug() << "[ImageManager] 标记坏图:" << img;
    }

    // 后续可加入写入标注结果到文件
}

void ImageManager::next() {
    if (currentIndex + 1 < imageList.size()) {
        currentIndex++;
        emit currentImageChanged();
    }
}

void ImageManager::previous() {
    if (currentIndex - 1 >= 0) {
        currentIndex--;
        emit currentImageChanged();
    }
}
