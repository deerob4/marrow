import * as React from "react";
import validate from "../utils/validators";

function useForm<T extends object>(constraints: object, empty: T) {
  type Data = T
  type Errors = { [key: string]: string[] };

  const [data, setData]: [Data, (data: Data) => void] = React.useState(empty);
  const [errors, setErrors]: [
    Errors,
    (errors: Errors) => void
  ] = React.useState({});

  function handleInput(e: React.FormEvent<HTMLInputElement>) {
    const target = e.currentTarget;
    const value = target.type === "checkbox" ? target.checked : target.value;

    // @ts-ignore
    setData({ ...data, [target.name]: value });
  }

  function handleSubmit(
    e: React.FormEvent<HTMLFormElement>,
    onSuccess: (data: Data) => void
  ) {
    setErrors({});
    e.preventDefault();

    validate
      .async(data, constraints)
      .then(() => {
        onSuccess(data);
      })
      .catch((e: any) => {
        setErrors(e);
      });
  }

  return { data, errors, handleInput, handleSubmit };
}

export { useForm };
