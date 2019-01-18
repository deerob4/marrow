import * as React from "react";
import classnames from "classnames";

interface BadgeProps {
  type: "primary" | "secondary";
  text: string;
  className?: string;
}

interface SeparatorProps {
  amount: 1 | 2 | 3 | 4 | 5;
}

export const BadgeSeparator: React.SFC<SeparatorProps> = props => {
  return (
    <div className={`d-inline-block ml-${props.amount}`}>{props.children}</div>
  );
};

export const Badge: React.SFC<BadgeProps> = ({ type, text, className }) => {
  return (
    <span className={classnames("badge", `badge-${type}`, className)}>
      {text}
    </span>
  );
};
