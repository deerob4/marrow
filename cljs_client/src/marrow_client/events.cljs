(ns marrow-client.events
  (:require [re-frame.core :refer [reg-event-db
                                   reg-event-fx
                                   reg-sub
                                   reg-fx
                                   reg-cofx
                                   path
                                   inject-cofx
                                   debug
                                   dispatch
                                   subscribe]]
            [day8.re-frame.tracing :refer-macros [fn-traced]]
            [marrow-client.db :as db]
            [marrow-client.utils :refer [map-keys map-values index-by]]
            [phoenix]
            [meander.match.alpha :refer [match search]]
            [clojure.walk :refer [keywordize-keys]]
            [clojure.string :refer [upper-case]]
            [cljs.spec.alpha :as s]
            [reagent.core :as r]))

(def standard-interceptors
  [(when ^boolean js/goog.DEBUG debug)])

(reg-event-fx
  :initialise-db
  [standard-interceptors (inject-cofx :user-id) (inject-cofx :board-size)]
  (fn-traced [cofx _]
    {:db (assoc-in db/default-db [:board-settings :size] (:board-size cofx))
     :connect-to-socket (clj->js {})
     ; Try and connect to the game without a password at first.
     ; The server will tell us if we do need one, and we can try
     ; again if need be.
     :connect-to-game {:user-id (:user-id cofx)}}))

(reg-sub
  :stage
  (fn [db _]
    (db :stage)))

(reg-cofx
  :user-id
  (fn [cofx _]
    (assoc cofx :user-id (.getItem (.-localStorage js/window) "userId"))))

(reg-fx
  :set-user-id
  (fn [user-id]
    (.setItem (.-localStorage js/window) "userId" user-id)))

(reg-cofx
  :board-size
  (fn [cofx _]
    (assoc cofx :board-size (.getItem (.-localStorage js/window) "boardSize"))))

(reg-fx
  :set-board-size
  (fn [board-size]
    (.setItem (.-localStorage js/window) "boardSize" board-size)))

(reg-fx
  :reload-page
  (fn []
    (.reload (.-location js/window))))

;; -- Connecting to Phoenix channels

(defonce socket (atom nil))
(defonce game-channel (atom nil))

(defn create-socket [url params]
  (reset! socket (js/Phoenix.Socket. url params)))

(defn extract-presence-role [presence-event]
  (-> presence-event js->clj (get-in ["metas" 0 "role"])))

(defn create-presence []
  (let [p (js/Phoenix.Presence. @game-channel)]
    (.onSync p #(dispatch [:game/update-online-players (js->clj (.list p))]))
    (.onJoin p (fn [_id _current new-presence]
                 (dispatch [:game/player-joined (extract-presence-role new-presence)])))
    (.onLeave p (fn [_id _current left-presence]
                  (dispatch [:game/player-left (extract-presence-role left-presence)])))))

(def game-id
  (-> (.. js/window -location -pathname)
      (clojure.string/replace "/" "")))

(defn create-join-game-from-lobby-payload [payload]
  (let [{:keys [events tiles game_state]} (-> payload js->clj keywordize-keys)]
    (merge game_state {:events events :tiles tiles})))

(defn register-game-handlers [game-channel]
  (.on game-channel "lobby:role_taken" #(dispatch [:lobby/role-taken (.-role %)]))
  (.on game-channel "lobby:role_released" #(dispatch [:lobby/role-released (.-role %)]))
  (.on game-channel "lobby:min_players_reached" #(dispatch [:lobby/min-players-reached]))
  (.on game-channel "lobby:countdown_cancelled" #(dispatch [:lobby/cancel-countdown]))
  (.on game-channel "lobby:countdown" #(dispatch [:lobby/update-countdown (.-countdown %)]))
  (.on game-channel "lobby:begin_game" #(dispatch [:lobby/begin-game (create-join-game-from-lobby-payload %)]))
  (.on game-channel "game:new_state" #(dispatch [:game/new-state (keywordize-keys (js->clj (.-game %)))]))
  (.on game-channel "game:new_event" #(dispatch [:game/new-event (keywordize-keys (js->clj (.-event %)))]))
  (.on game-channel "game:event_message" #(dispatch [:game/set-event-message (.-message %)]))
  (.on game-channel "game:turn_countdown" #(dispatch [:game/update-countdown (.-remaining %)]))
  (.on game-channel "game:source_error" #(dispatch [:game/set-interpret-error (.-error %)]))
  (.on game-channel "game:roll_dice_results" #(dispatch [:game/receive-roll-results (keywordize-keys (js->clj (.-next_tile %)))]))
  (.on game-channel "game:move_board_piece" #(dispatch [:game/move-board-piece (keywordize-keys (js->clj (.-role %))) (keywordize-keys (js->clj (.-tile %)))]))
  (.on game-channel "game:finish_moving_piece" #(dispatch [:game/finish-moving]))
  (.on game-channel "game:timeup" #(dispatch [:game/timeup]))
  (.on game-channel "game:player_won" #(dispatch [:game/win (.-winning_role %)]))
  (.on game-channel "game:show_card", #(dispatch [:game/show-player-card (keywordize-keys (js->clj (.-card %)))]))
  (.on game-channel "game:hide_player_card" #(dispatch [:game/hide-player-card]))
  (create-presence))
  ;(js/window.createPresence game-channel))
  ;(.on game-channel "presence_diff" (fn [a b c]
  ;                                    (js/console.log a)
  ;                                    (js/console.log (.list @presence))))
  ;(.on game-channel "presence_state" #(println %)))

  ;(create-presence))

(reg-fx
  :websocket
  (fn [{:keys [handler params response timeout]}]
    (let [push (.push @game-channel handler (clj->js params))]
      (doseq [[msg callback] response]
        (.receive push msg callback)))))

(reg-fx
  :connect-to-socket
  (fn [params]
    (create-socket "ws://localhost:4000/socket" params)
    (.onOpen @socket #(dispatch [:socket/connection-opened]))
    (.onError @socket #(dispatch [:socket/connection-error]))
    (.connect @socket)))

(reg-fx
  :connect-to-game
  (fn [{:keys [password user-id]}]
    (let [payload (clj->js (merge (when password {"password" password})
                                  (when user-id {"user_id" user-id})))]
      (reset! game-channel (.channel @socket (str "game:" game-id) payload)))
    (-> @game-channel
        (.join)
        (.receive "ok" #(do (dispatch [:channel/join-success (-> % js->clj keywordize-keys)])
                            (register-game-handlers @game-channel)))
        (.receive "error" #(dispatch [:channel/join-error (.-error %)])))))

(reg-event-db
  :socket/connection-error
  [standard-interceptors]
  (fn-traced [db _]
    (assoc-in db [:connection-error?] true)))

(reg-event-db
  :socket/connection-opened
  [standard-interceptors]
  (fn-traced [db _]
    (-> db
        (assoc :connected-to-socket-ever? true)
        (assoc :connection-error? false))))

(defn join-lobby [db {:keys [min_players_reached countdown roles]}]
  (let [roles (map (fn [{:keys [name repr available?]}]
                     {:name name
                      :repr {:type (keyword (:type repr)) :value (:value repr)}
                      :available? available?}) roles)]
    (-> db
        (assoc :stage :lobby)
        (assoc-in [:lobby :min-players-reached?] min_players_reached)
        (assoc-in [:lobby :countdown] countdown)
        (assoc-in [:lobby :roles] (index-by :name roles)))))

(defn translate-variable [{:keys [name type value values]}]
  "Transforms a variable received from the server into clj-keyed."
  {:name name :type (keyword type) :value value :values values})

(defn translate-role [{name :name {type :type value :value} :repr}]
  "Transforms a role received from the server into clj-keyed."
  {:name name :repr {:type (keyword type) :value value}})

(defn create-board-images-map [{:keys [images] :as _metadata}]
  "Takes the `images` from `metadata` and turns them into a map keyed by the `tile`."
  (reduce (fn [images {:keys [tile value]}] (assoc images tile value)) {} images))

(defn construct-game-state [{:keys [board tiles events roles metadata current_turn role_positions active_role variables]} {current-events :events}]
  {:current-turn current_turn
   :events (into [] (concat current-events events))
   :active-role active_role
   :board-images (create-board-images-map metadata)
   :variables (mapv translate-variable variables)
   :role-positions (map-keys (partial name) role_positions)
   :roles {:by-name (->> roles (mapv translate-role) (index-by :name))
           :ordered (mapv #(:name %) roles)}
   :board {:dimensions (:dimensions board)
           :tiles tiles}})

(defn begin-game [db game-state]
  (-> db
      (assoc :stage :in-progress)
      (assoc :game (merge (:game db) (construct-game-state game-state (:game db))))))

(defn join-in-progress-game [db {:keys [events game_state tiles]}]
  "Associates the data received when first joining a game into the database."
  (let [game-state (merge game_state {:tiles tiles :events events})]
    (begin-game db game-state)))

(reg-event-fx
  :channel/join-success
  [standard-interceptors (inject-cofx :board-size)]
  (fn-traced [{db :db} [_ {:keys [stage game_metadata user_id game_state player_role] :as payload}]]
    (merge {:db (let [db (-> db
                             (assoc :game game_metadata)
                             (assoc-in [:game :player-role] player_role))]
                  (case stage
                    "lobby" (join-lobby db payload)
                    "in_progress" (join-in-progress-game db game_state)))}
           (when user_id {:set-user-id user_id}))))

(reg-event-db
  :channel/join-error
  [standard-interceptors]
  (fn-traced [db [_ error]]
    (case error
      "incorrect_password" (assoc db :password-error? true)
      (assoc db :stage (case error
                         "invalid_game_id" :game-not-found
                         "password_required" :password-required
                         "already_started" :game-already-started
                         :not-available)))))

(reg-sub
  :socket/connection-error?
  (fn [db _]
    (db :connection-error?)))

; This should be true when the page is loaded successfully but the
; game server itself is down for whatever reason.
(reg-sub
  :socket/not-available?
  (fn [db _]
    (and (db :connection-error?) (not (db :connected-to-socket-ever?)))))

;; -- Passwords ------------------------------------------------

(reg-event-fx
  :game/check-password
  [standard-interceptors]
  (fn-traced [_cofx [_ password]]
    {:connect-to-game {:password password}}))

(reg-sub
  :password-error?
  (fn [db _]
    (db :password-error?)))

;; -- Role selection -------------------------------------------

(reg-event-db
  :lobby/select-role
  [standard-interceptors (path [:lobby :selected-role])]
  (fn-traced [_ [_ role]]
    role))

(reg-event-fx
  :lobby/confirm-role-attempt
  [standard-interceptors]
  (fn-traced [{:keys [db]} _]
    (let [role (get-in db [:lobby :selected-role])]
      {:websocket {:handler "lobby:select_role"
                   :params {:role role}
                   :response {"ok" #(dispatch [:lobby/confirm-role-success role])
                              "already_taken" #(dispatch [:lobby/confirm-role-failure role])}}})))

(reg-event-db
  :lobby/confirm-role-success
  [standard-interceptors]
  (fn-traced [db [_ role]]
    (-> db
        (assoc-in [:lobby :role-confirmed?] true)
        (assoc-in [:game :player-role] role))))

(reg-event-db
  :lobby/confirm-role-failure
  [standard-interceptors]
  (fn-traced[db [_ role]]
    (-> db
        (assoc-in [:errors :lobby/confirm-role] true)
        (assoc-in [:lobby :roles role :available?] true))))

(reg-event-db
  :lobby/role-taken
  [standard-interceptors (path :lobby)]
  (fn-traced [{:keys [selected-role] :as lobby} [_ taken-role]]
    (-> lobby
        (assoc-in [:roles taken-role :available?] false)
        (assoc-in [:selected-role] (if-not
                                     (= selected-role taken-role)
                                     selected-role)))))

(reg-event-db
  :lobby/role-released
  [standard-interceptors (path :lobby)]
  (fn-traced [lobby [_ role]]
    (-> lobby
        (assoc-in [:roles role :available?] true)
        (assoc :min-players-reached? false))))

(reg-sub
  :lobby/selected-role
  (fn [db _]
    (get-in db [:lobby :selected-role])))

(reg-sub
  :lobby/selected-role-details
  (fn [db _]
    (let [selected-role (get-in db [:lobby :selected-role])]
      (get-in db [:lobby :roles selected-role]))))

(reg-sub
  :lobby/role-selected?
  :<- [:lobby/selected-role]
  (fn [selected-role [_ role]]
    (= role selected-role)))

(reg-sub
  :lobby/any-role-selected?
  :<- [:lobby/selected-role]
  (fn [selected-role _]
    (not (nil? selected-role))))

(reg-sub
  :lobby/role-confirmed?
  (fn [db _]
    (= true (get-in db [:lobby :role-confirmed?]))))

(reg-sub
  :lobby/roles
  (fn [db _]
    (-> db
        (get-in [:lobby :roles])
        (vals))))

(reg-sub
  :lobby/confirm-role-error?
  (fn [db _]
    (= true (get-in db [:error :lobby/confirm-role]))))

;; -- Countdown ------------------------------------------------

(reg-event-db
  :lobby/min-players-reached
  [standard-interceptors (path :lobby)]
  (fn-traced [db _]
    (-> db
        (assoc :min-players-reached? true)
        (assoc :countdown-cancelled? false))))

(reg-event-db
  :lobby/update-countdown
  [standard-interceptors (path [:lobby :countdown])]
  (fn-traced [_ [_ new-countdown]]
    new-countdown))

(reg-event-db
  :lobby/cancel-countdown
  [standard-interceptors (path [:lobby])]
  (fn-traced [lobby _]
    (-> lobby
        (assoc :countdown-cancelled? true)
        (assoc :countdown nil))))

(reg-sub
  :lobby/countdown
  (fn [db _]
    (get-in db [:lobby :countdown])))

(reg-sub
  :lobby/status
  (fn [{:keys [lobby]} _]
    (cond
      (:countdown-cancelled? lobby) :player-left
      (:min-players-reached? lobby) :counting-down
      :else :waiting-for-others)))

;; -- Game -----------------------------------------------------

(reg-sub
  :game
  (fn [db _]
    (db :game)))

(reg-sub
  :game/title
  (fn [db _]
    (get-in db [:game :title])))

(reg-event-db
  :lobby/begin-game
  [standard-interceptors]
  (fn-traced [db [_ game-state]]
    (begin-game db game-state)))

(reg-sub
  :game/current-turn
  (fn [db]
    (get-in db [:game :current-turn])))

(reg-sub
  :game/max-turns
  (fn [db]
    (get-in db [:game :max_turns])))

(reg-sub
  :board
  (fn [db _]
    (get-in db [:game :board])))

(reg-sub
  :tiles
  :<- [:board]
  (fn [{:keys [tiles]}]
    tiles))

(reg-sub
  :dimensions
  :<- [:board]
  (fn [{:keys [dimensions]}]
    dimensions))

(reg-sub
  :tile-pieces
  (fn [db [_ {:keys [x y]}]]
    ()))

(reg-event-db
  :game/toggle-board-skew
  [standard-interceptors (path [:board-settings :skewed?])]
  (fn-traced [skewed? _]
    (not skewed?)))

(reg-event-fx
  :game/resize-board
  [standard-interceptors]
  (fn-traced [{:keys [db]} [_ new-size]]
    {:db (assoc-in db [:board-settings :size] new-size)
     :set-board-size new-size}))

(reg-sub
  :game/board-skewed?
  (fn [db _]
    (get-in db [:board-settings :skewed?])))

(reg-event-db
  :game/toggle-board-shadow
  [standard-interceptors (path [:board-settings :shadowed?])]
  (fn-traced [shadowed? _]
    (not shadowed?)))

(reg-sub
  :game/board-shadowed?
  (fn [db _]
    (get-in db [:board-settings :shadowed?])))

(reg-event-db
  :game/toggle-board-clear
  [standard-interceptors (path [:board-settings :clear?])]
  (fn-traced [clear? _]
    (not clear?)))

(reg-sub
  :game/board-clear?
  (fn [db _]
    (get-in db [:board-settings :clear?])))

(reg-event-db
  :game/toggle-show-images
  [standard-interceptors (path [:board-settings :show-images?])]
  (fn [show-images? _]
    (not show-images?)))

(reg-sub
  :game/show-images?
  (fn [db]
    (get-in db [:board-settings :show-images?])))

(reg-sub
  :game/tile-size
  (fn [db _]
    (get-in db [:board-settings :size])))

(reg-sub
  :game/piece-size
  :<- [:game/tile-size]
  (fn [board-size _]
    (/ board-size 3)))

(reg-sub
  :game/variables
  (fn [db _]
    (get-in db [:game :variables])))

(reg-sub
  :game/complete-variables
  :<- [:game/variables]
  :<- [:game/turn-timer]
  (fn [[variables turn-timer] _]
    (if-not turn-timer
      variables
      (conj variables {:type :timer :value turn-timer}))))

; -- Events ----------------------------------------------------

(reg-sub
  :game/events
  (fn [db _]
    (get-in db [:game :events])))

(reg-fx
  :scroll-to-bottom-of-event-log
  (fn [_]
    (when-let [event-log (js/document.getElementById "eventLogContainer")]
      (set! (.-scrollTop event-log) (+ (.-scrollHeight event-log) (.-clientHeight event-log))))))

; Returns the events grouped by turn number.
(reg-sub
  :game/grouped-events
  :<- [:game/events]
  (fn [events _]
    (sort (group-by #(get % :turn) events))))

(reg-event-fx
  :game/new-event
  [standard-interceptors]
  (fn-traced [{:keys [db]} [_ event]]
    (let [events (get-in db [:game :events])]
      {:db (assoc-in db [:game :events] (conj events event))
       :scroll-to-bottom-of-event-log nil})))

;; -- Roles ----------------------------------------------------

; A map of roles, keyed by name with the value being some useful
; information about the visual representation.
(reg-sub
  :game/roles
  (fn [db _]
    (get-in db [:game :roles :by-name])))

; The role that is currently moving.
(reg-sub
  :game/active-role
  (fn [db _]
    (let [role-name (get-in db [:game :active-role])]
      (get-in db [:game :roles :by-name role-name]))))

; The role of the local client player.
(reg-sub
  :game/player-role
  (fn [db]
    (get-in db [:game :player-role])))

; Whether the local client player can move.
(reg-sub
  :game/your-move?
  :<- [:game/player-role]
  :<- [:game/active-role]
  (fn [[player-role active-role] _]
    (= player-role (:name active-role))))

(reg-sub
  :game/role-names
  (fn [db _]
    (get-in db [:game :roles :ordered])))

(reg-sub
  :game/role-count
  :<- [:game/role-names]
  (fn [role-names _]
    (count role-names)))

(reg-sub
  :game/active-role-index
  :<- [:game/role-names]
  :<- [:game/active-role]
  (fn [[role-names {:keys [name]}] _]
    (.indexOf role-names name)))

(reg-sub
  :game/role-positions
  (fn [db _]
    (get-in db [:game :role-positions])))

(reg-sub
  :role/current-position
  :<- [:game/role-positions]
  (fn [role-positions [_ role]]
    (get role-positions role)))

(defn find-positions [role-positions search-tile roles]
  "Given a map of role positions, a tile to search for, and a map
  of role information, returns the information pertaining to all
  roles on the given tile."
  (->> role-positions
       (filter (fn [[_role tile]] (= tile search-tile)))
       (map #(-> % first roles))))

(reg-sub
  :board/roles-on-tile
  :<- [:game/role-positions]
  :<- [:game/roles]
  (fn [[role-positions roles] [_ search-tile]]
    (find-positions role-positions search-tile roles)))

(reg-sub
  :board/alone-on-tile?
  (fn [[_ tile] _]
    (subscribe [:board/roles-on-tile tile]))
  (fn [roles-on-tile _]
    (= (count roles-on-tile) 1)))

(reg-sub
  :board/role-index
  (fn [[_ tile _role] _]
    (subscribe [:board/roles-on-tile tile]))
  (fn [roles-on-tile [_ _tile role]]
    (-indexOf (map :name roles-on-tile) role)))

(reg-event-db
  :board/update-role-position
  [standard-interceptors (path [:game :role-positions])]
  (fn-traced [role-positions [_ role]]
    (update role-positions role (fn [{:keys [x y]}] {:x (+ x 1) :y y}))))


;; -- Player count ---------------------------------------------

(reg-event-db
  :game/update-online-players
  [standard-interceptors (path [:game :online-players])]
  (fn-traced [_ [_ online-players]]
    online-players))

(reg-sub
  :game/online-players
  (fn [db _]
    (get-in db [:game :online-players])))

(reg-sub
  :game/online-count
  :<- [:game/online-players]
  (fn [online-players _]
    (count online-players)))

(defn join-event [role turn]
  {:type :join :turn turn :player role :text "has joined the game"})

(defn leave-event [role turn]
  {:type :join :turn turn :player role :text "has left the game"})

(reg-event-fx
  :game/player-joined
  [standard-interceptors]
  (fn-traced [cofx [_ role]]
    {:dispatch [:game/new-event (join-event role (or (get-in cofx [:db :game :current-turn]) 0))]}))

(reg-event-fx
  :game/player-left
  [standard-interceptors]
  (fn-traced [cofx [_ role]]
    {:dispatch [:game/new-event (leave-event role (or (get-in cofx [:db :game :current-turn]) 0))]}))

;; -- Cards ----------------------------------------------------

(reg-event-db
  :game/show-player-card
  [standard-interceptors (path [:game])]
  (fn-traced [db [_ card]]
    (-> db
        (assoc :show-card? true)
        (assoc :player-card card))))

(reg-event-fx
  :game/choose-card-action
  [standard-interceptors]
  (fn-traced [{:keys [db]} [_ action-id]]
    {:websocket {:handler "game:pick_card_action"
                 :params {"action_id" action-id}
                 :response {}}}))
     ;:db (assoc-in db [:game :show-card?] false)}))

(reg-event-db
  :game/hide-player-card
  [standard-interceptors (path [:game :show-card?])]
  (fn [_ _] false))

(reg-sub
  :game/show-card?
  (fn [db _]
    (get-in db [:game :show-card?])))

(reg-sub
  :game/can-choose-card-actions?
  :<- [:game/show-card?]
  :<- [:game/your-move?]
  (fn [[show-card? your-move?] _]
    (and show-card? your-move?)))

(reg-sub
  :game/player-card
  (fn [db _]
    (get-in db [:game :player-card])))


;; -- Source code errors ---------------------------------------

(reg-event-db
  :game/set-interpret-error
  [standard-interceptors (path [:game :interpret-error])]
  (fn [_ [_ error]]
    error))

(reg-sub
  :game/interpret-error
  (fn [db _]
    (get-in db [:game :interpret-error])))

(reg-sub
  :game/card-showing?
  :<- [:game/player-card]
  :<- [:game/interpret-error]
  :<- [:game/winner]
  (fn [[player-card interpret-error winner] _]
    (or player-card interpret-error winner)))

;; -- Turn countdown timer -------------------------------------

(reg-event-db
  :game/update-countdown
  [(path [:game :turn-countdown-remaining])]
  (fn-traced [_ [_ remaining]]
    remaining))

(reg-sub
  :game/turn-timer
  (fn [db _]
    (get-in db [:game :turn-countdown-remaining])))

;; -- Rolling dice ---------------------------------------------

(reg-event-fx
  :game/roll-dice
  [standard-interceptors]
  (fn [{:keys [db]} _]
    {:websocket {:handler "game:roll_dice"
                 :params {}
                 :response {}}
     :db (assoc-in db [:game :rolling-dice?] true)}))

(reg-sub
  :game/rolling-dice?
  (fn [db _]
    (get-in db [:game :rolling-dice?])))

(reg-sub
  :game/can-role-dice?
  :<- [:game/rolling-dice?]
  :<- [:game/your-move?]
  :<- [:game/timeup?]
  (fn [[rolling? your-move? timeup?] _]
    (and your-move? (not timeup?) (not rolling?))))

(reg-event-db
  :game/finish-moving
  [standard-interceptors (path [:game :rolling-dice?])]
  (fn [_ _] false))

;; -- Game state changes ---------------------------------------

(reg-fx
  :dispatch-timeout
  (fn [{:keys [events ms-apart on-complete]}]
    (when on-complete
      (js/setTimeout on-complete (* ms-apart (count events))))
    (doseq [[i event] (map-indexed vector events)]
      (js/setTimeout event (* ms-apart i)))))

(reg-event-fx
  :game/receive-roll-results
  [standard-interceptors]
  (fn-traced [db [_ {:keys [next_tile role path]}]]
    {:dispatch-timeout {:events (drop 1 (map (fn [tile] #(dispatch [:game/move-board-piece role tile])) path))
                        :ms-apart 300
                        :on-complete #(dispatch [:game/finish-rolling])}}))

(reg-event-db
  :game/move-board-piece
  [standard-interceptors (path [:game :role-positions])]
  (fn [role-positions [_ role new-tile]]
    (assoc-in role-positions [role] new-tile)))

(defn keywordize-type [{:keys [type] :as m}]
  (merge m {:type (keyword type)}))

(reg-event-db
  :game/new-state
  [standard-interceptors (path :game)]
  (fn-traced [old-game [_ new-game]]
    (merge old-game {:current-turn (:current_turn new-game)
                     :active-role (:active_role new-game)
                     :variables (map keywordize-type (:variables new-game))})))

(reg-event-db
  :game/timeup
  [standard-interceptors (path [:game :timeup?])]
  (fn [_ _] true))

(reg-sub
  :game/timeup?
  (fn [db]
    (get-in db [:game :timeup?])))

(reg-event-fx
  :game/leave
  (fn [_cofx _]
    {:reload-page nil}))

;; -- Event message --------------------------------------------

(reg-event-db
  :game/set-event-message
  [standard-interceptors (path [:game :event-message])]
  (fn [_ [_ message]]
    message))

(reg-sub
  :game/event-message
  (fn [db _]
    (get-in db [:game :event-message])))

;; -- Winning

(reg-event-db
  :game/win
  [standard-interceptors (path [:game :winner])]
  (fn [_ [_ winner]]
    winner))

(reg-sub
  :game/winner
  (fn [db _]
    (get-in db [:game :winner])))

(reg-sub
  :game/local-player-won?
  :<- [:game/winner]
  :<- [:game/player-role]
  (fn [[winner local-role] _]
    (= winner local-role)))

;; -- Board images ---------------------------------------------

(reg-sub
  :game/board-images
  (fn [db _]
    (get-in db [:game :board-images])))

(reg-sub
  :game/tile-image
  :<- [:game/board-images]
  (fn [images [_ tile]]
    (get images tile)))