(ns marrow-client.utils)

(defn map-values [f m]
  (into {} (for [[k v] m] [k (f v)])))

(defn map-keys [f m]
  (into {} (for [[k v] m] [(f k) v])))

(defn index-by [field coll]
  (reduce (fn [map current]
            (assoc map (get current field) current)) {} coll))

(defn with-index [coll]
  (map-indexed vector coll))