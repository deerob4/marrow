import { useState } from "react";
import * as validate from "validate.js";

function useForm<T extends object>(
  constraints: { [key in keyof T]?: object },
  defaultValues: T
) {
  type Errors = { [key in keyof T]: string[] };

  const [data, setData]: [T, (data: T) => void] = useState(defaultValues);

  const emptyErrors = Object.keys(defaultValues).reduce(
    (errors, field) => ({ ...errors, [field]: [] }),
    {}
  ) as Errors;

  const [errors, setErrors]: [Errors, (errors: Errors) => void] = useState(
    emptyErrors
  );

  function handleInput(e: React.FormEvent<HTMLInputElement>) {
    const target = e.currentTarget;
    const value = target.type === "checkbox" ? target.checked : target.value;
    setData({ ...data, [target.name]: value });
  }

  function handleSubmit(
    e: React.FormEvent<HTMLFormElement>,
    onSuccess: (data: T) => void
  ) {
    setErrors(emptyErrors);
    e.preventDefault();

    validate
      .async(data, constraints)
      .then(() => onSuccess(data))
      .catch((e: Errors) => setErrors(e));
  }

  return { data, errors, handleInput, handleSubmit };
}

export { useForm };
