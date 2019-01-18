import * as React from "react";
import Spinner from "./Spinner";

interface Props {
  text: string;
  isSpinning: boolean;
}

const SpinnerButton: React.SFC<Props> = ({ text, isSpinning }) => {
  return (
    <button disabled={isSpinning} className="btn btn-primary">
      {text}
      {isSpinning ? (
        <span className="ml-2">
          <Spinner isSpinning={true} />
        </span>
      ) : null}
    </button>
  );
};

export default SpinnerButton;
