import React from 'react';
import { Link } from 'react-router-dom';
import Header from './Header';
import './LandingPage.css';

function LandingPage() {
  return (
    <div className="landing-page">
      <Header />

      <div className="options-container">
        {options.map((option, index) => (
          <Link key={index} to={`/${option.toLowerCase()}`} className="option">
            <button>{option}</button>
          </Link>
        ))}
      </div>
    </div>
  );
}

const options = [
  'Manufacturer',
  'Warehouse',
  'Retailer',
  'Farmer',
  'DepartmentOfFertilizer',
  'DepartmentOfAgriculture',
];

export default LandingPage;