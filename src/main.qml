import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls.Material 2.2
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3
import de.danielbulla 1.0
import "../data" as Data

Window {
    id: window
    visible: true
    width: 640
    height: 480
    title: "Name Ranking"
    // QTBUG-53022: High DPI Scaling uses value 2 instead of 1.75 when Windows is set to 175% scaling. Adapt this for exact comparison
    property real scaleFactor: Screen.devicePixelRatio === 2 ? 1.75/2.0 : 1.0
    property int nameRectWidth: 200 * scaleFactor
    property int nameRectHeight: 115 * scaleFactor
    property int nameRectSpacing: 18*2 * scaleFactor
    property int textSize: 16 // * scaleFactor
    Action {
        id: addAction
        text: qsTr("&Add")
        shortcut: StandardKey.New
        onTriggered: {
            var upper = nameText.text.toUpperCase();
            for (var i=0; i < namesModel.count; i++)
                if(namesModel.get(i).name.toUpperCase() > upper) break;
            namesModel.insert(i, { name: nameText.text })
        }
    }
    RowLayout {
        id: controlsRow
        anchors.leftMargin: 10
        spacing: 10
        //anchors.horizontalCenter: parent.horizontalCenter
        anchors.left: parent.left
        TextField {
            id: nameText
            width: 200
            focus: true
            validator: RegExpValidator {
                regExp: /.{1,20}/
            }
            placeholderText: qsTr("Enter name")
            selectByMouse: true
            KeyNavigation.right: addButton
            KeyNavigation.tab: addButton
            Keys.onReturnPressed: addAction.trigger()
        }
        Button {
            id: addButton
            action: addAction
            KeyNavigation.left: nameText
            KeyNavigation.backtab: nameText
        }
        CheckBox { id: addOneToAllFibsCheckbox }
        Label {
            Layout.minimumWidth: 70
            text: "fibo<sub>n</sub>" + (addOneToAllFibsCheckbox.checked ? " + 1" : "")
            textFormat: Text.RichText
        }
    }
    Label {
        anchors.verticalCenter: controlsRow.verticalCenter
        anchors.left: controlsRow.right
        anchors.leftMargin: 5
        opacity: nameText.text !== ""
        Behavior on opacity {
            NumberAnimation { duration: 500; easing.type: Easing.InOutQuad }
        }

        // Qml analyzes this binding and builds a dependency tree. text is updated, when "nameText.text" changes.
        // it also analyzes all dependencies of fibo(...)
        text: qsTr("Fibbonacci von \"<i>%1</i>\": %2").arg(nameText.text).arg(window.fibo(nameText.text.length * 3))
    }
    ScrollBar {
        id: scrollBar
        anchors.right: parent.right
        anchors.top: tableView.top
        anchors.bottom: tableView.bottom
    }
    TableView {
        id: tableView
        anchors.top: controlsRow.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        flickableDirection: Flickable.VerticalFlick
        ScrollBar.vertical: scrollBar
        clip: true

        property int spacing: window.nameRectSpacing

        // The expression reevaluates whenever parent.width or window.nameRectWidth changes
        property int myColumns: Math.floor(window.width / (window.nameRectWidth + spacing))
        onMyColumnsChanged: console.log("Number of columns is now: " + myColumns)

        width: columns * window.nameRectWidth + (columns-1) * spacing

        model: IndexModel { id: theModel; rowCount: Math.ceil(namesModel.count/tableView.myColumns); columnCount: tableView.myColumns }
        columnWidthProvider: function (column) { return tableView.width/tableView.columns }
        rowHeightProvider: function(row) {return window.nameRectHeight+spacing }

        delegate: Item {
            visible: nameRect.isValid // to hide items in last row which not exist
            Rectangle {
                id: nameRect
                anchors.centerIn: parent
                width: window.nameRectWidth
                height: window.nameRectHeight//-bottomButton.height
                SequentialAnimation {
                    id: removeAnimation
                    ParallelAnimation {
                        NumberAnimation { target: nameRect; property: "scale"; to: 0.0; duration: 400; easing.type: Easing.InQuad }
                        NumberAnimation { target: nameRect; property: "opacity"; to: 0.0; duration: 400 }
                    }
                    NumberAnimation { target: nameRect; property: "width"; to: 0.0; duration: 400; easing.type: Easing.InOutQuad }
                    onStopped: namesModel.remove(column*tableView.rows+row)
                }
                property bool isValid: typeof namesModel.get(column+row*tableView.columns) !== "undefined"
                property string name: isValid ? namesModel.get(column+row*tableView.columns).name : ""
                //property int fibo: window.fibo( name.split('').reduce((pv, cv) => pv+cv.charCodeAt(0), 0))
                property int fibo: window.fibo(   name.length * 3)
                property bool triggerRed: fibo > 500
                color: triggerRed ? "red" : "green" //Material.background
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 20 * window.scaleFactor
                    Layout.alignment: Qt.AlignCenter
                    text: nameRect.name
                    font.family: "Times New Roman"
                    font.weight: Font.Bold
                    font.pixelSize: window.textSize
                    color: nameRect.triggerRed ? "white" : "black"
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: bottomButton.height + 15 * window.scaleFactor
                    Layout.alignment: Qt.AlignCenter
                    text: nameRect.fibo
                    font.family: "Times New Roman"
                    font.pixelSize:  window.textSize
                    color: nameRect.triggerRed ? "white" : "black"
                }
                Rectangle {
                    id: bottomButton
                    height: 22 * window.scaleFactor
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    color: "grey"//Material.primary
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1.0/Screen.devicePixelRatio // haar, always one px
                        gradient: Gradient {
                            GradientStop { color: Qt.rgba(221,221,221); position: 0 }
                            GradientStop { color: Qt.lighter("lightGrey", mouseArea.containsMouse ? 1.1 : 1.0); position: 1 }
                        }
                        Text {
                            anchors.centerIn: parent
                            text: "REMOVE"
                            font.pixelSize: 13 //* window.scaleFactor
                            font.family: "Arial"
                        }
                    }
                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            removeAnimation.start()
                            //namesModel.remove(index)
                        }
                    }
                }
            }
        }
    }
    property var fibs: []
    function fibo_(n) {
        /*Wrong:*/ if(n<=1) return 1;
        //*Right:*/ if(n<=1) return n;
        if(typeof(fibs[n]) !== "undefined") return fibs[n];
        fibs[n] = fibo(n-1) + fibo(n-2);
        return fibs[n];
    }

    // Note that this function is reevaluated by all elements if the property window.addOneToAllFibs changes.
    // There is no observer explicitly defined.
    function fibo(n) {
        return fibo_(n) + (addOneToAllFibsCheckbox.checked ? 1 : 0);
    }
    Data.NamesModel { id: namesModel }
}
