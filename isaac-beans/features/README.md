The `.feature` files in this folder are Foreman machine tests for `config/machines/isaac-bean-work.edn`.
Run them with `isaac foreman test <file>` against an Isaac root with the Foreman module, the crews named by the machine, and the `isaac-worksites` pool.
Machine tests carry no instance data, so `{{data.*}}` renders empty in them.
The tests use a fixed step vocabulary provided by Foreman.
