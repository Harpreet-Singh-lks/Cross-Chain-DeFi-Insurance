import React from 'react';
import { useNavigate, Link } from 'react-router-dom';
import '../styles/navbar.css';
import Userprofile from "./userprofile"

export default function Navbar() {
    const navigate = useNavigate();

    const handleLogout = () => {
        // Clear any authentication tokens or user data from localStorage
        localStorage.removeItem('userToken');
        localStorage.removeItem('userAddress');
        
        // Redirect to home page
        navigate('/');
    };

    return (
        <nav className="nav">
            <Link to="/" className="site-title">DeFi Insurance</Link>
            
            <ul>
                <li>
                    <Link to="/userprofile" className="UserInformation">User Data</Link>
                </li>
                <li>
                    <Link to="/policies">Policies</Link>
                </li>
               
                <li>
                    <button className="logout-btn" onClick={handleLogout}>
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
                            <path d="M16 13v-2H7V8l-5 4 5 4v-3h9zm-1-8h4v12h-4v2h6V3h-6v2z" />
                        </svg>
                        Logout
                    </button>
                </li>
            </ul>
        </nav>
    );
}