import * as React from "react";
import styled from "styled-components";
import { Route, Link, Switch, Redirect } from "react-router-dom";
import Login from "./Login";
import Signup from "./Signup";
// import { signout } from "./actions";
import { connect } from "react-redux";

interface Props {
  // loggedIn: boolean;
  // user: string;
  // signout: () => void;
}

const AuthContainer = styled.div`
  background-color: #6161ff;
  width: 100%;
  height: 100%;
  display: grid;
`;

const InnerAuth = styled.div`
  background-color: #fff;
  padding: 30px;
  width: 400px;
  box-shadow: 0px 10px 30px 0px rgba(0, 0, 0, 0.1);
  /* Uncomment to centre auth instead. */
  border-radius: 5px;
  margin: auto;
`;

const Logo = styled.h1`
  font-family: reross-quadratic, sans-serif;
  text-align: center;
  margin-bottom: 0;
`;

const Auth: React.SFC<Props> = props => {
  return (
    <AuthContainer>
      <InnerAuth>
        <div className="d-flex justify-content-between align-items-center">
          <Logo>Marrow</Logo>

          <Route
            path="/signin"
            render={() => <Link to="signup">Create Account</Link>}
          />
          <Route
            path="/signup"
            render={() => <Link to="signin">Sign In</Link>}
          />
        </div>
        <div className="pt-3">
          <Switch>
            <Route path="/signin" component={Login} />
            <Route path="/signup" component={Signup} />
            <Route render={() => <Redirect to="/signin" />} />
          </Switch>
        </div>
      </InnerAuth>
    </AuthContainer>
  );
};

export default Auth;
