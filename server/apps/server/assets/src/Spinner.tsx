import * as React from "react";
import classnames from "classnames";

interface Props {
  isSpinning: boolean;
}

const Spinner: React.SFC<Props> = ({ isSpinning }) => {
  return (
    <i className={classnames("fa", "fa-spinner", { "fa-spin": isSpinning })} />
  );
};

export default Spinner;
