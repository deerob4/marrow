(ns marrow-client.app-server
  (:require
    [ring.util.response :refer [resource-response content-type not-found]]
    [clojure.string]))

(defn handler [req]
  "Renders index.html for every request. The client code takes everything
  after the domain as the game id, so this is the only page that ever needs
  to be rendered."
  (some-> (resource-response "index.html" {:root "public"})
          (content-type "text/html; charset=utf8")))