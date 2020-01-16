(ns marrow-client.views
  (:require
    [reagent.core :as r]
    [re-frame.core :refer [dispatch subscribe]]
    [cljss.reagent :refer-macros [defstyled]]
    [marrow-client.db]
    [marrow-client.utils :refer [with-index]]
    [posed]
    [pose-group]
    [react-select]
    [meander.match.alpha :refer [match]]
    [clojure.string :as str]))

; TODO: make the whole game interface customisable with theme packs so that it can match the style of the game.

(defn url [address]
  "Wraps the given address in `url(...) so that it can be used as
  an image in inline styles."
  (str "url(" address ")"))

;; -- Lobby ----------------------------------------------------

(defstyled logo :h1
  {:font-family "reross-quadratic, sans-serif"
   :margin-bottom 0})

(defstyled subtitle :h2
  {:font-size "1.5rem"
   :font-weight 900
   :margin-bottom "15px"})

(def Pretty
  (js/posed.div (clj->js {:enter {:y 0
                                  :delay 220
                                  :opacity 1}
                          :exit {:y 100 :opacity 0}})))

(defn pre-game-view [children]
  [:div.modal-container
   [:> js/PoseGroup {:animateOnMount true}
    [:> Pretty {:key "modal-inner" :class "modal-inner"}
     [logo "Marrow"]
     children]]])

(def AnimatedRole
  (js/posed.div (clj->js {:normal {:x 0 :y 0, :scale 1}
                          :zoomy {:x 425 :y -75, :scale 1.1}})))

(defn role-background-style [{:keys [type value]}]
  "Given a role repr map, returns the background style necessary
  for displaying it."
  (case type
    :colour {:background-color value}
    :image {:background-image (url value)
            :background-size "cover"}))

(defn role-view [{:keys [name available? repr]}]
  (let [selected? @(subscribe [:lobby/role-selected? name])]
    [:> AnimatedRole
     [:div.role-container
      [:div {:class ["lobby-role"
                     (when (and available? (not selected?)) "lobby-role--available")
                     (when selected? "lobby-role--selected")
                     (when-not available? "lobby-role--disabled")]
             :style (role-background-style repr)
             :on-click #(when (and available? (not selected?))
                          (dispatch [:lobby/select-role name]))}]
      [:span name]]]))

(defn role-selector []
  [:div.role-selector
   [:p.mb-0 "Please select the board piece you wish to play as from the available options below."]
   (when (= @(subscribe [:lobby/status]) :counting-down)
     [:p.mb-0.mt-3.text-danger (str "Hurry! The game will begin in " @(subscribe [:lobby/countdown]) " seconds!")])
   [:div.role-group
    (for [role @(subscribe [:lobby/roles])]
      ^{:key (:name role)} [role-view role])]

   (if @(subscribe [:lobby/confirm-role-error?])
     [:p.text-danger.mt-2 "Oops, looks like someone got to that piece before you!"])
   [:button.btn.btn-primary {:disabled (not @(subscribe [:lobby/any-role-selected?]))
                             :on-click #(dispatch [:lobby/confirm-role-attempt])}
    "Confirm Selection"]])

(defn countdown []
  (let [current-value @(subscribe [:lobby/countdown])]
    [:div.countdown
     [:span.countdown-text "There are enough players to start, so the game will begin in "]
     [:p.countdown-value.mb-0.mt-3 (str current-value " seconds!")]]))

(defn lobby-status []
  "Shown once the current player has selected their role and
  they are waiting for the game to begin."
  (case @(subscribe [:lobby/status])
    :counting-down [countdown]
    :waiting-for-others [:<> [:p.mb-0 "Great. Now hold tight whilst other players choose their pieces."]]
    :player-left [:<> [:p.mb-0 "A player left the lobby. The countdown will start again when somebody else has joined."]]))

(defn lobby []
  [:<>
   [subtitle "Game Lobby"]
   [:h4 (str "Welcome to " @(subscribe [:game/title]) "!")]
   (if @(subscribe [:lobby/role-confirmed?])
     [lobby-status]
     [role-selector])])

(defn password-screen []
  (let [password (r/atom "")]
    (fn []
      [:div.lobby-fence
       [subtitle "Password Required"]
       [:p "The owner of this game has required a password to be able to join. Enter it below or begone!"]
       [:form {:on-submit (fn [e]
                            (.preventDefault e)
                            (dispatch [:game/check-password @password]))}
        [:div.form-group
         [:input.form-control {:type "password"
                               :id "password"
                               :value @password
                               :on-change #(reset! password (-> % .-target .-value))}]
         (when @(subscribe [:password-error?])
           [:p.text-danger.mt-2 "Incorrect password."])]
        [:button.btn.btn-primary {:type "submit"
                                  :disabled (zero? (count @password))}
         "Join Game"]]])))

(defn game-not-found []
  [:<>
   [subtitle "Game not found"]
   [:p.mb-0 "No game exists at this address. Check with the person who gave you the link to see if it is correct."]])

(defn game-already-started []
  [:<>
   [subtitle "Game in progress"]
   [:p.mb-0 "This game has already begun and the owner hasn't allowed spectators to watch. Why not "
    [:a {:href "http://google.com/"} "create your own game"] " instead?"]])

(defn server-not-available []
  [:<>
   [subtitle "The server is down!"]
   [:p.mb-0 "Something is up with the main Marrow game server, so your game can't be accessed right now. Please try again a bit later."]])

(defn icon [name]
  [:i {:class (str "fas fa-" name)}])

;; -- Turn order bar -------------------------------------------

(defn turn-order []
  (let [grid-ref (r/atom nil)]
    (r/create-class
      {:component-did-mount
       #(js/wrapGrid @grid-ref (clj->js {:duration 250}))

       :reagent-render
       (fn []
         (let [roles @(subscribe [:game/roles])
               active-role @(subscribe [:game/active-role])
               active-role-index @(subscribe [:game/active-role-index])
               role-count @(subscribe [:game/role-count])
               player-role @(subscribe [:game/player-role])]
           [:div.turn-order
            {:ref #(reset! grid-ref %)
             :style {:grid-template-columns (str "repeat(" role-count ", 1fr)")}}
            [:div.turn-caret {:style {:grid-column (+ active-role-index 1)
                                      :color (case (get-in active-role [:repr :type])
                                               :image "#000000"
                                               :colour (get-in active-role [:repr :value]))}} [icon "caret-down"]]
            (doall
              (for [[_name {:keys [name repr]}] roles]
                ^{:key name} [:div.turn-order__player.noselect
                              {:style (role-background-style repr)
                               :class (when (= name (:name active-role)) "turn-order__player--current")}
                              (str name (when (= name player-role)
                                          " (you)"))]))]))})))

;; -- Event cards ----------------------------------------------

(defn player-choice-card []
  (let [{:keys [title body actions]} @(subscribe [:game/player-card])
        two-cards? (= (count actions) 2)]
    [:div.card-modal-bg
     [:div.card-modal-body
      [:h1.card-modal-type "— Player Choice —"]
      [:h2.card-modal-title title]
      [:p.card-modal-desc body]
      [:div {:style {:display (if two-cards? "grid" "block")
                     :grid-template-columns (str "repeat(" (count actions) ", 1fr)")
                     :grid-gap "10px"}}
       (for [{:keys [id title]} actions]
         ^{:key id} [:button.btn.btn-outline-primary
                     {:class ["btn"
                              (when-not two-cards? "btn-block")]
                      :on-click #(dispatch [:game/choose-card-action id])} title])]]]))

(defn leave-game-button []
  [:button.btn.btn-outline-primary.btn-block {:on-click #(dispatch [:game/leave])} "Leave Game"])

(defn error-card []
  (let [error @(subscribe [:game/interpret-error])]
    [:div.card-modal-bg
     [:div.card-modal-body.card-modal-body--error
      [:h1.card-modal-type "— Game Error —"]
      [:h1.card-modal-title "Failed to Interpret"]
      [:p.card-modal-error-text error]
      [:p.card-modal-desc "The above error occurred whilst interpreting the game code for this round. The game cannot continue."]
      [leave-game-button]]]))

(defn timeup-card []
  [:div.card-modal-bg
   [:div.card-modal-body
    [:h1.card-modal-type "— Game Over —"]
    [:h2.card-modal-title "Max Number of Turns Reached"]
    [:p.card-modal-desc "The maximum number of turns in the game has been reached without a winner, so the game is now over!"]
    [leave-game-button]]])

(defn winner-card []
  (let [local-player-won? @(subscribe [:game/local-player-won?])
        winner @(subscribe [:game/winner])]
    [:div.card-modal-bg
     [:div.card-modal-body
      [:h1.card-modal-type "— Game Over —"]
      [:h2.card-modal-title (if local-player-won?
                              "Congratulations, you won the game!"
                              (str (clojure.string/capitalize winner) " won the game!"))]
      [:p.card-modal-desc (if local-player-won?
                            "Well done for winning. The game is now over, so please leave."
                            "Bad luck, you didn't win. Better luck next time! Please leave now.")]
      [leave-game-button]]]))

;; -- Side panel -----------------------------------------------

(defn event-view [{:keys [text player]}]
  (let [roles @(subscribe [:game/roles])]
    [:li.event
     [:span.event__player-name
      {:style (case (get-in roles [player :repr :type])
                :colour {:background-color (get-in roles [player :repr :value])}
                :image {:background-image (url (get-in roles [player :repr :value]))}
                {:background-color "#000000"})} (if player player "var")]
     [:> js/ReactMarkdown {:source text :className "event__text"}]]))

(defn event-turn-group [turn events]
  [:div.event-turn-group
   [:span.event-turn-group__turn (str "Turn " turn)]
   [:ul.event-turn-group__events
    (for [[index event] (with-index events)]
      ^{:key index} [event-view event])]])

(defn event-log []
  (let [grouped-events @(subscribe [:game/grouped-events])]
    [:div.card.event-log
     [:div.card-header "Event Log"]
     [:div.card-body.p-0.event-log-container {:id "eventLogContainer"}
      (if-not (empty? grouped-events)
        (for [[turn events] grouped-events]
          ^{:key turn} [event-turn-group turn events])
        [:p "Important events and notices will be displayed here as the game progresses."])]]))

(defn size-slider []
  "Renders a slider that can be used to change the size of the game board."
  [:div.form-group.mb-2
   [:label {:for "boardSize"} "Board size"]
   [:input.custom-range {:type "range"
                         :id "boardSize"
                         :min "20"
                         :max "300"
                         :value @(subscribe [:game/tile-size])
                         :on-change #(dispatch [:game/resize-board (-> % .-target .-value (js/parseInt 10))])}]])

(defn settings-panel []
  [:div.card.settings-panel
   [:div.card-header "Game Settings"]
   [:div.card-body
    [size-slider]
    [:div.form-group.form-check.mb-2
     [:input {:type "checkbox"
              :id "skewCheck"
              :class "form-check-input"
              :checked @(subscribe [:game/board-skewed?])
              :on-change #(dispatch [:game/toggle-board-skew])}]
     [:label {:for "skewCheck" :class "form-check-label"} "Skew board?"]]
    [:div.form-group.form-check.mb-2
     [:input {:type "checkbox"
              :id "shadowCheck"
              :class "form-check-input"
              :checked @(subscribe [:game/board-shadowed?])
              :on-change #(dispatch [:game/toggle-board-shadow])}]
     [:label {:for "shadowCheck" :class "form-check-label"} "Shadow board?"]]
    [:div.form-group.form-check.mb-2
     [:input {:type "checkbox"
              :id "clearCheck"
              :class "form-check-input"
              :checked @(subscribe [:game/board-clear?])
              :on-change #(dispatch [:game/toggle-board-clear])}]
     [:label {:for "clearCheck" :class "form-check-label"} "Clear board?"]]
    [:div.form-group.form-check.mb-2
     [:input {:type "checkbox"
              :id "showImagesCheck"
              :class "form-check-input"
              :checked @(subscribe [:game/show-images?])
              :on-change #(dispatch [:game/toggle-show-images])}]
     [:label {:for "showImagesCheck" :class "form-check-label"} "Show tile images?"]]]])

;; -- Variables ------------------------------------------------

(def DraggableVariable
  (js/posed.div (clj->js {:draggable true
                          :dragBounds {:left "1%"}})))

(defn global-variable [{:keys [name value]}]
  [:div.global-variable
   [:span.variable__name (str name ": ")]
   [:span.variable__value value]])

(defn player-variable [{:keys [name values]}]
  [:div.player-variable
   [:span.variable__name (str name ":")]
   [:ul
    (for [{:keys [role value]} values]
      ^{:key role} [:li (str role ": " value)])]])

(defn turn-timer [{:keys [value]}]
  [:div.turn-timer
   [:span.turn-timer__countdown (str value " seconds left!")]])

(defn variable [var scale-factor]
  (let [card-showing? @(subscribe [:game/card-showing?])]
    [:div.variable-container.noselect
     {:class (when card-showing? "variable-container--background")
      :style {:transform (str "translateY(" scale-factor "px) translateX(10px)")}}
     [:> DraggableVariable {:class ["variable" (str "variable--" (name (:type var)))]}
      (case (:type var)
        :global [global-variable var]
        :player [player-variable var]
        :timer [turn-timer var])]]))

(defn variable-scale [{:keys [type values]}]
  (case type
    :global 83
    :player (* 10 (count values))
    :timer 83
    0))

(defn variables []
  (let [vars @(subscribe [:game/complete-variables])]
    (when-not (empty? vars)
      (->> vars
           (map-indexed vector)
           (reduce (fn [[prev acc] [index var]]
                     (let [scale (+ 10 (* (variable-scale prev) index))
                           var-view ^{:key index} [variable var scale]]
                       [var (conj acc var-view)]))
                   [nil [:<>]])
           (last)))))

;; -- Event Message --------------------------------------------

(defn event-message []
  (let [message @(subscribe [:game/event-message])]
    (when message [:h1.event-message.noselect message])))

;; -- Board ----------------------------------------------------

(defn board-piece [{:keys [name repr]}]
  (let [piece-size @(subscribe [:game/piece-size])
        {:keys [x y] :as tile} @(subscribe [:role/current-position name])
        index @(subscribe [:board/role-index tile name])
        background (case (:type repr)
                     :colour {:background-color (:value repr)}
                     :image {:background-image (url (:value repr))
                             :background-size "cover"})]
    [:div.board-piece {:data-index index
                       :style (merge {:width (str piece-size "px")
                                      :height (str piece-size "px")
                                      :grid-column (+ x 1)
                                      :grid-row (+ y 1)}
                                     (if @(subscribe [:board/alone-on-tile? tile])
                                       {:margin "auto"}
                                       {:margin-top (* piece-size index)
                                        :margin-left (* piece-size (quot index 4))})
                                     background)}]))

(defn board-tile [{:keys [x y] :as tile}]
  "Renders an individual tile on the board."
  (let [tile-image @(subscribe [:game/tile-image tile])
        show-images? @(subscribe [:game/show-images?])]
    [:div.board-tile
     {:class [(when @(subscribe [:game/board-shadowed?]) "board-tile--shadowed")
              (when @(subscribe [:game/board-clear?]) "board-tile--clear")]
      :style (merge {:grid-row (+ y 1)
                     :grid-column (+ x 1)} (if (and (not= tile-image nil) show-images?)
                                             {:background-image (url tile-image)
                                              :background-size "cover"}
                                             {}))}]))

(defn inner-board []
  (let [{:keys [dimensions tiles] :as board} @(subscribe [:board])
        tile-size @(subscribe [:game/tile-size])
        roles @(subscribe [:game/roles])]
    [:div.game-board
     {:class [(when @(subscribe [:game/board-skewed?]) "game-board--skewed")
              (when @(subscribe [:game/board-shadowed?]) "game-board--shadowed")]
      :style {:grid-template-columns (str "repeat(" (+ (:width dimensions) 0) ", " tile-size "px)")
              :grid-template-rows (str "repeat(" (+ (:height dimensions) 0) ", " tile-size "px)")}}
     (for [{:keys [x y] :as tile} tiles]
       ^{:key (str x y)} [board-tile tile])
     (for [[name role] roles]
       ^{:key name} [board-piece role])]))

(defn dice []
  [:button.dice.btn.btn-success {:style {:position "absolute"
                                         :bottom 10
                                         :left 10
                                         :padding "10px"}
                                 :disabled (not @(subscribe [:game/can-role-dice?]))
                                 :on-click #(dispatch [:game/roll-dice])} [:<> [:span.mr-2 "Roll Dice "] [icon "dice-five"]]])

(defn board []
  (let [show-card? @(subscribe [:game/can-choose-card-actions?])
        timeup? @(subscribe [:game/timeup?])
        winner? @(subscribe [:game/winner])
        interpret-error @(subscribe [:game/interpret-error])]
    [:div.game-board-container
     (when show-card? [player-choice-card])
     (when interpret-error [error-card])
     (when timeup? [timeup-card])
     (when winner? [winner-card])
     [event-message]
     [variables]
     [inner-board]
     [dice]]))

;; -- Top navigation bar ---------------------------------------

(defn player-count []
  (let [players @(subscribe [:game/online-count])]
    [:p.player-count.mb-0
     (str players (if (= players 1) " player" " players") " in game")]))

(defn game-topbar []
  (let [title @(subscribe [:game/title])
        time-left @(subscribe [:game/turn-timer])
        current-turn @(subscribe [:game/current-turn])
        max-turns @(subscribe [:game/max-turns])]
    [:div.game-topbar
     [:h1.game-logo "Marrow"]
     [:h2.game-title.noselect
      (str title " - Turn " current-turn (when max-turns (str " of " max-turns)))]
     [player-count]]))

;; -- Chatbox --------------------------------------------------

(defn roles->select-options [roles]
  "Converts a list of roles to the format needed by React-Select."
  (vec (map (fn [r] {:value r :label r}) roles)))

(defn chatbox []
  (let [text (r/atom "")
        send-to (r/atom [])
        roles ["Everyone" "Nick" "Keir" "Jay" "Jed"]]
    (fn []
      [:div.chatbox
       [:form {:on-submit (fn [e]
                            (.preventDefault e)
                            (println {:text @text
                                      :send-to (map #(get % "value") (js->clj @send-to))})
                            (reset! text ""))}
        [:input {:type "text"
                 :class "form-control"
                 :placeholder "Type in a message..."
                 :value @text
                 :on-change #(reset! text (-> % .-target .-value))}]

        [:> js/ReactSelect
         {:options (roles->select-options roles)
          :className "chatbox__role_select"
          :isMulti true
          :isClearable true
          :placeholder "Send to..."
          :menuPlacement "top"
          :value @send-to
          :onChange #(reset! send-to %)}]

        [:button {:type "submit"
                  :class "btn btn-primary"
                  :disabled (or (str/blank? @text)
                                (empty? (js->clj @send-to)))} "Send"]]])))

(defn game-view []
  "The main game view."
  [:div.game-view
   [game-topbar]
   [board]
   ;[card {:title "Flooding Down South"
   ;       :body "Let's all suckle on Hilda's cockle! We all know she fooky loves it!"
   ;       :options [{:id 1 :text "Suckle yes"}
   ;                 {:id 2 :text "Suckle nay"}]}]
   [turn-order]
   [event-log]
   [settings-panel]
   [chatbox]])
;[dice]])
