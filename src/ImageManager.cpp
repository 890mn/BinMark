#include "ImageManager.h"
#include <QDir>
#include <QFileInfo>
#include <QDebug>
#include <QStandardPaths>
#include <QFile>
#include <QTextStream>
#include <QUrl>

ImageManager::ImageManager(QObject *parent)
    : QObject(parent)
{}

void ImageManager::loadFromFolder(const QUrl &folderUrl)
{
    QString folderPath = folderUrl.toLocalFile();
    m_currentFolder = folderPath;

    QDir dir(folderPath);
    QStringList filters = {"*.png", "*.jpg", "*.jpeg", "*.bmp"};
    QFileInfoList fileInfos = dir.entryInfoList(filters, QDir::Files, QDir::Name);

    m_imagePaths.clear();
    for (const QFileInfo &fileInfo : fileInfos) {
        m_imagePaths.append(fileInfo.absoluteFilePath());
    }

    m_currentIndex = 0;
    emit imageChanged();
}

QUrl ImageManager::currentImage() const
{
    if (m_currentIndex >= 0 && m_currentIndex < m_imagePaths.size())
        return QUrl::fromLocalFile(m_imagePaths[m_currentIndex]);
    return {};
}

QUrl ImageManager::lastGoodImage() const
{
    return QUrl::fromLocalFile(m_lastGoodImage);
}

int ImageManager::currentIndex() const
{
    return m_currentIndex;
}

int ImageManager::totalCount() const
{
    return m_imagePaths.size();
}

void ImageManager::next()
{
    if (m_currentIndex < m_imagePaths.size() - 1) {
        ++m_currentIndex;
        emit imageChanged();
    }
}

void ImageManager::previous()
{
    if (m_currentIndex > 0) {
        --m_currentIndex;
        emit imageChanged();
    }
}

void ImageManager::markCurrent(bool isGood)
{
    if (m_currentIndex < 0 || m_currentIndex >= m_imagePaths.size())
        return;

    QString currentPath = m_imagePaths[m_currentIndex];
    QFileInfo info(currentPath);
    QString folderName = isGood ? "Well" : "Bad";
    QDir dir(m_currentFolder);
    QString targetDir = dir.absoluteFilePath(folderName);

    if (!dir.exists(folderName))
        dir.mkdir(folderName);

    QString targetPath = QDir(targetDir).filePath(info.fileName());

    if (QFile::rename(currentPath, targetPath)) {
        qDebug() << "[ImageManager] 移动成功:" << targetPath;

        // 记录 CSV
        QString csvPath = dir.filePath("BinMark_result.csv");
        QFile file(csvPath);
        if (file.open(QIODevice::Append | QIODevice::Text)) {
            QTextStream out(&file);
            out << info.fileName() << "," << (isGood ? "good" : "bad") << "\n";
            file.close();
        }

        if (isGood)
            m_lastGoodImage = targetPath;

        m_imagePaths.removeAt(m_currentIndex);

        if (m_currentIndex >= m_imagePaths.size())
            m_currentIndex = m_imagePaths.size() - 1;
    } else {
        qDebug() << "[ImageManager] ❌ 移动失败:" << currentPath;
    }

    emit imageChanged();
}
