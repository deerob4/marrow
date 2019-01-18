import * as React from "react";
import * as classnames from "classnames";

interface Props {
  name: string;
  label?: string;
  errors?: string[];
}

/**
 * `FormGroup` is a component that represents a grouping
 * of items related to an individual field. This includes
 * the field's label, the field itself, and any errors
 * associated witht he field.
 */
const FormGroup: React.SFC<Props> = (props) => {
  const className = classnames({
    "form-group": true,
    "form-group--error": props.errors ? props.errors.length > 0 : false,
  });


  return (
    <div className={className}>
      {props.label ? <label htmlFor={props.name}>{props.label}</label> : null}

      {props.children}

      {props.errors ? (
        <div className="text-danger">{props.errors[0]}</div>
      ) : null}
    </div>
  );
};

export default FormGroup;
