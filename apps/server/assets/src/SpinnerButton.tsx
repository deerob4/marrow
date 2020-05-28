import React from "react";
import Spinner from "./Spinner";
import classnames from "classnames";

interface Props {
  text: string;
  isSpinning: boolean;
  className?: string;
  element?: React.ButtonHTMLAttributes<HTMLButtonElement>;
}

const SpinnerButton: React.FC<Props> = (props) => {
  const { text, isSpinning } = props;
  const className = classnames("btn", "btn-primary", props.className);

  return (
    <button {...props.element} className={className}>
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
