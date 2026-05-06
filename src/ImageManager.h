#ifndef IMAGEMANAGER_H
#define IMAGEMANAGER_H

#include <QObject>
#include <QList>
#include <QStringList>
#include <QVariantList>
#include <QUrl>

class ImageManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QUrl currentImage READ currentImage NOTIFY imageChanged)
    Q_PROPERTY(QUrl lastGoodImage READ lastGoodImage NOTIFY imageChanged)
    Q_PROPERTY(int currentIndex READ currentIndex NOTIFY imageChanged)
    Q_PROPERTY(int totalCount READ totalCount NOTIFY imageChanged)
    Q_PROPERTY(QVariantList history READ history NOTIFY historyChanged)
    Q_PROPERTY(int historyCount READ historyCount NOTIFY historyChanged)
    Q_PROPERTY(QVariantList statusRecords READ statusRecords NOTIFY statusChanged)
    Q_PROPERTY(int statusCount READ statusCount NOTIFY statusChanged)
    Q_PROPERTY(int acceptedCount READ acceptedCount NOTIFY statusChanged)
    Q_PROPERTY(int rejectedCount READ rejectedCount NOTIFY statusChanged)
    Q_PROPERTY(bool canLoadMoreStatus READ canLoadMoreStatus NOTIFY statusChanged)
    Q_PROPERTY(QVariantList recentFolders READ recentFolders NOTIFY archivesChanged)
    Q_PROPERTY(QVariantList pinnedFolders READ pinnedFolders NOTIFY archivesChanged)

public:
    explicit ImageManager(QObject *parent = nullptr);

    Q_INVOKABLE void loadFromFolder(const QUrl &folderUrl);
    Q_INVOKABLE void next();
    Q_INVOKABLE void previous();
    Q_INVOKABLE void markCurrent(bool isGood);
    Q_INVOKABLE bool undoHistoryItem(int index);
    Q_INVOKABLE void loadMoreStatus();
    Q_INVOKABLE bool toggleStatusRecord(int index);
    Q_INVOKABLE bool addPinnedFolder(const QUrl &folderUrl);
    Q_INVOKABLE bool removePinnedFolder(const QString &folderPath);
    Q_INVOKABLE void clearRecentFolders();

    QUrl currentImage() const;
    QUrl lastGoodImage() const;
    int currentIndex() const;
    int totalCount() const;
    QVariantList history() const;
    int historyCount() const;
    QVariantList statusRecords() const;
    int statusCount() const;
    int acceptedCount() const;
    int rejectedCount() const;
    bool canLoadMoreStatus() const;
    QVariantList recentFolders() const;
    QVariantList pinnedFolders() const;

signals:
    void imageChanged();
    void historyChanged();
    void statusChanged();
    void archivesChanged();

private:
    struct HistoryItem {
        QString originalPath;
        QString targetPath;
        QString fileName;
        bool isGood = false;
        int restoreIndex = 0;
    };

    struct StatusRecord {
        QString fileName;
        QString targetPath;
        QString status;
        QString timestamp;
    };

    void refreshLastGoodImage();
    void appendCsvRecord(const QString &fileName, bool isGood) const;
    void removeCsvRecord(const QString &fileName, bool isGood) const;
    void loadStatusFile();
    void saveStatusFile() const;
    void appendStatusRecord(const QString &fileName, const QString &targetPath, bool isGood);
    void removeStatusRecord(const QString &fileName, bool isGood);
    void loadArchives();
    void saveArchives() const;
    void rememberRecentFolder(const QString &folderPath);
    QVariantList folderListToVariantList(const QStringList &paths) const;
    static QString normalizeFolderPath(const QUrl &folderUrl);
    static QString normalizeFolderPath(const QString &folderPath);

    QStringList m_imagePaths;
    QList<HistoryItem> m_history;
    QList<StatusRecord> m_statusRecords;
    QStringList m_recentFolders;
    QStringList m_pinnedFolders;
    int m_currentIndex = 0;
    int m_statusVisibleCount = 30;
    int m_acceptedCount = 0;
    int m_rejectedCount = 0;
    QString m_lastGoodImage;
    QString m_currentFolder;
};

#endif // IMAGEMANAGER_H
