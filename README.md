Dialer App
==========
Dialer Application for Ubuntu Touch.

Internals
=========

Dialer app relies on :
  - [telephony-service](https://github.com/ubports/telephony-service) for call relay.
  - [history-service](https://github.com/ubports/history-service) for call history



Building with clickable
=======================
Install [clickable](http://clickable.bhdouglass.com/en/latest/), then run:

```
clickable
```

For faster build speeds, building app tests is disabled in ```clickable.json``` 


Tests
=========

for QML tests, run `clickable test`
for integration tests, see the HACKING file
