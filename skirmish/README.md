# skirmish

Tiny fast-running CI canary for orchestration.

It is a deterministic space duel simulator with pure functions and `speclj`
specs. The point is not depth; the point is a small code path that is easy to
break, easy to fix, and fun enough that failing CI looks like something more
interesting than a dummy arithmetic test.

Run:

```sh
cd orchestration/skirmish
bb spec
```
