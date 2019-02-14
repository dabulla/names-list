#include <QtCore/QtCore>
#include <QtGui/QStandardItemModel>

// minimal Table model to use TableView "purely" in Qml
class TestModel : public QAbstractTableModel
{
    Q_OBJECT
    Q_PROPERTY(int rowCount READ rowCount WRITE setRowCount NOTIFY rowCountChanged)
    Q_PROPERTY(int columnCount READ columnCount WRITE setColumnCount NOTIFY columnCountChanged)

public:
    TestModel(QObject *parent = nullptr)
        : QAbstractTableModel(parent)
    {}

    int rowCount(const QModelIndex & = QModelIndex()) const override { return m_rows; }
    void setRowCount(int count) { beginResetModel(); m_rows = count; emit rowCountChanged(); endResetModel(); }

    int columnCount(const QModelIndex & = QModelIndex()) const override { return m_columns; }
    void setColumnCount(int count) { beginResetModel(); m_columns = count; emit columnCountChanged(); endResetModel(); }

    QVariant data(const QModelIndex &index, int role) const override { Q_UNUSED(index); Q_UNUSED(role); return QVariant(); }

signals:
    void rowCountChanged();
    void columnCountChanged();

private:
    int m_rows = 0;
    int m_columns = 0;
};
