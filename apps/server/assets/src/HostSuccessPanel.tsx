import React from "react";
import { CopyButton } from "./CopyButton";

interface Props {
  gameUrl: string;
}

export const HostSuccessPanel: React.FC<Props> = ({ gameUrl }) => {
  const url = `http://play.marrow.dk/${gameUrl}`;

  return (
    <>
      <h4 className="host-success">Success!</h4>
      <h4 className="host-success-message mb-3">Your game can be found at:</h4>
      <div className="input-group mb-2">
        <input
          type="text"
          readOnly={true}
          className="form-control hosted-url-container no-focus-shadow"
          value={url}
        />
        <div className="input-group-append">
          <CopyButton text={url} />
        </div>
      </div>
      <p className="mt-3 mb-0">
        Share the link with other people to allow them to play. The game will be held
        on the server for one week, after which the link will expire.
      </p>
    </>
  );
};
