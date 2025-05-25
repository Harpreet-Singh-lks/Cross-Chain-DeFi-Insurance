
import HomePage from './pages/HomePage';
import { BrowserRouter, Routes, Route } from 'react-router-dom';import Navbar from './pages/Navbar';
import Userprofile from "./pages/userprofile"
import Policies from "./pages/Policies"
import Claims from "./pages/Claims"

// Layout component to include Navbar in specific routes

function App() {
  return (
    <BrowserRouter>
    <Navbar />
    <Routes>
      <Route path="/" element={<HomePage />} />
      <Route path="/userprofile" element={<Userprofile />} />
      <Route path="/policies" element={<Policies />} />
      <Route path="/claims" element={<Claims />} />
      {/* Other routes */}
    </Routes>
  </BrowserRouter>
      
   
  );
}

export default App;