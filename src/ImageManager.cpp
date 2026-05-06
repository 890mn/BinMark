#include "ImageManager.h"

#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSettings>
#include <QTextStream>
#include <QDateTime>
#include <QUrl>
#include <QVariantMap>
#include <QtGlobal>

#include <utility>

ImageManager::ImageManager(QObject *parent)
    : QObject(parent)
{
    loadArchives();
}

void ImageManager::loadFromFolder(const QUrl &folderUrl)
{
    const QString folderPath = normalizeFolderPath(folderUrl);
    if (folderPath.isEmpty())
        return;

    m_currentFolder = folderPath;
    rememberRecentFolder(folderPath);

    QDir dir(folderPath);
    const QStringList filters = {"*.png", "*.jpg", "*.jpeg", "*.bmp"};
    const QFileInfoList fileInfos = dir.entryInfoList(filters, QDir::Files, QDir::Name);

    m_imagePaths.clear();
    m_history.clear();
    m_lastGoodImage.clear();
    loadStatusFile();

    for (const QFileInfo &fileInfo : fileInfos)
        m_imagePaths.append(fileInfo.absoluteFilePath());

    m_currentIndex = m_imagePaths.isEmpty() ? -1 : 0;
    emit imageChanged();
    emit historyChanged();
    emit statusChanged();
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

QVariantList ImageManager::history() const
{
    QVariantList items;
    items.reserve(m_history.size());

    for (int i = 0; i < m_history.size(); ++i) {
        const HistoryItem &item = m_history.at(i);
        QVariantMap map;
        map.insert(QStringLiteral("index"), i);
        map.insert(QStringLiteral("fileName"), item.fileName);
        map.insert(QStringLiteral("isGood"), item.isGood);
        map.insert(QStringLiteral("label"), item.isGood ? QStringLiteral("Accepted") : QStringLiteral("Rejected"));
        map.insert(QStringLiteral("originalPath"), item.originalPath);
        map.insert(QStringLiteral("targetPath"), item.targetPath);
        map.insert(QStringLiteral("imageUrl"), QUrl::fromLocalFile(item.targetPath));
        items.append(map);
    }

    return items;
}

int ImageManager::historyCount() const
{
    return m_history.size();
}

QVariantList ImageManager::statusRecords() const
{
    QVariantList items;
    const int itemCount = qMin(m_statusVisibleCount, m_statusRecords.size());
    items.reserve(itemCount);

    for (int i = 0; i < itemCount; ++i) {
        const StatusRecord &item = m_statusRecords.at(i);
        const bool isAccepted = item.status == QStringLiteral("a");
        QVariantMap map;
        map.insert(QStringLiteral("index"), i);
        map.insert(QStringLiteral("fileName"), item.fileName);
        map.insert(QStringLiteral("status"), item.status);
        map.insert(QStringLiteral("label"), isAccepted ? QStringLiteral("Accepted") : QStringLiteral("Rejected"));
        map.insert(QStringLiteral("isGood"), isAccepted);
        map.insert(QStringLiteral("targetPath"), item.targetPath);
        map.insert(QStringLiteral("imageUrl"), QUrl::fromLocalFile(item.targetPath));
        map.insert(QStringLiteral("time"), item.timestamp);
        items.append(map);
    }

    return items;
}

int ImageManager::statusCount() const
{
    return m_statusRecords.size();
}

int ImageManager::acceptedCount() const
{
    return m_acceptedCount;
}

int ImageManager::rejectedCount() const
{
    return m_rejectedCount;
}

bool ImageManager::canLoadMoreStatus() const
{
    return m_statusVisibleCount < m_statusRecords.size();
}

QVariantList ImageManager::recentFolders() const
{
    return folderListToVariantList(m_recentFolders);
}

QVariantList ImageManager::pinnedFolders() const
{
    return folderListToVariantList(m_pinnedFolders);
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

    const QString currentPath = m_imagePaths[m_currentIndex];
    const int restoreIndex = m_currentIndex;
    const QFileInfo info(currentPath);
    const QString folderName = isGood ? QStringLiteral("Well") : QStringLiteral("Bad");
    QDir dir(m_currentFolder);
    const QString targetDir = dir.absoluteFilePath(folderName);

    if (!dir.exists(folderName))
        dir.mkdir(folderName);

    const QString targetPath = QDir(targetDir).filePath(info.fileName());

    if (QFile::rename(currentPath, targetPath)) {
        qDebug() << "[ImageManager] moved:" << targetPath;
        appendCsvRecord(info.fileName(), isGood);
        appendStatusRecord(info.fileName(), targetPath, isGood);

        HistoryItem historyItem;
        historyItem.originalPath = currentPath;
        historyItem.targetPath = targetPath;
        historyItem.fileName = info.fileName();
        historyItem.isGood = isGood;
        historyItem.restoreIndex = restoreIndex;
        m_history.prepend(historyItem);

        if (isGood)
            m_lastGoodImage = targetPath;

        m_imagePaths.removeAt(m_currentIndex);
        if (m_imagePaths.isEmpty())
            m_currentIndex = -1;
        else if (m_currentIndex >= m_imagePaths.size())
            m_currentIndex = m_imagePaths.size() - 1;
    } else {
        qWarning() << "[ImageManager] move failed:" << currentPath << "->" << targetPath;
    }

    emit imageChanged();
    emit historyChanged();
    emit statusChanged();
}

bool ImageManager::undoHistoryItem(int index)
{
    if (index < 0 || index >= m_history.size())
        return false;

    const HistoryItem item = m_history.at(index);
    if (!QFile::exists(item.targetPath)) {
        qWarning() << "[ImageManager] undo source missing:" << item.targetPath;
        return false;
    }

    if (QFile::exists(item.originalPath)) {
        qWarning() << "[ImageManager] undo target already exists:" << item.originalPath;
        return false;
    }

    QDir originalDir = QFileInfo(item.originalPath).absoluteDir();
    if (!originalDir.exists() && !originalDir.mkpath(QStringLiteral("."))) {
        qWarning() << "[ImageManager] failed to create undo target dir:" << originalDir.absolutePath();
        return false;
    }

    if (!QFile::rename(item.targetPath, item.originalPath)) {
        qWarning() << "[ImageManager] undo rename failed:" << item.targetPath << "->" << item.originalPath;
        return false;
    }

    removeCsvRecord(item.fileName, item.isGood);
    removeStatusRecord(item.fileName, item.isGood);
    m_history.removeAt(index);

    if (QFileInfo(item.originalPath).absolutePath() == m_currentFolder
        && !m_imagePaths.contains(item.originalPath)) {
        const int insertIndex = qBound(0, item.restoreIndex, m_imagePaths.size());
        m_imagePaths.insert(insertIndex, item.originalPath);
        m_currentIndex = insertIndex;
    }

    refreshLastGoodImage();
    emit imageChanged();
    emit historyChanged();
    emit statusChanged();
    return true;
}

void ImageManager::loadMoreStatus()
{
    if (!canLoadMoreStatus())
        return;

    m_statusVisibleCount = qMin(m_statusVisibleCount + 30, m_statusRecords.size());
    emit statusChanged();
}

bool ImageManager::toggleStatusRecord(int index)
{
    if (index < 0 || index >= m_statusRecords.size())
        return false;

    StatusRecord &record = m_statusRecords[index];
    const bool oldIsGood = record.status == QStringLiteral("a");
    const bool newIsGood = !oldIsGood;
    const QString newStatus = newIsGood ? QStringLiteral("a") : QStringLiteral("r");
    const QString targetFolderName = newIsGood ? QStringLiteral("Well") : QStringLiteral("Bad");

    if (!QFile::exists(record.targetPath)) {
        qWarning() << "[ImageManager] status source missing:" << record.targetPath;
        return false;
    }

    QDir dir(m_currentFolder);
    if (!dir.exists(targetFolderName) && !dir.mkdir(targetFolderName)) {
        qWarning() << "[ImageManager] failed to create status target folder:" << targetFolderName;
        return false;
    }

    const QString newTargetPath = QDir(dir.filePath(targetFolderName)).filePath(record.fileName);
    if (QFile::exists(newTargetPath)) {
        qWarning() << "[ImageManager] status target already exists:" << newTargetPath;
        return false;
    }

    const QString oldTargetPath = record.targetPath;
    if (!QFile::rename(oldTargetPath, newTargetPath)) {
        qWarning() << "[ImageManager] status move failed:" << oldTargetPath << "->" << newTargetPath;
        return false;
    }

    record.status = newStatus;
    record.targetPath = newTargetPath;
    record.timestamp = QDateTime::currentDateTime().toString(Qt::ISODate);

    if (newIsGood) {
        ++m_acceptedCount;
        m_rejectedCount = qMax(0, m_rejectedCount - 1);
    } else {
        ++m_rejectedCount;
        m_acceptedCount = qMax(0, m_acceptedCount - 1);
    }

    for (HistoryItem &item : m_history) {
        if (item.targetPath == oldTargetPath || item.fileName == record.fileName) {
            item.targetPath = newTargetPath;
            item.isGood = newIsGood;
        }
    }

    removeCsvRecord(record.fileName, oldIsGood);
    appendCsvRecord(record.fileName, newIsGood);
    saveStatusFile();
    refreshLastGoodImage();

    emit imageChanged();
    emit historyChanged();
    emit statusChanged();
    return true;
}

bool ImageManager::addPinnedFolder(const QUrl &folderUrl)
{
    const QString folderPath = normalizeFolderPath(folderUrl);
    if (folderPath.isEmpty())
        return false;

    QFileInfo info(folderPath);
    if (!info.exists() || !info.isDir())
        return false;

    m_pinnedFolders.removeAll(folderPath);
    m_pinnedFolders.prepend(folderPath);
    saveArchives();
    emit archivesChanged();
    return true;
}

bool ImageManager::removePinnedFolder(const QString &folderPath)
{
    const QString normalizedPath = normalizeFolderPath(folderPath);
    if (normalizedPath.isEmpty())
        return false;

    const bool removed = m_pinnedFolders.removeAll(normalizedPath) > 0;
    if (removed) {
        saveArchives();
        emit archivesChanged();
    }
    return removed;
}

void ImageManager::clearRecentFolders()
{
    if (m_recentFolders.isEmpty())
        return;

    m_recentFolders.clear();
    saveArchives();
    emit archivesChanged();
}

void ImageManager::refreshLastGoodImage()
{
    m_lastGoodImage.clear();
    for (const HistoryItem &item : m_history) {
        if (item.isGood) {
            m_lastGoodImage = item.targetPath;
            return;
        }
    }
}

void ImageManager::appendCsvRecord(const QString &fileName, bool isGood) const
{
    QDir dir(m_currentFolder);
    QFile file(dir.filePath(QStringLiteral("BinMark_result.csv")));
    if (file.open(QIODevice::Append | QIODevice::Text)) {
        QTextStream out(&file);
        out << fileName << "," << (isGood ? "good" : "bad") << "\n";
    }
}

void ImageManager::removeCsvRecord(const QString &fileName, bool isGood) const
{
    QDir dir(m_currentFolder);
    QFile file(dir.filePath(QStringLiteral("BinMark_result.csv")));
    if (!file.exists())
        return;

    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return;

    QStringList lines;
    QTextStream in(&file);
    while (!in.atEnd())
        lines.append(in.readLine());
    file.close();

    const QString targetLine = fileName + "," + (isGood ? "good" : "bad");
    for (int i = lines.size() - 1; i >= 0; --i) {
        if (lines.at(i) == targetLine) {
            lines.removeAt(i);
            break;
        }
    }

    if (!file.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate))
        return;

    QTextStream out(&file);
    for (const QString &line : std::as_const(lines))
        out << line << "\n";
}

void ImageManager::loadStatusFile()
{
    m_statusRecords.clear();
    m_acceptedCount = 0;
    m_rejectedCount = 0;
    m_statusVisibleCount = 30;

    QDir dir(m_currentFolder);
    QFile file(dir.filePath(QStringLiteral(".mark")));
    if (!file.exists())
        return;

    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return;

    QList<StatusRecord> loadedRecords;
    QTextStream in(&file);
    while (!in.atEnd()) {
        const QByteArray line = in.readLine().toUtf8();
        if (line.trimmed().isEmpty())
            continue;

        const QJsonDocument document = QJsonDocument::fromJson(line);
        if (!document.isObject())
            continue;

        const QJsonObject object = document.object();
        StatusRecord record;
        record.fileName = object.value(QStringLiteral("file")).toString();
        record.status = object.value(QStringLiteral("status")).toString();
        record.targetPath = object.value(QStringLiteral("target")).toString();
        record.timestamp = object.value(QStringLiteral("time")).toString();

        if (record.fileName.isEmpty()
            || (record.status != QStringLiteral("a") && record.status != QStringLiteral("r"))) {
            continue;
        }

        if (record.targetPath.isEmpty()) {
            const QString folderName = record.status == QStringLiteral("a")
                                       ? QStringLiteral("Well")
                                       : QStringLiteral("Bad");
            record.targetPath = QDir(dir.filePath(folderName)).filePath(record.fileName);
        } else if (QDir::isRelativePath(record.targetPath)) {
            record.targetPath = dir.filePath(record.targetPath);
        }

        loadedRecords.append(record);
        if (record.status == QStringLiteral("a"))
            ++m_acceptedCount;
        else
            ++m_rejectedCount;
    }

    for (int i = loadedRecords.size() - 1; i >= 0; --i)
        m_statusRecords.append(loadedRecords.at(i));
}

void ImageManager::saveStatusFile() const
{
    QDir dir(m_currentFolder);
    QFile file(dir.filePath(QStringLiteral(".mark")));
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate))
        return;

    for (int i = m_statusRecords.size() - 1; i >= 0; --i) {
        const StatusRecord &record = m_statusRecords.at(i);
        QJsonObject object;
        object.insert(QStringLiteral("file"), record.fileName);
        object.insert(QStringLiteral("status"), record.status);
        object.insert(QStringLiteral("target"), dir.relativeFilePath(record.targetPath));
        object.insert(QStringLiteral("time"), record.timestamp);
        file.write(QJsonDocument(object).toJson(QJsonDocument::Compact));
        file.write("\n");
    }
}

void ImageManager::appendStatusRecord(const QString &fileName, const QString &targetPath, bool isGood)
{
    const QString status = isGood ? QStringLiteral("a") : QStringLiteral("r");
    QDir dir(m_currentFolder);

    StatusRecord record;
    record.fileName = fileName;
    record.status = status;
    record.targetPath = targetPath;
    record.timestamp = QDateTime::currentDateTime().toString(Qt::ISODate);

    QJsonObject object;
    object.insert(QStringLiteral("file"), record.fileName);
    object.insert(QStringLiteral("status"), record.status);
    object.insert(QStringLiteral("target"), dir.relativeFilePath(record.targetPath));
    object.insert(QStringLiteral("time"), record.timestamp);

    QFile file(dir.filePath(QStringLiteral(".mark")));
    if (file.open(QIODevice::Append | QIODevice::Text)) {
        file.write(QJsonDocument(object).toJson(QJsonDocument::Compact));
        file.write("\n");
    }

    m_statusRecords.prepend(record);
    if (isGood)
        ++m_acceptedCount;
    else
        ++m_rejectedCount;
}

void ImageManager::removeStatusRecord(const QString &fileName, bool isGood)
{
    const QString status = isGood ? QStringLiteral("a") : QStringLiteral("r");
    for (int i = 0; i < m_statusRecords.size(); ++i) {
        const StatusRecord &record = m_statusRecords.at(i);
        if (record.fileName == fileName && record.status == status) {
            m_statusRecords.removeAt(i);
            if (isGood)
                m_acceptedCount = qMax(0, m_acceptedCount - 1);
            else
                m_rejectedCount = qMax(0, m_rejectedCount - 1);
            m_statusVisibleCount = qMin(m_statusVisibleCount, qMax(30, m_statusRecords.size()));
            break;
        }
    }

    QDir dir(m_currentFolder);
    QFile file(dir.filePath(QStringLiteral(".mark")));
    if (!file.exists())
        return;

    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return;

    QList<QByteArray> lines;
    while (!file.atEnd())
        lines.append(file.readLine());
    file.close();

    for (int i = lines.size() - 1; i >= 0; --i) {
        const QJsonDocument document = QJsonDocument::fromJson(lines.at(i));
        if (!document.isObject())
            continue;

        const QJsonObject object = document.object();
        if (object.value(QStringLiteral("file")).toString() == fileName
            && object.value(QStringLiteral("status")).toString() == status) {
            lines.removeAt(i);
            break;
        }
    }

    if (file.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate)) {
        for (QByteArray line : std::as_const(lines)) {
            if (!line.endsWith('\n'))
                line.append('\n');
            file.write(line);
        }
    }

    loadStatusFile();
}

void ImageManager::loadArchives()
{
    QSettings settings(QStringLiteral("BinMark"), QStringLiteral("BinMark"));
    m_recentFolders = settings.value(QStringLiteral("archive/recentFolders")).toStringList();
    m_pinnedFolders = settings.value(QStringLiteral("archive/pinnedFolders")).toStringList();

    for (QStringList *list : {&m_recentFolders, &m_pinnedFolders}) {
        QStringList normalized;
        for (const QString &path : std::as_const(*list)) {
            const QString normalizedPath = normalizeFolderPath(path);
            if (!normalizedPath.isEmpty() && !normalized.contains(normalizedPath))
                normalized.append(normalizedPath);
        }
        *list = normalized;
    }
}

void ImageManager::saveArchives() const
{
    QSettings settings(QStringLiteral("BinMark"), QStringLiteral("BinMark"));
    settings.setValue(QStringLiteral("archive/recentFolders"), m_recentFolders);
    settings.setValue(QStringLiteral("archive/pinnedFolders"), m_pinnedFolders);
}

void ImageManager::rememberRecentFolder(const QString &folderPath)
{
    const QString normalizedPath = normalizeFolderPath(folderPath);
    if (normalizedPath.isEmpty())
        return;

    QFileInfo info(normalizedPath);
    if (!info.exists() || !info.isDir())
        return;

    m_recentFolders.removeAll(normalizedPath);
    m_recentFolders.prepend(normalizedPath);
    while (m_recentFolders.size() > 10)
        m_recentFolders.removeLast();

    saveArchives();
    emit archivesChanged();
}

QVariantList ImageManager::folderListToVariantList(const QStringList &paths) const
{
    QVariantList items;
    items.reserve(paths.size());

    for (const QString &path : paths) {
        QFileInfo info(path);
        QVariantMap map;
        map.insert(QStringLiteral("path"), path);
        map.insert(QStringLiteral("url"), QUrl::fromLocalFile(path));
        map.insert(QStringLiteral("name"), info.fileName().isEmpty() ? path : info.fileName());
        map.insert(QStringLiteral("exists"), info.exists() && info.isDir());
        items.append(map);
    }

    return items;
}

QString ImageManager::normalizeFolderPath(const QUrl &folderUrl)
{
    if (!folderUrl.isValid())
        return {};

    if (folderUrl.isLocalFile())
        return normalizeFolderPath(folderUrl.toLocalFile());

    return normalizeFolderPath(folderUrl.toString());
}

QString ImageManager::normalizeFolderPath(const QString &folderPath)
{
    if (folderPath.trimmed().isEmpty())
        return {};

    QString path = folderPath;
    if (path.startsWith(QStringLiteral("file:/")))
        path = QUrl(path).toLocalFile();

    QFileInfo info(path);
    return QDir::cleanPath(info.absoluteFilePath());
}
