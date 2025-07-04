#ifndef IMAGEMANAGER_H
#define IMAGEMANAGER_H

#include <QObject>
#include <QStringList>
#include <QUrl>

class ImageManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QUrl currentImage READ currentImage NOTIFY imageChanged)
    Q_PROPERTY(QUrl lastGoodImage READ lastGoodImage NOTIFY imageChanged)
    Q_PROPERTY(int currentIndex READ currentIndex NOTIFY imageChanged)
    Q_PROPERTY(int totalCount READ totalCount NOTIFY imageChanged)

public:
    explicit ImageManager(QObject *parent = nullptr);

    Q_INVOKABLE void loadFromFolder(const QUrl &folderUrl);
    Q_INVOKABLE void next();
    Q_INVOKABLE void previous();
    Q_INVOKABLE void markCurrent(bool isGood);

    QUrl currentImage() const;
    QUrl lastGoodImage() const;
    int currentIndex() const;
    int totalCount() const;

signals:
    void imageChanged();

private:
    QStringList m_imagePaths;
    int m_currentIndex = 0;
    QString m_lastGoodImage;
    QString m_currentFolder;
};

#endif // IMAGEMANAGER_H
