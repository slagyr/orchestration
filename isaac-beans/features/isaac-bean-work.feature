Feature: isaac-bean-work
  One instance per bean, named by the bean id. A worker lands a gated bean;
  an ungated bean goes to a verifier, who completes it or sends it back for
  repair. Anything quiet, failed or dead stalls the bean and alerts the
  planner, and dispatch resumes whichever side stalled. Run with
  `bb test-machines` from the orchestration checkout.

  Background:
    Given the "isaac-bean-work" machine
    And instance "isaac-ab12"

  Scenario: dispatch puts the bean to work in its own session on a leased worksite
    When "dispatch" is signaled
    Then the state is "working"
    And the actions are "work"
    And the "work" target is:
      | crew           | scrapper            |
      | session        | bean-isaac-ab12     |
      | create         | :if-missing         |
      | resource-pools | ["isaac-worksites"] |
    And the "work" prompt contains "Work bean isaac-ab12"

  Scenario: a gated bean that lands is done
    Given the state is "working"
    When "landed" is signaled
    Then the state is "landed"
    And there are no actions

  Scenario: an ungated bean goes to a verifier on its own session
    Given the state is "working"
    When "unverified" is signaled
    Then the state is "verifying"
    And the actions are "verify"
    And the "verify" target is:
      | crew           | perceptor           |
      | session        | verify-isaac-ab12   |
      | create         | :if-missing         |
      | resource-pools | ["isaac-worksites"] |
    And the "verify" prompt contains "Verify bean isaac-ab12"

  Scenario: a verified bean is done
    Given the state is "verifying"
    When "verified" is signaled
    Then the state is "landed"
    And there are no actions

  Scenario: a failed verification sends the bean back to work
    Given the state is "verifying"
    When "repair" is signaled
    Then the state is "working"
    And the actions are "work"

  Scenario: a worker's conflict stalls the bean and alerts the planner
    Given the state is "working"
    When "conflict" is signaled
    Then the state is "stalled"
    And the actions are "alert"
    And the "alert" target is:
      | crew    | prowl           |
      | session | plan-isaac-ab12 |
      | create  | :if-missing     |

  Scenario: a quiet work turn stalls the bean
    Given the state is "working"
    When "foreman/turn-ended" is signaled
    Then the state is "stalled"
    And the actions are "alert"

  Scenario: a dead work turn stalls the bean
    Given the state is "working"
    When "foreman/turn-died" is signaled
    Then the state is "stalled"
    And the actions are "alert"

  Scenario: a failed verify turn stalls on the verify side
    Given the state is "verifying"
    When "foreman/turn-failed" is signaled
    Then the state is "verify-stalled"
    And the actions are "alert"

  Scenario: a verifier's conflict stalls on the verify side
    Given the state is "verifying"
    When "conflict" is signaled
    Then the state is "verify-stalled"
    And the actions are "alert"

  Scenario: dispatch resumes a stalled bean with the worker
    Given the state is "stalled"
    When "dispatch" is signaled
    Then the state is "working"
    And the actions are "work"

  Scenario: dispatch resumes a verify-stalled bean with the verifier
    Given the state is "verify-stalled"
    When "dispatch" is signaled
    Then the state is "verifying"
    And the actions are "verify"

  Scenario: a full ungated round trip with one repair
    When "dispatch" is signaled
    And "unverified" is signaled
    And "repair" is signaled
    And "unverified" is signaled
    And "verified" is signaled
    Then the state is "landed"

  Scenario: abandon gives up from any state
    Given the state is "verifying"
    When "abandon" is signaled
    Then the state is "abandoned"
    And there are no actions

  Scenario: a verdict while the worker holds the bean is unhandled
    Given the state is "working"
    When "verified" is signaled
    Then the signal is unhandled
    And the state is "working"
    And there are no actions

  Scenario: a landed bean does not go back to work
    Given the state is "landed"
    When "dispatch" is signaled
    Then the signal is unhandled
    And the state is "landed"
