# CfMailGun - CFML Client for the MailGun API

This CFML client is a simple, single `CFC` to enable you to easily interact with the MailGun API in your CFML applications (Railo, ColdFusion, Open BlueDragon).

**It is currently a work in progress and pre-alpha. First official release due soon.**

## MailGun

[MailGun](http://www.mailgun.com) is a service for email handling. It has an easy to use API and great tools for managing the sending, tracking and receiving of emails.

## Documentation

Documentation can be found here: [http://dominicwatson.github.io/cfmailgun](http://dominicwatson.github.io/cfmailgun). If you have issues with the documentation and wish to contribute, the source code can be found in the `gh-pages` branch of this repository.

## CFML Engine Compatibility

The client has been developed with compatibility in mind for all engines and as far back as possible. However, the client has only been tested on Railo 4.1.2. If you have compatibility issues, please holla.

## Test suite

The test suite relies on [TestBox](http://wiki.coldbox.org/wiki/TestBox.cfm). To run the tests, make the /test folder web accessible and ensure that a "/testbox" mapping exists pointing to a testbox install. Then browse /tests/index.cfm in a browser.

Please note that the test suite has not been written with compatibility in mind and requires ColdFusion 10 and above or Railo 4.1 and above.

## Contributing

Contributions are always welcome be it feedback, bug fixing or code contributions. Pull requests very welcome.

