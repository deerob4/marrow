(ns marrow-client.db
  (:require
    [cljs.spec.alpha :as s]
    [meander.match.alpha :refer [match search find]]))

;--------------------------------------
; Spec definitions --------------------
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(s/def ::auth-status #{:password-required :allowed :already-started})
(s/def ::stage #{:lobby :in-progress :results})
(s/def ::fence (s/tuple ::stage ::auth-status))

(s/def ::role-name string?)
(s/def ::role-image-url (s/nilable string?))
(s/def ::role-taken? boolean?)
(s/def ::role (s/keys :req [::role-name ::role-taken?]
                      :opt [::role-image-url]))

(s/def ::game-id string?)
(s/def ::game-title string?)
(s/def ::game-min-players integer?)
(s/def ::game-max-players integer?)
(s/def ::game-description (s/nilable string?))
(s/def ::game (s/keys :req [::game-id ::game-title ::game-min-players
                            ::game-max-players ::game-description]))

(s/def ::countdown-started? boolean?)
(s/def ::countdown (s/and integer? #(>= % 0)))

(s/def ::lobby-status #{:waiting-for-others :player-left :counting-down})

(s/def ::variable-type #{:global :player})

;(s/def ::game/id string?)
;(s/def ::game/title string?)
;(s/def ::game/description (s/nilable string?))
;(s/def ::game (s/keys :req [:game/id :game/title :game/description]))

(s/def ::x (s/and integer? #(>= % 0)))
(s/def ::y (s/and integer? #(>= % 0)))
(s/def ::coord (s/keys :req-un [::x ::y]))
(s/def ::role-positions (s/map-of ::role-name ::coord))

(defn generate-tiles [path-line]
  (match path-line
    {:from {:x ?x1 :y ?y} :to {:x ?x2 :y ?y}}
    (for [x (range ?x1 ?x2)] {:x x :y ?y})

    {:from {:x ?x :y ?y1} :to {:x ?x :y ?y2}}
    (for [y (range ?y1 ?y2)] {:x ?x :y y})))

(generate-tiles {:from {:x 0 :y 0} :to {:x 5 :y 0}})

(def default-db
  {:stage :loading
   :connected-to-socket-ever? false
   :board-settings {:skewed? false
                    :shadowed? false
                    :clear? true
                    :show-images? true
                    :size 80}
   :game {:id "ebc93423434"
          :active-role "dee"
          :title "Snakes and Ladders"
          :player-role "a"
          :current-turn 0
          :show-card? true
          :player-card {:title "Revenge of the Fooker! Or, Finding de Hvid Whale af Møder."
                        :body "Keir has stumbled, and you now have the chance to show either mercy or revenge.
                        Where will you send him?"
                        :actions [{:id 0 :title "Mordor"}
                                  {:id 1 :title "Askaban"}]}
          :role-positions {"jay" {:x 0 :y 0}
                           "keir" {:x 0 :y 0}
                           "dee" {:x 0 :y 0}
                           "chris" {:x 0 :y 0}
                           "smithy" {:x 0 :y 0}
                           "rose" {:x 0 :y 0}}
          :roles {:ordered ["jay" "dee" "chris" "smithy" "rose"]
                  :by-name {"jay" {:name "jay"
                                   :repr {:type :image
                                          :value "http://doj.me/wp-content/uploads/2017/02/Wikimedia-Commons-1140x640.jpg"}}
                            "dee" {:name "dee"
                                   :repr {:type :colour
                                          :value "skyblue"}}
                            "chris" {:name "chris"
                                     :repr {:type :colour
                                            :value "indigo"}}
                            "smithy" {:name "smithy"
                                      :repr {:type :colour
                                             :value "red"}}
                            "rose" {:name "rose"
                                    :repr {:type :image
                                           :value "https://5.imimg.com/data5/OF/GC/MY-4584302/red-rose-flower-500x500.jpg"}}}}
          :variables [{:type :global :name "Rounds" :value 1}
                      {:type :global :name "Message" :value "Let's go lads!"}

                      {:type :global :name "Time to destruction" :value 100}
                      {:type :player :name "Score" :values [{:role "Jay" :value 10}
                                                            {:role "Keir" :value 20}
                                                            {:role "Dee" :value 30}]}]
          :events [{:turn 1
                    :text "Jay joined the game."
                    :type :join}
                   {:turn 1
                    :text "Keir joined the game."
                    :type :join}
                   {:turn 1
                    :text "Dee joined the game."
                    :type :join}
                   {:turn 1
                    :text "Chris joined the game."
                    :type :join}
                   {:turn 1
                    :text "Smithy joined the game."
                    :type :join}
                   {:turn 1
                    :text "Rose joined the game."
                    :type :join}]
          :board {:diimensions {:width 5 :height 2}
                  :dimensions {:width 5 :height 5}
                  :tiles9 [{:x 0 :y 0}
                           {:x 1 :y 0}
                           {:x 2 :y 0}
                           {:x 3 :y 0}
                           {:x 4 :y 0}
                           {:x 5 :y 0}]
                  :tiles7 [{:x 0 :y 0}
                           {:x 1 :y 0}
                           {:x 2 :y 0}
                           {:x 3 :y 0}
                           {:x 4 :y 0}
                           {:x 4 :y 1}
                           {:x 4 :y 2}
                           {:x 5 :y 2}]
                  :tiles [{:x 0 :y 0}
                          {:x 1 :y 0}
                          {:x 2 :y 0}
                          {:x 3 :y 0}
                          {:x 4 :y 0}
                          {:x 5 :y 0}
                          {:x 5 :y 1}
                          {:x 5 :y 2}
                          {:x 5 :y 3}
                          {:x 5 :y 4}
                          {:x 5 :y 5}
                          {:x 4 :y 5}
                          {:x 3 :y 5}
                          {:x 2 :y 5}
                          {:x 1 :y 5}
                          {:x 0 :y 5}
                          {:x 0 :y 4}
                          {:x 0 :y 3}
                          {:x 0 :y 2}
                          {:x 0 :y 1}]}

          :min-players 2
          :max-players 3}
   :lobby {:roles {"Keir" {:name "Keir"
                           :taken? false}
                   "Jay" {:name "Jay"
                          :taken? false}
                   "Rose" {:name "Rose"
                           :taken? false}
                   "Jed" {:name "Jed"
                          :taken? true}}
           :selected-role nil
           :countdown 10}})

(defn travel-direction [[{x1 :x} {x2 :x}]]
  (if (not= x1 x2) :x :y))

(defn find-corners
  ([[first _ & rest :as coords]] (find-corners rest (travel-direction coords) #{first}))
  ([[current-coord _ & rest :as coords] direction corners])) []
   ;(if (empty? coords)
   ;  corners
   ;  (let [new-direction (travel-direction coords)]
   ;    (find-corners rest new-direction (if (= direction new-direction)
   ;                                       corners
   ;                                       (conj corners current-coord)))))))

(defn woo []
  (search [1 1 2 2 3 4 5 6]
    [_ ... (pred odd? ?the-odd-one) (pred even? ?the-even-one) . _ ...]
    [?the-odd-one ?the-even-one]))

(defn direction [coords]
  (match coords
    [{:x _ :y ?y} {:x _ :y ?y}] :horizontal
    [{:x ?x :y _} {:x ?x :y _}] :vertical))

(defn magic [numbers]
  (match numbers
    [?x ?y ~(+ ?x ?y)] true
    _ false))

(def tiles [{:x 0 :y 0}
            {:x 1 :y 0}
            {:x 2 :y 0}
            {:x 3 :y 0}
            {:x 4 :y 0}
            {:x 5 :y 0}
            {:x 5 :y 1}
            {:x 5 :y 2}
            {:x 5 :y 3}
            {:x 5 :y 4}
            {:x 5 :y 5}
            {:x 4 :y 5}
            {:x 3 :y 5}
            {:x 2 :y 5}
            {:x 1 :y 5}
            {:x 0 :y 5}
            {:x 0 :y 4}
            {:x 0 :y 3}
            {:x 0 :y 2}
            {:p 0 :y 1}])

;(match tiles
;  [. {:x _ :y _} .]
;  "yay")