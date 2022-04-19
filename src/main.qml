import QtQuick 2.15
import QtQuick.Window 2.12
import QtQuick.Controls.Material 2.2
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3
import de.danielbulla 1.0
import "../data" as Data

Window {
    id: window
    visible: true
    minimumWidth: 640
    minimumHeight: 480
    title: "Name Ranking"

    Material.theme: Material.Dark
    color: Material.background

    property int nameRectWidth: 200
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
            clip:true
            Label {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 5
                text: "x"
                font.weight: Font.Bold
                MouseArea {
                    anchors.fill: parent
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
                       change detection and optimization code to achieve similar results.
                       The source code for this example is ~200 lines."
            }
        }

        RowLayout {
            id: controlsRow
            spacing: 10
            TextField {
                id: nameText
                width: 200
                focus: true
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
            CheckBox { id: addOneToAllFibsCheckbox }
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
        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true
            TableView {
                id: tableView
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                flickableDirection: Flickable.VerticalFlick
                ScrollBar.vertical: scrollBar
                clip: true

                property int spacing: window.nameRectSpacing

                // The expression reevaluates whenever parent.width or window.nameRectWidth changes
                property int myColumns: Math.floor(window.width / (window.nameRectWidth + spacing))
                onMyColumnsChanged: console.log("Number of columns is now: " + myColumns)

                // center the whole table view horizontally by updating width based on the number of columns
                width: columns * window.nameRectWidth + (columns-1) * spacing

                // model will update tableView.columns
                model: IndexModel { id: theModel; rowCount: Math.ceil(namesModel.count/tableView.myColumns); columnCount: tableView.myColumns }
                columnWidthProvider: function (column) { return tableView.width/tableView.columns }
                rowHeightProvider: function(row) { return window.nameRectHeight+spacing }

                delegate: Item {
                    visible: nameRect.isValid // hide items in last row which do not exist
                    Rectangle {
                        id: nameRect
                        anchors.centerIn: parent
                        width: window.nameRectWidth
                        height: window.nameRectHeight
                        property int myIndex: column + row * tableView.columns
                        SequentialAnimation {
                            id: removeAnimation
                            ParallelAnimation {
                                NumberAnimation { target: nameRect; property: "scale";   to: 0.0; duration: 400; easing.type: Easing.InQuad }
                                NumberAnimation { target: nameRect; property: "opacity"; to: 0.0; duration: 400 }
                            }
                            NumberAnimation { target: nameRect; property: "width"; to: 0.0; duration: 400; easing.type: Easing.InOutQuad }
                            onStopped: { namesModel.remove( nameRect.myIndex ) }
                        }
                        property bool isValid: typeof namesModel.get( myIndex ) !== "undefined"
                        property string name: isValid ? namesModel.get( myIndex ).name : ""
                        property int thres: 500
                        property int fibo: window.fibo( name.length * 3 )
                        property bool triggered: fibo > nameRect.thres
                        color: Material.color(nameRect.triggered ? Material.Green : Material.Red)
                        radius: 10
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: 20
                            Layout.alignment: Qt.AlignCenter
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
                            Layout.alignment: Qt.AlignCenter
                            text: nameRect.fibo
                            font.pixelSize:  window.textSize
                            color: Material.primaryTextColor
                        }
                        Text {
                            visible: mouseAreaRect.containsMouse
                            anchors.baseline: score.baseline
                            anchors.left: score.right
                            text: " is " + (nameRect.triggered ? "above" : "below") + " " + nameRect.thres
                            font.pixelSize:  window.textSize/2
                            color: Material.primaryTextColor
                        }
                        MouseArea {
                            id: mouseAreaRect
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
                            color: Qt.darker(Material.foreground, mouseArea.containsMouse ? 1.1 : 0.0)
                            Text {
                                anchors.centerIn: parent
                                text: "REMOVE"
                                font.pixelSize: 13
                            }
                            MouseArea {
                                id: mouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    removeAnimation.start()
                                }
                            }
                        }
                    }
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
    Data.NamesModel { id: namesModel }
}
