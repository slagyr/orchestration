(ns orchestration.skirmish-spec
  (:require
    [orchestration.skirmish :as sut]
    [speclj.core :refer :all]))

(describe "skirmish"

  (it "lets shields absorb damage before hull"
    (should= {:name :red-dwarf :hull 10 :shields 2 :attack 4}
             (sut/absorb-damage {:name :red-dwarf :hull 10 :shields 5 :attack 4} 3)))

  (it "spills overflow damage into hull after shields collapse"
    (should= {:name :ion-wasp :hull 6 :shields 0 :attack 3}
             (sut/absorb-damage {:name :ion-wasp :hull 8 :shields 2 :attack 3} 4)))

  (it "overcharge boosts damage and deals recoil to the attacker"
    (let [result (sut/fire {:name :red-dwarf :hull 9 :shields 3 :attack 4}
                           {:name :ion-wasp :hull 8 :shields 2 :attack 3}
                           {:overcharge? true})]
      (should= 6 (get-in result [:report :damage]))
      (should= 1 (get-in result [:report :recoil]))
      (should= {:name :red-dwarf :hull 8 :shields 3 :attack 4}
               (:attacker result))
      (should= {:name :ion-wasp :hull 4 :shields 0 :attack 3}
               (:defender result))))

  (it "detects the surviving ship as the winner"
    (should= :red-dwarf
             (sut/winner {:name :red-dwarf :hull 4 :shields 0 :attack 4}
                         {:name :ion-wasp :hull 0 :shields 0 :attack 3})))

  (it "resolves a deterministic duel transcript"
    (let [result (sut/duel {:name :red-dwarf :hull 9 :shields 3 :attack 4}
                           {:name :ion-wasp :hull 8 :shields 2 :attack 3}
                           [{:side :left}
                            {:side :right :overcharge? true}
                            {:side :left :overcharge? true}
                            {:side :right}])]
      (should= :ion-wasp (:winner result))
      (should= {:name :red-dwarf :hull 6 :shields 0 :attack 4} (:left result))
      (should= {:name :ion-wasp :hull 0 :shields 0 :attack 3} (:right result))
      (should= [{:attacker :red-dwarf :defender :ion-wasp :damage 4 :recoil 0 :overcharge? false}
                {:attacker :ion-wasp :defender :red-dwarf :damage 5 :recoil 1 :overcharge? true}
                {:attacker :red-dwarf :defender :ion-wasp :damage 6 :recoil 1 :overcharge? true}]
               (:transcript result)))))
