    /*
 * Copyright (C) 2012-2015 Canonical, Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import QtContacts 5.0
//import Ubuntu.Contacts 0.1

ContactModel {
    id: root

    property var externalFilter: null
    property string filterTerm: ""
    property bool onlyFavorites: false
    property var view: null

    /* internal */
    property bool _clearModel: false
    property list<QtObject> _extraFilters
    property QtObject _timeout


    function changeFilter(newFilter)
    {
        if (root.contacts.length > 0) {
            root._clearModel = true
        }
        root.externalFilter = newFilter
    }


    filter: {
        if (root._clearModel) {
            return invalidFilter
        } else if (contactsFilter.active) {
            return contactsFilter
        } else {
            return null
        }
    }

    _extraFilters: [
        InvalidFilter {
            id: invalidFilter
        },
        DetailFilter {
            id: favouritesFilter

            detail: ContactDetail.Favorite
            field: Favorite.Favorite
            value: true
            matchFlags: DetailFilter.MatchExactly
        },
        UnionFilter {
            id: contactTermFilter

            property string value: ""
            property var phoneNumberFilter: DetailFilter {
                detail: ContactDetail.PhoneNumber
                field: PhoneNumber.Number
                value: contactTermFilter.value
                matchFlags: (DetailFilter.MatchPhoneNumber | DetailFilter.MatchContains)
            }

            filters: [
                DetailFilter {
                    id: firstNameFilter
                    detail: ContactDetail.Name
                    field: Name.FirstName
                    matchFlags: Filter.MatchContains
                    value: contactTermFilter.value
                },
                DetailFilter {
                    id: middleNameFilter
                    detail: ContactDetail.Name
                    field: Name.MiddleName
                    matchFlags: Filter.MatchContains
                    value: contactTermFilter.value
                },
                DetailFilter {
                    id: lastNameFilter
                    detail: ContactDetail.Name
                    field: Name.LastName
                    matchFlags: Filter.MatchContains
                    value: contactTermFilter.value
                }
            ]

            onValueChanged: {
                var containsOnlyNumbers = value.match(/^[0-9\+\s]+$/) !== null;
                if (!containsOnlyNumbers && (filters.length > 3)) {
                    filters = [firstNameFilter, middleNameFilter, lastNameFilter]
                } else if (containsOnlyNumbers) {
                    filters = [firstNameFilter, middleNameFilter, lastNameFilter, phoneNumberFilter]
                }
            }
        },
        IntersectionFilter {
            id: contactsFilter

            // avoid runtime warning "depends on non-NOTIFYable properties"
            readonly property alias filtersProxy: contactsFilter.filters

            property bool active: {
                var filters_ = []
                if (contactTermFilter.value.length > 0) {
                    filters_.push(contactTermFilter)
                } else if (root.onlyFavorites) {
                    filters_.push(favouritesFilter)
                }

                if (root.externalFilter) {
                    filters_.push(root.externalFilter)
                }

                // check if the filter has changed
                var oldFilters = filtersProxy
                if (oldFilters.length !== filters_.length) {
                    contactsFilter.filters = filters_
                } else {
                    for(var i=0; i < oldFilters.length; i++) {
                        if (filters_.indexOf(oldFilters[i]) === -1) {
                            contactsFilter.filters = filters_
                        }
                    }
                }

                return (filters_.length > 0)
            }
        }
    ]

    _timeout: Timer {
        id: contactSearchTimeout

        running: false
        repeat: false
        interval: 300
        onTriggered: {
            if (root.view) {
                view.positionViewAtBeginning()
            }

            root.changeFilter(root.externalFilter)
            contactTermFilter.value = root.filterTerm.trim()

            // manually update if autoUpdate is disabled
            if (!root.autoUpdate) {
                root.update()
            }
        }
    }

    onFilterTermChanged: {
        var newFilterTerm = root.filterTerm.trim()
        if (contactTermFilter.value != newFilterTerm)
            contactSearchTimeout.restart()
    }

    onErrorChanged: {
        if (error) {
            console.error("Contact List error:" + error)
        }
    }

    onContactsChanged: {
        //WORKAROUND: clear the model before start populate it with the new contacts
        //otherwise the model will wait for all contacts before show any new contact

        //after all contacts get removed we can populate the model again, this will show
        //new contacts as soon as it arrives in the model
        if (root._clearModel && contacts.length === 0) {
            root._clearModel = false
            // do a new update if autoUpdate is false
            if (!root.autoUpdate) {
                root.update()
            }

        }
    }
}

