import React from "react";

import { Controlled as CodeMirror } from "react-codemirror2";
// @ts-ignore
import * as parinferCodeMirror from "parinfer-codemirror";

import "codemirror/mode/clojure/clojure.js";
import "codemirror/addon/edit/matchbrackets";
import "codemirror/addon/edit/closebrackets";

interface Props {
  onChange: (value: string) => void;
  value: string;
}

const CodeEditor: React.SFC<Props> = ({ onChange, value }) => {
  return (
    <CodeMirror
      value={value}
      options={{
        tabSize: 2,
        lineNumbers: true,
        matchBrackets: true,
        smartIndent: false,
        mode: "clojure",
      }}
      editorDidMount={(e) => parinferCodeMirror.init(e)}
      onBeforeChange={(e, s, v) => onChange(v)}
    />
  );
};

export default CodeEditor;
