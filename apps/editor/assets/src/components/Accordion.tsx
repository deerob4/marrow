import React from "react";
import classnames from "classnames";
import Icon from "./Icon";

interface Props {
  title: string;
  isShown: boolean;
  toggle: () => void;
}

const Accordion: React.FC<Props> = ({ title, isShown, toggle, children }) => {
  const className = classnames("accordion", { "accordion--open": isShown });

  function toggleAccordion() {
    toggle();
  }

  return (
    <div className={className}>
      <h6
        style={{
          cursor: "pointer",
          display: "inline-block",
          fontWeight: "bold"
        }}
        onClick={toggleAccordion}>
        <span className="mr-2">{title}</span>
        {isShown ? <Icon name="caret-up" /> : <Icon name="caret-down" />}
      </h6>
      {isShown ? children : null}
    </div>
  );
};

export default Accordion;
