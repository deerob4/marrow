import React from "react";
import { connect } from "react-redux";

import Input from "./Input";
import FormGroup from "./FormGroup";
import SpinnerButton from "./SpinnerButton";

import { useForm } from "../hooks/useForm";
import { useTitle } from "../hooks/useTitle";
import { login } from "../thunks/auth";
import { LoginCredentials, AppState } from "../types";

interface Props {
  login: typeof login;
  loginError: string;
  loggingIn: boolean;
  signedOut: boolean;
}

const Login: React.FC<Props> = (props) => {
  useTitle("Sign In");

  const { data, errors, handleInput, handleSubmit } = useForm<LoginCredentials>(
    {
      email: { presence: { allowEmpty: false } },
      password: { presence: { allowEmpty: false } },
    },
    { email: "", password: "" }
  );

  function renderLoginError() {
    if (!props.loginError) return null;
    return <div className="alert alert-danger">{props.loginError}</div>;
  }

  function renderSignoutMessage() {
    if (!props.signedOut) return null;
    return (
      <div className="alert alert-success">
        You have successfully been signed out.
      </div>
    );
  }

  return (
    <>
      <h2>Sign in to your account</h2>

      <p>Enter your credentials below to access and make changes to your games.</p>

      {renderLoginError()}
      {renderSignoutMessage()}

      <form
        onSubmit={(e) => {
          handleSubmit(e, (credentials) => props.login(credentials));
        }}
      >
        <FormGroup name="email" label="Email" errors={errors.email}>
          <Input
            id="email"
            name="email"
            type="email"
            value={data.email}
            onChange={handleInput}
          />
        </FormGroup>

        <FormGroup name="password" label="Password" errors={errors.password}>
          <Input
            id="password"
            name="password"
            type="password"
            value={data.password}
            onChange={handleInput}
          />
        </FormGroup>

        <SpinnerButton text="Sign In" isSpinning={props.loggingIn} />
      </form>
    </>
  );
};

const mapStateToProps = (state: AppState) => ({
  loginError: state.auth.error,
  signedOut: state.user === null,
  loggingIn: state.auth.status === "loggingIn",
});

const mapDispatchToProps = { login };

export default connect(
  mapStateToProps,
  mapDispatchToProps
  // @ts-ignore
)(Login);
