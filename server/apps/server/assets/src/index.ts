// import "../css/app.scss";


import { render } from "./Wow";

// import {main} from "./HostGame.bs";
render()
// main(document.getElementById("app"));

// const app = new Vue({
//   el: "#host-app",
//   data: {
//     selected: 26,
//     isHosted: false,
//     gameUrl: "http://play.marrow.dk/aw79kkp938Nodsp0",
//     fetching: false,
//     fetchError: false,
//     urlCopied: false,
//     config: defaultConfig
//   },
//   methods: {
//     selectGame() {
//       this.fetchError = false;
//       this.config = Object.assign({}, this.config, defaultConfig);
//     },
//     copyUrl() {
//       this.urlCopied = true;
//     },
//     hostGame() {
//       this.fetching = true;
//       this.fetchError = false;

//       const data = {
//         game_id: this.selected,
//         configuration: {
//           password: this.config.password,
//           is_public: this.config.isPublic,
//           allow_spectators: this.config.allowSpectators
//         }
//       };

//       axios
//         .post("/api/hosted-games", data)
//         .then(r => {
//           const url = r.data.data.id;
//           this.gameUrl = `http://play.marrow.dk/${url}`;
//           this.fetching = false;
//           this.isHosted = true;
//         })
//         .catch(e => {
//           this.fetching = false;
//           this.fetchError = true;
//         });
//     }
//   },
//   computed: {
//     requirePassword: {
//       get() {
//         return Maybe.isJust(this.config.password);
//       },
//       set(required) {
//         return required ? Maybe.just("") : Maybe.nothing();
//       }
//     },
//     validForm() {
//       return this.config.password.caseOf({
//         just: password => password.length >= 6,
//         nothing: () => true
//       });
//     }
//   }
// });

// main(document.getElementById("hostContainer"), 10)

{
  /* <div class="hero-container">
  <%= render "_game_container.html", games: @games %>
  <%= render "_game_container.html", games: @games %> 
</div> */
}


{/* <div id="host-app">
  <div class="hero-container">
    <div class="hero-modal">
      <div class="hero-modal__top">
        <h1 class="logo">Marrow</h1>
        <h2 class="hero-modal__title">Host Game</h2>

        <div v-if="!isHosted">
          <p class="mb-2">You can host a game to play online against others. Select one below and get playing!</p>

          <div class="form-group">
            <label for="game">Choose game:</label>
            <select name="game" id="game" class="form-control" @change="selectGame" v-model="selected" :disabled="fetching">
              <%= for game <- @games do %>
                <option value="<%= game.id %>"><%= game.title %></option>
              <% end %>
            </select>
          </div>
        </div>
      </div>

      <div class="hero-modal__inner">
        <template v-if="!isHosted">
          <%= for game <- @games do %>
            <div class="game-info" v-if="selected == <%= game.id %>">
              <h3 class="game__title"><%= game.title %></h3>
              <h4 class="game__author">By <%= game.user.name %></h4>
              <p><%= description(game) %></p>
            </div>
          <% end %>

          <form @submit.prevent="hostGame">
            <fieldset :disabled="fetching">
              <div class="form-group form-check mb-0">
                <input type="checkbox" class="form-check-input" id="isPublic" v-model="config.isPublic">
                <label for="isPublic" clsas="form-check-label">List publicly?</label>
              </div>
              <div class="form-group form-check mb-0">
                <input type="checkbox" class="form-check-input" id="allowSpectators" v-model="config.allowSpectators">
                <label for="allowSpectators" clsas="form-check-label">Allow spectators?</label>
              </div>
              <div class="form-group form-check mb-0">
                <input type="checkbox" class="form-check-input" :disabled="config.isPublic" id="requirePassword" v-model="requirePassword">
                <label for="requirePassword" class="form-check-label">Require password to join?</label>
              </div>
              <div class="form-group mt-2" v-if="requirePassword">
                <label for="password">Password (at least 6 characters)</label>
                <input type="password" id="password" class="form-control" v-model="config.password">
              </div>
              <p class="text-danger mt-2 mb-0" v-if="fetchError">An error occurred while trying to setup your game. Please try again later.</p>
              <button type="submit" :disabled="!validForm" :class="{'btn btn-primary': true, 'mt-0': requirePassword, 'mt-3': !requirePassword}">
                Host Game
                <div v-if="fetching" class="ml-2 mb-1 spinner-border spinner-border-sm"></div>
              </button>
            </fieldset>
          </form>
        </template>

        <template v-else>
          <h4 class="host-success">Success!</h4>
          <h4 class="host-success-message">Your game can be found at:</h4>
          <div class="input-group mt-2 mb-3">
            <input
              type="text"
              readonly="true"
              class="form-control hosted-url-container no-focus-shadow"
              :value="gameUrl">
            <div class="input-group-append">
              <button class="btn btn-info btn-sm no-focus-shadow" @click="copyUrl">
                {{ urlCopied ? "Copied" : "Copy" }}
                <i :class="{ 'ml-2 fas': true, 'fa-check': urlCopied, 'fa-copy': !urlCopied }"></i>
              </button>
            </div>
          </div>
          <p class="mb-0">
            Share the link with other people to allow them to play.
            The game will be held on the server for one week, after which
            the link will expire.
          </p>
        </template>
      </div>
    </div>
  </div>
</div> */}

