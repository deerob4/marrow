import React from "react";
import { connect } from "react-redux";
import { Link } from "react-router-dom";
import { User, AppState } from "../types";
import { logout } from "../thunks/auth";

interface Props {
  user: User;
  logout: () => void;
}

const Navbar: React.SFC<Props> = ({ user, logout }) => {
  return (
    <nav className="navbar navbar-expand-lg navbar-dark bg-primary mb-4">
      <Link className="navbar-brand" to="/games">
        Marrow
      </Link>
      <div className="collapse navbar-collapse">
        <ul className="navbar-nav mr-auto">
          <li className="nav-item">
            <a
              className="nav-link"
              onClick={(e) => {
                e.preventDefault();
                logout();
              }}
              href="/logout"
            >
              Logout
            </a>
          </li>
        </ul>
      </div>
    </nav>
  );
};

const mapStateToProps = (state: AppState) => ({
  user: state.user,
});

const mapDispatchToProps = { logout };

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(Navbar);
