import QtQuick 2.15
import QtQuick.Window 2.12
import QtQuick.Controls.Material 2.2
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3
import de.danielbulla 1.0
import "../data" as Data

Window {
    id: window
    visible: false
    minimumWidth: 640
    minimumHeight: 480
    title: "Name Ranking"

    Material.theme: Material.Dark
    color: Material.background

    Component.onCompleted: window.show()
    property int nameRectWidth: Screen.orientation === Qt.PortraitOrientation ? 120 : 200
    property int nameRectHeight: 115
    property int nameRectSpacing: 18*2
    property int textSize: 16
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
    ScrollBar {
        id: scrollBar
        z: 99
        anchors.right: parent.right
        height: mainLayout.height - descriptionBox.height
        anchors.bottom: parent.bottom
    }
    ColumnLayout {
        id: mainLayout
        anchors.leftMargin: 10
        anchors.fill: parent
        Item {
            id: descriptionBox
            property int myHeight: descriptionText.implicitHeight + descriptionText.anchors.margins * 2
            Behavior on myHeight { NumberAnimation { duration: 500 } }
            Layout.fillWidth: true
            Layout.preferredHeight: myHeight
            clip: true
            Item {
                z: 99
                anchors.top: parent.top
                anchors.right: parent.right
                width: 48
                height: 48
                Label {
                    anchors.centerIn: parent
                    text: "x"
                    font.weight: Font.Bold
                    font.pixelSize: 24
                    color: Qt.darker(Material.primaryTextColor, closeButtonMouseArea.containsMouse ? 1.2 : 1.0)
                }
                MouseArea {
                    id: closeButtonMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: descriptionBox.myHeight = 0
                }
            }
            Label {
                anchors.margins: 20
                anchors.fill: parent
                id: descriptionText
                wrapMode: Text.WordWrap
                textFormat: Text.RichText
                text: "<b>Description:</b><br>
                       This example shows a list with more than 4k entries. For each entry/name a calculation is performed.
                       The entry is rendered green or red, depending on the result. Entries can be added or removed using the controls.
                       When the 'fibo<sub>n</sub>' box is (un)checked, all items are updated.
                       <br><b>Why is this awesome?</b><br>
                       The name list is fully loaded into memory while the calculation is done lazily only for visible items. This however, is not done explicitly in
                       this examples source code and is automatically done by Qt. Other frameworks usually require developers to define a multitude of data generation,
                       change detection and optimization code to achieve similar results. Works with touch screens.
                       The source code for this example is ~200 lines."
            }
        }
        RowLayout {
            id: controlsRow
            spacing: 10
            TextField {
                id: nameText
                width: 200
                validator: RegularExpressionValidator {
                    regularExpression: /.{1,20}/
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
            CheckBox {
                id: addOneToAllFibsCheckbox
                focus: true
            }
            Label {
                Layout.minimumWidth: 70
                text: "fibo<sub>n</sub>" + (addOneToAllFibsCheckbox.checked ? " + 1" : "")
                textFormat: Text.RichText
            }
        }
        Label {
            opacity: nameText.text !== ""
            Behavior on opacity {
                NumberAnimation { duration: 500; easing.type: Easing.InOutQuad }
            }

            // Qml analyzes this binding and builds a dependency tree. text is updated, when "nameText.text" changes.
            // it also analyzes all dependencies of fibo(...)
            text: qsTr("Fibbonacci of \"<i>%1</i>\": %2").arg(nameText.text).arg(window.fibo(nameText.text.length * 3))
        }
        TableView {
            id: tableView
            Layout.fillHeight: true
            Layout.fillWidth: true
            flickableDirection: Flickable.VerticalFlick
            ScrollBar.vertical: scrollBar
            clip: true

            property int spacing: window.nameRectSpacing

            // The expression reevaluates whenever parent.width or window.nameRectWidth changes
            property int myColumns: Math.floor(window.width / (window.nameRectWidth + spacing))
            onMyColumnsChanged: console.log("Number of columns is now: " + myColumns)

            contentWidth: columns * window.nameRectWidth + (columns) * spacing

            // center the whole table view horizontally by updating leftMargin
            leftMargin: (parent.width - contentWidth) * 0.5

            // model will update tableView.columns
            model: IndexModel { id: theModel; rowCount: Math.ceil(namesModel.count/tableView.myColumns); columnCount: tableView.myColumns }
            columnWidthProvider: function (column) { return window.nameRectWidth + spacing }
            rowHeightProvider: function(row) { return window.nameRectHeight+spacing }

            delegate: Item {
                visible: nameRect.isValid // hide items in last row which do not exist
                Rectangle {
                    id: nameRect
                    anchors.centerIn: parent
                    width: window.nameRectWidth
                    height: window.nameRectHeight
                    radius: 10
                    color: Material.color(nameRect.triggered ? Material.Green : Material.Red)
                    property int myIndex: column + row * tableView.columns
                    property bool isValid: typeof namesModel.get( myIndex ) !== "undefined"
                    property string name: isValid ? namesModel.get( myIndex ).name : ""
                    property int fibo: window.fibo( name.length * 3 )
                    property bool triggered: fibo > window.threshold
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 20
                        text: nameRect.name
                        font.weight: Font.Bold
                        font.pixelSize: window.textSize
                        color: Material.primaryTextColor
                    }
                    Text {
                        id: score
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: bottomButton.height + 15
                        text: nameRect.fibo
                        font.pixelSize:  window.textSize
                        color: Material.primaryTextColor
                    }
                    Text {
                        visible: mouseAreaScore.containsMouse
                        anchors.baseline: score.baseline
                        anchors.left: score.right
                        text: " is " + (nameRect.triggered ? "above" : "below") + " " + window.threshold
                        font.pixelSize:  window.textSize/2
                        color: Material.primaryTextColor
                    }
                    MouseArea {
                        id: mouseAreaScore
                        anchors.fill: score
                        hoverEnabled: true
                    }
                    Rectangle {
                        id: bottomButton
                        height: 22
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 10
                        radius: 5
                        color: Qt.darker(Material.foreground, mouseArea.containsMouse ? 1.1 : 1.0)
                        Text {
                            anchors.centerIn: parent
                            text: "REMOVE"
                            font.pixelSize: 13
                        }
                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: removeAnimation.start()
                        }
                    }
                }
                SequentialAnimation {
                    id: removeAnimation
                    ParallelAnimation {
                        NumberAnimation { target: nameRect; property: "scale";   to: 0.0; duration: 400; easing.type: Easing.InQuad }
                        NumberAnimation { target: nameRect; property: "opacity"; to: 0.0; duration: 400 }
                    }
                    NumberAnimation { target: nameRect; property: "width"; to: 0.0; duration: 400; easing.type: Easing.InOutQuad }
                    onStopped: { namesModel.remove( nameRect.myIndex ) }
                }
            }
        }
    }
    property var fibs: []
    function fibo_(n) {
        if(n<=1) return n;
        if(typeof(fibs[n]) !== "undefined") return fibs[n];
        fibs[n] = fibo(n-1) + fibo(n-2);
        return fibs[n];
    }

    // Note that this function is reevaluated by all elements if the property window.addOneToAllFibs changes.
    // There is no observer explicitly defined.
    function fibo(n) {
        return fibo_(n) + (addOneToAllFibsCheckbox.checked ? 1 : 0);
    }
    property int threshold: 500
    Data.NamesModel { id: namesModel }
}
