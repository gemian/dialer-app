file(GLOB CONTACTS_PAGE_QML_JS_FILES *.qml *.js)

# make the files visible on qtcreator
add_custom_target(dialer_contacts_page_QMlFiles ALL SOURCES ${CONTACTS_PAGE_QML_JS_FILES})

install(FILES ${CONTACTS_PAGE_QML_JS_FILES} DESTINATION ${DIALER_APP_DIR}/ContactsPage)

