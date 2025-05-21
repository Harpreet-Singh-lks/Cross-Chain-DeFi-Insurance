
//import './App.css';
import HomePage from './pages/HomePage';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import ProfilePage from './pages/ProfilePage';

function App() {
  return (
    <Router>
    <Routes>
        <Route path="/" element={<HomePage />} />
        <Route path="/Profile" element={<ProfilePage />} />
    </Routes>
</Router>
  );
}

export default App;
