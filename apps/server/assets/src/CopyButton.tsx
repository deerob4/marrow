import React from "react";
import { useState } from "react";
import classnames from "classnames";

interface Props {
  text: string;
}

export const CopyButton: React.SFC<Props> = ({ text }) => {
  const [urlCopied, setUrlCopied] = useState(false);

  function copyUrl() {
    setUrlCopied(true);
  }

  return (
    <button className="btn btn-info btn-sm no-focus-shadow" onClick={copyUrl}>
      {urlCopied ? "Copied" : "Copy"}
      <i
        className={classnames("ml-2", "fas", {
          "fa-check": urlCopied,
          "fa-copy": !urlCopied,
        })}
      />
    </button>
  );
};
