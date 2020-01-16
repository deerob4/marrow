(ns marrow-client.introduction
  (:require [clojure.spec.alpha :as s]))

(defn blank? [str]
  (every? #(Character/isWhitespace %) str))

(def accounts (atom #{}))

(defn create-account [username]
  (if (contains? @accounts username)
    "You already have an account!"
    (do
      (swap! accounts conj username)
      "Account created!")))

(defn print-accounts []
  (reduce (partial str " ") @accounts))


(def ingredients [{:name "Bread Flour"
                   :quantity 250
                   :unit :grams}

                  {:name "Yeast"
                   :quantity 7
                   :unit :grams}

                  {:name "Dried Fruit"
                   :quantity 200
                   :unit :grams}

                  {:name "Unsalted Butter"
                   :quantity 40
                   :unit :grams}

                  {:name "Soft Brown Sugar"
                   :quantity 75
                   :unit :grams}

                  {:name "Milk"
                   :quantity 300
                   :unit :ml}])

(s/def ::ingredient (s/keys :req [::name ::quantity ::unit]))
(s/def ::name string?)
(s/def ::quantity pos-int?)
(s/def ::unit #{:grams :ml})
(s/def ::ingredients (s/coll-of ::ingredient))

(s/def :role-repr/type #{:colour :image})
(s/def :role-repr/value string?)
(s/def :role-repr (s/keys :req-un [:role-repr/type :role-repr/value]))

(s/def :role/id string?)
(s/def :role/name string?)
(s/def :role/repr :role-repr)
(s/def :role/taken? boolean?)




(defn measured-in? [unit]
  #(= (:unit %) unit))

(def measured-in-grams? (measured-in? :grams))
(def measured-in-ml? (measured-in? :ml))

(s/def :bowling/roll (s/int-in 1 11))
(s/exercise ::ingredient)

(defn scale-ingredients [factor ingredient]
 (update ingredient :quantity * factor))

(s/fdef scale-ingredients
        :args (s/cat :ingredient ::ingredient
                     :factor number?)
        :ret ::ingredient)

(s/def ::odd-int (s/and odd? integer?))
(s/valid? ::odd-int 19)
(s/def ::odd-or-42 (s/or :odd ::odd-int :42 #{42}))
(s/valid? ::odd-or-42 3)
(defn flip [f & xs]
  (apply f (reverse xs)))

(map (partial scale-ingredients 10) ingredients)


;(reduce
;  (fn [acc ingredient]
;    (if (measured-in-grams? ingredient)
;      (+ acc (:quantity ingredient))
;      acc))
;  ingredients)

(for [ingredient ingredients :when (= (:unit ingredient) :grams)]
  (:name ingredient))

(rand-nth [1 2 3 4 5])