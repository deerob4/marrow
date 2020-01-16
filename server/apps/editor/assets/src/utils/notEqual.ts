import { curry, compose, not, equals } from "ramda";

const notEquals = curry(
  compose(
    not,
    equals
  )
);

export default notEquals;
