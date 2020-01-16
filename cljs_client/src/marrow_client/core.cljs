(ns ^:figwheel-hooks marrow-client.core
  (:require
    [goog.dom :as gdom]
    [reagent.core :as reagent :refer [atom]]
    [re-frame.core :refer [subscribe dispatch dispatch-sync]]
    [re-frame.loggers :as rf.log]
    [marrow-client.events]
    [marrow-client.views :as views]))

(defn multiply [a b] (* a b))

(defn get-app-element []
  (gdom/getElement "app"))

(defn expand-path [{:keys [from to]}]
  (let [[x1 y1] (vals from)
        [x2 y2] (vals to)]
    (if (= y1 y2)
      (map (fn [x] {:x x :y y1}) (range x1 x2))
      (map (fn [y] {:x x1 :y y} (range y1 y2))))))

(def pre-game-views
  #{:lobby :password-required :game-not-found :game-already-started :not-available})

(defn stage-to-view
  "Maps the given stage to the appropriate root-level view function."
  [stage]
  (case stage
    :loading [:div]
    :in-progress [views/game-view]
    :lobby [views/lobby]
    :password-required [views/password-screen]
    :game-not-found [views/game-not-found]
    :game-already-started [views/game-already-started]
    :not-available [views/server-not-available]))

(defn root []
  (let [stage @(subscribe [:stage])
        view (stage-to-view stage)]
    (if @(subscribe [:socket/not-available?])
      [views/pre-game-view [views/server-not-available]]
      (if (contains? pre-game-views stage)
        [views/pre-game-view view]
        [:<> view]))))

(defn mount [el]
  (reagent/render-component [root] el))

(defn mount-app-element []
  (when-let [el (get-app-element)]
    (mount el)))

;; Prevent re-frame from warning when event handlers are redefined.
;; Taken from https://github.com/Day8/re-frame/issues/204#issuecomment-250337344.
(def warn (js/console.warn.bind js/console))
(rf.log/set-loggers!
  {:warn (fn [& args]
           (cond
             (= "re-frame: overwriting" (first args)) nil
             :else (apply warn args)))})

;; specify reload hook with ^;after-load metadata
(defn ^:after-load on-reload []
  (mount-app-element))
;; optionally touch your app-state to force rerendering depending on
;; your application
;; (swap! app-state update-in [:__figwheel_counter] inc)

(defonce start-up (do
                    (dispatch-sync [:initialise-db])
                    (mount-app-element)
                    true))

(def amy 14)
(if (= amy 14) "Yay, Amy is 14"
               "Amy is not 14")