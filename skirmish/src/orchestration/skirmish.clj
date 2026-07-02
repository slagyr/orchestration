(ns orchestration.skirmish)

(defn make-ship [name hull shields attack]
  {:name name :hull hull :shields shields :attack attack})

(defn alive? [ship]
  (pos? (:hull ship)))

(defn absorb-damage [ship damage]
  (let [shields  (:shields ship)
        absorbed (min shields damage)
        overflow (- damage absorbed)]
    (-> ship
        (update :shields - absorbed)
        (update :hull #(max 0 (- % overflow))))))

(defn- apply-recoil [ship recoil]
  (update ship :hull #(max 0 (- % recoil))))

(defn fire
  ([attacker defender]
   (fire attacker defender {}))
  ([attacker defender {:keys [overcharge?] :or {overcharge? false}}]
   (let [overcharge? (boolean overcharge?)
         damage      (+ (:attack attacker) (if overcharge? 2 0))
         recoil      (if overcharge? 1 0)
         attacker* (apply-recoil attacker recoil)
         defender* (absorb-damage defender damage)]
     {:attacker attacker*
      :defender defender*
      :report   {:attacker    (:name attacker)
                 :defender    (:name defender)
                 :damage      damage
                 :recoil      recoil
                 :overcharge? overcharge?}})))

(defn winner [left right]
  (cond
    (and (not (alive? left)) (not (alive? right))) :draw
    (not (alive? left)) (:name right)
    (not (alive? right)) (:name left)
    :else nil))

(defn duel [left right turns]
  (loop [left*      left
         right*     right
         remaining  turns
         transcript []]
    (if (or (empty? remaining) (winner left* right*))
      {:left left* :right right* :winner (winner left* right*) :transcript transcript}
      (let [{:keys [side overcharge?]} (first remaining)
            outcome (case side
                      :left  (fire left* right* {:overcharge? overcharge?})
                      :right (let [{:keys [attacker defender report]}
                                   (fire right* left* {:overcharge? overcharge?})]
                               {:attacker defender :defender attacker :report report})
                      (throw (ex-info "unknown skirmish side" {:side side})))
            left-next  (:attacker outcome)
            right-next (:defender outcome)]
        (recur left-next
               right-next
               (rest remaining)
               (conj transcript (:report outcome)))))))
