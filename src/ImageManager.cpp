#include "ImageManager.h"
#include <QDir>
#include <QDebug>
#include <QFileInfo>

ImageManager::ImageManager(QObject *parent)
    : QObject(parent)
{
}

QUrl ImageManager::currentImage() const
{
    if (m_currentIndex >= 0 && m_currentIndex < m_images.size())
        return QUrl::fromLocalFile(m_images[m_currentIndex]);
    return QUrl();
}

QUrl ImageManager::lastGoodImage() const
{
    return m_lastGoodImage;
}

int ImageManager::currentIndex() const
{
    return m_currentIndex;
}

int ImageManager::totalCount() const
{
    return m_images.size();
}

void ImageManager::loadFromFolder(const QUrl &folderUrl)
{
    QString folderPath = folderUrl.toLocalFile();
    QDir dir(folderPath);
    QStringList filters = { "*.png", "*.jpg", "*.jpeg", "*.bmp" };
    QFileInfoList files = dir.entryInfoList(filters, QDir::Files | QDir::NoDotAndDotDot, QDir::Name);

    m_images.clear();
    for (const QFileInfo &file : files) {
        m_images << file.absoluteFilePath();
    }

    m_currentIndex = m_images.isEmpty() ? -1 : 0;

    qDebug() << "[ImageManager] 加载图片数:" << m_images.size();

    emit currentIndexChanged();
    emit totalCountChanged();
    emit currentImageChanged();
}

void ImageManager::markCurrent(bool good)
{
    if (m_currentIndex < 0 || m_currentIndex >= m_images.size())
        return;

    QString imgPath = m_images[m_currentIndex];

    qDebug() << "[ImageManager] 标记为" << (good ? "好图" : "坏图") << ":" << imgPath;

    if (good) {
        m_lastGoodImage = QUrl::fromLocalFile(imgPath);
        emit lastGoodImageChanged();
    }

    next();
}

void ImageManager::next()
{
    if (m_currentIndex + 1 < m_images.size()) {
        m_currentIndex++;
        emit currentIndexChanged();
        emit currentImageChanged();
    }
}

void ImageManager::previous()
{
    if (m_currentIndex > 0) {
        m_currentIndex--;
        emit currentIndexChanged();
        emit currentImageChanged();
    }
}
