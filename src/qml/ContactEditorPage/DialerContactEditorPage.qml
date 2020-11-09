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

//import Ubuntu.AddressBook.ContactEditor 0.1

ContactEditorPage {
    id: root
    objectName: "contactEditorPage"

    property var contactListPage: null

    leadingActions: Action {
        objectName: "cancel"

        text: i18n.tr("Cancel")
        iconName: "back"
        onTriggered: {
            root.cancel()
            root.active = false
        }
    }

    headerActions: [
        Action {
            objectName: "save"

            text: i18n.tr("Save")
            iconName: "ok"
            enabled: root.isContactValid
            onTriggered: root.save()
        }
    ]

    onContactSaved: {
        if (root.contactListPage) {
            root.contactListPage.moveListToContact(contact)
            root.contactListPage.phoneToAdd = ""
        }
    }
}
