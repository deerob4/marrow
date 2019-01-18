import * as React from "react";
import { connect } from "react-redux";

import Input from "./Input";
import FormGroup from "./FormGroup";
import SpinnerButton from "./SpinnerButton";

import { useForm } from "../hooks/useForm";
import { useTitle } from "../hooks/useTitle";
import { SignupFields, AppState } from "../types";
import { signup } from "../thunks/auth";

interface Props {
  signup: typeof signup;
  signingUp: boolean;
  signupError: string;
}

const Signup: React.SFC<Props> = props => {
  useTitle("Create Account");

  const { data, errors, handleInput, handleSubmit } = useForm<SignupFields>(
    {
      name: { presence: true },
      email: { presence: true, email: true, uniqueEmail: false },
      password: { presence: true, length: { minimum: 8 } }
    },
    { name: "", email: "", password: "" }
  );

  function renderSignupError() {
    if (!props.signupError) return null;
    return (
      <div
        className="alert alert-danger"
        dangerouslySetInnerHTML={{ __html: props.signupError }}
      />
    );
  }

  return (
    <>
      <h2>Get started with a free account</h2>

      <p>
        Creating an account will allow you to create and schedule games with
        other people.
      </p>

      {renderSignupError()}

      <form onSubmit={e => handleSubmit(e, details => props.signup(details))}>
        <FormGroup name="name" label="Name" errors={errors.name}>
          <Input
            id="name"
            name="name"
            value={data.name}
            onChange={handleInput}
          />
        </FormGroup>

        <FormGroup name="email" label="Email" errors={errors.email}>
          <Input
            id="email"
            type="email"
            name="email"
            value={data.email}
            onChange={handleInput}
          />
        </FormGroup>

        <FormGroup name="password" label="Password" errors={errors.password}>
          <Input
            id="password"
            type="password"
            name="password"
            value={data.password}
            onChange={handleInput}
          />
        </FormGroup>

        <SpinnerButton text="Create Account" isSpinning={props.signingUp} />
      </form>
    </>
  );
};

const mapStateToProps = (state: AppState) => ({
  signupError: state.auth.error,
  signingUp: state.auth.status === "signingUp"
});

const mapDispatchToProps = { signup };

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(Signup);
