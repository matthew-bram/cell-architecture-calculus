# generated from Library/Circulation.lean#2465870485711712215+../../cell-calculus/CellCalculus/Cell.lean#2309738383907301477; do not edit
Feature: circulation lends

Scenario: LOAN-OUT-1
  Given nothing has happened yet
  When a checkout arrives with key k1 for copy b-1
  Then copy b-1 was checked out under key k1, 1 on loan

Scenario: LOAN-OUT-2 (retry after unknown)
  Given copy b-1 was checked out under key k1, 1 on loan
  When a checkout arrives with key k1 for copy b-1
  Then nothing happens

Scenario: LOAN-OUT-3 (refused, card closed)
  Given the card was closed
  When a checkout arrives with key k2 for copy b-2
  Then it is refused because the card is closed

Scenario: LOAN-OUT-4 (the sixth is refused)
  Given copy b-1 was checked out under key k1, 1 on loan
  And copy b-2 was checked out under key k2, 2 on loan
  And copy b-3 was checked out under key k3, 3 on loan
  And copy b-4 was checked out under key k4, 4 on loan
  And copy b-5 was checked out under key k5, 5 on loan
  When a checkout arrives with key k6 for copy b-6
  Then it is refused because five items are already on loan

Scenario: LOAN-OUT-5 (the fifth is fine)
  Given copy b-1 was checked out under key k1, 1 on loan
  And copy b-2 was checked out under key k2, 2 on loan
  And copy b-3 was checked out under key k3, 3 on loan
  And copy b-4 was checked out under key k4, 4 on loan
  When a checkout arrives with key k5 for copy b-5
  Then copy b-5 was checked out under key k5, 5 on loan

Scenario: LOAN-IN-1
  Given copy b-1 was checked out under key k1, 1 on loan
  When a return arrives with key k2 for copy b-1
  Then copy b-1 was checked in under key k2

Scenario: LOAN-IN-2 (not on loan)
  Given nothing has happened yet
  When a return arrives with key k2 for copy b-9
  Then it is refused because the copy is not on loan

Scenario: LOAN-IN-3 (retry after unknown)
  Given copy b-1 was checked out under key k1, 1 on loan
  And copy b-1 was checked in under key k2
  When a return arrives with key k2 for copy b-1
  Then nothing happens

Scenario: LOAN-IN-4 (a closed card's item comes back)
  Given copy b-1 was checked out under key k1, 1 on loan
  And the card was closed
  When a return arrives with key k2 for copy b-1
  Then copy b-1 was checked in under key k2

Scenario: LOAN-RENEW-1
  Given copy b-1 was checked out under key k1, 1 on loan
  When a renewal arrives with key k3 for copy b-1
  Then copy b-1 was renewed under key k3

Scenario: LOAN-RENEW-2 (not on loan)
  Given nothing has happened yet
  When a renewal arrives with key k3 for copy b-9
  Then it is refused because the copy is not on loan

Scenario: LOAN-CLOSE-2
  Given nothing has happened yet
  When the card is closed
  Then the card was closed

Scenario: LOAN-CLOSE-3 (already closed, quiet)
  Given the card was closed
  When the card is closed
  Then nothing happens
