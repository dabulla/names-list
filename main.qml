import QtQuick 2.10
import QtQuick.Window 2.10
import QtQuick.Controls.Material 2.2
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3
import "."

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
    Flickable {
    //ScrollView {
        anchors.top: controlsRow.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        flickableDirection: Flickable.VerticalFlick
        contentHeight: flow.implicitHeight
        contentWidth: window.width
        ScrollBar.vertical: ScrollBar { }
        //ScrollBar.vertical.policy: ScrollBar.AsNeeded // AlwaysOn
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
            /*property int*/ spacing: window.nameRectSpacing

            // The expression reevaluates whenever parent.width or window.nameRectWidth changes
            property int columns: Math.floor(window.width / (window.nameRectWidth + spacing))
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
            //property int flexItemsInLastRow: repeater.count % columns
            //property int flexCountWithoutLastRow: repeater.count - flexItemsInLastRow
            // ngFor
            Repeater {
                id: repeater
                model: namesModel
                // use for flex-layout behaviour of last row
//                Item {
//                    id: flexDummyForLastRow
//                    property bool firstInLastRow: index === flow.flexCountWithoutLastRow
//                    width: window.nameRectWidth + (firstInLastRow ? (flow.width-flow.flexItemsInLastRow*window.nameRectWidth-(flow.flexItemsInLastRow-1)*flow.spacing)*0.5 : 0)
//                    height: window.nameRectHeight
                    Rectangle {
                        id: nameRect
                        //anchors.right: flexDummyForLastRow.right
                        width: window.nameRectWidth
                        height: window.nameRectHeight//-bottomButton.height
                        SequentialAnimation {
                            id: removeAnimation
                            ParallelAnimation {
                                NumberAnimation { target: nameRect; property: "scale"; to: 0.0; duration: 400; easing.type: Easing.InQuad }
                                NumberAnimation { target: nameRect; property: "opacity"; to: 0.0; duration: 400 }
                            }
                            NumberAnimation { target: nameRect; property: "width"; to: 0.0; duration: 400; easing.type: Easing.InOutQuad }
                            onStopped: namesModel.remove(index)
                        }
                        property int fibo: window.fibo(modelData.length * 3)
                        property bool triggerRed: fibo > 500
                        //color: "grey"
                        color: triggerRed ? "red" : "green"//Material.background
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: 20 * window.scaleFactor
                            Layout.alignment: Qt.AlignCenter
                            text: modelData
//                            font.family: "Times New Roman"
//                            font.weight: Font.Bold
                            font.pixelSize: window.textSize
                            color: nameRect.triggerRed ? "white" : "black"
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: bottomButton.height + 15 * window.scaleFactor
                            Layout.alignment: Qt.AlignCenter
                            text: nameRect.fibo
//                            font.family: "Times New Roman"
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
                                    GradientStop { color: "lightGrey"; position: 1 }
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: "REMOVE"
                                    font.pixelSize: 13 //* window.scaleFactor
                                    font.family: "Arial"
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    removeAnimation.start()
                                    //namesModel.remove(index)
                                }
                            }
                        }
                    }
//                } // flexDummy
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

    // Note that this function is reevaluated by all elements if the property window.addOneToAllFibs changes.
    // There is no observer explicitly defined.
    function fibo(n) {
        return fibo_(n) + (addOneToAllFibsCheckbox.checked ? 1 : 0);
    }
    NamesModel { id: namesModel }
}
