(require 'cljs.build.api)

(cljs.build.api/build "src/marrow_client"
  {:output-to "out/main.js"
   :optimizations :advanced})

(System/exit 0)