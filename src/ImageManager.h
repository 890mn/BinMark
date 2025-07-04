#ifndef IMAGEMANAGER_H
#define IMAGEMANAGER_H

#include <QObject>
#include <QStringList>
#include <QUrl>

class ImageManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QUrl currentImage READ currentImage NOTIFY currentImageChanged)
    Q_PROPERTY(QUrl lastGoodImage READ lastGoodImage NOTIFY lastGoodImageChanged)
    Q_PROPERTY(int currentIndex READ currentIndex NOTIFY currentIndexChanged)
    Q_PROPERTY(int totalCount READ totalCount NOTIFY totalCountChanged)

public:
    explicit ImageManager(QObject *parent = nullptr);

    QUrl currentImage() const;
    QUrl lastGoodImage() const;

    int currentIndex() const;
    int totalCount() const;

    Q_INVOKABLE void loadFromFolder(const QUrl &folderUrl);
    Q_INVOKABLE void markCurrent(bool good);
    Q_INVOKABLE void next();
    Q_INVOKABLE void previous();

signals:
    void currentImageChanged();
    void lastGoodImageChanged();
    void currentIndexChanged();
    void totalCountChanged();

private:
    QStringList m_images;
    int m_currentIndex = -1;
    QUrl m_lastGoodImage;
};

#endif // IMAGEMANAGER_H
