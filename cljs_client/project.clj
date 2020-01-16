(defproject marrow-client "0.1.0-SNAPSHOT"
  :description "FIXME: write this!"
  :url "http://example.com/FIXME"
  :license {:name "Eclipse Public License"
            :url "http://www.eclipse.org/legal/epl-v10.html"}

  :min-lein-version "2.7.1"

  :dependencies [[org.clojure/clojure "1.10.0"]
                 [org.clojure/clojurescript "1.10.516"]
                 [org.clojure/core.match "0.3.0-alpha5"]
                 [reagent "0.8.1"]
                 [re-frame "0.10.6"]
                 [meander/alpha "0.0.533"]
                 [cljsjs/react-pose "1.6.4-1"]
                 [cljsjs/phoenix "1.3.0-0"]
                 [org.roman01la/cljss "1.6.3"]]

  :source-paths ["src"]

  :aliases {"fig"       ["trampoline" "run" "-m" "figwheel.main"]
            "fig:build" ["trampoline" "run" "-m" "figwheel.main" "-b" "dev" "-r"]
            "fig:min"   ["run" "-m" "figwheel.main" "-O" "advanced" "-bo" "dev"]
            "fig:test"  ["run" "-m" "figwheel.main" "-co" "test.cljs.edn" "-m" marrow-client.test-runner]}

  :profiles {:dev {:dependencies [[com.bhauman/figwheel-main "0.2.0"]
                                  [day8.re-frame/re-frame-10x "0.3.7-react16"]
                                  [day8.re-frame/tracing "0.5.1"]]}})


