import LiveSocket from "../node_modules/phoenix_live_view/priv/static/phoenix_live_view.js";

let liveSocket = new LiveSocket("/live");
liveSocket.connect();