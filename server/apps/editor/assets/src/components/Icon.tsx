import * as React from "react";
import classnames from "classnames";

interface Props {
  name: string;
  isSpinning?: boolean;
}

const Icon: React.SFC<Props> = ({ name, isSpinning = false }) => {
  return (
    <i className={classnames("fas", `fa-${name}`, { "fa-spin": isSpinning })} />
  );
};

export default Icon;
