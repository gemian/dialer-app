/*
 * Copyright 2012-2013 Canonical Ltd.
 *
 * This file is part of dialer-app.
 *
 * dialer-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * dialer-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components.Popups 0.1
import Ubuntu.Telephony 0.1

MainView {
    id: mainView

    property bool applicationActive: Qt.application.active
    property string ussdResponseTitle: ""
    property string ussdResponseText: ""
    automaticOrientation: false
    width: units.gu(40)
    height: units.gu(71)
    useDeprecatedToolbar: false

    signal applicationReady
    signal closeUSSDProgressIndicator

    property string pendingNumberToDial: ""
    property string pendingAccountId: ""
    property bool accountReady: false

    onApplicationActiveChanged: {
        if (applicationActive) {
            telepathyHelper.registerChannelObserver()
        } else {
            telepathyHelper.unregisterChannelObserver()
        }
    }

    function viewContact(contactId) {
        Qt.openUrlExternally("addressbook:///contact?id=" + encodeURIComponent(contactId))
    }

    function addNewContact(phoneNumber) {
        Qt.openUrlExternally("addressbook:///create?phone=" + encodeURIComponent(phoneNumber))
    }

    function addPhoneNumberToExistingContact(contactId, phoneNumber) {
        Qt.openUrlExternally("addressbook:///addphone?id=" + encodeURIComponent(contactId) + "&phone=" + encodeURIComponent(phoneNumber))
    }

    function sendMessage(phoneNumber) {
        Qt.openUrlExternally("message:///" + encodeURIComponent(phoneNumber))
    }

    function callVoicemail() {
        call(callManager.voicemailNumber);
    }

    function checkUSSD(number) {
        var endString = "#"
        // check if it ends with #
        if (number.slice(-endString.length) == endString) {
            // check if it starts with any of these strings
            var startStrings = ["*", "#", "**", "##", "*#"]
            for(var i in startStrings) {
                if (number.slice(0, startStrings[i].length) == startStrings[i]) {
                    return true
                }
            }
        }
        return false
    }

    function call(number, accountId) {
        // clear the values here so that the changed signals are fired when the new value is set
        pendingNumberToDial = "";
        pendingAccountId = "";

        if (number === "") {
            return
        }

        if (!telepathyHelper.connected) {
            pendingNumberToDial = number;
            pendingAccountId = accountId;
            return;
        }

        if (checkUSSD(number)) {
            PopupUtils.open(ussdProgressDialog)
            ussdManager.initiate(number, accountId)
            return
        }

        // pop the stack if the live call is not the visible view
        // FIXME: using the objectName here is not pretty, change by something less prone to errors
        while (pageStack.depth > 1 && pageStack.currentPage.objectName != "pageLiveCall") {
            pageStack.pop();
        }

        if (pageStack.depth === 1 && !callManager.hasCalls)  {
            pageStack.push(Qt.resolvedUrl("LiveCallPage/LiveCall.qml"))
        }

        if (!accountReady) {
            pendingNumberToDial = number;
            pendingAccountId = accountId;
            return;
        }

        if (accountId && telepathyHelper.accountIds.indexOf(accountId) != -1) {
            callManager.startCall(number, accountId);
            return
        }
        callManager.startCall(number);
    }

    function populateDialpad(number, accountId) {
        // populate the dialpad with the given number but don't start the call
        // FIXME: check what to do when not in the dialpad view

        // if not on the livecall view, go back to the dialpad
        while (pageStack.depth > 1 && pageStack.currentPage.objectName != "pageLiveCall") {
            pageStack.pop();
        }

        if (pageStack.currentPage && typeof(pageStack.currentPage.dialNumber) != 'undefined') {
            pageStack.currentPage.dialNumber = number;
        }
    }

    function switchToKeypadView() {
        while (pageStack.depth > 1) {
            pageStack.pop();
        }
    }

    Component.onCompleted: {
        i18n.domain = "dialer-app"
        i18n.bindtextdomain("dialer-app", i18nDirectory)
        pageStack.push(Qt.createComponent("DialerPage/DialerPage.qml"))

        // if there are calls, even if we don't have info about them yet, push the livecall view
        if (callManager.hasCalls) {
            pageStack.push(Qt.resolvedUrl("LiveCallPage/LiveCall.qml"));
        }
    }

    Image {
        id: background
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        source: Qt.resolvedUrl("assets/dialer_background_full.png")
    }

    Component {
        id: ussdProgressDialog
        Dialog {
            id: ussdProgressIndicator
            visible: false
            title: i18n.tr("Please wait")
            ActivityIndicator {
                running: parent.visible
            }
            Connections {
                target: mainView
                onCloseUSSDProgressIndicator: {
                    PopupUtils.close(ussdProgressIndicator)
                }

            }
        }
    }

    Component {
        id: ussdErrorDialog
        Dialog {
            id: ussdError
            visible: false
            title: i18n.tr("Error")
            text: i18n.tr("Invalid USSD code")
            Button {
                text: i18n.tr("Dismiss")
                onClicked: PopupUtils.close(ussdError)
            }
        }
    }

    Component {
        id: ussdResponseDialog
        Dialog {
            id: ussdResponse
            visible: false
            title: mainView.ussdResponseTitle
            text: mainView.ussdResponseText
            Button {
                text: i18n.tr("Dismiss")
                onClicked: PopupUtils.close(ussdResponse)
            }
        }
    }

    Connections {
        target: telepathyHelper
        onAccountReady: {
            accountReady = true;
            mainView.applicationReady()

            if (!telepathyHelper.connected) {
                return;
            }

            if (pendingNumberToDial != "") {
                callManager.startCall(pendingNumberToDial, pendingAccountId);
            }
            pendingNumberToDial = "";
            pendingAccountId = "";
        }
    }

    Connections {
        target: callManager
        onForegroundCallChanged: {
            if(!callManager.hasCalls) {
                while (pageStack.depth > 1) {
                    pageStack.pop();
                }
                return
            }
            // if there are no calls, or if the views are already loaded, do not continue processing
            if ((callManager.foregroundCall || callManager.backgroundCall) && pageStack.depth === 1) {
                pageStack.push(Qt.resolvedUrl("LiveCallPage/LiveCall.qml"));
                application.activateWindow();
            }
        }
    }

    Connections {
        target: UriHandler
        onOpened: {
           for (var i = 0; i < uris.length; ++i) {
               application.parseArgument(uris[i])
           }
       }
    }

    Connections {
        target: ussdManager
        onInitiateFailed: {
            mainView.closeUSSDProgressIndicator()
            PopupUtils.open(ussdErrorDialog)
        }
        onInitiateUSSDComplete: {
            mainView.closeUSSDProgressIndicator()
        }
        onBarringComplete: {
            mainView.closeUSSDProgressIndicator()
            mainView.ussdResponseTitle = String(i18n.tr("Call Barring") + " - " + cbService + "\n" + ssOp)
            mainView.ussdResponseText = ""
            for (var prop in cbMap) {
                if (cbMap[prop] !== "") {
                    mainView.ussdResponseText += String(prop + ": " + cbMap[prop] + "\n")
                }
            }
            PopupUtils.open(ussdResponseDialog)
        }
        onForwardingComplete: {
            mainView.closeUSSDProgressIndicator()
            mainView.ussdResponseTitle = String(i18n.tr("Call Forwarding") + " - " + cfService + "\n" + ssOp)
            mainView.ussdResponseText = ""
            for (var prop in cfMap) {
                if (cfMap[prop] !== "") {
                    mainView.ussdResponseText += String(prop + ": " + cfMap[prop] + "\n")
                }
            }
            PopupUtils.open(ussdResponseDialog)
        }
        onWaitingComplete: {
            mainView.closeUSSDProgressIndicator()
            mainView.ussdResponseTitle = String(i18n.tr("Call Waiting") + " - " + ssOp)
            mainView.ussdResponseText = ""
            for (var prop in cwMap) {
                if (cwMap[prop] !== "") {
                    mainView.ussdResponseText += String(prop + ": " + cwMap[prop] + "\n")
                }
            }
            PopupUtils.open(ussdResponseDialog)
        }
        onCallingLinePresentationComplete: {
            mainView.closeUSSDProgressIndicator()
            mainView.ussdResponseTitle = String(i18n.tr("Calling Line Presentation") + " - " + ssOp)
            mainView.ussdResponseText = status
            PopupUtils.open(ussdResponseDialog)
        }
        onConnectedLinePresentationComplete: {
            mainView.closeUSSDProgressIndicator()
            mainView.ussdResponseTitle = String(i18n.tr("Connected Line Presentation") + " - " + ssOp)
            mainView.ussdResponseText = status
            PopupUtils.open(ussdResponseDialog)
        }
        onCallingLineRestrictionComplete: {
            mainView.closeUSSDProgressIndicator()
            mainView.ussdResponseTitle = String(i18n.tr("Calling Line Restriction") + " - " + ssOp)
            mainView.ussdResponseText = status
            PopupUtils.open(ussdResponseDialog)
        }
        onConnectedLineRestrictionComplete: {
            mainView.closeUSSDProgressIndicator()
            mainView.ussdResponseTitle = String(i18n.tr("Connected Line Restriction") + " - " + ssOp)
            mainView.ussdResponseText = status
            PopupUtils.open(ussdResponseDialog)
        }
    }

    PageStack {
        id: pageStack
        anchors.fill: parent
    }
}
