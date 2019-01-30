import QtQuick 2.10
import QtQuick.Window 2.10
import QtQuick.Controls.Material 2.2
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3
import "."
//import "Names.js" as Names;

Window {
    id: window
    visible: true
    width: 640
    height: 480
    title: "Names"
    property int nameRectWidth: 100
    Action {
        id: addAction
        text: qsTr("&Add")
        icon.name: "add"
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
            KeyNavigation.right: addButton
            KeyNavigation.tab: addButton
            Keys.onReturnPressed: addAction.trigger()
        }
        Button {
            id: addButton
            action: addAction
            focus: true
            text: "Add"
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
    Flickable {
        anchors.top: controlsRow.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        flickableDirection: Flickable.VerticalFlick
        contentHeight: flow.implicitHeight
        ScrollBar.vertical: ScrollBar { }
        clip: true
        // Flex: create a behaviour like CSS-flex-layout by uncommenting "dummyForLastRowFlex" and flex*-properties
        //       Qml has a powerfull layout/positioning and an super performant anchoring system.
        //       "Propertybindings" make it easy to define layouts in a css-like way.
        //       Flexbox behaviour is based on quite complex rules. This example shows that it can be
        //       calculated in qml with great performance. 90% of flex-layout behaviour can be reached with
        //       out-of-the-box Qml Items.
        Flow {
        //GridLayout {
            id: flow
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 5

            // The expression reevaluates whenever parent.width or window.nameRectWidth changes
            property int columns: Math.floor(parent.width / (window.nameRectWidth + spacing))
            onColumnsChanged: console.log("Number of columns is now: " + columns)

            width: columns * window.nameRectWidth + (columns-1) * spacing
            add: Transition {
                SequentialAnimation {
                    NumberAnimation { property: "scale"; to: 0.0; duration: 0 }
                    NumberAnimation { property: "width"; from: 1.0; to: window.nameRectWidth; duration: 400; easing.type: Easing.InOutQuad }
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 0; to: 1.0; duration: 400 }
                        NumberAnimation { property: "scale"; from: 0; to: 1.0; duration: 400; easing.type: Easing.OutQuad }
                    }
                }
            }

            // Effect for movement of other items, if one got deleted/added
//            move: Transition {
//                NumberAnimation { properties: "x,y"; duration: 400; easing.type: Easing.InOutQuad }
//            }

            // use for flex-layout behaviour of last row
            property int flexItemsInLastRow: repeater.count%columns
            property int flexCountWithoutLastRow: repeater.count-flexItemsInLastRow
            // ngFor
            Repeater {
                id: repeater
                model: namesModel
                // use for flex-layout behaviour of last row
                Item {
                    id: flexDummyForLastRow
                    property bool firstInLastRow: index === flow.flexCountWithoutLastRow
                    width: window.nameRectWidth + (firstInLastRow ? (flow.width-flow.flexItemsInLastRow*window.nameRectWidth-(flow.flexItemsInLastRow-1)*flow.spacing)*0.5 : 0)
                    height: 80
                    Rectangle {
                        id: nameRect
                        anchors.right: flexDummyForLastRow.right
                        width: window.nameRectWidth
                        //clip: removeAnimation.running
                        SequentialAnimation {
                            id: removeAnimation
                            ParallelAnimation {
                                NumberAnimation { target: flexDummyForLastRow; property: "scale"; to: 0.0; duration: 400; easing.type: Easing.InQuad }
                                NumberAnimation { target: flexDummyForLastRow; property: "opacity"; to: 0.0; duration: 400 }
                            }
                            NumberAnimation { target: flexDummyForLastRow; property: "width"; to: 0.0; duration: 400; easing.type: Easing.InOutQuad }
                            onStopped: namesModel.remove(index)
                        }
                        height: 80
                        color: Material.background
                        border {
                            width: 1
                            color: Material.primary
                        }
                        Text {
                            anchors.top: parent.top
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: parseInt(window.fibo(modelData.length * 3))

                        }
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: parent.border.width
                            height: 20
                            color: Material.accent
                            Text {
                                anchors.centerIn: parent
                                text: "Remove"
                            }
                            MouseArea {
                                z: 100
                                anchors.fill: parent
                                onClicked: {
                                    removeAnimation.start()
                                    //namesModel.remove(index)
                                }
                            }
                        }
                    }
                } // flexDummy
            }
        }
    }

    property var fibs: []
    function fibo_(n) {
        if(n<2) return n;
        if(typeof(fibs[n]) !== "undefined") return fibs[n];
        fibs[n] = fibo(n-1) + fibo(n-2);
        return fibs[n];
    }

    property bool addOneToAllFibs: addOneToAllFibsCheckbox.checked

    // Note that this function is reevaluated by all elements if the property window.addOneToAllFibs changes.
    // There is no observer explicitly defined.
    function fibo(n) {
        return fibo_(n) + (window.addOneToAllFibs ? 1 : 0);
    }

    NamesModel { id: namesModel }
}
