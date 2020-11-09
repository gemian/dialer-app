/*
 * Copyright 2015 Canonical Ltd.
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


import QtQuick 2.2
import QtContacts 5.0

import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3 as Popups

//import Ubuntu.AddressBook.Base 0.1
//import Ubuntu.AddressBook.ContactView 0.1
//import Ubuntu.AddressBook.ContactShare 0.1
import "../Contacts"

ContactViewPage {
    id: root
    objectName: "contactViewPage"

    readonly property string contactEditorPageURL: Qt.resolvedUrl("../ContactEditorPage/DialerContactEditorPage.qml")
    property string addPhoneToContact: ""
    property var contactListPage: null

    function addPhoneToContactImpl(contact, phoneNumber)
    {
        var detailSourceTemplate = "import QtContacts 5.0; PhoneNumber{ number: \"" + phoneNumber.trim() + "\" }"
        var newDetail = Qt.createQmlObject(detailSourceTemplate, contact)
        if (newDetail) {
            contact.addDetail(newDetail)
            pageStack.push(root.contactEditorPageURL,
                           { model: root.model,
                             contact: contact,
                             initialFocusSection: "phones",
                             newDetails: [newDetail],
                             contactListPage: root.contactListPage })
            root.addPhoneToContact = ""
        } else {
            console.warn("Fail to create phone number detail")
        }
    }

    model: null
    
    onContactRemoved: pageStack.pop()
    onActionTrigerred: {
        if ((action == "tel") || (action == "default")) {
            if (callManager.hasCalls) {
                mainView.call(detail.number, mainView.account.accountId);
            } else {
                mainView.startCall(detail.number)
            }
        } else {
            Qt.openUrlExternally(("%1:%2").arg(action).arg(detail.value(0)))
        }
    }

    Component {
        id: contactShareComponent
        ContactSharePage {}
    }

    onContactFetched: {
        root.contact = contact
        if (root.active && root.addPhoneToContact != "") {
            root.addPhoneToContactImpl(contact, root.addPhoneToContact)
            root.addPhoneToContact = ""
        }
    }

    Component {
        id: contactModelComponent

        ContactModel {
            id: contactModelHelper

            manager: (typeof(QTCONTACTS_MANAGER_OVERRIDE) !== "undefined") &&
                      (QTCONTACTS_MANAGER_OVERRIDE != "") ? QTCONTACTS_MANAGER_OVERRIDE : "galera"
            autoUpdate: false
        }
    }

    onActiveChanged: {
        if (active && root.contact && root.addPhoneToContact != "") {
            root.addPhoneToContactImpl(contact, root.addPhoneToContact)
            root.addPhoneToContact = ""
        }
    }

    Component.onCompleted: {
        if (!root.model) {
            root.model = contactModelComponent.createObject(root)
        }
    }
}
